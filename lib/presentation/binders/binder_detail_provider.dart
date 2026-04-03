import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';

class BinderSlotData {
  final BinderCard binderCard; 
  final Card? card;   
  final UserCard? userCard; 
  final double marketPrice;    
  
  BinderSlotData({required this.binderCard, this.card, this.userCard, this.marketPrice = 0.0});
}

class BinderDetailState {
  final List<BinderSlotData> slots;
  final double totalValue;
  final int totalSlots;
  final int filledSlots;

  BinderDetailState({this.slots = const [], this.totalValue = 0.0, this.totalSlots = 0, this.filledSlots = 0});
}

class BinderStats {
  final double value;
  final int total;
  final int filled;
  double get progress => total == 0 ? 0 : filled / total;

  BinderStats(this.value, this.filled, this.total);
}

final binderStatsProvider = StreamProvider.family<BinderStats, int>((ref, binderId) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.binders).join([
    leftOuterJoin(db.binderCards, db.binderCards.binderId.equalsExp(db.binders.id)),
  ])..where(db.binders.id.equals(binderId));

  return query.watch().map((rows) {
    if (rows.isEmpty) return BinderStats(0.0, 0, 0);
    final binder = rows.first.readTable(db.binders);
    final double value = binder.totalValue;

    int total = 0;
    int filled = 0;
    for (final row in rows) {
      final slot = row.readTableOrNull(db.binderCards);
      if (slot != null) {
        total++;
        if (!slot.isPlaceholder && slot.cardId != null) filled++;
      }
    }
    return BinderStats(value, filled, total);
  });
});

