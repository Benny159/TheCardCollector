import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- WICHTIG: DIESER IMPORT HAT GEFEHLT ---
import '../database/app_database.dart'; 

import '../../domain/models/api_card.dart';
import '../../domain/models/api_set.dart';
import '../sync/set_importer.dart';
import '../database/database_provider.dart';
import 'tcg_api_client.dart';
import 'package:intl/intl.dart';

// --- 1. CONFIG ---
enum SearchMode { name, artist }
final searchModeProvider = StateProvider<SearchMode>((ref) => SearchMode.name);
final searchQueryProvider = StateProvider<String>((ref) => '');

// --- 2. SETS PROVIDER ---
final allSetsProvider = FutureProvider<List<ApiSet>>((ref) async {
  final db = ref.read(databaseProvider);
  final localSets = await db.select(db.cardSets).get();
  
  if (localSets.isNotEmpty) {
    localSets.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
    return localSets.map((s) => ApiSet(
      id: s.id,
      name: s.name,
      series: s.series,
      printedTotal: s.printedTotal,
      total: s.total,
      releaseDate: s.releaseDate,
      updatedAt: s.updatedAt,
      logoUrl: s.logoUrl,
      symbolUrl: s.symbolUrl,
    )).toList();
  }

  final api = ref.read(apiClientProvider);
  final importer = SetImporter(api, db);
  final apiSets = await api.fetchAllSets();
  for (final set in apiSets) {
    await importer.importSetInfo(set);
  }
  return apiSets;
});

