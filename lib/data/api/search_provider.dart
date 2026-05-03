import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart'; 
import '../../domain/models/api_card.dart';
import '../../domain/models/api_set.dart';
import '../sync/set_importer.dart';
import '../database/database_provider.dart';
import '../../domain/logic/binder_service.dart';
import 'package:flutter/foundation.dart';
import '../../data/api/tcgdex_api_client.dart';

// --- 1. CONFIG ---
enum SearchMode { name, artist }
final searchModeProvider = StateProvider<SearchMode>((ref) => SearchMode.name);
final searchQueryProvider = StateProvider<String>((ref) => '');
final inventoryGroupBySetProvider = StateProvider<bool>((ref) => false);

// --- 2. SETS PROVIDER ---
final allSetsProvider = FutureProvider<List<ApiSet>>((ref) async {
  final db = ref.read(databaseProvider);
  final localSets = await db.select(db.cardSets).get();
  
  if (localSets.isNotEmpty) {
    // JETZT KÖNNEN WIR WIEDER NACH DATUM SORTIEREN!
    localSets.sort((a, b) {
       final dateA = a.releaseDate ?? '';
       final dateB = b.releaseDate ?? '';
       return dateB.compareTo(dateA); // Neueste zuerst
    });

    return localSets.map((s) => ApiSet(
      id: s.id,
      name: s.name,
      nameDe: s.nameDe,
      series: s.series,
      printedTotal: s.printedTotal ?? 0,
      total: s.total ?? 0,
      releaseDate: s.releaseDate ?? '',
      updatedAt: s.updatedAt,
      logoUrl: s.logoUrl,
      logoUrlDe: s.logoUrlDe,
      symbolUrl: s.symbolUrl,
    )).toList();
  }

  // Fallback: Initialer Download (nur Metadaten der Sets)
  final dexApi = ref.read(tcgDexApiClientProvider);
  final importer = SetImporter(dexApi, db);
  await importer.syncAllData(); 
  
  return [];
});

// --- 3. SEARCH PROVIDER ---
final searchResultsProvider = FutureProvider<List<ApiCard>>((ref) async {
  final queryText = ref.watch(searchQueryProvider);
  final mode = ref.watch(searchModeProvider);

  if (queryText.isEmpty) return [];

  final db = ref.watch(databaseProvider);

  final query = db.select(db.cards).join([
    innerJoin(db.cardSets, db.cardSets.id.equalsExp(db.cards.setId))
  ]);
  
  if (mode == SearchMode.name) {
    query.where(db.cards.name.like('%$queryText%') | db.cards.nameDe.like('%$queryText%'));
  } else {
    query.where(db.cards.artist.like('%$queryText%'));
  }
  
  query.limit(100);

  final rows = await query.get();
  if (rows.isEmpty) return [];

  // IDs sammeln für Batch-Abfragen
  final cardIds = rows.map((r) => r.readTable(db.cards).id).toList();

  // 2. ALLE nötigen Zusatzdaten PARALLEL in einem Rutsch holen
  final results = await Future.wait([
    _fetchOwnedIds(db, cardIds),
    (db.select(db.cardMarketPrices)..where((tbl) => tbl.cardId.isIn(cardIds))).get(),
    (db.select(db.tcgPlayerPrices)..where((tbl) => tbl.cardId.isIn(cardIds))).get(),
    (db.select(db.customCardPrices)..where((tbl) => tbl.cardId.isIn(cardIds))).get(),
  ]);

  final Set<String> ownedSet = results[0] as Set<String>;
  final List<CardMarketPrice> allCmPrices = results[1] as List<CardMarketPrice>;
  final List<TcgPlayerPrice> allTcgPrices = results[2] as List<TcgPlayerPrice>;
  final List<CustomCardPrice> allCustomPrices = results[3] as List<CustomCardPrice>;

  // 3. Mapping für schnellen Zugriff
  final cmPriceMap = _getLatestCmPrices(allCmPrices);
  final tcgPriceMap = _getLatestTcgPrices(allTcgPrices);
  final customPriceMap = _getLatestCustomPrices(allCustomPrices);

  List<ApiCard> apiCards = [];

  // 4. Synchrones, schnelles Zusammenbauen
  for (final row in rows) {
    final card = row.readTable(db.cards);
    final set = row.readTable(db.cardSets);

    apiCards.add(_mapToApiCard(
      card, 
      set.printedTotal ?? 0, 
      ownedSet.contains(card.id), 
      cmPriceMap[card.id], 
      tcgPriceMap[card.id],
      customPriceMap[card.id]
    ));
  }

  return apiCards;
});

