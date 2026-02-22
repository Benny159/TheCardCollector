import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';

// Daten-Klasse für einen Slot im UI
class BinderSlotData {
  final BinderCard binderCard; 
  final Card? card;            
  final double marketPrice;    
  
  BinderSlotData({required this.binderCard, this.card, this.marketPrice = 0.0});
}

class BinderDetailState {
  final List<BinderSlotData> slots;
  final double totalValue;
  final int totalSlots;
  final int filledSlots;

  BinderDetailState({
    this.slots = const [], 
    this.totalValue = 0.0,
    this.totalSlots = 0,
    this.filledSlots = 0,
  });
}

class BinderStats {
  final double value;
  final int total;
  final int filled;
  double get progress => total == 0 ? 0 : filled / total;

  BinderStats(this.value, this.filled, this.total);
}

final forceBinderRefreshProvider = StateProvider<int>((ref) => 0);

// =========================================================================
// 1. STATS PROVIDER (Für die Listen-Ansicht) - NEU & CRASH-SICHER
// =========================================================================
final binderStatsProvider = StreamProvider.family<BinderStats, int>((ref, binderId) {
  final db = ref.watch(databaseProvider);

  // Wir überwachen die Binder-Tabelle (für totalValue)
  // und die BinderCards-Tabelle (für die Anzahl der gefüllten Slots)
  
  final slotsQuery = db.select(db.binderCards)..where((t) => t.binderId.equals(binderId));
  
  return slotsQuery.watch().asyncMap((slots) async {
    // 1. Wert holen (Jetzt ganz sicher ohne Ausrufezeichen)
    final binder = await (db.select(db.binders)..where((t) => t.id.equals(binderId))).getSingleOrNull();
    final double value = binder?.totalValue ?? 0.0;

    // 2. Slots zählen
    int total = slots.length;
    int filled = 0;
    
    for (var slot in slots) {
      if (slot.isPlaceholder == false && slot.cardId != null) {
         filled++;
      }
    }
    
    return BinderStats(value, filled, total);
  });
});

// =========================================================================
// 2. DETAIL PROVIDER (Wieder FutureProvider für absolute Stabilität!)
// =========================================================================
final binderDetailProvider = FutureProvider.family<BinderDetailState, int>((ref, binderId) async {
  final db = ref.watch(databaseProvider);

  final query = db.select(db.binderCards).join([
    leftOuterJoin(db.cards, db.cards.id.equalsExp(db.binderCards.cardId)),
  ]);

  query.where(db.binderCards.binderId.equals(binderId));
  query.orderBy([OrderingTerm(expression: db.binderCards.pageIndex), OrderingTerm(expression: db.binderCards.slotIndex)]);

  // --- WICHTIG: Wieder .get() statt .watch() ---
  final rows = await query.get();
    
  // Alle relevanten Karten-IDs sammeln
  final cardIds = rows.map((r) => r.readTableOrNull(db.cards)?.id).whereType<String>().toSet().toList();
  
  List<CardMarketPrice> cmPrices = [];
  List<TcgPlayerPrice> tcgPrices = [];
  
  if (cardIds.isNotEmpty) {
    cmPrices = await (db.select(db.cardMarketPrices)..where((t) => t.cardId.isIn(cardIds))).get();
    tcgPrices = await (db.select(db.tcgPlayerPrices)..where((t) => t.cardId.isIn(cardIds))).get();
  }

  final cmMap = <String, CardMarketPrice>{};
  for (var p in cmPrices) {
    if (!cmMap.containsKey(p.cardId) || p.fetchedAt.isAfter(cmMap[p.cardId]!.fetchedAt)) cmMap[p.cardId] = p;
  }
  
  final tcgMap = <String, TcgPlayerPrice>{};
  for (var p in tcgPrices) {
    if (!tcgMap.containsKey(p.cardId) || p.fetchedAt.isAfter(tcgMap[p.cardId]!.fetchedAt)) tcgMap[p.cardId] = p;
  }

  final Map<int, BinderSlotData> uniqueSlotsMap = {};

  for (final row in rows) {
    final bc = row.readTable(db.binderCards);
    if (uniqueSlotsMap.containsKey(bc.id)) continue;

    final card = row.readTableOrNull(db.cards);
    double price = 0.0;

    if (card != null && !bc.isPlaceholder) {
      final cmPrice = cmMap[card.id];
      final tcgPrice = tcgMap[card.id];
      
      bool baseIsHolo = !card.hasNormal && card.hasHolo;
      final variant = bc.variant ?? 'Normal';
      
      final isFirstEd = variant.toLowerCase().contains('1st') || variant.toLowerCase().contains('first');
      final isHolo = variant.toLowerCase().contains('holo') || baseIsHolo;
      final isReverse = variant == 'Reverse Holo';

      if (card.hasFirstEdition) {
        if (isHolo) {
          if (isFirstEd) {
            price = cmPrice?.trend ?? tcgPrice?.holoMarket ?? 0.0;
          } else {
            price = cmPrice?.trendHolo ?? tcgPrice?.holoMarket ?? 0.0;
          }
        } else {
          if (isFirstEd) {
            price = cmPrice?.trendHolo ?? tcgPrice?.normalMarket ?? 0.0;
          } else {
            price = cmPrice?.trend ?? tcgPrice?.normalMarket ?? 0.0;
          }
        }
      } 
      else if (isReverse) {
        price = cmPrice?.trendHolo ?? cmPrice?.trendReverse ?? tcgPrice?.reverseMarket ?? 0.0;
      } else if (isHolo) {
        if (baseIsHolo) {
          price = cmPrice?.trend ?? tcgPrice?.holoMarket ?? 0.0;
        } else {
          price = cmPrice?.trendHolo ?? tcgPrice?.holoMarket ?? 0.0;
        }
      } else {
        price = cmPrice?.trend ?? tcgPrice?.normalMarket ?? 0.0;
      }
      
      if (price == 0.0) {
        price = (isHolo ? tcgPrice?.holoMarket : tcgPrice?.normalMarket) ?? cmPrice?.trend ?? 0.0;
      }
    }

    uniqueSlotsMap[bc.id] = BinderSlotData(binderCard: bc, card: card, marketPrice: price);
  }

  final slots = uniqueSlotsMap.values.toList();
  
  int filled = 0;
  for (var slot in slots) {
    if (slot.binderCard.isPlaceholder == false && slot.card != null) filled++;
  }

  final binder = await (db.select(db.binders)..where((t) => t.id.equals(binderId))).getSingleOrNull();
  
  return BinderDetailState(
    slots: slots,
    totalValue: binder?.totalValue ?? 0.0,
    totalSlots: slots.length,
    filledSlots: filled,
  );
});

// =========================================================================
// 3. HISTORY PROVIDER (Für den Graphen) - NUTZT JETZT DIE NEUE TABELLE
// =========================================================================
class BinderHistoryPoint {
  final DateTime date;
  final double value;
  BinderHistoryPoint(this.date, this.value);
}

final binderHistoryProvider = FutureProvider.family<List<BinderHistoryPoint>, int>((ref, binderId) async {
  final db = ref.read(databaseProvider);
  
  // Da wir jetzt extra eine BinderHistory Tabelle haben, ist das extrem einfach und schnell!
  final historyRows = await (db.select(db.binderHistory)
    ..where((t) => t.binderId.equals(binderId))
    ..orderBy([(t) => OrderingTerm(expression: t.date)])
  ).get();

  if (historyRows.isEmpty) return [];

  return historyRows.map((row) => BinderHistoryPoint(row.date, row.value)).toList();
});