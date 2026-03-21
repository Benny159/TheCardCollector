import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';

class BinderSlotData {
  final BinderCard binderCard; 
  final Card? card;   
  // --- NEU: Der Slot kennt jetzt die physische Karte aus dem Inventar! ---         
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
    // --- DER ENTSCHEIDENDE FIX: Wir laden die spezifische Inventar-Karte dazu! ---
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
      final userCard = row.readTableOrNull(db.userCards); // <--- Lade das gefundene Inventar-Stück
      double price = 0.0;

      if (card != null && !bc.isPlaceholder) {
        final cmPrice = cmMap[card.id];
        final tcgPrice = tcgMap[card.id];
        final customPriceRow = customMap[card.id]; 
        
        bool baseIsHolo = !card.hasNormal && card.hasHolo;
        // Priorisiere die Variante aus dem Inventar!
        final variant = userCard?.variant ?? bc.variant ?? 'Normal';
        
        final isFirstEd = variant.toLowerCase().contains('1st') || variant.toLowerCase().contains('first');
        final isHolo = variant.toLowerCase().contains('holo') || baseIsHolo;
        final isReverse = variant == 'Reverse Holo';
        
        // --- DIE NEUE WERT-HIERARCHIE FÜR DEN BINDER! ---
        if (userCard != null && userCard.customPrice != null && userCard.customPrice! > 0) {
            price = userCard.customPrice!; // Der Joker schlägt alles!
        } 
        else {
            final pref = card.preferredPriceSource;
            final customPrice = customPriceRow?.price;

            if (pref == 'custom' && customPrice != null && customPrice > 0) {
                price = customPrice;
            } 
            else if (pref == 'tcgplayer') {
                if (isReverse) price = tcgPrice?.reverseMarket ?? 0.0;
                else if (isHolo) price = tcgPrice?.holoMarket ?? 0.0;
                else price = tcgPrice?.normalMarket ?? 0.0;
            } 
            else {
                if (card.hasFirstEdition) {
                   if (isHolo) price = isFirstEd ? (cmPrice?.trend ?? 0.0) : (cmPrice?.trendHolo ?? 0.0);
                   else price = isFirstEd ? (cmPrice?.trendHolo ?? 0.0) : (cmPrice?.trend ?? 0.0);
                } else if (isReverse) {
                   price = cmPrice?.trendHolo ?? cmPrice?.trendReverse ?? 0.0;
                } else if (isHolo && !baseIsHolo) {
                   price = cmPrice?.trendHolo ?? 0.0;
                } else {
                   price = cmPrice?.trend ?? 0.0;
                }
            }
            if (price == 0.0) price = (isHolo ? tcgPrice?.holoMarket : tcgPrice?.normalMarket) ?? cmPrice?.trend ?? customPrice ?? 0.0;
        }
      }

      // userCard an das UI übergeben!
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