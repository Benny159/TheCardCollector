import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart'; 
import '../../domain/models/api_card.dart';
import '../../domain/models/api_set.dart';
import '../sync/set_importer.dart';
import '../database/database_provider.dart';
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
  final cardIds = rows.map((r) => r.readTable(db.cards).id).toList();
  final ownedSet = await _fetchOwnedIds(db, cardIds);

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

    results.add(_mapToApiCard(card, set.printedTotal ?? 0, ownedSet.contains(card.id), cmPrice, tcgPrice));
  }

  return results;
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

  final cmPriceMap = _getLatestCmPrices(allCmPrices);
  final tcgPriceMap = _getLatestTcgPrices(allTcgPrices);

  return dbCards.map((dbCard) {
    return _mapToApiCard(
      dbCard,
      setInfo?.printedTotal ?? 0,
      ownedSet.contains(dbCard.id),
      cmPriceMap[dbCard.id],
      tcgPriceMap[dbCard.id],
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
  TcgPlayerPrice? tcgPrice
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
    setPrintedTotal: printedTotal.toString(),
    artist: dbCard.artist ?? '',
    rarity: dbCard.rarity ?? '',
    flavorText: dbCard.flavorText,
    flavorTextDe: dbCard.flavorTextDe,
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

// -----------------------------------------------------------------------------
// INVENTORY PROVIDER
// -----------------------------------------------------------------------------

class InventoryItem {
  final ApiCard card;
  final ApiSet set;
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

enum InventorySort { value, name, rarity }
final inventorySortProvider = StateProvider<InventorySort>((ref) => InventorySort.value);

final inventoryProvider = StreamProvider<List<InventoryItem>>((ref) {
  final db = ref.read(databaseProvider);

  final query = db.select(db.userCards).join([
    innerJoin(db.cards, db.cards.id.equalsExp(db.userCards.cardId)),
    innerJoin(db.cardSets, db.cardSets.id.equalsExp(db.cards.setId)),
  ]);

  return query.watch().asyncMap((rows) async {
    if (rows.isEmpty) return [];

    final cardIds = rows.map((r) => r.readTable(db.userCards).cardId).toList();
    
    final allCmPrices = await (db.select(db.cardMarketPrices)..where((tbl) => tbl.cardId.isIn(cardIds))).get();
    final allTcgPrices = await (db.select(db.tcgPlayerPrices)..where((tbl) => tbl.cardId.isIn(cardIds))).get();
    
    final cmPriceMap = _getLatestCmPrices(allCmPrices);
    final tcgPriceMap = _getLatestTcgPrices(allTcgPrices);

    List<InventoryItem> items = [];

    for (final row in rows) {
      final userCard = row.readTable(db.userCards);
      final dbCard = row.readTable(db.cards);
      final dbSet = row.readTable(db.cardSets);

      final apiCard = _mapToApiCard(
        dbCard, 
        dbSet.printedTotal ?? 0, 
        true, 
        cmPriceMap[dbCard.id], 
        tcgPriceMap[dbCard.id]
      );

      final apiSet = ApiSet(
        id: dbSet.id,
        name: dbSet.name,
        nameDe: dbSet.nameDe,
        series: dbSet.series,
        printedTotal: dbSet.printedTotal ?? 0,
        total: dbSet.total ?? 0,
        releaseDate: dbSet.releaseDate ?? '',
        updatedAt: dbSet.updatedAt,
        logoUrl: dbSet.logoUrl,
        logoUrlDe: dbSet.logoUrlDe,
        symbolUrl: dbSet.symbolUrl,
      );

      double singlePrice = 0.0;
      if (userCard.variant == 'Reverse Holo') {
        singlePrice = apiCard.tcgplayer?.prices?.reverseHolofoil?.market 
                   ?? apiCard.cardmarket?.reverseHoloTrend ?? 0.0;
      } else if (userCard.variant == 'Holo') {
         singlePrice = apiCard.cardmarket?.trendHolo
                    ?? apiCard.tcgplayer?.prices?.holofoil?.market ?? 0.0;
         if (singlePrice == 0) singlePrice = apiCard.cardmarket?.trendPrice ?? 0.0;
      } else {
        singlePrice = apiCard.cardmarket?.trendPrice 
                   ?? apiCard.tcgplayer?.prices?.normal?.market ?? 0.0;
      }

      items.add(InventoryItem(
        card: apiCard,
        set: apiSet,
        quantity: userCard.quantity,
        variant: userCard.variant,
        totalValue: singlePrice * userCard.quantity,
      ));
    }

    return items;
  });
});

final top10CardsProvider = Provider<List<InventoryItem>>((ref) {
  final allItemsAsync = ref.watch(inventoryProvider);
  return allItemsAsync.when(
    data: (items) {
      final sorted = List<InventoryItem>.from(items);
      sorted.sort((a, b) => b.totalValue.compareTo(a.totalValue));
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
  final db = ref.read(databaseProvider);
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
}