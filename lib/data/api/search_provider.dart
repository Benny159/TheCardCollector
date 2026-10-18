import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../../domain/models/api_card.dart';
import '../../domain/models/api_set.dart';
import '../sync/set_importer.dart';
import '../database/database_provider.dart';
import 'package:flutter/foundation.dart';
import '../../data/api/tcgdex_api_client.dart';
import '../../domain/logic/price_calculator.dart';

// --- 1. SEARCH CONFIGURATION ---

/// Defines the search target attribute when querying cards.
enum SearchMode {
  /// Search matching against German and English card names.
  name,

  /// Search matching against card illustrator names.
  artist,
}

/// Active search mode (by card name or artist), disposed when not listened to.
final searchModeProvider =
    StateProvider.autoDispose<SearchMode>((ref) => SearchMode.name);

/// Current search query string filter.
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Controls whether cards in the inventory view should be grouped by their set.
final inventoryGroupBySetProvider = StateProvider<bool>((ref) => false);

// --- 2. SETS PROVIDER ---

/// Loads all available expansion sets from local storage, sorted newest first.
///
/// Falls back to performing an initial metadata synchronization via [SetImporter]
/// if no sets are found in the local database.
final allSetsProvider = FutureProvider<List<ApiSet>>((ref) async {
  final db = ref.watch(databaseProvider);
  final localSets = await db.select(db.cardSets).get();

  if (localSets.isNotEmpty) {
    // Sort chronologically descending (newest release dates first)
    localSets.sort((a, b) {
      final dateA = a.releaseDate ?? '';
      final dateB = b.releaseDate ?? '';
      return dateB.compareTo(dateA);
    });

    return localSets
        .map((s) => ApiSet(
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
            ))
        .toList();
  }

  // Fallback: Initial metadata sync for sets
  final dexApi = ref.read(tcgDexApiClientProvider);
  final importer = SetImporter(dexApi, db);
  await importer.syncAllData();

  return [];
});

// --- 3. SEARCH PROVIDER ---

/// Searches cards by name or artist matching [searchQueryProvider].
///
/// Returns up to 100 card matches with batch-loaded ownership and price data.
final searchResultsProvider =
    FutureProvider.autoDispose<List<ApiCard>>((ref) async {
  final queryText = ref.watch(searchQueryProvider);
  final mode = ref.watch(searchModeProvider);

  if (queryText.isEmpty) return [];

  final db = ref.watch(databaseProvider);

  final query = db
      .select(db.cards)
      .join([innerJoin(db.cardSets, db.cardSets.id.equalsExp(db.cards.setId))]);

  if (mode == SearchMode.name) {
    query.where(db.cards.name.like('%$queryText%') |
        db.cards.nameDe.like('%$queryText%'));
  } else {
    query.where(db.cards.artist.like('%$queryText%'));
  }

  query.limit(100);

  final rows = await query.get();
  if (rows.isEmpty) return [];

  // Collect card IDs for batch relation queries
  final cardIds = rows.map((r) => r.readTable(db.cards).id).toList();

  // Parallel batch queries for ownership and pricing (Anti-N+1)
  final results = await Future.wait([
    _fetchOwnedIds(db, cardIds),
    (db.select(db.cardMarketPrices)..where((tbl) => tbl.cardId.isIn(cardIds)))
        .get(),
    (db.select(db.tcgPlayerPrices)..where((tbl) => tbl.cardId.isIn(cardIds)))
        .get(),
    (db.select(db.customCardPrices)..where((tbl) => tbl.cardId.isIn(cardIds)))
        .get(),
  ]);

  final Set<String> ownedSet = results[0] as Set<String>;
  final List<CardMarketPrice> allCmPrices = results[1] as List<CardMarketPrice>;
  final List<TcgPlayerPrice> allTcgPrices = results[2] as List<TcgPlayerPrice>;
  final List<CustomCardPrice> allCustomPrices =
      results[3] as List<CustomCardPrice>;

  // Build in-memory lookup maps for O(1) resolution
  final cmPriceMap = _getLatestCmPrices(allCmPrices);
  final tcgPriceMap = _getLatestTcgPrices(allTcgPrices);
  final customPriceMap = _getLatestCustomPrices(allCustomPrices);

  List<ApiCard> apiCards = [];

  // Assemble ApiCard domain models in memory
  for (final row in rows) {
    final card = row.readTable(db.cards);
    final set = row.readTable(db.cardSets);

    apiCards.add(_mapToApiCard(
        card,
        set.printedTotal ?? 0,
        ownedSet.contains(card.id),
        cmPriceMap[card.id],
        tcgPriceMap[card.id],
        customPriceMap[card.id]));
  }

  return apiCards;
});

