import 'package:drift/drift.dart';
import '../../data/database/app_database.dart';
import '../models/binder_templates.dart';

class BinderService {
  final AppDatabase db;

  BinderService(this.db);

  Future<void> createBinder({
    required String name,
    required int color,
    required int rows,
    required int cols,
    required BinderType type,
  }) async {
    return db.transaction(() async {
      // 1. Binder erstellen
      final binderId = await db.into(db.binders).insert(
        BindersCompanion.insert(
          name: name,
          color: color,
          rowsPerPage: Value(rows),
          columnsPerPage: Value(cols),
          type: Value(type.name),
        ),
      );

      // 2. Slots generieren (nur wenn nicht Custom)
      if (type != BinderType.custom) {
        await _generateSmartSlots(binderId, type, rows, cols);
      }
    });
  }

  Future<void> _generateSmartSlots(int binderId, BinderType type, int rows, int cols) async {
    int startId = 0;
    int endId = 0;

    // --- A) ID-Bereiche definieren ---
    switch (type) {
      case BinderType.kantoDex:   startId = 1; endId = 151; break;
      case BinderType.johtoDex:   startId = 152; endId = 251; break;
      case BinderType.hoennDex:   startId = 252; endId = 386; break;
      case BinderType.sinnohDex:  startId = 387; endId = 493; break;
      case BinderType.einallDex:  startId = 494; endId = 649; break;
      case BinderType.kalosDex:   startId = 650; endId = 721; break;
      case BinderType.alolaDex:   startId = 722; endId = 809; break;
      case BinderType.galarDex:   startId = 810; endId = 905; break;
      case BinderType.paldeaDex:  startId = 906; endId = 1025; break;
      case BinderType.nationalDex: startId = 1; endId = 1025; break;
      default: return; 
    }

    // --- B) Pokedex-Daten laden (Englisch) ---
    final List<PokedexData> speciesList = await (db.select(db.pokedex)
      ..where((tbl) => tbl.id.isBetweenValues(startId, endId))
      ..orderBy([(t) => OrderingTerm(expression: t.id)])
    ).get();

    // Map für schnellen Zugriff: ID -> Englischer Name ("1" -> "Bulbasaur")
    final Map<int, String> nameMap = {
      for (var s in speciesList) s.id: s.name
    };

    final int slotsPerPage = rows * cols;
    final List<BinderCardsCompanion> inserts = [];
    int indexCounter = 0; 

    // --- C) Iteration durch alle Nummern ---
    for (int id = startId; id <= endId; id++) {
      final pokeNameEn = nameMap[id] ?? "???"; 
      
      final pageIndex = (indexCounter / slotsPerPage).floor();
      final slotIndex = indexCounter % slotsPerPage;
      
      // --- KARTE SUCHEN ---
      // Wir suchen in der Tabelle 'cards' im Feld 'name' (Englisch)
      // Wir sortieren nach ID, um z.B. ältere Karten (Base Set) zu bevorzugen, falls möglich.
      // (Die TCGdex ID ist oft sprechend, z.B. "base1-1")
      final matchingCard = await (db.select(db.cards)
        ..where((tbl) => tbl.name.equals(pokeNameEn)) 
        ..orderBy([(t) => OrderingTerm(expression: t.id)]) 
        ..limit(1)
      ).getSingleOrNull();

      // Label bauen: Wir wollen den deutschen Namen anzeigen, wenn verfügbar!
      String displayName = pokeNameEn; // Fallback: Englisch
      if (matchingCard != null && matchingCard.nameDe != null && matchingCard.nameDe!.isNotEmpty) {
        displayName = matchingCard.nameDe!;
      }

      final label = "#${id.toString().padLeft(4, '0')} $displayName";

      inserts.add(BinderCardsCompanion.insert(
        binderId: binderId,
        pageIndex: pageIndex,
        slotIndex: slotIndex,
        isPlaceholder: const Value(true), // Es ist ein Platzhalter
        placeholderLabel: Value(label),
        // Wenn Karte gefunden, ID speichern (für Bild-Anzeige)
        cardId: matchingCard != null ? Value(matchingCard.id) : const Value.absent(),
      ));

      indexCounter++;
    }

    // --- D) Speichern ---
    if (inserts.isNotEmpty) {
      await db.batch((batch) {
        batch.insertAll(db.binderCards, inserts);
      });
    }
  }
}