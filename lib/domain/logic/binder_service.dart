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
    required AdvancedBinderType type,
    required BinderSortOrder sortOrder,
    int customPages = 10,
    Set<int>? selectedGens,
    bool dexMegas = false,
    bool dexGmax = false,
    bool dexRegional = false,
    DexSortStyle dexSort = DexSortStyle.inline,
    SetCompletionType setCompletion = SetCompletionType.standard,
    String? selectedSetName,
    String? selectedTarget,
  }) async {
    final binderId = await db.into(db.binders).insert(
      BindersCompanion.insert(
        name: name,
        color: color,
        rowsPerPage: Value(rows),
        columnsPerPage: Value(cols),
        type: Value(type.name),
        sortOrder: Value(sortOrder.name), 
      ),
    );

    await _generateAdvancedSlots(
      binderId: binderId,
      type: type,
      rows: rows,
      cols: cols,
      sortOrder: sortOrder,
      customPages: customPages,
      selectedGens: selectedGens ?? {1},
      dexMegas: dexMegas,
      dexGmax: dexGmax,
      dexRegional: dexRegional,
      dexSort: dexSort,
      setCompletion: setCompletion,
      selectedSetName: selectedSetName,
      selectedTarget: selectedTarget,
    );

    final now = DateTime.now();
    final twoDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 2));
    await db.into(db.binderHistory).insert(BinderHistoryCompanion.insert(binderId: binderId, date: twoDaysAgo, value: 0.0));
    final today = DateTime(now.year, now.month, now.day);
    await db.into(db.binderHistory).insert(BinderHistoryCompanion.insert(binderId: binderId, date: today, value: 0.0));
  }

  // =====================================================================
  // DIE MAGISCHE SLOT GENERIERUNG
  // =====================================================================
  Future<void> _generateAdvancedSlots({
    required int binderId, required AdvancedBinderType type, required int rows, required int cols,
    required BinderSortOrder sortOrder, required int customPages, required Set<int> selectedGens,
    required bool dexMegas, required bool dexGmax, required bool dexRegional, required DexSortStyle dexSort,
    required SetCompletionType setCompletion, String? selectedSetName, String? selectedTarget,
  }) async {
    
    final int slotsPerPage = rows * cols;
    if (slotsPerPage == 0 && type != AdvancedBinderType.custom) return;
    
    List<BinderCardsCompanion> inserts = [];
    int indexCounter = 0;

    void addSlot(String label, String? cardId, String? variant) {
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

      inserts.add(BinderCardsCompanion.insert(
        binderId: binderId,
        pageIndex: pageIndex,
        slotIndex: visualSlotIndex,
        isPlaceholder: const Value(true),
        placeholderLabel: Value(label),
        cardId: cardId != null ? Value(cardId) : const Value.absent(),
        variant: variant != null ? Value(variant) : const Value.absent(),
      ));
      indexCounter++;
    }

    if (type == AdvancedBinderType.custom) {
      int totalSlots = slotsPerPage * customPages;
      for (int i = 0; i < totalSlots; i++) addSlot("Leerer Slot", null, null);
    } 

    else if (type == AdvancedBinderType.dex) {
      final allDex = await db.select(db.pokedex).get();
      List<PokedexData> basePokemon = [];
      List<PokedexData> specialForms = [];

      int getGen(int id) {
        if (id <= 151) return 1; if (id <= 251) return 2; if (id <= 386) return 3;
        if (id <= 493) return 4; if (id <= 649) return 5; if (id <= 721) return 6;
        if (id <= 809) return 7; if (id <= 905) return 8; return 9;
      }

      for (var p in allDex) {
        // --- 1. DER GEISTER-FILTER (Müll aus der API ignorieren) ---
        if (_isIgnoredForm(p.name)) continue;

        if (p.id <= 1025) {
          if (selectedGens.contains(getGen(p.id))) basePokemon.add(p);
        } else {
          final lowerName = p.name.toLowerCase();
          bool isMega = lowerName.contains('-mega') || lowerName.contains('-primal');
          bool isGmax = lowerName.contains('-gmax');
          bool isRegional = lowerName.contains('-alola') || lowerName.contains('-galar') || lowerName.contains('-hisui') || lowerName.contains('-paldea');
          
          if ((isMega && dexMegas) || (isGmax && dexGmax) || (isRegional && dexRegional)) {
            specialForms.add(p);
          }
        }
      }

      List<PokedexData> finalDex = [];
      if (dexSort == DexSortStyle.appended) {
        finalDex.addAll(basePokemon);
        finalDex.addAll(specialForms);
      } else {
        for (var base in basePokemon) {
          finalDex.add(base);
          // --- 2. DER MR. MIME FIX (Exakte Zuordnung statt Überschneidung) ---
          var forms = specialForms.where((f) => _getBaseIdentifier(f.name) == _getBaseIdentifier(base.name));
          finalDex.addAll(forms);
        }
      }

      for (var p in finalDex) {
        final isBase = p.id <= 1025;
        final prefix = isBase ? "#${p.id.toString().padLeft(4, '0')} " : "✨ ";
        
        final candidates = _getCandidateNames(p.name);
        
        // --- DER CASE-SENSITIVITY KILLER: ALLES IN KLEINBUCHSTABEN SUCHEN! ---
        final lowerCandidates = candidates.map((c) => c.toLowerCase()).toList();
        
        final cards = await (db.select(db.cards)
          ..where((t) => t.name.lower().isIn(lowerCandidates) | t.nameDe.lower().isIn(lowerCandidates))
        ).get();
        
        cards.sort((a, b) {
          final aHasImg = a.imageUrl.isNotEmpty || (a.imageUrlDe != null && a.imageUrlDe!.isNotEmpty);
          final bHasImg = b.imageUrl.isNotEmpty || (b.imageUrlDe != null && b.imageUrlDe!.isNotEmpty);
          if (aHasImg && !bHasImg) return -1;
          if (!aHasImg && bHasImg) return 1;

          // Prio prüfen (Kleinbuchstaben!)
          int aPriority = lowerCandidates.indexOf(a.name.toLowerCase());
          int bPriority = lowerCandidates.indexOf(b.name.toLowerCase());
          if (aPriority == -1) aPriority = lowerCandidates.indexOf(a.nameDe?.toLowerCase() ?? "");
          if (bPriority == -1) bPriority = lowerCandidates.indexOf(b.nameDe?.toLowerCase() ?? "");
          if (aPriority == -1) aPriority = 999;
          if (bPriority == -1) bPriority = 999;

          return aPriority.compareTo(bPriority);
        });

        final bestCard = cards.isNotEmpty ? cards.first : null;
        String cleanName = bestCard?.nameDe ?? bestCard?.name ?? candidates.first;
        addSlot("$prefix$cleanName", bestCard?.id, null);
      }
    }

    else if (type == AdvancedBinderType.set && selectedSetName != null) {
      final setInfo = await (db.select(db.cardSets)..where((t) => t.name.equals(selectedSetName))).getSingleOrNull();
      if (setInfo != null) {
        final cardsInSet = await (db.select(db.cards)..where((t) => t.setId.equals(setInfo.id))).get();
        cardsInSet.sort((a, b) => a.sortNumber.compareTo(b.sortNumber)); 

        for (var c in cardsInSet) {
          bool isSecret = false;
          if (c.number.contains('/') && setInfo.printedTotal != null) {
             int num = int.tryParse(c.number.split('/').first.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
             if (num > setInfo.printedTotal!) isSecret = true;
          }

          if (setCompletion == SetCompletionType.standard && isSecret) continue;

          String displayName = "${c.nameDe ?? c.name} (${c.number})";

          if (setCompletion == SetCompletionType.complete) {
             if (c.hasNormal) addSlot(displayName, c.id, "Normal");
             if (c.hasHolo) addSlot("$displayName (Holo)", c.id, "Holo");
             if (c.hasReverse) addSlot("$displayName (Reverse)", c.id, "Reverse Holo");
          } else {
             addSlot(displayName, c.id, null);
          }
        }
      }
    }

    else if ((type == AdvancedBinderType.pokemon || type == AdvancedBinderType.artist) && selectedTarget != null) {
      final query = db.select(db.cards);
      if (type == AdvancedBinderType.pokemon) {
        query.where((t) => t.name.like('%$selectedTarget%') | t.nameDe.like('%$selectedTarget%'));
      } else {
        query.where((t) => t.artist.equals(selectedTarget));
      }
      
      final cards = await query.get();
      cards.sort((a, b) => a.sortNumber.compareTo(b.sortNumber)); 
      
      for (var c in cards) {
        addSlot("${c.nameDe ?? c.name} (${c.number})", c.id, null);
      }
    }

    if (inserts.isNotEmpty) {
      await db.transaction(() async {
        for (var i = 0; i < inserts.length; i += 500) {
          final end = (i + 500 < inserts.length) ? i + 500 : inserts.length;
          await db.batch((batch) {
            batch.insertAll(db.binderCards, inserts.sublist(i, end));
          });
        }
      });
    }
  }

  // =====================================================================
  // KANDIDATEN-GENERIERUNG FÜR CHAOTISCHE KARTENNAMEN
  // =====================================================================
  List<String> _getCandidateNames(String apiName) {
    final String workStr = apiName.toLowerCase();
    final List<String> candidates = [];

    // --- 1. HARDCODED EXCEPTIONS (Exakte Zuordnungen & Ausnahmen) ---
    final exceptions = {
      'nidoran-f': ['Nidoran♀'],
      'nidoran-m': ['Nidoran♂'],
      'farfetchd': ["Farfetch'd"],
      'mr-mime': ['Mr. Mime'],
      'mime-jr': ['Mime Jr.'],
      'mr-rime': ['Galarian Mr. Rime','Mr. Rime'],
      'ho-oh': ['Ho-Oh'],
      'porygon-z': ['Porygon-Z'],
      'flabebe': ['Flabébé', 'Flabebe'],
      'type-null': ['Type: Null'],
      'wo-chien': ['Wo-Chien ex', 'Wo-Chien'],
      'chien-pao': ['Chien-Pao ex', 'Chien-Pao'],
      'ting-lu': ['Ting-Lu ex', 'Ting-Lu'],
      'chi-yu': ['Chi-Yu ex', 'Chi-Yu'],
      'jangmo-o': ['Jangmo-o'],
      'hakamo-o': ['Hakamo-o'],
      'kommo-o': ['Kommo-o'],
      'sirfetchd': ["Galarian Sirfetch'd", "Sirfetch'd"],
      'chingling': ['Chingling', "Team Rocket's Chingling"],
      'arceus': ['Arceus V', 'Arceus VSTAR', 'Arceus'],
      'giratina-altered': ['Giratina V', 'Giratina VSTAR', 'Giratina'],
      'deoxys-normal': ['Deoxys'],
      
      // Die Toxtricity/Urshifu Fixes (Kein VMAX Diebstahl mehr!)
      'toxtricity-amped': ['Toxtricity'], 
      'toxtricity-amped-gmax': ['Toxtricity VMAX'],
      'urshifu': ['Urshifu', 'Urshifu V'], 
      'tatsugiri-curly-mega': ['Mega Tatsugiri ex', 'Mega Tatsugiri'], 
      
      // Die Galar & Hisui Basis-Entwicklungen
      'obstagoon': ['Galarian Obstagoon', 'Obstagoon'],
      'perrserker': ['Galarian Perrserker', 'Perrserker'],
      'cursola': ['Galarian Cursola', 'Cursola'],
      'runerigus': ['Galarian Runerigus', 'Runerigus'],
      'sneasler': ['Hisuian Sneasler', 'Sneasler'],
      'overqwil': ['Hisuian Overqwil', 'Overqwil'],
      'basculegion-male': ['Hisuian Basculegion', 'Basculegion'],
      'basculegion': ['Hisuian Basculegion', 'Basculegion'],
      'clodsire': ['Paldean Clodsire', 'Clodsire ex', 'Clodsire'],
    };

    if (exceptions.containsKey(workStr)) {
      candidates.addAll(exceptions[workStr]!);
      return candidates;
    }

    // --- 2. MEGAS ---
    if (workStr.contains('-mega')) {
      final isX = workStr.endsWith('-x');
      final isY = workStr.endsWith('-y');
      final isZ = workStr.endsWith('-z');
      final suffix = isX ? ' X' : (isY ? ' Y' : (isZ ? ' Z' : ''));
      final rawBase = workStr.split('-mega').first;
      final base = _formatBase(rawBase);

      // Englisch Modern
      candidates.add('Mega $base$suffix EX');
      candidates.add('Mega $base$suffix ex');
      candidates.add('Mega $base$suffix-EX');
      // Deutsch Modern (mit Bindestrich)
      candidates.add('Mega-$base$suffix-EX');
      candidates.add('Mega-$base$suffix-ex'); 
      candidates.add('Mega-$base-EX'); 
      candidates.add('Mega-$base-ex');
      // Englisch Alt
      candidates.add('M $base$suffix-EX');
      candidates.add('M $base$suffix EX');
      candidates.add('M $base$suffix-ex');
      candidates.add('M $base$suffix ex');
      
      // Ohne Suffix
      if (isX || isY || isZ) {
        candidates.add('Mega $base EX');
        candidates.add('Mega $base ex');
        candidates.add('Mega-$base-ex');
        candidates.add('M $base-EX');
        candidates.add('M $base EX');
      }
      return candidates.toSet().toList();
    }

    // --- 3. PRIMAL (Proto) ---
    if (workStr.contains('-primal')) {
      final rawBase = workStr.split('-primal').first;
      final base = _formatBase(rawBase);
      candidates.add('Primal $base EX');
      candidates.add('Primal $base-EX');
      candidates.add('Primal $base ex');
      candidates.add('Proto-$base-EX'); 
      candidates.add('Proto-$base-ex'); 
      return candidates;
    }

    // --- 4. GMAX (Wird VMAX/VSTAR) ---
    if (workStr.contains('-gmax')) {
      final rawBase = workStr.split('-gmax').first;
      final base = _formatBase(rawBase);
      candidates.add('$base VMAX');
      candidates.add('$base VSTAR');
      candidates.add(base);
      return candidates;
    }

    // --- 5. URSHIFU SONDERFORMEN ---
    if (workStr.contains('urshifu')) {
      if (workStr.contains('single-strike')) {
        return ['Single Strike Urshifu VMAX', 'Single Strike Urshifu V', 'Single Strike Urshifu'];
      } else if (workStr.contains('rapid-strike')) {
        return ['Rapid Strike Urshifu VMAX', 'Rapid Strike Urshifu V', 'Rapid Strike Urshifu'];
      }
    }

    // --- 6. REGIONALFORMEN ---
    if (workStr.contains('-alola') || workStr.contains('-galar') || workStr.contains('-hisui') || workStr.contains('-paldea')) {
        String cleanedRegion = workStr.replaceAll(RegExp(r'-alola|-galar|-hisui|-paldea|-standard|-combat-breed|-blaze-breed|-aqua-breed'), '');
        String formattedBase = _formatBase(cleanedRegion);
        
        if (workStr.contains('-alola')) candidates.add('Alolan $formattedBase');
        if (workStr.contains('-galar')) {
             candidates.add('Galarian $formattedBase');
             if (workStr.contains('mr-mime')) candidates.add('Galarian Mr. Mime');
        }
        if (workStr.contains('-hisui')) candidates.add('Hisuian $formattedBase');
        if (workStr.contains('-paldea')) {
             candidates.add('Paldean $formattedBase');
             if (workStr.contains('tauros')) candidates.add('Paldean Tauros');
        }
        candidates.add(formattedBase);
        return candidates.toSet().toList();
    }
    
    // --- 7. OGERPON ---
    if (workStr.contains('ogerpon')) {
      if (workStr.contains('wellspring')) return ['Wellspring Mask Ogerpon ex', 'Ogerpon ex'];
      if (workStr.contains('hearthflame')) return ['Hearthflame Mask Ogerpon ex', 'Ogerpon ex'];
      if (workStr.contains('cornerstone')) return ['Cornerstone Mask Ogerpon ex', 'Ogerpon ex'];
      if (workStr.contains('teal')) return ['Teal Mask Ogerpon ex', 'Ogerpon ex'];
      return ['Ogerpon ex', 'Ogerpon'];
    }

    // --- 8. SUFFIX CLEANUP ---
    final suffixesToRemove = [
      '-normal', '-plant', '-altered', '-land', '-red-striped', '-standard', 
      '-incarnate', '-ordinary', '-aria', '-male', '-female', '-shield', '-blade',
      '-average', '-50', '-10', '-complete', '-baile', '-pom-pom', '-pau', '-sensu',
      '-midday', '-midnight', '-dusk', '-solo', '-school', '-red-meteor', '-orange-meteor',
      '-yellow-meteor', '-green-meteor', '-blue-meteor', '-indigo-meteor', '-violet-meteor',
      '-disguised', '-busted', '-amped', '-low-key', '-ice', '-noice', '-full-belly', '-hangry',
      '-single-strike', '-rapid-strike', '-zero', '-hero', '-curly', '-droopy', '-stretchy', 
      '-two-segment', '-three-segment', '-green-plumage', '-blue-plumage', '-yellow-plumage', '-white-plumage',
      '-family-of-four', '-family-of-three', '-roaming', '-terastal', '-stellar', '-bloodmoon',
      '-combat-breed', '-blaze-breed', '-aqua-breed'
    ];

    String cleaned = workStr;
    for (var suffix in suffixesToRemove) {
      if (cleaned.endsWith(suffix)) {
        cleaned = cleaned.substring(0, cleaned.length - suffix.length);
        break; 
      }
    }

    // --- 9. STANDARD BEHANDLUNG ---
    final titleCased = _formatBase(cleaned);
    
    candidates.add(titleCased);
    candidates.add('$titleCased ex');
    candidates.add('$titleCased EX');
    candidates.add('$titleCased V');

    return candidates.toSet().toList(); 
  }

  // --- WICHTIGE HELPER FÜR DEN KORREKTEN BASIS-NAMEN ---
  String _formatBase(String b) {
      final n = b.toLowerCase();
      if (n == 'farfetchd') return "Farfetch'd";
      if (n == 'sirfetchd') return "Sirfetch'd";
      if (n == 'mr-mime') return "Mr. Mime";
      if (n == 'mr-rime') return "Mr. Rime";
      if (n == 'mime-jr') return "Mime Jr.";
      if (n == 'ho-oh') return "Ho-Oh";
      if (n == 'porygon-z') return "Porygon-Z";
      
      return n.split('-').map((w) {
         if(['ex', 'gx', 'v', 'vmax', 'vstar'].contains(w.toLowerCase())) return w.toUpperCase();
         if(w.isEmpty) return '';
         return w[0].toUpperCase() + w.substring(1).toLowerCase();
      }).join(' ');
  }

  // --- Identifiziert den "Stamm" für die saubere Sortierung (Mime vs Rime) ---
  String _getBaseIdentifier(String name) {
    final n = name.toLowerCase();
    if (n.startsWith('mr-mime')) return 'mr-mime';
    if (n.startsWith('mr-rime')) return 'mr-rime';
    if (n.startsWith('mime-jr')) return 'mime-jr';
    if (n.startsWith('ho-oh')) return 'ho-oh';
    if (n.startsWith('porygon-z')) return 'porygon-z';
    if (n.startsWith('type-null')) return 'type-null';
    if (n.startsWith('tapu-')) return n; // Tapu Koko bleibt Tapu Koko
    return n.split('-').first;
  }

  // --- DER HARTE GEISTER-FILTER ---
  bool _isIgnoredForm(String name) {
      final n = name.toLowerCase();
      if (n == 'magearna-original-mega') return true;
      if (n == 'tatsugiri-droopy-mega') return true;
      if (n == 'tatsugiri-stretchy-mega') return true;
      if (n == 'tatsugiri-droopy') return true;
      if (n == 'tatsugiri-stretchy') return true;
      if (n == 'toxtricity-low-key-gmax') return true;
      if (n == 'toxtricity-low-key') return true;
      if (n == 'darmanitan-galar-zen') return true;
      if (n == 'darmanitan-zen') return true;
      if (n == 'magearna-original') return true;
      if (n == 'appletun-gmax') return true;
      if (n == 'tauros-paldea-blaze-breed') return true;
      if (n == 'tauros-paldea-aqua-breed') return true;
      
      if (n.contains('-totem')) return true;
      if (n.contains('-cap')) return true;
      if (n.startsWith('pikachu-') && !n.contains('gmax')) return true;
      if (n.startsWith('eevee-') && !n.contains('gmax')) return true;
      // Unsichtbare Formen
      if (n.contains('-busted') || n.contains('-meteor') || n.contains('-school')) return true;
      if (n.contains('-noice') || n.contains('-hangry') || n.contains('family-of-three')) return true;
      if (n.contains('squawkabilly-') && n != 'squawkabilly-green-plumage') return true;
      if (n.contains('koraidon-') && n != 'koraidon') return true;
      if (n.contains('miraidon-') && n != 'miraidon') return true;
      if (n.contains('-crowned') || n.contains('eternamax')) return true;
      return false;
  }

  // --- STANDARD HILFSFUNKTIONEN (Bleiben gleich) ---

  Future<void> deleteBinder(int binderId) async {
   await db.batch((batch) {
      batch.deleteWhere(db.binderCards, (t) => t.binderId.equals(binderId));
      batch.deleteWhere(db.binders, (t) => t.id.equals(binderId));
    });
  }

  Future<bool> isCardAvailable(String cardId) async {
    final userCards = await (db.select(db.userCards)..where((t) => t.cardId.equals(cardId))).get();
    int ownedQty = 0;
    for (var uc in userCards) { ownedQty += uc.quantity; }
    if (ownedQty == 0) return false;
    final usedCountList = await (db.select(db.binderCards)..where((t) => t.cardId.equals(cardId) & t.isPlaceholder.equals(false))).get();
    return ownedQty > usedCountList.length;
  }

  Future<List<String>> getAvailableVariantsForCard(String cardId) async {
    final userCards = await (db.select(db.userCards)..where((t) => t.cardId.equals(cardId))).get();
    Map<String, int> inventoryCounts = {};
    for (var uc in userCards) { inventoryCounts[uc.variant] = (inventoryCounts[uc.variant] ?? 0) + uc.quantity; }

    final binderCards = await (db.select(db.binderCards)..where((t) => t.cardId.equals(cardId) & t.isPlaceholder.equals(false))).get();
    for (var bc in binderCards) {
      final v = bc.variant ?? 'Normal'; 
      if (inventoryCounts.containsKey(v)) inventoryCounts[v] = inventoryCounts[v]! - 1;
    }
    return inventoryCounts.entries.where((e) => e.value > 0).map((e) => e.key).toList();
  }

  Future<List<String>> getBindersForCard(String cardId) async {
    final query = db.select(db.binderCards).join([innerJoin(db.binders, db.binders.id.equalsExp(db.binderCards.binderId))]);
    query.where(db.binderCards.cardId.equals(cardId) & db.binderCards.isPlaceholder.equals(false));
    final rows = await query.get();
    return rows.map((r) => r.readTable(db.binders).name).toSet().toList(); 
  }

  Future<void> configureSlot(int slotId, String newCardId, String labelName) async {
    await (db.update(db.binderCards)..where((t) => t.id.equals(slotId))).write(
      BinderCardsCompanion(cardId: Value(newCardId), placeholderLabel: Value(labelName), isPlaceholder: const Value(true), variant: const Value.absent())
    );
  }
  
  Future<void> fillSlot(int slotId, String cardId, {String? variant}) async {
    if (!await isCardAvailable(cardId)) throw Exception("Keine Karte mehr verfügbar!");
    await (db.update(db.binderCards)..where((t) => t.id.equals(slotId))).write(
      BinderCardsCompanion(cardId: Value(cardId), isPlaceholder: const Value(false), variant: variant != null ? Value(variant) : const Value.absent())
    );
    final slot = await (db.select(db.binderCards)..where((t) => t.id.equals(slotId))).getSingle();
    await recalculateBinderValue(slot.binderId);
  }

  Future<void> clearSlot(int slotId) async {
    await (db.update(db.binderCards)..where((t) => t.id.equals(slotId))).write(
      const BinderCardsCompanion(isPlaceholder: Value(true), variant: Value(null)),
    );
    final slot = await (db.select(db.binderCards)..where((t) => t.id.equals(slotId))).getSingle();
    await recalculateBinderValue(slot.binderId);
  }

  Future<void> recalculateBinderValue(int binderId) async {
    final slots = await (db.select(db.binderCards)..where((t) => t.binderId.equals(binderId) & t.isPlaceholder.equals(false))).get();
    double total = 0.0;

    for (var slot in slots) {
      final cardId = slot.cardId;
      if (cardId == null) continue;

      final card = await (db.select(db.cards)..where((t) => t.id.equals(cardId))).getSingleOrNull();
      if (card == null) continue;

      final cmPrice = await (db.select(db.cardMarketPrices)..where((t) => t.cardId.equals(cardId))..orderBy([(t) => OrderingTerm(expression: t.fetchedAt, mode: OrderingMode.desc)])..limit(1)).getSingleOrNull();
      final tcgPrice = await (db.select(db.tcgPlayerPrices)..where((t) => t.cardId.equals(cardId))..orderBy([(t) => OrderingTerm(expression: t.fetchedAt, mode: OrderingMode.desc)])..limit(1)).getSingleOrNull();

      double singlePrice = 0.0;
      bool baseIsHolo = !card.hasNormal && card.hasHolo;
      final variant = slot.variant ?? 'Normal'; 
      
      final isFirstEd = variant.toLowerCase().contains('1st') || variant.toLowerCase().contains('first');
      final isHolo = variant.toLowerCase().contains('holo') || baseIsHolo;
      final isReverse = variant == 'Reverse Holo';

      if (card.hasFirstEdition) {
        if (isHolo) { singlePrice = isFirstEd ? (cmPrice?.trend ?? tcgPrice?.holoMarket ?? 0.0) : (cmPrice?.trendHolo ?? tcgPrice?.holoMarket ?? 0.0); } 
        else { singlePrice = isFirstEd ? (cmPrice?.trendHolo ?? tcgPrice?.normalMarket ?? 0.0) : (cmPrice?.trend ?? tcgPrice?.normalMarket ?? 0.0); }
      } 
      else if (isReverse) { singlePrice = cmPrice?.trendHolo ?? cmPrice?.trendReverse ?? tcgPrice?.reverseMarket ?? 0.0; } 
      else if (isHolo) { singlePrice = baseIsHolo ? (cmPrice?.trend ?? tcgPrice?.holoMarket ?? 0.0) : (cmPrice?.trendHolo ?? tcgPrice?.holoMarket ?? 0.0); } 
      else { singlePrice = cmPrice?.trend ?? tcgPrice?.normalMarket ?? 0.0; }

      if (singlePrice == 0.0) singlePrice = (isHolo ? tcgPrice?.holoMarket : tcgPrice?.normalMarket) ?? cmPrice?.trend ?? 0.0;
      total += singlePrice;
    }

    await (db.update(db.binders)..where((t) => t.id.equals(binderId))).write(BindersCompanion(totalValue: Value(total)));
    
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);
    final existingEntry = await (db.select(db.binderHistory)..where((t) => t.binderId.equals(binderId) & t.date.equals(dateOnly))).getSingleOrNull();

    if (existingEntry != null) {
      await (db.update(db.binderHistory)..where((t) => t.id.equals(existingEntry.id))).write(BinderHistoryCompanion(value: Value(total)));
    } else {
      await db.into(db.binderHistory).insert(BinderHistoryCompanion.insert(binderId: binderId, date: dateOnly, value: total));
    }
  }

  Future<void> recalculateAllBinders() async {
    final allBinders = await db.select(db.binders).get();
    for (var binder in allBinders) {
      await recalculateBinderValue(binder.id);
    }
  }
}