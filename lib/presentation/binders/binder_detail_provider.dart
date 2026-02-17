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

final binderStatsProvider = StreamProvider.family<BinderStats, int>((ref, binderId) {
  final db = ref.watch(databaseProvider);

  // Wir nutzen .watch() statt .get(), damit es live bleibt
  final query = db.select(db.binderCards).join([
    leftOuterJoin(db.cards, db.cards.id.equalsExp(db.binderCards.cardId)),
    leftOuterJoin(db.cardMarketPrices, db.cardMarketPrices.cardId.equalsExp(db.cards.id)),
  ]);

  query.where(db.binderCards.binderId.equals(binderId));
  
  // Mappen des Streams
  return query.watch().map((rows) {
    final Set<int> processedSlots = {};
    double totalValue = 0;
    int filled = 0;
    int total = 0;

    for (final row in rows) {
      final bc = row.readTable(db.binderCards);
      if (processedSlots.contains(bc.id)) continue;
      processedSlots.add(bc.id);

      total++;
      if (!bc.isPlaceholder && bc.cardId != null) {
         filled++;
         final price = row.readTableOrNull(db.cardMarketPrices)?.trend ?? 0.0;
         totalValue += price;
      }
    }
    return BinderStats(totalValue, filled, total);
  });
});

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

class BinderHistoryPoint {
  final DateTime date;
  final double value;
  BinderHistoryPoint(this.date, this.value);
}

final binderHistoryProvider = FutureProvider.family<List<BinderHistoryPoint>, int>((ref, binderId) async {
  final db = ref.read(databaseProvider);
  
  // 1. Hole alle Karten-IDs, die aktuell im Binder stecken (keine Platzhalter)
  final binderCards = await (db.select(db.binderCards)..where((t) => t.binderId.equals(binderId))).get();
  final cardIds = binderCards
      .where((bc) => !bc.isPlaceholder && bc.cardId != null)
      .map((bc) => bc.cardId!)
      .toList();

  if (cardIds.isEmpty) return [];

  // 2. Hole die gesamte Preishistorie für diese Karten
  // Wir laden nur das Datum (fetchedAt) und den Trend-Preis
  final prices = await (db.select(db.cardMarketPrices)
    ..where((t) => t.cardId.isIn(cardIds))
    ..orderBy([(t) => OrderingTerm(expression: t.fetchedAt)])
  ).get();

  if (prices.isEmpty) return [];

  // 3. Daten aggregieren (Tag -> {CardId -> Preis})
  final Map<DateTime, Map<String, double>> dailyPrices = {};
  
  for (var p in prices) {
    // Datum normalisieren (Uhrzeit entfernen)
    final date = DateTime(p.fetchedAt.year, p.fetchedAt.month, p.fetchedAt.day);
    
    if (!dailyPrices.containsKey(date)) {
      dailyPrices[date] = {};
    }
    // Wir speichern den Preis. Falls es mehrere Einträge pro Tag gibt, gewinnt der letzte.
    if (p.trend != null) {
       dailyPrices[date]![p.cardId] = p.trend!;
    }
  }

  // 4. Historie aufbauen (Forward Fill)
  // Wir gehen alle Tage durch und summieren den Wert des Binders
  if (dailyPrices.isEmpty) return [];
  
  final sortedDates = dailyPrices.keys.toList()..sort();
  final start = sortedDates.first;
  final end = DateTime.now(); // Bis heute
  
  final List<BinderHistoryPoint> history = [];
  final Map<String, double> currentCardValues = {}; // Letzter bekannter Wert jeder Karte

  // Schleife über jeden Tag vom ersten Datenpunkt bis heute
  for (var d = start; d.isBefore(end) || d.isAtSameMomentAs(end); d = d.add(const Duration(days: 1))) {
    final today = DateTime(d.year, d.month, d.day);
    
    // Updates für heute einpflegen
    if (dailyPrices.containsKey(today)) {
      currentCardValues.addAll(dailyPrices[today]!);
    }
    
    // Gesamtwert berechnen (Summe aller aktuellen Kartenwerte)
    double dailyTotal = 0.0;
    // Wir summieren nur die Karten, die JETZT im Binder sind (cardIds)
    // Das simuliert: "Was wäre mein jetziger Binder damals wert gewesen?"
    for (var id in cardIds) {
      dailyTotal += currentCardValues[id] ?? 0.0;
    }
    
    // Nur speichern, wenn wir > 0 sind (optional)
    if (dailyTotal > 0) {
       history.add(BinderHistoryPoint(today, dailyTotal));
    }
  }

  return history;
});