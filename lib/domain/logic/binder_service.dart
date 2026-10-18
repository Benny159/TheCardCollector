import 'package:drift/drift.dart';
import '../../data/database/app_database.dart';
import '../models/binder_templates.dart';
import 'price_calculator.dart';

/// Core domain service responsible for binder creation, slot calculation,
/// card placement, bulk box assignments, and collection value aggregation.
class BinderService {
  final AppDatabase db;
  final PriceCalculator _priceCalculator = const PriceCalculator();

  BinderService(this.db);

  /// Creates a new binder entity in the database and generates its initial grid slots.
  ///
  /// Populates slots based on the provided [type], dimensions ([rows] x [cols]),
  /// [sortOrder], and optional Pokédex/set filters.
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
    String? icon,
  }) async {
    final binderId = await db.into(db.binders).insert(
      BindersCompanion.insert(
        name: name,
        color: color,
        icon: Value(icon),
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
  // ADVANCED SLOT GENERATION
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
      for (int i = 0; i < totalSlots; i++) {
        addSlot("Leerer Slot", null, null);
      }
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
        // 1. Filter out ignored non-card forms
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
          // 2. Base identifier matching for distinct species forms
          var forms = specialForms.where((f) => _getBaseIdentifier(f.name) == _getBaseIdentifier(base.name));
          finalDex.addAll(forms);
        }
      }

      for (var p in finalDex) {
        final isBase = p.id <= 1025;
        final prefix = isBase ? "#${p.id.toString().padLeft(4, '0')} " : "✨ ";
        
        final candidates = _getCandidateNames(p.name);
        
        // Case-insensitive candidate name query
        final lowerCandidates = candidates.map((c) => c.toLowerCase()).toList();
        
        final cards = await (db.select(db.cards)
          ..where((t) => t.name.lower().isIn(lowerCandidates) | t.nameDe.lower().isIn(lowerCandidates))
        ).get();
        
        cards.sort((a, b) {
          final aHasImg = a.imageUrl.isNotEmpty || (a.imageUrlDe != null && a.imageUrlDe!.isNotEmpty);
          final bHasImg = b.imageUrl.isNotEmpty || (b.imageUrlDe != null && b.imageUrlDe!.isNotEmpty);
          if (aHasImg && !bHasImg) return -1;
          if (!aHasImg && bHasImg) return 1;

          // Match priority check (lowercase)
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
  // CANDIDATE NAME GENERATION HEURISTICS
  // =====================================================================
  List<String> _getCandidateNames(String apiName) {
    final String workStr = apiName.toLowerCase();
    final List<String> candidates = [];

    // 1. Hardcoded exact name mappings and edge case exceptions
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
      
      // Specific Toxtricity/Urshifu disambiguations
      'toxtricity-amped': ['Toxtricity'], 
      'toxtricity-amped-gmax': ['Toxtricity VMAX'],
      'urshifu': ['Urshifu', 'Urshifu V'], 
      'tatsugiri-curly-mega': ['Mega Tatsugiri ex', 'Mega Tatsugiri'], 
      
      // Galarian and Hisuian distinct base evolutions
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

    // 2. Mega Evolution naming patterns
    if (workStr.contains('-mega')) {
      final isX = workStr.endsWith('-x');
      final isY = workStr.endsWith('-y');
      final isZ = workStr.endsWith('-z');
      final suffix = isX ? ' X' : (isY ? ' Y' : (isZ ? ' Z' : ''));
      final rawBase = workStr.split('-mega').first;
      final base = _formatBase(rawBase);

      // English Modern
      candidates.add('Mega $base$suffix EX');
      candidates.add('Mega $base$suffix ex');
      candidates.add('Mega $base$suffix-EX');
      // German Modern (hyphenated)
      candidates.add('Mega-$base$suffix-EX');
      candidates.add('Mega-$base$suffix-ex'); 
      candidates.add('Mega-$base-EX'); 
      candidates.add('Mega-$base-ex');
      // English Classic (M prefix)
      candidates.add('M $base$suffix-EX');
      candidates.add('M $base$suffix EX');
      candidates.add('M $base$suffix-ex');
      candidates.add('M $base$suffix ex');
      
      // Without X/Y suffix
      if (isX || isY || isZ) {
        candidates.add('Mega $base EX');
        candidates.add('Mega $base ex');
        candidates.add('Mega-$base-ex');
        candidates.add('M $base-EX');
        candidates.add('M $base EX');
      }
      return candidates.toSet().toList();
    }

    // 3. Primal reversion patterns
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

    // 4. Gigantamax (maps to VMAX/VSTAR in TCG)
    if (workStr.contains('-gmax')) {
      final rawBase = workStr.split('-gmax').first;
      final base = _formatBase(rawBase);
      candidates.add('$base VMAX');
      candidates.add('$base VSTAR');
      candidates.add(base);
      return candidates;
    }

    // 5. Urshifu battle style variants
    if (workStr.contains('urshifu')) {
      if (workStr.contains('single-strike')) {
        return ['Single Strike Urshifu VMAX', 'Single Strike Urshifu V', 'Single Strike Urshifu'];
      } else if (workStr.contains('rapid-strike')) {
        return ['Rapid Strike Urshifu VMAX', 'Rapid Strike Urshifu V', 'Rapid Strike Urshifu'];
      }
    }

    // 6. Regional variant forms
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
    
    // 7. Ogerpon mask forms
    if (workStr.contains('ogerpon')) {
      if (workStr.contains('wellspring')) return ['Wellspring Mask Ogerpon ex', 'Ogerpon ex'];
      if (workStr.contains('hearthflame')) return ['Hearthflame Mask Ogerpon ex', 'Ogerpon ex'];
      if (workStr.contains('cornerstone')) return ['Cornerstone Mask Ogerpon ex', 'Ogerpon ex'];
      if (workStr.contains('teal')) return ['Teal Mask Ogerpon ex', 'Ogerpon ex'];
      return ['Ogerpon ex', 'Ogerpon'];
    }

    // 8. Form suffix cleanup
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

    // 9. Standard card candidate variations
    final titleCased = _formatBase(cleaned);
    
    candidates.add(titleCased);
    candidates.add('$titleCased ex');
    candidates.add('$titleCased EX');
    candidates.add('$titleCased V');

    return candidates.toSet().toList(); 
  }

  // Helper to normalize base Pokémon names
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

  // Identifies base stem for grouping (e.g. Mime vs Rime)
  String _getBaseIdentifier(String name) {
    final n = name.toLowerCase();
    if (n.startsWith('mr-mime')) return 'mr-mime';
    if (n.startsWith('mr-rime')) return 'mr-rime';
    if (n.startsWith('mime-jr')) return 'mime-jr';
    if (n.startsWith('ho-oh')) return 'ho-oh';
    if (n.startsWith('porygon-z')) return 'porygon-z';
    if (n.startsWith('type-null')) return 'type-null';
    if (n.startsWith('tapu-')) return n; // Keep Tapu Koko intact
    return n.split('-').first;
  }

  // Ignored forms filter
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
      // Non-card aesthetic forms
      if (n.contains('-busted') || n.contains('-meteor') || n.contains('-school')) return true;
      if (n.contains('-noice') || n.contains('-hangry') || n.contains('family-of-three')) return true;
      if (n.contains('squawkabilly-') && n != 'squawkabilly-green-plumage') return true;
      if (n.contains('koraidon-') && n != 'koraidon') return true;
      if (n.contains('miraidon-') && n != 'miraidon') return true;
      if (n.contains('-crowned') || n.contains('eternamax')) return true;
      return false;
  }

  // Standard helper functions

  /// Deletes the binder with [binderId] and cascades removal of all associated slots.
  Future<void> deleteBinder(int binderId) async {
   await db.batch((batch) {
      batch.deleteWhere(db.binderCards, (t) => t.binderId.equals(binderId));
      batch.deleteWhere(db.binders, (t) => t.id.equals(binderId));
    });
  }

  /// Returns whether the user owns at least one unassigned copy of [cardId].
  Future<bool> isCardAvailable(String cardId) async {
    final userCards = await (db.select(db.userCards)..where((t) => t.cardId.equals(cardId))).get();
    int ownedQty = 0;
    for (var uc in userCards) { ownedQty += uc.quantity; }
    if (ownedQty == 0) return false;
    final usedCountList = await (db.select(db.binderCards)..where((t) => t.cardId.equals(cardId) & t.isPlaceholder.equals(false))).get();
    return ownedQty > usedCountList.length;
  }

  /// Returns a list of variant names for [cardId] with unassigned copies available.
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

  /// Returns the names of all physical binders currently containing [cardId].
  Future<List<String>> getBindersForCard(String cardId) async {
    final query = db.select(db.binderCards).join([innerJoin(db.binders, db.binders.id.equalsExp(db.binderCards.binderId))]);
    query.where(db.binderCards.cardId.equals(cardId) & db.binderCards.isPlaceholder.equals(false));
    final rows = await query.get();
    return rows.map((r) => r.readTable(db.binders).name).toSet().toList(); 
  }

  /// Configures a planned placeholder slot with a target [newCardId] and [labelName].
  Future<void> configureSlot(int slotId, String newCardId, String labelName) async {
    await (db.update(db.binderCards)..where((t) => t.id.equals(slotId))).write(
      BinderCardsCompanion(cardId: Value(newCardId), placeholderLabel: Value(labelName), isPlaceholder: const Value(true), variant: const Value.absent())
    );
  }
  
  /// Assigns a user inventory card [userCardId] to the binder slot [slotId].
  Future<void> fillSlot(int slotId, String cardId, int userCardId, {String? variant}) async {
    if (!await isUserCardAvailable(userCardId)) throw Exception("Diese spezifische Karte ist nicht mehr verfügbar!");
    await (db.update(db.binderCards)..where((t) => t.id.equals(slotId))).write(
      BinderCardsCompanion(
        cardId: Value(cardId), 
        userCardId: Value(userCardId),
        isPlaceholder: const Value(false), 
        variant: variant != null ? Value(variant) : const Value.absent()
      )
    );
    final slot = await (db.select(db.binderCards)..where((t) => t.id.equals(slotId))).getSingle();
    await recalculateBinderValue(slot.binderId);
  }

  /// Clears card assignment from slot [slotId] and recalculates the binder's valuation.
  Future<void> clearSlot(int slotId) async {
    await (db.update(db.binderCards)..where((t) => t.id.equals(slotId))).write(
      const BinderCardsCompanion(isPlaceholder: Value(true), variant: Value(null)),
    );
    final slot = await (db.select(db.binderCards)..where((t) => t.id.equals(slotId))).getSingle();
    await recalculateBinderValue(slot.binderId);
  }

  /// Aggregates the total valuation of all cards in binder [binderId] using [PriceCalculator].
  ///
  /// Also updates or inserts the daily portfolio snapshot record for the binder.
  Future<void> recalculateBinderValue(int binderId) async {
    final slots = await (db.select(db.binderCards)..where((t) => t.binderId.equals(binderId) & t.isPlaceholder.equals(false))).get();
    double total = 0.0;

    if (slots.isEmpty) {
      await (db.update(db.binders)..where((t) => t.id.equals(binderId))).write(const BindersCompanion(totalValue: Value(0.0)));
      return;
    }

    final cardIds = slots.map((s) => s.cardId).whereType<String>().toSet().toList();
    // Preload all user card entries associated with slots in batch
    final userCardIds = slots.map((s) => s.userCardId).whereType<int>().toSet().toList();
    
    final cardsList = await (db.select(db.cards)..where((t) => t.id.isIn(cardIds))).get();
    final cardMap = {for (var c in cardsList) c.id: c};

    final userCardsList = await (db.select(db.userCards)..where((t) => t.id.isIn(userCardIds))).get();
    final userCardMap = {for (var u in userCardsList) u.id: u};

    final cmList = await (db.select(db.cardMarketPrices)..where((t) => t.cardId.isIn(cardIds))).get();
    final cmMap = <String, CardMarketPrice>{};
    for (var p in cmList) {
      if (!cmMap.containsKey(p.cardId) || p.fetchedAt.isAfter(cmMap[p.cardId]!.fetchedAt)) cmMap[p.cardId] = p;
    }

    final tcgList = await (db.select(db.tcgPlayerPrices)..where((t) => t.cardId.isIn(cardIds))).get();
    final tcgMap = <String, TcgPlayerPrice>{};
    for (var p in tcgList) {
      if (!tcgMap.containsKey(p.cardId) || p.fetchedAt.isAfter(tcgMap[p.cardId]!.fetchedAt)) tcgMap[p.cardId] = p;
    }

    final customList = await (db.select(db.customCardPrices)..where((t) => t.cardId.isIn(cardIds))).get();
    final customMap = <String, CustomCardPrice>{};
    for (var p in customList) {
      if (!customMap.containsKey(p.cardId) || p.fetchedAt.isAfter(customMap[p.cardId]!.fetchedAt)) customMap[p.cardId] = p;
    }

    for (var slot in slots) {
      final cardId = slot.cardId;
      if (cardId == null) continue;

      final card = cardMap[cardId];
      if (card == null) continue;

      // Specific user card inventory instance for this slot
      final userCard = slot.userCardId != null ? userCardMap[slot.userCardId!] : null;

      final cmPrice = cmMap[cardId];
      final tcgPrice = tcgMap[cardId];
      final customPriceRow = customMap[cardId];

      double singlePrice = 0.0;
      final variant = userCard?.variant ?? slot.variant ?? 'Normal'; 
      
      // Calculate slot value with custom price override fallback
      if (userCard != null && userCard.customPrice != null && userCard.customPrice! > 0) {
        singlePrice = userCard.customPrice!;
      } else {
        singlePrice = _priceCalculator.calculateCardPrice(
          pref: card.preferredPriceSource,
          variant: variant,
          hasFirstEdition: card.hasFirstEdition,
          hasNormal: card.hasNormal,
          hasHolo: card.hasHolo,
          cmPrice: cmPrice,
          tcgPrice: tcgPrice,
          customPrice: customPriceRow?.price,
        );
      }
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

  /// Triggers full valuation recalculation across all existing binders.
  Future<void> recalculateAllBinders() async {
    final allBinders = await db.select(db.binders).get();
    for (var binder in allBinders) {
      await recalculateBinderValue(binder.id);
    }
  }

  /// Finds all binders containing [cardId] and recalculates each binder's total value.
  Future<void> recalculateBindersForCard(String cardId) async {
    // 1. Find all binders containing this card
    final usedSlotsQuery = db.select(db.binderCards)..where((t) => t.cardId.equals(cardId) & t.isPlaceholder.equals(false));
    final usedSlots = await usedSlotsQuery.get();
    
    // 2. Collect unique binder IDs
    final Set<int> affectedBinderIds = usedSlots.map((s) => s.binderId).toSet();
    
    // 3. Recalculate affected binders only
    for (var binderId in affectedBinderIds) {
      await recalculateBinderValue(binderId);
    }
  }

 // =====================================================================
  // SLOT MANAGEMENT
  // =====================================================================
  
  /// Inserts a new empty slot immediately to the right of [currentSlotId], shifting remaining slots forward.
  Future<void> addSlotRight(int binderId, int currentSlotId) async {
    final binder = await (db.select(db.binders)..where((t) => t.id.equals(binderId))).getSingle();
    final isBulk = binder.rowsPerPage == 0 || binder.columnsPerPage == 0;
    final rows = binder.rowsPerPage;
    final cols = binder.columnsPerPage;
    final slotsPerPage = isBulk ? 999999 : (rows * cols); // Bulk containers have unbounded capacity

    final sortOrder = binder.sortOrder == BinderSortOrder.topToBottom.name 
        ? BinderSortOrder.topToBottom 
        : BinderSortOrder.leftToRight;

    final slots = await (db.select(db.binderCards)..where((t) => t.binderId.equals(binderId))).get();

    int getAbsoluteIndex(BinderCard s) {
      if (isBulk) return s.slotIndex;
      int localIndex;
      if (sortOrder == BinderSortOrder.leftToRight) {
        localIndex = s.slotIndex;
      } else {
        final int targetRow = (s.slotIndex / cols).floor();
        final int targetCol = s.slotIndex % cols;
        localIndex = targetCol * rows + targetRow;
      }
      return s.pageIndex * slotsPerPage + localIndex;
    }

    final sortedSlots = List<BinderCard>.from(slots);
    sortedSlots.sort((a, b) => getAbsoluteIndex(a).compareTo(getAbsoluteIndex(b)));

    final targetIndex = sortedSlots.indexWhere((s) => s.id == currentSlotId);
    if (targetIndex == -1) return;

    await db.transaction(() async {
      final newSlotId = await db.into(db.binderCards).insert(
        BinderCardsCompanion.insert(
          binderId: binderId,
          pageIndex: 0, 
          slotIndex: 0, 
          isPlaceholder: const Value(true),
          placeholderLabel: const Value("Leerer Slot"),
        )
      );

      final List<int> orderedIds = sortedSlots.map((s) => s.id).toList();
      orderedIds.insert(targetIndex + 1, newSlotId); 

      await db.batch((batch) {
        for (int i = 0; i < orderedIds.length; i++) {
          int pageIndex = 0;
          int visualSlotIndex = i;

          if (!isBulk) {
            pageIndex = (i / slotsPerPage).floor();
            final localIndex = i % slotsPerPage;
            if (sortOrder == BinderSortOrder.leftToRight) {
              visualSlotIndex = localIndex;
            } else {
              final int targetRow = localIndex % rows;
              final int targetCol = (localIndex / rows).floor();
              visualSlotIndex = targetRow * cols + targetCol;
            }
          }

          batch.update(
            db.binderCards,
            BinderCardsCompanion(pageIndex: Value(pageIndex), slotIndex: Value(visualSlotIndex)),
            where: (t) => t.id.equals(orderedIds[i])
          );
        }
      });
    });
  }

  /// Deletes slot [slotId] and shifts all subsequent cards backwards to eliminate gaps.
  Future<void> deleteSlotAndShift(int binderId, int slotId) async {
    final binder = await (db.select(db.binders)..where((t) => t.id.equals(binderId))).getSingle();
    final isBulk = binder.rowsPerPage == 0 || binder.columnsPerPage == 0;
    final rows = binder.rowsPerPage;
    final cols = binder.columnsPerPage;
    final slotsPerPage = isBulk ? 999999 : (rows * cols);

    final sortOrder = binder.sortOrder == BinderSortOrder.topToBottom.name 
        ? BinderSortOrder.topToBottom 
        : BinderSortOrder.leftToRight;

    final slots = await (db.select(db.binderCards)..where((t) => t.binderId.equals(binderId))).get();

    int getAbsoluteIndex(BinderCard s) {
      if (isBulk) return s.slotIndex;
      int localIndex;
      if (sortOrder == BinderSortOrder.leftToRight) {
        localIndex = s.slotIndex;
      } else {
        final int targetRow = (s.slotIndex / cols).floor();
        final int targetCol = s.slotIndex % cols;
        localIndex = targetCol * rows + targetRow;
      }
      return s.pageIndex * slotsPerPage + localIndex;
    }

    final sortedSlots = List<BinderCard>.from(slots);
    sortedSlots.sort((a, b) => getAbsoluteIndex(a).compareTo(getAbsoluteIndex(b)));

    await db.transaction(() async {
      await (db.delete(db.binderCards)..where((t) => t.id.equals(slotId))).go();
      final orderedIds = sortedSlots.map((s) => s.id).where((id) => id != slotId).toList();

      await db.batch((batch) {
        for (int i = 0; i < orderedIds.length; i++) {
          int pageIndex = 0;
          int visualSlotIndex = i;

          if (!isBulk) {
            pageIndex = (i / slotsPerPage).floor();
            final localIndex = i % slotsPerPage;
            if (sortOrder == BinderSortOrder.leftToRight) {
              visualSlotIndex = localIndex;
            } else {
              final int targetRow = localIndex % rows;
              final int targetCol = (localIndex / rows).floor();
              visualSlotIndex = targetRow * cols + targetCol;
            }
          }

          batch.update(
            db.binderCards,
            BinderCardsCompanion(pageIndex: Value(pageIndex), slotIndex: Value(visualSlotIndex)),
            where: (t) => t.id.equals(orderedIds[i])
          );
        }
      });
    });

    await recalculateBinderValue(binderId);
  }

  // =====================================================================
  // SLOT REORDERING AND SWAPPING
  // =====================================================================
  
  Future<void> moveSlotLeft(int binderId, int slotId) => _swapSlot(binderId, slotId, -1);
  Future<void> moveSlotRight(int binderId, int slotId) => _swapSlot(binderId, slotId, 1);

  /// Swaps the positions and assigned card content of two slots [slotId1] and [slotId2].
  Future<void> swapTwoSlots(int binderId, int slotId1, int slotId2) async {
    if (slotId1 == slotId2) return;
    final binder = await (db.select(db.binders)..where((t) => t.id.equals(binderId))).getSingle();
    final isBulk = binder.rowsPerPage == 0 || binder.columnsPerPage == 0;
    final rows = binder.rowsPerPage;
    final cols = binder.columnsPerPage;
    final slotsPerPage = isBulk ? 999999 : (rows * cols);
    final sortOrder = binder.sortOrder == BinderSortOrder.topToBottom.name ? BinderSortOrder.topToBottom : BinderSortOrder.leftToRight;

    final slots = await (db.select(db.binderCards)..where((t) => t.binderId.equals(binderId))).get();

    int getAbsoluteIndex(BinderCard s) {
      if (isBulk) return s.slotIndex;
      int localIndex;
      if (sortOrder == BinderSortOrder.leftToRight) { localIndex = s.slotIndex; } 
      else {
        final int targetRow = (s.slotIndex / cols).floor();
        final int targetCol = s.slotIndex % cols;
        localIndex = targetCol * rows + targetRow;
      }
      return s.pageIndex * slotsPerPage + localIndex;
    }

    final sortedSlots = List<BinderCard>.from(slots);
    sortedSlots.sort((a, b) => getAbsoluteIndex(a).compareTo(getAbsoluteIndex(b)));

    final index1 = sortedSlots.indexWhere((s) => s.id == slotId1);
    final index2 = sortedSlots.indexWhere((s) => s.id == slotId2);

    if (index1 == -1 || index2 == -1) return;

    await db.transaction(() async {
      final orderedIds = sortedSlots.map((s) => s.id).toList();
      final temp = orderedIds[index1];
      orderedIds[index1] = orderedIds[index2];
      orderedIds[index2] = temp;

      await db.batch((batch) {
        for (int i = 0; i < orderedIds.length; i++) {
          int pageIndex = 0;
          int visualSlotIndex = i;
          if (!isBulk) {
            pageIndex = (i / slotsPerPage).floor();
            final localIndex = i % slotsPerPage;
            if (sortOrder == BinderSortOrder.leftToRight) { visualSlotIndex = localIndex; } 
            else {
              final int targetRow = localIndex % rows;
              final int targetCol = (localIndex / rows).floor();
              visualSlotIndex = targetRow * cols + targetCol;
            }
          }
          batch.update(db.binderCards, BinderCardsCompanion(pageIndex: Value(pageIndex), slotIndex: Value(visualSlotIndex)), where: (t) => t.id.equals(orderedIds[i]));
        }
      });
    });
  }

  Future<void> _swapSlot(int binderId, int slotId, int offset) async {
    final binder = await (db.select(db.binders)..where((t) => t.id.equals(binderId))).getSingle();
    final isBulk = binder.rowsPerPage == 0 || binder.columnsPerPage == 0;
    final rows = binder.rowsPerPage;
    final cols = binder.columnsPerPage;
    final slotsPerPage = isBulk ? 999999 : (rows * cols);
    final sortOrder = binder.sortOrder == BinderSortOrder.topToBottom.name ? BinderSortOrder.topToBottom : BinderSortOrder.leftToRight;

    final slots = await (db.select(db.binderCards)..where((t) => t.binderId.equals(binderId))).get();

    int getAbsoluteIndex(BinderCard s) {
      if (isBulk) return s.slotIndex;
      int localIndex;
      if (sortOrder == BinderSortOrder.leftToRight) { localIndex = s.slotIndex; } 
      else {
        final int targetRow = (s.slotIndex / cols).floor();
        final int targetCol = s.slotIndex % cols;
        localIndex = targetCol * rows + targetRow;
      }
      return s.pageIndex * slotsPerPage + localIndex;
    }

    final sortedSlots = List<BinderCard>.from(slots);
    sortedSlots.sort((a, b) => getAbsoluteIndex(a).compareTo(getAbsoluteIndex(b)));

    final targetIndex = sortedSlots.indexWhere((s) => s.id == slotId);
    if (targetIndex == -1) return;

    final newIndex = targetIndex + offset;
    if (newIndex < 0 || newIndex >= sortedSlots.length) return;

    await db.transaction(() async {
      final orderedIds = sortedSlots.map((s) => s.id).toList();
      final temp = orderedIds[targetIndex];
      orderedIds[targetIndex] = orderedIds[newIndex];
      orderedIds[newIndex] = temp;

      await db.batch((batch) {
        for (int i = 0; i < orderedIds.length; i++) {
          int pageIndex = 0;
          int visualSlotIndex = i;
          if (!isBulk) {
            pageIndex = (i / slotsPerPage).floor();
            final localIndex = i % slotsPerPage;
            if (sortOrder == BinderSortOrder.leftToRight) { visualSlotIndex = localIndex; } 
            else {
              final int targetRow = localIndex % rows;
              final int targetCol = (localIndex / rows).floor();
              visualSlotIndex = targetRow * cols + targetCol;
            }
          }
          batch.update(db.binderCards, BinderCardsCompanion(pageIndex: Value(pageIndex), slotIndex: Value(visualSlotIndex)), where: (t) => t.id.equals(orderedIds[i]));
        }
      });
    });
  }

  // =====================================================================
  // BULK BOX MANAGEMENT (List inventory, dividers, and sorting)
  // =====================================================================

  /// Adds a card instance to a bulk box container at the trailing slot position.
  Future<void> addCardToBulkBox(int binderId, String cardId, int userCardId, String variant) async {
    if (!await isUserCardAvailable(userCardId)) throw Exception("Diese spezifische Karte ist nicht mehr verfügbar!");
    final existingSlots = await (db.select(db.binderCards)..where((t) => t.binderId.equals(binderId))).get();
    
    await db.into(db.binderCards).insert(
      BinderCardsCompanion.insert(
        binderId: binderId,
        pageIndex: 0, 
        slotIndex: existingSlots.length,
        isPlaceholder: const Value(false),
        cardId: Value(cardId),
        userCardId: Value(userCardId),
        variant: Value(variant),
      )
    );
    await recalculateBinderValue(binderId);
  }

  /// Inserts a section divider tab with [title] into a bulk storage box.
  Future<void> addBulkDivider(int binderId, String title) async {
    final existingSlots = await (db.select(db.binderCards)..where((t) => t.binderId.equals(binderId))).get();
    await db.into(db.binderCards).insert(
      BinderCardsCompanion.insert(
        binderId: binderId,
        pageIndex: 0,
        slotIndex: existingSlots.length,
        isPlaceholder: const Value(true), 
        placeholderLabel: Value("DIVIDER:$title"), 
      )
    );
  }

  /// Updates whether the bulk box with [binderId] is marked as full.
  Future<void> toggleBinderFullStatus(int binderId, bool isFull) async {
    await (db.update(db.binders)..where((t) => t.id.equals(binderId))).write(BindersCompanion(isFull: Value(isFull)));
  }

  // Bulk container sorting algorithm preserving section divider boundaries
  Future<void> sortBulkBox(int binderId, String sortMode) async {
    final slots = await (db.select(db.binderCards)..where((t) => t.binderId.equals(binderId))..orderBy([(t) => OrderingTerm(expression: t.slotIndex)])).get();

    final cardIds = slots.map((s) => s.cardId).whereType<String>().toSet().toList();
    final cardsList = await (db.select(db.cards)..where((t) => t.id.isIn(cardIds))).get();
    final cardMap = {for (var c in cardsList) c.id: c};

    List<BinderCard> newOrder = [];
    List<BinderCard> currentGroupCards = [];
    BinderCard? currentDivider;

    // Helper: calculate rarity tier score (higher value = rarer)
    int getRarityScore(String? rarity) {
      if (rarity == null) return 0;
      final r = rarity.toLowerCase();
      if (r.contains('secret') || r.contains('hyper') || r.contains('rainbow') || r.contains('gold')) return 100;
      if (r.contains('illustration') || r.contains('alt art')) return 90;
      if (r.contains('ultra') || r.contains('vmax') || r.contains('vstar')) return 80;
      if (r.contains('double') || r.contains('v') || r.contains('ex') || r.contains('gx')) return 70;
      if (r.contains('holo') || r.contains('rare')) return 50;
      if (r.contains('uncommon')) return 20;
      return 10; // Common tier baseline
    }

    void sortAndAppendGroup() {
      currentGroupCards.sort((a, b) {
        final ca = cardMap[a.cardId];
        final cb = cardMap[b.cardId];
        if (ca == null || cb == null) return 0;
        
        if (sortMode == 'name') {
           return (ca.nameDe ?? ca.name).compareTo(cb.nameDe ?? cb.name);
        } else if (sortMode == 'number') {
           return ca.sortNumber.compareTo(cb.sortNumber);
        } else if (sortMode == 'rarity') {
           return getRarityScore(cb.rarity).compareTo(getRarityScore(ca.rarity));
        } else if (sortMode == 'type') {
           // Sort by element type (A-Z, Trainers and Energy sort naturally to end)
           // When type matches, sort secondary by collector number
           final tA = ca.cardType ?? 'ZZZ'; // Fallback to end of list
           final tB = cb.cardType ?? 'ZZZ';
           final typeCompare = tA.compareTo(tB);
           if (typeCompare != 0) return typeCompare;
           return ca.sortNumber.compareTo(cb.sortNumber);
        }
        return 0;
      });
      
      if (currentDivider != null) newOrder.add(currentDivider);
      newOrder.addAll(currentGroupCards);
      currentGroupCards.clear();
    }

    for (var slot in slots) {
      if (slot.isPlaceholder && (slot.placeholderLabel?.startsWith('DIVIDER:') ?? false)) {
        sortAndAppendGroup(); 
        currentDivider = slot; 
      } else {
        currentGroupCards.add(slot);
      }
    }
    sortAndAppendGroup(); 

    await db.transaction(() async {
      await db.batch((batch) {
        for (int i = 0; i < newOrder.length; i++) {
          batch.update(db.binderCards, BinderCardsCompanion(slotIndex: Value(i)), where: (t) => t.id.equals(newOrder[i].id));
        }
      });
    });
  }

  /// Toggles the favorite status for the binder with [binderId].
  Future<void> toggleBinderFavorite(int binderId, bool isFavorite) async {
    await (db.update(db.binders)..where((t) => t.id.equals(binderId))).write(
      BindersCompanion(isFavorite: Value(isFavorite))
    );
  }

  // Fetches available unassigned copies of card instances with grading and pricing metadata
  Future<List<UserCard>> getAvailableUserCards(String cardId) async {
    final userCards = await (db.select(db.userCards)..where((t) => t.cardId.equals(cardId))).get();
    final binderCards = await (db.select(db.binderCards)..where((t) => t.cardId.equals(cardId) & t.isPlaceholder.equals(false))).get();
    
    Map<int, int> usedById = {};
    Map<String, int> usedByVariant = {};

    for (var bc in binderCards) {
      if (bc.userCardId != null) {
        usedById[bc.userCardId!] = (usedById[bc.userCardId!] ?? 0) + 1;
      } else {
        // Fallback for legacy database rows without assigned userCardId
        final v = bc.variant ?? 'Normal';
        usedByVariant[v] = (usedByVariant[v] ?? 0) + 1;
      }
    }
    
    List<UserCard> available = [];
    for (var uc in userCards) {
      int used = usedById[uc.id] ?? 0;
      int availableQty = uc.quantity - used;

      if (availableQty > 0 && usedByVariant.containsKey(uc.variant) && usedByVariant[uc.variant]! > 0) {
          int reduce = availableQty < usedByVariant[uc.variant]! ? availableQty : usedByVariant[uc.variant]!;
          usedByVariant[uc.variant] = usedByVariant[uc.variant]! - reduce;
          availableQty -= reduce;
      }

      if (availableQty > 0) {
        available.add(uc);
      }
    }
    return available;
  }

  /// Returns whether a specific [userCardId] inventory record has unallocated quantity available.
  Future<bool> isUserCardAvailable(int userCardId) async {
    final uc = await (db.select(db.userCards)..where((t) => t.id.equals(userCardId))).getSingleOrNull();
    if (uc == null) return false;
    final usedCountList = await (db.select(db.binderCards)..where((t) => t.userCardId.equals(userCardId) & t.isPlaceholder.equals(false))).get();
    return uc.quantity > usedCountList.length;
  }
}

