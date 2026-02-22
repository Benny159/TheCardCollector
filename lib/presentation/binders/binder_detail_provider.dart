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

// =========================================================================
// 1. STATS PROVIDER (Für die Listen-Ansicht) - NEU & GANZ LIVE
// =========================================================================
final binderStatsProvider = StreamProvider.family<BinderStats, int>((ref, binderId) {
  final db = ref.watch(databaseProvider);

  // WICHTIG: Wir nutzen einen JOIN, um BEIDE Tabellen (Binders UND BinderCards) gleichzeitig zu überwachen!
  // Wenn sich ein Slot ändert ODER der Preis des Binders fertig berechnet wurde, feuert dieser Stream sofort.
  final query = db.select(db.binders).join([
    leftOuterJoin(db.binderCards, db.binderCards.binderId.equalsExp(db.binders.id)),
  ])..where(db.binders.id.equals(binderId));

  // Wir nutzen .map statt .asyncMap, weil wir jetzt alles direkt in einem Rutsch aus der DB haben!
  return query.watch().map((rows) {
    if (rows.isEmpty) return BinderStats(0.0, 0, 0);

    // 1. Den Wert direkt aus der Binders-Tabelle holen
    final binder = rows.first.readTable(db.binders);
    final double value = binder.totalValue;

    // 2. Alle verknüpften Slots durchzählen
    int total = 0;
    int filled = 0;

    for (final row in rows) {
      final slot = row.readTableOrNull(db.binderCards);
      if (slot != null) {
        total++;
        if (!slot.isPlaceholder && slot.cardId != null) {
          filled++;
        }
      }
    }

    return BinderStats(value, filled, total);
  });
});

// =========================================================================
// 2. DETAIL PROVIDER (JETZT EIN LIVE-STREAM!)
// =========================================================================
final binderDetailProvider = StreamProvider.family<BinderDetailState, int>((ref, binderId) {
  final db = ref.watch(databaseProvider);

  final query = db.select(db.binderCards).join([
    leftOuterJoin(db.cards, db.cards.id.equalsExp(db.binderCards.cardId)),
  ]);

  query.where(db.binderCards.binderId.equals(binderId));
  query.orderBy([OrderingTerm(expression: db.binderCards.pageIndex), OrderingTerm(expression: db.binderCards.slotIndex)]);

  // --- DIE MAGIE: .watch() statt .get() ---
  return query.watch().asyncMap((rows) async {
    
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
            price = isFirstEd ? (cmPrice?.trend ?? tcgPrice?.holoMarket ?? 0.0) : (cmPrice?.trendHolo ?? tcgPrice?.holoMarket ?? 0.0);
          } else {
            price = isFirstEd ? (cmPrice?.trendHolo ?? tcgPrice?.normalMarket ?? 0.0) : (cmPrice?.trend ?? tcgPrice?.normalMarket ?? 0.0);
          }
        } 
        else if (isReverse) {
          price = cmPrice?.trendHolo ?? cmPrice?.trendReverse ?? tcgPrice?.reverseMarket ?? 0.0;
        } else if (isHolo) {
          price = baseIsHolo ? (cmPrice?.trend ?? tcgPrice?.holoMarket ?? 0.0) : (cmPrice?.trendHolo ?? tcgPrice?.holoMarket ?? 0.0);
        } else {
          price = cmPrice?.trend ?? tcgPrice?.normalMarket ?? 0.0;
        }
        
        if (price == 0.0) price = (isHolo ? tcgPrice?.holoMarket : tcgPrice?.normalMarket) ?? cmPrice?.trend ?? 0.0;
      }

      uniqueSlotsMap[bc.id] = BinderSlotData(binderCard: bc, card: card, marketPrice: price);
    }

    final slots = uniqueSlotsMap.values.toList();
    int filled = slots.where((s) => s.binderCard.isPlaceholder == false && s.card != null).length;
    final binder = await (db.select(db.binders)..where((t) => t.id.equals(binderId))).getSingleOrNull();
    
    return BinderDetailState(slots: slots, totalValue: binder?.totalValue ?? 0.0, totalSlots: slots.length, filledSlots: filled);
  });
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