// --- 4. SET LIST PROVIDER ---
final cardsForSetProvider = FutureProvider.family<List<ApiCard>, String>((ref, setId) async {
  final db = ref.read(databaseProvider);
  final setInfo = await (db.select(db.cardSets)..where((tbl) => tbl.id.equals(setId))).getSingleOrNull();
  
  final dbCards = await (db.select(db.cards)
      ..where((tbl) => tbl.setId.equals(setId))
      ..orderBy([(t) => OrderingTerm(expression: t.sortNumber)]) 
    ).get();

  if (dbCards.isEmpty) return [];

  final cardIds = dbCards.map((c) => c.id).toList();
  final ownedSet = await _fetchOwnedIds(db, cardIds);

  final allCmPrices = await (db.select(db.cardMarketPrices)..where((tbl) => tbl.cardId.isIn(cardIds))).get();
  final allTcgPrices = await (db.select(db.tcgPlayerPrices)..where((tbl) => tbl.cardId.isIn(cardIds))).get();
  final allCustomPrices = await (db.select(db.customCardPrices)..where((tbl) => tbl.cardId.isIn(cardIds))).get();

  final cmPriceMap = _getLatestCmPrices(allCmPrices);
  final tcgPriceMap = _getLatestTcgPrices(allTcgPrices);
  final customPriceMap = _getLatestCustomPrices(allCustomPrices);

  return dbCards.map((dbCard) {
    return _mapToApiCard(
      dbCard,
      setInfo?.printedTotal ?? 0,
      ownedSet.contains(dbCard.id),
      cmPriceMap[dbCard.id],
      tcgPriceMap[dbCard.id],
      customPriceMap[dbCard.id],
    );
  }).toList();
});

// --- SET BY ID PROVIDER ---
final setByIdProvider = FutureProvider.family<ApiSet?, String>((ref, setId) async {
  final sets = await ref.watch(allSetsProvider.future);
  try {
    return sets.firstWhere((s) => s.id == setId);
  } catch (e) {
    return null;
  }
});

// --- STATS PROVIDER ---
final setStatsProvider = FutureProvider.family<int, String>((ref, setId) async {
  final db = ref.read(databaseProvider);
  final setCardsQuery = db.select(db.cards)..where((tbl) => tbl.setId.equals(setId));
  final setCardIds = (await setCardsQuery.get()).map((c) => c.id).toList();
  if (setCardIds.isEmpty) return 0;
  final result = await (db.select(db.userCards)..where((tbl) => tbl.cardId.isIn(setCardIds))).get();
  return result.map((e) => e.cardId).toSet().length;
});

// --- HELPER ---

Future<Set<String>> _fetchOwnedIds(AppDatabase db, List<String> cardIds) async {
  if (cardIds.isEmpty) return {};
  final ownedEntries = await (db.select(db.userCards)..where((tbl) => tbl.cardId.isIn(cardIds))).get();
  return ownedEntries.map((e) => e.cardId).toSet();
}

