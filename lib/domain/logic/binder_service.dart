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
      
      // 1. VISUELLEN INDEX BERECHNEN (Bleibt gleich)
      final pageIndex = (indexCounter / slotsPerPage).floor();
      final localIndex = indexCounter % slotsPerPage;
      int visualSlotIndex;
      if (sortOrder == BinderSortOrder.leftToRight) {
        visualSlotIndex = localIndex;
      } else {
        final int targetRow = localIndex % rows;
        final int targetCol = (localIndex / rows).floor();
        visualSlotIndex = targetRow * cols + targetCol;
      }

      // 2. INTELLIGENTE NAMENSUCHE
      // Wir generieren eine Liste möglicher Namen (z.B. ["Tapu-koko", "Tapu Koko", "Tapu Lele GX"])
      final List<String> candidates = _generateCandidateNames(pokeNameEn);

      // Wir suchen in der DB nach irgendeinem dieser Namen
      // Wir sortieren so, dass normale Karten vor V/VMAX kommen, falls mehrere matchen.
      final matchingCard = await (db.select(db.cards)
        ..where((tbl) => tbl.name.isIn(candidates)) 
        ..orderBy([(t) => OrderingTerm(expression: t.id)]) 
        ..limit(1)
      ).getSingleOrNull();

      // 3. LABEL BAUEN (Deutsch bevorzugt)
      String displayName = pokeNameEn; // Fallback
      
      // Wenn wir eine Karte gefunden haben, nehmen wir deren deutschen Namen
      if (matchingCard != null && matchingCard.nameDe != null && matchingCard.nameDe!.isNotEmpty) {
        displayName = matchingCard.nameDe!;
      } else {
        // Wenn keine Karte gefunden, versuchen wir den API Namen wenigstens schön zu formatieren
        // (z.B. "Tapu-koko" -> "Tapu Koko")
        displayName = candidates.last; // Der letzte Kandidat ist meist der "sauberste" (ohne Bindestriche)
      }

      final label = "#${id.toString().padLeft(4, '0')} $displayName";

      inserts.add(BinderCardsCompanion.insert(
        binderId: binderId,
        pageIndex: pageIndex,
        slotIndex: visualSlotIndex,
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

  // --- DIE NEUE "GEHIRN"-FUNKTION ---
  List<String> _generateCandidateNames(String apiName) {
    final Set<String> candidates = {};
    final String cleanInput = apiName.toLowerCase();

    // 1. Das Original (z.B. "Bulbasaur")
    candidates.add(apiName);

    // 2. Spezielle Mappings (Hardcoded Exceptions)
    final Map<String, String> exceptions = {
      'nidoran-f': 'Nidoran♀',
      'nidoran-m': 'Nidoran♂',
      'farfetchd': "Farfetch'd",
      'sirfetchd': "Sirfetch'd",
      'mr-mime': 'Mr. Mime',
      'mr-rime': 'Mr. Rime',
      'mime-jr': 'Mime Jr.',
      'ho-oh': 'Ho-Oh',
      'porygon-z': 'Porygon-Z',
      'flabebe': 'Flabébé',
      'type-null': 'Type: Null',
      'jangmo-o': 'Jangmo-o',
      'hakamo-o': 'Hakamo-o',
      'kommo-o': 'Kommo-o',
      'chingling': "Team Rocket's Chingling", 
      'dudunsparce-two-segments': "Dudunsparce",
      'wo-chien': "Wo-Chien",
      'chien-pao': "Chien-Pao",
      'ting-lu': "Ting-Lu",
      'chi-yu': "Chi-Yu",
      'Ogerpon': "Cornerstone Mask Ogerpon",
    };

    if (exceptions.containsKey(cleanInput)) {
      candidates.add(exceptions[cleanInput]!);
    }

    // 3. Bindestriche zu Leerzeichen (Paradox, Tapus, Legends of Ruin)
    // "tapu-koko" -> "Tapu Koko", "iron-moth" -> "Iron Moth"
    if (cleanInput.contains('-')) {
      final spaced = apiName.replaceAll('-', ' ');
      candidates.add(_capitalizeWords(spaced));
    }

    // 4. Suffixe entfernen (Formen, die auf Karten oft nicht stehen)
    // Liste der Suffixe, die wir einfach abschneiden
    final List<String> suffixesToRemove = [
      '-normal', '-average', '-standard', '-altered', '-land', '-plant', 
      '-ordinary', '-aria', '-midday', '-solo', '-red-striped', '-red-meteor',
      '-disguised', '-amped', '-ice', '-full-belly', '-male', '-female',
      '-shield', '-50', '-baile', '-incarnate', '-zero', '-curly', 
      '-family-of-four', '-green-plumage', '-two-segments'
    ];

    for (final suffix in suffixesToRemove) {
      if (cleanInput.endsWith(suffix)) {
        // Schneide Suffix ab und mache den Rest schön
        final base = cleanInput.substring(0, cleanInput.length - suffix.length);
        candidates.add(_capitalizeWords(base)); // z.B. "Deoxys"
        break; // Nur ein Suffix entfernen
      }
    }

    // 5. Regionalformen (Prefixe hinzufügen)
    // Wenn die API "Obstagoon" liefert, die Karte aber "Galarian Obstagoon" heißt
    final Map<String, String> regionalPrefixes = {
      'obstagoon': 'Galarian',
      'perrserker': 'Galarian',
      'cursola': 'Galarian',
      'sirfetchd': 'Galarian',
      'mr-rime': 'Galarian',
      'runerigus': 'Galarian',
      'darmanitan': 'Galarian', // Oft Galarian
      'basculegion': 'Hisuian',
      'sneasler': 'Hisuian',
      'overqwil': 'Hisuian',
      'clodsire': 'Paldean',
    };

    // Wir prüfen den Basis-Namen (evtl. nach Suffix-Entfernung)
    String checkRegional = cleanInput;
    for (final suffix in suffixesToRemove) {
      if (checkRegional.endsWith(suffix)) {
        checkRegional = checkRegional.substring(0, checkRegional.length - suffix.length);
      }
    }

    if (regionalPrefixes.containsKey(checkRegional)) {
      final prefix = regionalPrefixes[checkRegional]!;
      final base = _capitalizeWords(checkRegional);
      candidates.add("$prefix $base"); // "Galarian Obstagoon"
    }

    // 6. Urshifu Sonderfall (Swap)
    if (cleanInput.contains('urshifu')) {
      if (cleanInput.contains('single-strike')) candidates.add('Single Strike Urshifu');
      if (cleanInput.contains('rapid-strike')) candidates.add('Rapid Strike Urshifu');
    }

    // 7. Arceus & Co (Falls keine normale Karte existiert, V/VSTAR suchen)
    // Das ist ein "weicher" Fallback.
    if (cleanInput == 'arceus') {
      candidates.add('Arceus V');
      candidates.add('Arceus VSTAR');
    }
    if (cleanInput == 'giratina') { // Giratina ist oft V/VSTAR im modernen Kontext
      candidates.add('Giratina V');
    }

    return candidates.toList();
  }

  // Hilfsfunktion: "tapu koko" -> "Tapu Koko"
  String _capitalizeWords(String input) {
    if (input.isEmpty) return input;
    return input.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Future<void> deleteBinder(int binderId) async {
    await (db.delete(db.binders)..where((t) => t.id.equals(binderId))).go();
  }
}

