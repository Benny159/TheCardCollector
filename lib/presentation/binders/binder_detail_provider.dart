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

final binderDetailProvider = FutureProvider.family<BinderDetailState, int>((ref, binderId) async {
  final db = ref.watch(databaseProvider);

  // 1. Query bleibt gleich
  final query = db.select(db.binderCards).join([
    leftOuterJoin(db.cards, db.cards.id.equalsExp(db.binderCards.cardId)),
    leftOuterJoin(db.cardMarketPrices, db.cardMarketPrices.cardId.equalsExp(db.cards.id)),
  ]);

  query.where(db.binderCards.binderId.equals(binderId));
  
  // Wichtig: Sortierung beibehalten
  query.orderBy([OrderingTerm(expression: db.binderCards.pageIndex), OrderingTerm(expression: db.binderCards.slotIndex)]);

  final rows = await query.get();

  // --- FIX: Deduplizierung mit einer Map ---
  // Wir mappen BinderCard.id -> SlotData. 
  // Wenn durch den Join Duplikate entstehen, werden sie hier überschrieben/ignoriert.
  final Map<int, BinderSlotData> uniqueSlotsMap = {};

  for (final row in rows) {
    final bc = row.readTable(db.binderCards);
    
    // Wenn wir diesen Slot schon haben, überspringen wir weitere Einträge (z.B. alte Preise)
    if (uniqueSlotsMap.containsKey(bc.id)) continue;

    final card = row.readTableOrNull(db.cards);
    final prices = row.readTableOrNull(db.cardMarketPrices);

    double price = 0.0;
    if (!bc.isPlaceholder && card != null) {
      price = prices?.trend ?? 0.0; 
    }

    uniqueSlotsMap[bc.id] = BinderSlotData(binderCard: bc, card: card, marketPrice: price);
  }

  // Jetzt bauen wir die Liste aus den bereinigten Werten
  final slots = uniqueSlotsMap.values.toList();
  
  // Werte berechnen (jetzt stimmt die Summe auch wieder!)
  double totalVal = 0;
  int filled = 0;
  
  for (var slot in slots) {
    if (!slot.binderCard.isPlaceholder && slot.card != null) {
      filled++;
      totalVal += slot.marketPrice;
    }
  }

  return BinderDetailState(
    slots: slots,
    totalValue: totalVal,
    totalSlots: slots.length,
    filledSlots: filled,
  );
});