// --- 4. SET LIST PROVIDER ---

/// Fetches all cards belonging to the set with [setId], ordered by card number.
///
/// Performs batch hydration of ownership flags and pricing data.
final cardsForSetProvider =
    FutureProvider.family<List<ApiCard>, String>((ref, setId) async {
  final db = ref.watch(databaseProvider);
  final setInfo = await (db.select(db.cardSets)
        ..where((tbl) => tbl.id.equals(setId)))
      .getSingleOrNull();

  final dbCards = await (db.select(db.cards)
        ..where((tbl) => tbl.setId.equals(setId))
        ..orderBy([(t) => OrderingTerm(expression: t.sortNumber)]))
      .get();

  if (dbCards.isEmpty) return [];

  final cardIds = dbCards.map((c) => c.id).toList();

  final results = await Future.wait([
    _fetchOwnedIds(db, cardIds),
    (db.select(db.cardMarketPrices)..where((tbl) => tbl.cardId.isIn(cardIds)))
        .get(),
    (db.select(db.tcgPlayerPrices)..where((tbl) => tbl.cardId.isIn(cardIds)))
        .get(),
    (db.select(db.customCardPrices)..where((tbl) => tbl.cardId.isIn(cardIds)))
        .get(),
  ]);

  final ownedSet = results[0] as Set<String>;
  final allCmPrices = results[1] as List<CardMarketPrice>;
  final allTcgPrices = results[2] as List<TcgPlayerPrice>;
  final allCustomPrices = results[3] as List<CustomCardPrice>;

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

/// Resolves a single [ApiSet] metadata record by its unique [setId].
final setByIdProvider =
    FutureProvider.family<ApiSet?, String>((ref, setId) async {
  final sets = await ref.watch(allSetsProvider.future);
  try {
    return sets.firstWhere((s) => s.id == setId);
  } catch (e) {
    return null;
  }
});

// --- ALL SET STATS PROVIDER (Anti-N+1 Batch Aggregation) ---

/// Aggregates distinct owned card counts grouped by set ID in a single SQL query.
///
/// Prevents N+1 database queries across set list items.
final allSetStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = ref.watch(databaseProvider);
  final query = db.customSelect(
    'SELECT c.set_id, COUNT(DISTINCT uc.card_id) AS owned_count '
    'FROM user_cards uc '
    'INNER JOIN cards c ON c.id = uc.card_id '
    'GROUP BY c.set_id',
    readsFrom: {db.userCards, db.cards},
  );
  final rows = await query.get();
  final Map<String, int> statsMap = {};
  for (final row in rows) {
    statsMap[row.read<String>('set_id')] = row.read<int>('owned_count');
  }
  return statsMap;
});

// --- SINGLE SET STATS PROVIDER ---

/// Returns the owned card count for a specific set [setId] from [allSetStatsProvider].
final setStatsProvider = FutureProvider.family<int, String>((ref, setId) async {
  final allStats = await ref.watch(allSetStatsProvider.future);
  return allStats[setId] ?? 0;
});

// --- HELPER ---