ApiCard _mapToApiCard(
  Card dbCard, 
  int printedTotal, 
  bool isOwned, 
  CardMarketPrice? cmPrice, 
  TcgPlayerPrice? tcgPrice,
  CustomCardPrice? customPrice,
) {
  return ApiCard(
    id: dbCard.id,
    name: dbCard.name,
    nameDe: dbCard.nameDe,
    supertype: '', 
    subtypes: [],
    types: [],
    setId: dbCard.setId,
    number: dbCard.number,
    cardType: dbCard.cardType,
    setPrintedTotal: printedTotal.toString(),
    artist: dbCard.artist ?? '',
    rarity: dbCard.rarity ?? '',
    flavorText: dbCard.flavorText,
    flavorTextDe: dbCard.flavorTextDe,
    preferredPriceSource: dbCard.preferredPriceSource,
    customPrice: customPrice?.price,
    smallImageUrl: dbCard.imageUrl, 
    largeImageUrl: dbCard.imageUrl,
    imageUrlDe: dbCard.imageUrlDe,
    hasNormal: dbCard.hasNormal,
    hasHolo: dbCard.hasHolo,
    hasReverse: dbCard.hasReverse,
    hasWPromo: dbCard.hasWPromo,
    hasFirstEdition: dbCard.hasFirstEdition,
    
    isOwned: isOwned,
    
    cardmarket: cmPrice != null 
        ? ApiCardMarket(
            url: cmPrice.url ?? '',
            updatedAt: cmPrice.fetchedAt.toIso8601String(),
            trendPrice: cmPrice.trend,
            avg30: cmPrice.avg30,
            avg7: cmPrice.avg7,
            avg1: cmPrice.avg1,
            lowPrice: cmPrice.low,
            trendHolo: cmPrice.trendHolo,
            avg30Holo: cmPrice.avg30Holo,
            avg7Holo: cmPrice.avg7Holo,
            avg1Holo: cmPrice.avg1Holo,
            lowHolo: cmPrice.lowHolo,
            reverseHoloTrend: cmPrice.trendReverse,
          )
        : null,
    
    tcgplayer: tcgPrice != null 
        ? ApiTcgPlayer(
            url: tcgPrice.url ?? '',
            updatedAt: tcgPrice.fetchedAt.toIso8601String(),
            prices: ApiTcgPlayerPrices(
              normal: ApiPriceType(
                market: tcgPrice.normalMarket, 
                low: tcgPrice.normalLow,
                mid: tcgPrice.normalMid,
                directLow: tcgPrice.normalDirectLow,
              ),
              holofoil: ApiPriceType(
                market: tcgPrice.holoMarket,
                low: tcgPrice.holoLow,
                mid: tcgPrice.holoMid,
                directLow: tcgPrice.holoDirectLow,
              ),
              reverseHolofoil: ApiPriceType(
                market: tcgPrice.reverseMarket, 
                low: tcgPrice.reverseLow,
                mid: tcgPrice.reverseMid,
                directLow: tcgPrice.reverseDirectLow,
              ),
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

Map<String, CustomCardPrice> _getLatestCustomPrices(List<CustomCardPrice> allPrices) {
  final Map<String, CustomCardPrice> map = {};
  for (final p in allPrices) {
    if (!map.containsKey(p.cardId) || p.fetchedAt.isAfter(map[p.cardId]!.fetchedAt)) {
      map[p.cardId] = p;
    }
  }
  return map;
}

// -----------------------------------------------------------------------------
// INVENTORY PROVIDER
// -----------------------------------------------------------------------------

class InventoryItem {
  final ApiCard card;
  final ApiSet set;
  final int quantity;
  final String variant;
  final double totalValue;
  final String? binderName; 
  final UserCard userCard;
  final double performance; // --- NEU: Rendite / Gewinn in Euro ---

  InventoryItem({
    required this.card,
    required this.set, 
    required this.quantity,
    required this.variant,
    required this.totalValue,
    this.binderName, 
    required this.userCard,
    this.performance = 0.0, // Standardmäßig 0
  });
}
// --- NEU: Erweiterte Sortierung & Sortier-Richtung ---
enum InventorySort { value, name, rarity, type, performance, dateAdded }
final inventorySortProvider = StateProvider<InventorySort>((ref) => InventorySort.value);
// false = Absteigend (Das Beste/Neueste zuerst), true = Aufsteigend (Das Schlechteste/Älteste zuerst)
final inventorySortAscendingProvider = StateProvider<bool>((ref) => false);

// --- SCHRITT 1: ID-Provider (Blitzschnell, beobachtet nur Veränderungen an der Menge) ---
// PERFORMANCE FIX: Aus StreamProvider wird ein manueller FutureProvider.
// Verhindert, dass SQLite bei jedem Insert die UI blockiert, während der Dialog lädt!
final inventoryIdsProvider = FutureProvider<List<int>>((ref) async {
  final db = ref.read(databaseProvider); // read() statt watch()
  final rows = await db.select(db.userCards).get();
  return rows.map((r) => r.id).toList();
});

// --- SCHRITT 2: Detail-Provider (Cacht die aufwändige Logik pro EINZELNER Karte) ---
final inventoryItemProvider = FutureProvider.family<List<InventoryItem>, int>((ref, userCardId) async {
  final db = ref.watch(databaseProvider);

  final row = await (db.select(db.userCards).join([
    innerJoin(db.cards, db.cards.id.equalsExp(db.userCards.cardId)),
    innerJoin(db.cardSets, db.cardSets.id.equalsExp(db.cards.setId)),
  ])..where(db.userCards.id.equals(userCardId))).getSingle();

  final userCard = row.readTable(db.userCards);
  final dbCard = row.readTable(db.cards);
  final dbSet = row.readTable(db.cardSets);
  final cardId = dbCard.id;

  // Preise NUR für diese eine Karte laden!
  final allCmPrices = await (db.select(db.cardMarketPrices)..where((tbl) => tbl.cardId.equals(cardId))..orderBy([(t) => OrderingTerm(expression: t.fetchedAt, mode: OrderingMode.asc)])).get();
  final allTcgPrices = await (db.select(db.tcgPlayerPrices)..where((tbl) => tbl.cardId.equals(cardId))..orderBy([(t) => OrderingTerm(expression: t.fetchedAt, mode: OrderingMode.asc)])).get();
  final allCustomPrices = await (db.select(db.customCardPrices)..where((tbl) => tbl.cardId.equals(cardId))..orderBy([(t) => OrderingTerm(expression: t.fetchedAt, mode: OrderingMode.asc)])).get();

  final latestCm = allCmPrices.isNotEmpty ? allCmPrices.last : null;
  final latestTcg = allTcgPrices.isNotEmpty ? allTcgPrices.last : null;
  final latestCustom = allCustomPrices.isNotEmpty ? allCustomPrices.last : null;

  final apiCard = _mapToApiCard(dbCard, dbSet.printedTotal ?? 0, true, latestCm, latestTcg, latestCustom);
  final apiSet = ApiSet(
    id: dbSet.id, name: dbSet.name, nameDe: dbSet.nameDe, series: dbSet.series,
    printedTotal: dbSet.printedTotal ?? 0, total: dbSet.total ?? 0,
    releaseDate: dbSet.releaseDate ?? '', updatedAt: dbSet.updatedAt,
    logoUrl: dbSet.logoUrl, logoUrlDe: dbSet.logoUrlDe, symbolUrl: dbSet.symbolUrl,
  );

  // Preis-Logik
  double singlePrice = 0.0;
  double purchasePrice = 0.0;
  bool baseIsHolo = !dbCard.hasNormal && dbCard.hasHolo;
  final variant = userCard.variant;
  final isFirstEd = variant.toLowerCase().contains('1st') || variant.toLowerCase().contains('first');
  final isHolo = variant.toLowerCase().contains('holo') || baseIsHolo;
  final isReverse = variant == 'Reverse Holo';
  final pref = dbCard.preferredPriceSource;

  double getTcg(ApiTcgPlayer? tcg) {
     if (tcg == null) return 0.0;
     double p = 0.0;
     if (isReverse) { p = tcg.prices?.reverseHolofoil?.market ?? 0.0; }
     else if (isHolo) p = tcg.prices?.holofoil?.market ?? 0.0;
     else p = tcg.prices?.normal?.market ?? 0.0;
     if (p == 0.0) p = tcg.prices?.normal?.market ?? tcg.prices?.holofoil?.market ?? tcg.prices?.reverseHolofoil?.market ?? 0.0;
     return p;
  }

  double getCm(ApiCardMarket? cm) {
     if (cm == null) return 0.0;
     double p = 0.0;
     if (dbCard.hasFirstEdition) { p = isFirstEd ? (isHolo ? cm.trendPrice ?? 0.0 : cm.trendHolo ?? 0.0) : (isHolo ? cm.trendHolo ?? 0.0 : cm.trendPrice ?? 0.0); }
     else if (isReverse) { p = cm.reverseHoloTrend ?? cm.trendHolo ?? 0.0; }
     else if (isHolo && !baseIsHolo) { p = cm.trendHolo ?? 0.0; }
     else { p = cm.trendPrice ?? 0.0; }
     if (p == 0.0) p = cm.trendPrice ?? cm.trendHolo ?? 0.0;
     return p;
  }

  String usedSource = pref;
  if (userCard.customPrice != null && userCard.customPrice! > 0) {
      singlePrice = userCard.customPrice!;
      purchasePrice = singlePrice;
      usedSource = 'custom';
  } else {
      double tcgCur = getTcg(apiCard.tcgplayer);
      double cmCur = getCm(apiCard.cardmarket);
      if (pref == 'custom' && apiCard.customPrice != null && apiCard.customPrice! > 0) {
          singlePrice = apiCard.customPrice!;
          usedSource = 'custom';
          purchasePrice = singlePrice;
      } else if (pref == 'tcgplayer' && tcgCur > 0.0) {
          singlePrice = tcgCur; usedSource = 'tcgplayer';
      } else if (pref == 'cardmarket' && cmCur > 0.0) {
          singlePrice = cmCur; usedSource = 'cardmarket';
      } else {
          if (cmCur > 0.0) { singlePrice = cmCur; usedSource = 'cardmarket'; }
          else if (tcgCur > 0.0) { singlePrice = tcgCur; usedSource = 'tcgplayer'; }
          else if (apiCard.customPrice != null) { singlePrice = apiCard.customPrice!; usedSource = 'custom'; purchasePrice = singlePrice; }
      }
  }

  if (usedSource != 'custom') {
     final targetDate = userCard.createdAt;
     if (usedSource == 'tcgplayer' && allTcgPrices.isNotEmpty) {
        final index = allTcgPrices.lastIndexWhere((p) => !p.fetchedAt.isAfter(targetDate));
        final p = (index != -1) ? allTcgPrices[index] : allTcgPrices.first;
        double hp = 0.0;
        if (isReverse) { hp = p.reverseMarket ?? 0.0; }
        else if (isHolo) { hp = p.holoMarket ?? 0.0; }
        else { hp = p.normalMarket ?? 0.0; }
        if (hp == 0.0) { hp = p.normalMarket ?? p.holoMarket ?? p.reverseMarket ?? 0.0; }
        purchasePrice = hp;
     } else if (usedSource == 'cardmarket' && allCmPrices.isNotEmpty) {
        final index = allCmPrices.lastIndexWhere((p) => !p.fetchedAt.isAfter(targetDate));
        final p = (index != -1) ? allCmPrices[index] : allCmPrices.first;
        double hp = 0.0;
        if (dbCard.hasFirstEdition) { hp = isFirstEd ? (isHolo ? p.trend ?? 0.0 : p.trendHolo ?? 0.0) : (isHolo ? p.trendHolo ?? 0.0 : p.trend ?? 0.0); }
        else if (isReverse) { hp = p.trendReverse ?? p.trendHolo ?? 0.0; }
        else if (isHolo && !baseIsHolo) { hp = p.trendHolo ?? 0.0; }
        else { hp = p.trend ?? 0.0; }
        if (hp == 0.0) hp = p.trend ?? p.trendHolo ?? 0.0;
        purchasePrice = hp;
     }
  }

  if (purchasePrice == 0.0) purchasePrice = singlePrice;
  final double itemPerformance = (singlePrice - purchasePrice);

  // Binder-Zuweisungen NUR für diese eine Karte checken
  final binderCardsQuery = db.select(db.binderCards).join([
    innerJoin(db.binders, db.binders.id.equalsExp(db.binderCards.binderId))
  ]);
  binderCardsQuery.where((db.binderCards.userCardId.equals(userCardId) | (db.binderCards.cardId.equals(cardId) & db.binderCards.variant.equals(userCard.variant))) & db.binderCards.isPlaceholder.equals(false));
  final binderRows = await binderCardsQuery.get();

  final Map<String, int> bindersForThisCard = {};
  for (final bRow in binderRows) {
    final b = bRow.readTable(db.binders);
    bindersForThisCard[b.name] = (bindersForThisCard[b.name] ?? 0) + 1;
  }

  List<InventoryItem> items = [];
  int totalInBinders = 0;

  for (final entry in bindersForThisCard.entries) {
    final binderName = entry.key;
    final qtyInBinder = entry.value;
    int assignedQty = qtyInBinder;
    if (totalInBinders + assignedQty > userCard.quantity) { assignedQty = userCard.quantity - totalInBinders; }
    if (assignedQty <= 0) continue;
    totalInBinders += assignedQty;
    items.add(InventoryItem(
      card: apiCard, set: apiSet, quantity: assignedQty, variant: userCard.variant,
      totalValue: singlePrice * assignedQty, binderName: binderName, userCard: userCard,
      performance: itemPerformance * assignedQty,
    ));
  }

  final looseQty = userCard.quantity - totalInBinders;
  if (looseQty > 0) {
    items.add(InventoryItem(
      card: apiCard, set: apiSet, quantity: looseQty, variant: userCard.variant,
      totalValue: singlePrice * looseQty, binderName: null, userCard: userCard,
      performance: itemPerformance * looseQty,
    ));
  }

  return items;
});

// --- SCHRITT 3: Der Master-Provider (Sammelt alle gecachten Ergebnisse) ---
final inventoryProvider = FutureProvider<List<InventoryItem>>((ref) async {
  // 1. Liste der IDs überwachen
  final ids = await ref.watch(inventoryIdsProvider.future);
  if (ids.isEmpty) return [];

  // 2. Paralleles Laden: Riverpod hat 99% davon sofort aus dem Cache abrufbereit!
  final futures = ids.map((id) => ref.watch(inventoryItemProvider(id).future));
  final results = await Future.wait(futures);

  // 3. Flache Liste zusammenbauen
  return results.expand((i) => i).toList();
});

final top10CardsProvider = Provider<List<InventoryItem>>((ref) {
  final allItemsAsync = ref.watch(inventoryProvider);
  return allItemsAsync.when(
    data: (items) {
      final sorted = List<InventoryItem>.from(items);
      // --- FIX: Nach Einzel-Wert sortieren ---
      sorted.sort((a, b) {
         final singleA = a.totalValue / (a.quantity > 0 ? a.quantity : 1);
         final singleB = b.totalValue / (b.quantity > 0 ? b.quantity : 1);
         return singleB.compareTo(singleA);
      });
      return sorted.take(10).toList();
    },
    loading: () => [],
    error: (_,__) => [],
  );
});

// --- TOP 10 GEWINNER (Nach Einzel-Rendite sortiert) ---
final top10GainersProvider = Provider<List<InventoryItem>>((ref) {
  final allItemsAsync = ref.watch(inventoryProvider);
  return allItemsAsync.when(
    data: (items) {
      final Map<String, InventoryItem> mergedMap = {};
      for (final item in items) {
        final key = "${item.card.id}_${item.variant}";
        if (mergedMap.containsKey(key)) {
          final existing = mergedMap[key]!;
          mergedMap[key] = InventoryItem(
            card: existing.card, set: existing.set,
            quantity: existing.quantity + item.quantity,
            variant: existing.variant,
            totalValue: existing.totalValue + item.totalValue,
            binderName: null, userCard: existing.userCard,
            performance: existing.performance + item.performance, 
          );
        } else {
          mergedMap[key] = item;
        }
      }

      var sorted = mergedMap.values.where((item) => item.performance > 0).toList();
      // --- FIX: Nach Einzelkarten-Performance sortieren! ---
      sorted.sort((a, b) {
         final singleA = a.performance / (a.quantity > 0 ? a.quantity : 1);
         final singleB = b.performance / (b.quantity > 0 ? b.quantity : 1);
         return singleB.compareTo(singleA);
      });
      return sorted.take(10).toList();
    },
    loading: () => [],
    error: (_,__) => [],
  );
});

// --- TOP 10 VERLIERER (Nach Einzel-Rendite sortiert, schlechteste zuerst) ---
final top10LosersProvider = Provider<List<InventoryItem>>((ref) {
  final allItemsAsync = ref.watch(inventoryProvider);
  return allItemsAsync.when(
    data: (items) {
      final Map<String, InventoryItem> mergedMap = {};
      for (final item in items) {
        final key = "${item.card.id}_${item.variant}";
        if (mergedMap.containsKey(key)) {
          final existing = mergedMap[key]!;
          mergedMap[key] = InventoryItem(
            card: existing.card, set: existing.set,
            quantity: existing.quantity + item.quantity,
            variant: existing.variant,
            totalValue: existing.totalValue + item.totalValue,
            binderName: null, userCard: existing.userCard,
            performance: existing.performance + item.performance, 
          );
        } else {
          mergedMap[key] = item;
        }
      }

      var sorted = mergedMap.values.where((item) => item.performance < 0).toList();
      // --- FIX: Nach Einzelkarten-Performance sortieren! ---
      sorted.sort((a, b) {
         final singleA = a.performance / (a.quantity > 0 ? a.quantity : 1);
         final singleB = b.performance / (b.quantity > 0 ? b.quantity : 1);
         return singleA.compareTo(singleB); // a < b für schlechteste zuerst
      });
      return sorted.take(10).toList();
    },
    loading: () => [],
    error: (_,__) => [],
  );
});

final portfolioHistoryProvider = StreamProvider<List<PortfolioHistoryData>>((ref) {
  final db = ref.read(databaseProvider);
  return (db.select(db.portfolioHistory)..orderBy([(t) => OrderingTerm(expression: t.date)])).watch();
});

Future<void> createPortfolioSnapshot(WidgetRef ref) async {
  try {
    final db = ref.read(databaseProvider);
    // PERFORMANCE FIX: read() statt refresh(), wir nutzen den sauberen Cache!
    final items = await ref.read(inventoryProvider.future);
    
    final double currentTotal = items.fold(0.0, (sum, item) => sum + item.totalValue);

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final existingEntry = await (db.select(db.portfolioHistory)
      ..where((t) => t.date.equals(todayDate))
    ).getSingleOrNull();

    if (existingEntry != null) {
      await (db.update(db.portfolioHistory)..where((t) => t.id.equals(existingEntry.id)))
        .write(PortfolioHistoryCompanion(totalValue: Value(currentTotal)));
    } else {
      await db.into(db.portfolioHistory).insert(
        PortfolioHistoryCompanion.insert(
          date: todayDate,
          totalValue: currentTotal,
        ),
      );
    }
    
    // PERFORMANCE FIX: Komplett entfernt! Der Service berechnet den einen
    // betroffenen Binder beim Einsortieren des Slots bereits live neu.
    ref.invalidate(portfolioHistoryProvider);

  } on StateError catch (_) {
  } catch (e) {
    debugPrint("Fehler beim Portfolio Snapshot: $e");
  }
}

final cardPriceHistoryProvider = FutureProvider.family<Map<String, List<dynamic>>, String>((ref, cardId) async {
  final db = ref.read(databaseProvider);
  
  final cmHistory = await (db.select(db.cardMarketPrices)..where((t) => t.cardId.equals(cardId))..orderBy([(t) => OrderingTerm(expression: t.fetchedAt)])).get();
  final tcgHistory = await (db.select(db.tcgPlayerPrices)..where((t) => t.cardId.equals(cardId))..orderBy([(t) => OrderingTerm(expression: t.fetchedAt)])).get();
  final customHistory = await (db.select(db.customCardPrices)..where((t) => t.cardId.equals(cardId))..orderBy([(t) => OrderingTerm(expression: t.fetchedAt)])).get();

  return {
    'cm': cmHistory,
    'tcg': tcgHistory,
    'custom': customHistory,
  };
});

final cardBinderLocationProvider = StreamProvider.autoDispose.family<List<String>, String>((ref, cardId) {
  final db = ref.watch(databaseProvider); 
  
  final query = db.select(db.binderCards).join([
    innerJoin(db.binders, db.binders.id.equalsExp(db.binderCards.binderId))
  ]);
  
  query.where(db.binderCards.cardId.equals(cardId) & db.binderCards.isPlaceholder.equals(false));
  
  return query.watch().map((rows) {
    if (rows.isEmpty) return [];
    return rows.map((r) => r.readTable(db.binders).name).toSet().toList();
  });
});