// --- 3. SEARCH PROVIDER (Optimiert) ---
final searchResultsProvider = FutureProvider<List<ApiCard>>((ref) async {
  final queryText = ref.watch(searchQueryProvider);
  final mode = ref.watch(searchModeProvider);

  if (queryText.isEmpty) return [];

  final db = ref.watch(databaseProvider);

  final query = db.select(db.cards).join([
    innerJoin(db.cardSets, db.cardSets.id.equalsExp(db.cards.setId))
  ]);
  
  if (mode == SearchMode.name) {
    query.where(db.cards.name.like('%$queryText%'));
  } else {
    query.where(db.cards.artist.like('%$queryText%'));
  }
  
  final rows = await query.get();
  
  // -- TURBO: Wir holen Inventar-Daten für alle gefundenen Karten auf einmal --
  final cardIds = rows.map((r) => r.readTable(db.cards).id).toList();
  final ownedSet = await _fetchOwnedIds(db, cardIds);
  // -----------------------------------------------------------------------

  List<ApiCard> results = [];

  for (final row in rows) {
    final card = row.readTable(db.cards);
    final set = row.readTable(db.cardSets);

    final cmPrice = await (db.select(db.cardMarketPrices)
          ..where((tbl) => tbl.cardId.equals(card.id))
          ..orderBy([(t) => OrderingTerm(expression: t.fetchedAt, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();

    final tcgPrice = await (db.select(db.tcgPlayerPrices)
          ..where((tbl) => tbl.cardId.equals(card.id))
          ..orderBy([(t) => OrderingTerm(expression: t.fetchedAt, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();

    results.add(_mapToApiCard(card, set.printedTotal, ownedSet.contains(card.id), cmPrice, tcgPrice));
  }

  return results;
});

// --- 4. SET LIST PROVIDER (ULTRA OPTIMIERT) ---
final cardsForSetProvider = FutureProvider.family<List<ApiCard>, String>((ref, setId) async {
  final db = ref.read(databaseProvider);

  // A) Basis-Daten holen
  final setInfo = await (db.select(db.cardSets)..where((tbl) => tbl.id.equals(setId))).getSingleOrNull();
  final dbCards = await (db.select(db.cards)..where((tbl) => tbl.setId.equals(setId))).get();

  if (dbCards.isEmpty) return [];

  // Alle IDs sammeln
  final cardIds = dbCards.map((c) => c.id).toList();

  // B) BULK FETCH: Inventar (Alles auf einmal holen)
  final ownedSet = await _fetchOwnedIds(db, cardIds);

  // C) BULK FETCH: Preise (Alles auf einmal holen!)
  final allCmPrices = await (db.select(db.cardMarketPrices)..where((tbl) => tbl.cardId.isIn(cardIds))).get();
  final allTcgPrices = await (db.select(db.tcgPlayerPrices)..where((tbl) => tbl.cardId.isIn(cardIds))).get();

  // Maps erstellen für schnellen Zugriff: ID -> Preis
  final cmPriceMap = _getLatestCmPrices(allCmPrices);
  final tcgPriceMap = _getLatestTcgPrices(allTcgPrices);

  // D) Liste zusammenbauen
  return dbCards.map((dbCard) {
    return _mapToApiCard(
      dbCard,
      setInfo?.printedTotal ?? 0,
      ownedSet.contains(dbCard.id), // Blitzschneller Check
      cmPriceMap[dbCard.id],        // Blitzschneller Zugriff
      tcgPriceMap[dbCard.id],       // Blitzschneller Zugriff
    );
  }).toList();
});

final setByIdProvider = FutureProvider.family<ApiSet?, String>((ref, setId) async {
  final sets = await ref.watch(allSetsProvider.future);
  try {
    return sets.firstWhere((s) => s.id == setId);
  } catch (e) {
    return null;
  }
});

// --- NEU & WICHTIG: setStatsProvider HIERHIN VERSCHIEBEN ---
// Damit wir ihn von überall (auch aus dem BottomSheet) neu laden können.
final setStatsProvider = FutureProvider.family<int, String>((ref, setId) async {
  final db = ref.read(databaseProvider);
  
  // 1. Alle Karten-IDs des Sets holen
  final setCardsQuery = db.select(db.cards)..where((tbl) => tbl.setId.equals(setId));
  final setCardIds = (await setCardsQuery.get()).map((c) => c.id).toList();
  
  if (setCardIds.isEmpty) return 0;

  // 2. Prüfen, welche davon im Inventar sind (Unique Count)
  final result = await (db.select(db.userCards)
    ..where((tbl) => tbl.cardId.isIn(setCardIds))
  ).get();
  
  // Wir zählen unique cardIds im Inventar
  final uniqueOwned = result.map((e) => e.cardId).toSet().length;
  
  return uniqueOwned;
});

// --- HILFSFUNKTIONEN (Private) ---

// Holt alle IDs, die der User besitzt, als Set (für schnellen .contains Check)
Future<Set<String>> _fetchOwnedIds(AppDatabase db, List<String> cardIds) async {
  if (cardIds.isEmpty) return {};
  
  final ownedEntries = await (db.select(db.userCards)
    ..where((tbl) => tbl.cardId.isIn(cardIds))
  ).get();

  return ownedEntries.map((e) => e.cardId).toSet();
}

// Wandelt DB-Objekt in API-Objekt um
ApiCard _mapToApiCard(
  Card dbCard,  // <-- Hier wird 'Card' aus app_database.dart benötigt
  int printedTotal, 
  bool isOwned, 
  CardMarketPrice? cmPrice, // <-- Hier wird 'CardMarketPrice' aus app_database.dart benötigt
  TcgPlayerPrice? tcgPrice  // <-- Hier wird 'TcgPlayerPrice' aus app_database.dart benötigt
) {
  List<String> parseList(String? value) => (value ?? '').split(', ').where((e) => e.isNotEmpty).toList();

  return ApiCard(
    id: dbCard.id,
    name: dbCard.name,
    supertype: dbCard.supertype ?? '',
    subtypes: parseList(dbCard.subtypes),
    types: parseList(dbCard.types),
    setId: dbCard.setId,
    number: dbCard.number,
    setPrintedTotal: printedTotal.toString(),
    artist: dbCard.artist ?? '',
    rarity: dbCard.rarity ?? 'Unbekannt',
    flavorText: dbCard.flavorText,
    smallImageUrl: dbCard.imageUrlSmall,
    largeImageUrl: dbCard.imageUrlLarge,
    isOwned: isOwned,
    
    cardmarket: cmPrice != null 
        ? ApiCardMarket(
            url: cmPrice.url ?? '',
            updatedAt: cmPrice.updatedAt,
            trendPrice: cmPrice.trendPrice,
            avg30: cmPrice.avg30,
            lowPrice: cmPrice.lowPrice,
            reverseHoloTrend: cmPrice.reverseHoloTrend,
          )
        : null,
    
    tcgplayer: tcgPrice != null 
        ? ApiTcgPlayer(
            url: tcgPrice.url ?? '',
            updatedAt: tcgPrice.updatedAt,
            prices: ApiTcgPlayerPrices(
              normal: ApiPriceType(market: tcgPrice.normalMarket, low: tcgPrice.normalLow),
              reverseHolofoil: ApiPriceType(market: tcgPrice.reverseHoloMarket, low: tcgPrice.reverseHoloLow),
            ),
          )
        : null, 
  );
}

Map<String, CardMarketPrice> _getLatestCmPrices(List<CardMarketPrice> allPrices) {
  final Map<String, CardMarketPrice> map = {};
  for (final p in allPrices) {
    if (!map.containsKey(p.cardId) || p.fetchedAt.isAfter(map[p.cardId]!.fetchedAt)) {
      map[p.cardId] = p;
    }
  }
  return map;
}

Map<String, TcgPlayerPrice> _getLatestTcgPrices(List<TcgPlayerPrice> allPrices) {
  final Map<String, TcgPlayerPrice> map = {};
  for (final p in allPrices) {
    if (!map.containsKey(p.cardId) || p.fetchedAt.isAfter(map[p.cardId]!.fetchedAt)) {
      map[p.cardId] = p;
    }
  }
  return map;
}

// 1. Hilfsklasse: Verbindet Karte + User-Daten + SET-Daten
class InventoryItem {
  final ApiCard card;
  final ApiSet set; // <--- NEU: Das Set-Objekt für Logos/Namen
  final int quantity;
  final String variant;
  final double totalValue;

  InventoryItem({
    required this.card,
    required this.set, 
    required this.quantity,
    required this.variant,
    required this.totalValue,
  });
}

// 2. Sortier-Optionen
enum InventorySort { value, name, rarity, type, number }

// 3. Filter-Status Provider
final inventorySortProvider = StateProvider<InventorySort>((ref) => InventorySort.value);
final inventoryGroupBySetProvider = StateProvider<bool>((ref) => false);

// 4. DER HAUPT-PROVIDER (JETZT ALS STREAM!)
// StreamProvider sorgt für automatische Updates, wenn sich die DB ändert.
final inventoryProvider = StreamProvider<List<InventoryItem>>((ref) {
  final db = ref.read(databaseProvider);

  // A) Query bauen (Join UserCards -> Cards -> Sets)
  final query = db.select(db.userCards).join([
    innerJoin(db.cards, db.cards.id.equalsExp(db.userCards.cardId)),
    innerJoin(db.cardSets, db.cardSets.id.equalsExp(db.cards.setId)),
  ]);

  // B) .watch() nutzen statt .get() -> Das macht es LIVE!
  return query.watch().asyncMap((rows) async {
    // Diese Funktion wird jedes Mal ausgeführt, wenn sich UserCards ändert.
    
    // Preise holen (Bulk)
    final cardIds = rows.map((r) => r.readTable(db.userCards).cardId).toList();
    final allCmPrices = await (db.select(db.cardMarketPrices)..where((tbl) => tbl.cardId.isIn(cardIds))).get();
    final allTcgPrices = await (db.select(db.tcgPlayerPrices)..where((tbl) => tbl.cardId.isIn(cardIds))).get();
    
    final cmPriceMap = _getLatestCmPrices(allCmPrices);
    final tcgPriceMap = _getLatestTcgPrices(allTcgPrices);

    List<InventoryItem> items = [];

    for (final row in rows) {
      final userCard = row.readTable(db.userCards);
      final dbCard = row.readTable(db.cards);
      final dbSet = row.readTable(db.cardSets); // Das Set aus der DB

      // ApiCard bauen
      final apiCard = _mapToApiCard(
        dbCard, 
        dbSet.printedTotal, 
        true, 
        cmPriceMap[dbCard.id], 
        tcgPriceMap[dbCard.id]
      );

      // ApiSet bauen (für das UI)
      final apiSet = ApiSet(
        id: dbSet.id,
        name: dbSet.name,
        series: dbSet.series,
        printedTotal: dbSet.printedTotal,
        total: dbSet.total,
        releaseDate: dbSet.releaseDate,
        updatedAt: dbSet.updatedAt,
        logoUrl: dbSet.logoUrl,
        symbolUrl: dbSet.symbolUrl,
      );

      // Preis berechnen
      double singlePrice = 0.0;
      if (userCard.variant == 'Reverse Holo') {
        singlePrice = apiCard.tcgplayer?.prices?.reverseHolofoil?.market 
                   ?? apiCard.cardmarket?.reverseHoloTrend ?? 0.0;
      } else if (userCard.variant == 'Holo') {
         singlePrice = apiCard.tcgplayer?.prices?.holofoil?.market ?? 0.0;
         if (singlePrice == 0) singlePrice = apiCard.cardmarket?.trendPrice ?? 0.0;
      } else {
        singlePrice = apiCard.cardmarket?.trendPrice 
                   ?? apiCard.tcgplayer?.prices?.normal?.market ?? 0.0;
      }

      items.add(InventoryItem(
        card: apiCard,
        set: apiSet, // <--- Hier übergeben wir das Set
        quantity: userCard.quantity,
        variant: userCard.variant,
        totalValue: singlePrice * userCard.quantity,
      ));
    }

    return items;
  });
});

// 2. NEU: Provider für die Top 10 teuersten Karten
final top10CardsProvider = Provider<List<InventoryItem>>((ref) {
  // Wir nutzen den existierenden Stream!
  final allItemsAsync = ref.watch(inventoryProvider);
  
  return allItemsAsync.when(
    data: (items) {
      // Kopie erstellen und sortieren
      final sorted = List<InventoryItem>.from(items);
      // Teuerste zuerst (nach Gesamtpreis des Items, oder Einzelpreis? Meist Einzelpreis für Top 10)
      // Wir nehmen hier den *Gesamtwert* des Stacks (z.B. 2x Glurak = 200€ > 1x Lugia = 150€)
      sorted.sort((a, b) => b.totalValue.compareTo(a.totalValue));
      return sorted.take(10).toList();
    },
    loading: () => [],
    error: (_,__) => [],
  );
});

// 3. NEU: Provider für die Historie (Diagramm-Daten)
final portfolioHistoryProvider = StreamProvider<List<PortfolioHistoryData>>((ref) {
  final db = ref.read(databaseProvider);
  // Sortiert nach Datum aufsteigend
  return (db.select(db.portfolioHistory)..orderBy([(t) => OrderingTerm(expression: t.date)])).watch();
});

// 4. NEU: Funktion zum Erstellen eines Snapshots (ruft man beim App-Start auf)
Future<void> createPortfolioSnapshot(WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  
  // 1. Berechne aktuellen Gesamtwert
  // (Wir holen die Daten einmalig "on demand")
  final items = await ref.read(inventoryProvider.future);
  final double currentTotal = items.fold(0.0, (sum, item) => sum + item.totalValue);

  if (currentTotal == 0) return; // Leeres Inventar nicht speichern (optional)

  final today = DateTime.now();
  // Nur Datum ohne Uhrzeit für den Vergleich
  final todayDate = DateTime(today.year, today.month, today.day);

  // 2. Prüfen, ob für HEUTE schon ein Eintrag existiert
  final existingEntry = await (db.select(db.portfolioHistory)
    ..where((t) => t.date.equals(todayDate))
  ).getSingleOrNull();

  if (existingEntry != null) {
    // Update (falls sich heute der Wert geändert hat durch Hinzufügen)
    await (db.update(db.portfolioHistory)..where((t) => t.id.equals(existingEntry.id)))
        .write(PortfolioHistoryCompanion(totalValue: Value(currentTotal)));
  } else {
    // Insert (Neuer Tag)
    await db.into(db.portfolioHistory).insert(
      PortfolioHistoryCompanion.insert(
        date: todayDate,
        totalValue: currentTotal,
      ),
    );
  }
}