Future<Set<String>> _fetchOwnedIds(AppDatabase db, List<String> cardIds) async {
  if (cardIds.isEmpty) return {};
  final ownedEntries = await (db.select(db.userCards)
        ..where((tbl) => tbl.cardId.isIn(cardIds)))
      .get();
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

Map<String, CardMarketPrice> _getLatestCmPrices(
    List<CardMarketPrice> allPrices) {
  final Map<String, CardMarketPrice> map = {};
  for (final p in allPrices) {
    if (!map.containsKey(p.cardId) ||
        p.fetchedAt.isAfter(map[p.cardId]!.fetchedAt)) {
      map[p.cardId] = p;
    }
  }
  return map;
}

Map<String, TcgPlayerPrice> _getLatestTcgPrices(
    List<TcgPlayerPrice> allPrices) {
  final Map<String, TcgPlayerPrice> map = {};
  for (final p in allPrices) {
    if (!map.containsKey(p.cardId) ||
        p.fetchedAt.isAfter(map[p.cardId]!.fetchedAt)) {
      map[p.cardId] = p;
    }
  }
  return map;
}

Map<String, CustomCardPrice> _getLatestCustomPrices(
    List<CustomCardPrice> allPrices) {
  final Map<String, CustomCardPrice> map = {};
  for (final p in allPrices) {
    if (!map.containsKey(p.cardId) ||
        p.fetchedAt.isAfter(map[p.cardId]!.fetchedAt)) {
      map[p.cardId] = p;
    }
  }
  return map;
}

// -----------------------------------------------------------------------------
// INVENTORY PROVIDER
// -----------------------------------------------------------------------------

/// Represents a distinct card entry in the user's inventory or binder.
class InventoryItem {
  /// Domain model for the card details and current market price.
  final ApiCard card;

  /// Expansion set that this card belongs to.
  final ApiSet set;

  /// Quantity of cards represented by this inventory line item.
  final int quantity;

  /// Specific printing variant (e.g. 'Normal', 'Holo', 'Reverse Holo', '1st Edition').
  final String variant;

  /// Current cumulative market valuation in EUR for this item entry.
  final double totalValue;

  /// Name of the physical binder containing this item, or `null` if stored loose.
  final String? binderName;

  /// Underlying database user card record with purchase date and custom settings.
  final UserCard userCard;

  /// Total capital gain/loss in EUR relative to the purchase/acquisition date.
  final double performance;

  /// Creates a fully resolved [InventoryItem].
  const InventoryItem({
    required this.card,
    required this.set,
    required this.quantity,
    required this.variant,
    required this.totalValue,
    this.binderName,
    required this.userCard,
    this.performance = 0.0,
  });
}

/// Available sorting criteria for the inventory overview.
enum InventorySort {
  /// Sort by total portfolio value.
  value,

  /// Sort alphabetically by card name.
  name,

  /// Sort by card rarity tier.
  rarity,

  /// Sort by card element/type.
  type,

  /// Sort by historical profit/loss performance.
  performance,

  /// Sort by date added to the collection.
  dateAdded,
}

/// Currently active sorting criterion for the inventory screen.
final inventorySortProvider =
    StateProvider<InventorySort>((ref) => InventorySort.value);

/// Controls sort order: `false` for descending (highest first), `true` for ascending.
final inventorySortAscendingProvider = StateProvider<bool>((ref) => false);

/// High-performance provider loading all collection items with valuations and binder locations.
///
/// Uses parallel batch queries and in-memory resolution to avoid N+1 queries.
final inventoryProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final db = ref.watch(databaseProvider);

  // Fetch all UserCards joined with Card and Set metadata in one query
  final rows = await (db.select(db.userCards).join([
    innerJoin(db.cards, db.cards.id.equalsExp(db.userCards.cardId)),
    innerJoin(db.cardSets, db.cardSets.id.equalsExp(db.cards.setId)),
  ])).get();

  if (rows.isEmpty) return [];

  // Collect distinct card IDs for batch relation queries
  final cardIds = rows.map((r) => r.readTable(db.cards).id).toSet().toList();

  // Execute batch pricing and binder slot queries in parallel
  final results = await Future.wait([
    (db.select(db.cardMarketPrices)
          ..where((tbl) => tbl.cardId.isIn(cardIds))
          ..orderBy([
            (t) => OrderingTerm(expression: t.fetchedAt, mode: OrderingMode.asc)
          ]))
        .get(),
    (db.select(db.tcgPlayerPrices)
          ..where((tbl) => tbl.cardId.isIn(cardIds))
          ..orderBy([
            (t) => OrderingTerm(expression: t.fetchedAt, mode: OrderingMode.asc)
          ]))
        .get(),
    (db.select(db.customCardPrices)
          ..where((tbl) => tbl.cardId.isIn(cardIds))
          ..orderBy([
            (t) => OrderingTerm(expression: t.fetchedAt, mode: OrderingMode.asc)
          ]))
        .get(),
    (db.select(db.binderCards).join([
      innerJoin(db.binders, db.binders.id.equalsExp(db.binderCards.binderId))
    ])
          ..where(db.binderCards.cardId.isIn(cardIds) &
              db.binderCards.isPlaceholder.equals(false)))
        .get(),
  ]);

  final allCmPrices = results[0] as List<CardMarketPrice>;
  final allTcgPrices = results[1] as List<TcgPlayerPrice>;
  final allCustomPrices = results[2] as List<CustomCardPrice>;
  final binderRows = results[3] as List<TypedResult>;

  // Build in-memory lookup maps for fast O(1) access
  final Map<String, List<CardMarketPrice>> cmMap = {};
  for (final p in allCmPrices) {
    cmMap.putIfAbsent(p.cardId, () => []).add(p);
  }

  final Map<String, List<TcgPlayerPrice>> tcgMap = {};
  for (final p in allTcgPrices) {
    tcgMap.putIfAbsent(p.cardId, () => []).add(p);
  }

  final Map<String, List<CustomCardPrice>> customMap = {};
  for (final p in allCustomPrices) {
    customMap.putIfAbsent(p.cardId, () => []).add(p);
  }

  // Latest prices for the ApiCard model
  final latestCmPriceMap = _getLatestCmPrices(allCmPrices);
  final latestTcgPriceMap = _getLatestTcgPrices(allTcgPrices);
  final latestCustomPriceMap = _getLatestCustomPrices(allCustomPrices);

  // Pre-index binder allocations in O(M) before row iteration (Eliminates O(N*M) lag)
  final Map<int, Map<String, int>> bindersByUserCardId = {};
  final Map<String, Map<String, int>> bindersByCardAndVariant = {};

  for (final bRow in binderRows) {
    final bc = bRow.readTable(db.binderCards);
    final b = bRow.readTable(db.binders);
    if (bc.userCardId != null) {
      final m = bindersByUserCardId.putIfAbsent(bc.userCardId!, () => {});
      m[b.name] = (m[b.name] ?? 0) + 1;
    }
    if (bc.cardId != null && bc.variant != null) {
      final key = '${bc.cardId}_${bc.variant}';
      final m = bindersByCardAndVariant.putIfAbsent(key, () => {});
      m[b.name] = (m[b.name] ?? 0) + 1;
    }
  }

  List<InventoryItem> inventoryItems = [];

  // Assemble InventoryItem models in memory
  for (final row in rows) {
    final userCard = row.readTable(db.userCards);
    final dbCard = row.readTable(db.cards);
    final dbSet = row.readTable(db.cardSets);
    final cardId = dbCard.id;

    final cardCmPrices = cmMap[cardId] ?? [];
    final cardTcgPrices = tcgMap[cardId] ?? [];

    final latestCm = latestCmPriceMap[cardId];
    final latestTcg = latestTcgPriceMap[cardId];
    final latestCustom = latestCustomPriceMap[cardId];

    final apiCard = _mapToApiCard(dbCard, dbSet.printedTotal ?? 0, true,
        latestCm, latestTcg, latestCustom);
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

    // Pricing calculation using pure domain service PriceCalculator
    const priceCalculator = PriceCalculator();
    final variant = userCard.variant;
    final pref = dbCard.preferredPriceSource;
    double singlePrice = 0.0;
    double purchasePrice = 0.0;
    String usedSource = pref;

    if (userCard.customPrice != null && userCard.customPrice! > 0) {
      singlePrice = userCard.customPrice!;
      purchasePrice = singlePrice;
      usedSource = 'custom';
    } else {
      singlePrice = priceCalculator.calculateCardPrice(
        pref: pref,
        variant: variant,
        hasFirstEdition: dbCard.hasFirstEdition,
        hasNormal: dbCard.hasNormal,
        hasHolo: dbCard.hasHolo,
        cmPrice: latestCm,
        tcgPrice: latestTcg,
        customPrice: apiCard.customPrice,
      );

      final double tcgCur = priceCalculator.calculateTcgPrice(
        tcgPrice: latestTcg,
        isReverse: variant == 'Reverse Holo',
        isHolo: variant.toLowerCase().contains('holo') || (!dbCard.hasNormal && dbCard.hasHolo),
      );
      final double cmCur = priceCalculator.calculateCardMarketPrice(
        cmPrice: latestCm,
        hasFirstEdition: dbCard.hasFirstEdition,
        baseIsHolo: !dbCard.hasNormal && dbCard.hasHolo,
        isFirstEd: variant.toLowerCase().contains('1st') || variant.toLowerCase().contains('first'),
        isHolo: variant.toLowerCase().contains('holo') || (!dbCard.hasNormal && dbCard.hasHolo),
        isReverse: variant == 'Reverse Holo',
      );

      if (pref == 'custom' && apiCard.customPrice != null && apiCard.customPrice! > 0) {
        usedSource = 'custom';
        purchasePrice = singlePrice;
      } else if (pref == 'tcgplayer' && tcgCur > 0.0) {
        usedSource = 'tcgplayer';
      } else if (pref == 'cardmarket' && cmCur > 0.0) {
        usedSource = 'cardmarket';
      } else if (cmCur > 0.0) {
        usedSource = 'cardmarket';
      } else if (tcgCur > 0.0) {
        usedSource = 'tcgplayer';
      } else if (apiCard.customPrice != null) {
        usedSource = 'custom';
        purchasePrice = singlePrice;
      }
    }

    if (usedSource != 'custom') {
      final hp = priceCalculator.resolveHistoricalPrice(
        usedSource: usedSource,
        targetDate: userCard.createdAt,
        tcgPrices: cardTcgPrices,
        cmPrices: cardCmPrices,
        hasFirstEdition: dbCard.hasFirstEdition,
        hasNormal: dbCard.hasNormal,
        hasHolo: dbCard.hasHolo,
        variant: variant,
      );
      if (hp > 0.0) {
        purchasePrice = hp;
      }
    }

    if (purchasePrice == 0.0) {
      purchasePrice = singlePrice;
    }
    final double itemPerformance = (singlePrice - purchasePrice);

    // Fast O(1) in-memory binder allocation resolution
    final Map<String, int> bindersForThisCard = bindersByUserCardId[userCard.id] ??
        bindersByCardAndVariant['${cardId}_${userCard.variant}'] ??
        const {};

    int totalInBinders = 0;
    for (final entry in bindersForThisCard.entries) {
      final binderName = entry.key;
      final qtyInBinder = entry.value;
      int assignedQty = qtyInBinder;
      if (totalInBinders + assignedQty > userCard.quantity) {
        assignedQty = userCard.quantity - totalInBinders;
      }
      if (assignedQty <= 0) continue;
      totalInBinders += assignedQty;

      inventoryItems.add(InventoryItem(
        card: apiCard,
        set: apiSet,
        quantity: assignedQty,
        variant: userCard.variant,
        totalValue: singlePrice * assignedQty,
        binderName: binderName,
        userCard: userCard,
        performance: itemPerformance * assignedQty,
      ));
    }

    final looseQty = userCard.quantity - totalInBinders;
    if (looseQty > 0) {
      inventoryItems.add(InventoryItem(
        card: apiCard,
        set: apiSet,
        quantity: looseQty,
        variant: userCard.variant,
        totalValue: singlePrice * looseQty,
        binderName: null,
        userCard: userCard,
        performance: itemPerformance * looseQty,
      ));
    }
  }

  return inventoryItems;
});