final binderDetailProvider = StreamProvider.family<BinderDetailState, int>((ref, binderId) {
  final db = ref.watch(databaseProvider);

  final query = db.select(db.binderCards).join([
    leftOuterJoin(db.cards, db.cards.id.equalsExp(db.binderCards.cardId)),
    innerJoin(db.binders, db.binders.id.equalsExp(db.binderCards.binderId)), 
    leftOuterJoin(db.userCards, db.userCards.id.equalsExp(db.binderCards.userCardId)), 
  ]);

  query.where(db.binderCards.binderId.equals(binderId));
  query.orderBy([OrderingTerm(expression: db.binderCards.pageIndex), OrderingTerm(expression: db.binderCards.slotIndex)]);

  return query.watch().asyncMap((rows) async {
    
    final cardIds = rows.map((r) => r.readTableOrNull(db.cards)?.id).whereType<String>().toSet().toList();
    
    List<CardMarketPrice> cmPrices = [];
    List<TcgPlayerPrice> tcgPrices = [];
    List<CustomCardPrice> customPrices = []; 
    
    if (cardIds.isNotEmpty) {
      cmPrices = await (db.select(db.cardMarketPrices)..where((t) => t.cardId.isIn(cardIds))).get();
      tcgPrices = await (db.select(db.tcgPlayerPrices)..where((t) => t.cardId.isIn(cardIds))).get();
      customPrices = await (db.select(db.customCardPrices)..where((t) => t.cardId.isIn(cardIds))).get(); 
    }

    final cmMap = <String, CardMarketPrice>{};
    for (var p in cmPrices) {
      if (!cmMap.containsKey(p.cardId) || p.fetchedAt.isAfter(cmMap[p.cardId]!.fetchedAt)) cmMap[p.cardId] = p;
    }
    
    final tcgMap = <String, TcgPlayerPrice>{};
    for (var p in tcgPrices) {
      if (!tcgMap.containsKey(p.cardId) || p.fetchedAt.isAfter(tcgMap[p.cardId]!.fetchedAt)) tcgMap[p.cardId] = p;
    }

    final customMap = <String, CustomCardPrice>{};
    for (var p in customPrices) {
      if (!customMap.containsKey(p.cardId) || p.fetchedAt.isAfter(customMap[p.cardId]!.fetchedAt)) customMap[p.cardId] = p;
    }

    final Map<int, BinderSlotData> uniqueSlotsMap = {};

    for (final row in rows) {
      final bc = row.readTable(db.binderCards);
      if (uniqueSlotsMap.containsKey(bc.id)) continue;

      final card = row.readTableOrNull(db.cards);
      final userCard = row.readTableOrNull(db.userCards); 
      double price = 0.0;

      if (card != null && !bc.isPlaceholder) {
        final cmPrice = cmMap[card.id];
        final tcgPrice = tcgMap[card.id];
        
        bool baseIsHolo = !card.hasNormal && card.hasHolo;
        final variant = userCard?.variant ?? bc.variant ?? 'Normal';
        
        final isFirstEd = variant.toLowerCase().contains('1st') || variant.toLowerCase().contains('first');
        final isHolo = variant.toLowerCase().contains('holo') || baseIsHolo;
        final isReverse = variant == 'Reverse Holo';
        
final pref = card.preferredPriceSource;
        final customPrice = customMap[card.id]?.price; // <-- WICHTIG: Globale Custom-Preise bereitlegen!

        // --- NEUE SMARTE PREIS LOGIK (Exakt wie im Search Provider) ---
        if (userCard != null && userCard.customPrice != null && userCard.customPrice! > 0) {
            price = userCard.customPrice!;
        } else {
            // Hilfsfunktion: TCG Preis holen
            double getTcg() {
               double p = 0.0;
               if (isReverse) p = tcgPrice?.reverseMarket ?? 0.0;
               else if (isHolo) p = tcgPrice?.holoMarket ?? 0.0;
               else p = tcgPrice?.normalMarket ?? 0.0;
               if (p == 0.0) p = tcgPrice?.normalMarket ?? tcgPrice?.holoMarket ?? tcgPrice?.reverseMarket ?? 0.0;
               return p;
            }

            // Hilfsfunktion: CM Preis holen
            double getCm() {
               double p = 0.0;
               if (card.hasFirstEdition) {
                  p = isFirstEd ? (isHolo ? cmPrice?.trend ?? 0.0 : cmPrice?.trendHolo ?? 0.0) : (isHolo ? cmPrice?.trendHolo ?? 0.0 : cmPrice?.trend ?? 0.0);
               } else if (isReverse) {
                  p = cmPrice?.trendReverse ?? cmPrice?.trendHolo ?? 0.0;
               } else if (isHolo && !baseIsHolo) {
                  p = cmPrice?.trendHolo ?? 0.0;
               } else {
                  p = cmPrice?.trend ?? 0.0;
               }
               if (p == 0.0) p = cmPrice?.trend ?? cmPrice?.trendHolo ?? 0.0;
               return p;
            }

            double tcgCur = getTcg();
            double cmCur = getCm();

            // --- FIX: WEICHE FÜR GLOBALE CUSTOM PREISE EINGEBAUT! ---
            if (pref == 'custom' && customPrice != null && customPrice > 0) {
                price = customPrice;
            } else if (pref == 'tcgplayer' && tcgCur > 0.0) {
                price = tcgCur;
            } else if (pref == 'cardmarket' && cmCur > 0.0) {
                price = cmCur;
            } else {
                if (cmCur > 0.0) price = cmCur; 
                else if (tcgCur > 0.0) price = tcgCur;
                else if (customPrice != null) price = customPrice;
            }
        }
        // -------------------------------------------------------------
      }

      uniqueSlotsMap[bc.id] = BinderSlotData(binderCard: bc, card: card, userCard: userCard, marketPrice: price);
    }

    final slots = uniqueSlotsMap.values.toList();
    int filled = slots.where((s) => s.binderCard.isPlaceholder == false && s.card != null).length;
    final binder = await (db.select(db.binders)..where((t) => t.id.equals(binderId))).getSingleOrNull();
    
    return BinderDetailState(slots: slots, totalValue: binder?.totalValue ?? 0.0, totalSlots: slots.length, filledSlots: filled);
  });
});

class BinderHistoryPoint {
  final DateTime date;
  final double value;
  BinderHistoryPoint(this.date, this.value);
}

final binderHistoryProvider = FutureProvider.family<List<BinderHistoryPoint>, int>((ref, binderId) async {
  final db = ref.read(databaseProvider);
  final historyRows = await (db.select(db.binderHistory)
    ..where((t) => t.binderId.equals(binderId))
    ..orderBy([(t) => OrderingTerm(expression: t.date)])
  ).get();
  if (historyRows.isEmpty) return [];
  return historyRows.map((row) => BinderHistoryPoint(row.date, row.value)).toList();
});