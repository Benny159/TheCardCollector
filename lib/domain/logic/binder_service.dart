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
    required BinderSortOrder sortOrder, // <--- NEU
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
          sortOrder: Value(sortOrder.name), // <--- Speichern
        ),
      );

      // 2. Slots generieren
      if (type != BinderType.custom) {
        await _generateSmartSlots(binderId, type, rows, cols, sortOrder);
      }
    });
  }

  Future<void> _generateSmartSlots(
      int binderId, 
      BinderType type, 
      int rows, 
      int cols, 
      BinderSortOrder sortOrder // <--- NEU
  ) async {
    int startId = 0;
    int endId = 0;

    // --- A) BEREICHE (Unverändert) ---
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

    // --- B) DATEN LADEN (Unverändert) ---
    final List<PokedexData> speciesList = await (db.select(db.pokedex)
      ..where((tbl) => tbl.id.isBetweenValues(startId, endId))
      ..orderBy([(t) => OrderingTerm(expression: t.id)])
    ).get();

    final Map<int, String> nameMap = { for (var s in speciesList) s.id: s.name };

    // --- C) SLOTS BERECHNEN (MIT SORTIERUNG) ---
    final int slotsPerPage = rows * cols;
    final List<BinderCardsCompanion> inserts = [];
    int indexCounter = 0; 

    for (int id = startId; id <= endId; id++) {
      final pokeNameEn = nameMap[id] ?? "???"; 
      
      // 1. Auf welcher Seite sind wir?
      final pageIndex = (indexCounter / slotsPerPage).floor();
      
      // 2. Der wievielte Slot auf dieser Seite ist es (0 bis 8 bei 3x3)?
      final localIndex = indexCounter % slotsPerPage;
      
      // 3. VISUELLEN SLOT BERECHNEN
      int visualSlotIndex;

      if (sortOrder == BinderSortOrder.leftToRight) {
        // Standard: Einfach durchzählen (0, 1, 2, 3...)
        visualSlotIndex = localIndex;
      } else {
        // Top-to-Bottom: Transponieren
        // Beispiel 3x3:
        // Index 0 -> Zeile 0, Spalte 0 -> Slot 0
        // Index 1 -> Zeile 1, Spalte 0 -> Slot 3
        // Index 2 -> Zeile 2, Spalte 0 -> Slot 6
        // Index 3 -> Zeile 0, Spalte 1 -> Slot 1
        
        // Wir füllen erst die Spalte voll (rows), dann nächste Spalte.
        final int targetRow = localIndex % rows;
        final int targetCol = (localIndex / rows).floor();
        
        // Zurückrechnen auf visuellen Index (Zeile * Breite + Spalte)
        visualSlotIndex = targetRow * cols + targetCol;
      }

      // --- KARTE SUCHEN (Unverändert) ---
      final matchingCard = await (db.select(db.cards)
        ..where((tbl) => tbl.name.equals(pokeNameEn)) 
        ..orderBy([(t) => OrderingTerm(expression: t.id)]) 
        ..limit(1)
      ).getSingleOrNull();

      String displayName = pokeNameEn;
      if (matchingCard != null && matchingCard.nameDe != null && matchingCard.nameDe!.isNotEmpty) {
        displayName = matchingCard.nameDe!;
      }

      final label = "#${id.toString().padLeft(4, '0')} $displayName";

      inserts.add(BinderCardsCompanion.insert(
        binderId: binderId,
        pageIndex: pageIndex,
        slotIndex: visualSlotIndex, // <-- Hier nutzen wir den berechneten Index
        isPlaceholder: const Value(true),
        placeholderLabel: Value(label),
        cardId: matchingCard != null ? Value(matchingCard.id) : const Value.absent(),
      ));

      indexCounter++;
    }

    if (inserts.isNotEmpty) {
      await db.batch((batch) {
        batch.insertAll(db.binderCards, inserts);
      });
    }
  }
}