/// Returns the top 10 most valuable individual cards across the user's inventory.
final top10CardsProvider = Provider<List<InventoryItem>>((ref) {
  final allItemsAsync = ref.watch(inventoryProvider);
  return allItemsAsync.when(
    data: (items) {
      final sorted = List<InventoryItem>.from(items);
      // Sort descending by single-card value
      sorted.sort((a, b) {
        final singleA = a.totalValue / (a.quantity > 0 ? a.quantity : 1);
        final singleB = b.totalValue / (b.quantity > 0 ? b.quantity : 1);
        return singleB.compareTo(singleA);
      });
      return sorted.take(10).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Returns the top 10 cards with the highest historical single-unit value gain.
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
            card: existing.card,
            set: existing.set,
            quantity: existing.quantity + item.quantity,
            variant: existing.variant,
            totalValue: existing.totalValue + item.totalValue,
            binderName: null,
            userCard: existing.userCard,
            performance: existing.performance + item.performance,
          );
        } else {
          mergedMap[key] = item;
        }
      }

      var sorted =
          mergedMap.values.where((item) => item.performance > 0).toList();
      // Sort descending by individual card performance
      sorted.sort((a, b) {
        final singleA = a.performance / (a.quantity > 0 ? a.quantity : 1);
        final singleB = b.performance / (b.quantity > 0 ? b.quantity : 1);
        return singleB.compareTo(singleA);
      });
      return sorted.take(10).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Returns the top 10 cards with the lowest historical single-unit value performance.
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
            card: existing.card,
            set: existing.set,
            quantity: existing.quantity + item.quantity,
            variant: existing.variant,
            totalValue: existing.totalValue + item.totalValue,
            binderName: null,
            userCard: existing.userCard,
            performance: existing.performance + item.performance,
          );
        } else {
          mergedMap[key] = item;
        }
      }

      var sorted =
          mergedMap.values.where((item) => item.performance < 0).toList();
      // Sort ascending by individual card performance (worst first)
      sorted.sort((a, b) {
        final singleA = a.performance / (a.quantity > 0 ? a.quantity : 1);
        final singleB = b.performance / (b.quantity > 0 ? b.quantity : 1);
        return singleA.compareTo(singleB);
      });
      return sorted.take(10).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Streams the historical portfolio value snapshots ordered chronologically.
final portfolioHistoryProvider =
    StreamProvider<List<PortfolioHistoryData>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.portfolioHistory)
        ..orderBy([(t) => OrderingTerm(expression: t.date)]))
      .watch();
});

/// Computes and persists a portfolio valuation snapshot for today's date.
Future<void> createPortfolioSnapshot(WidgetRef ref, {bool force = false}) async {
  try {
    final db = ref.read(databaseProvider);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (!force) {
      final existing = await (db.select(db.portfolioHistory)
            ..where((t) => t.date.equals(todayDate)))
          .getSingleOrNull();
      if (existing != null) {
        // Daily snapshot already exists, skip heavy inventory calculation on startup
        return;
      }
    }

    final items = await ref.read(inventoryProvider.future);

    final double currentTotal =
        items.fold(0.0, (sum, item) => sum + item.totalValue);

    final existingEntry = await (db.select(db.portfolioHistory)
          ..where((t) => t.date.equals(todayDate)))
        .getSingleOrNull();

    if (existingEntry != null) {
      await (db.update(db.portfolioHistory)
            ..where((t) => t.id.equals(existingEntry.id)))
          .write(PortfolioHistoryCompanion(totalValue: Value(currentTotal)));
    } else {
      await db.into(db.portfolioHistory).insert(
            PortfolioHistoryCompanion.insert(
              date: todayDate,
              totalValue: currentTotal,
            ),
          );
    }

    // Invalidate historical portfolio stream to trigger UI chart update
    ref.invalidate(portfolioHistoryProvider);
  } on StateError catch (_) {
  } catch (e) {
    debugPrint("Fehler beim Portfolio Snapshot: $e");
  }
}

/// Loads historical price timelines across CardMarket, TCGPlayer, and Custom prices for [cardId].
final cardPriceHistoryProvider =
    FutureProvider.family<Map<String, List<dynamic>>, String>(
        (ref, cardId) async {
  final db = ref.read(databaseProvider);

  final cmHistory = await (db.select(db.cardMarketPrices)
        ..where((t) => t.cardId.equals(cardId))
        ..orderBy([(t) => OrderingTerm(expression: t.fetchedAt)]))
      .get();
  final tcgHistory = await (db.select(db.tcgPlayerPrices)
        ..where((t) => t.cardId.equals(cardId))
        ..orderBy([(t) => OrderingTerm(expression: t.fetchedAt)]))
      .get();
  final customHistory = await (db.select(db.customCardPrices)
        ..where((t) => t.cardId.equals(cardId))
        ..orderBy([(t) => OrderingTerm(expression: t.fetchedAt)]))
      .get();

  return {
    'cm': cmHistory,
    'tcg': tcgHistory,
    'custom': customHistory,
  };
});

/// Resolves the names of all physical binders containing instances of [cardId].
final cardBinderLocationProvider =
    FutureProvider.autoDispose.family<List<String>, String>((ref, cardId) async {
  final db = ref.watch(databaseProvider);

  final query = db.select(db.binderCards).join([
    innerJoin(db.binders, db.binders.id.equalsExp(db.binderCards.binderId))
  ]);

  query.where(db.binderCards.cardId.equals(cardId) &
      db.binderCards.isPlaceholder.equals(false));

  final rows = await query.get();
  if (rows.isEmpty) return [];
  return rows.map((r) => r.readTable(db.binders).name).toSet().toList();
});
