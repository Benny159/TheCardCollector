import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/drift.dart' as drift; 

import '../../data/database/database_provider.dart';
import '../../data/database/app_database.dart'; 
import '../../domain/models/api_card.dart';
import '../../data/api/search_provider.dart'; 
import '../../domain/logic/binder_service.dart';

// --- NEU: Speichert die letzte Binder-Auswahl für diese App-Session ---
final lastSelectedBinderProvider = StateProvider<int?>((ref) => -1);

class InventoryBottomSheet extends ConsumerStatefulWidget {
  final ApiCard card;

  const InventoryBottomSheet({super.key, required this.card});

  @override
  ConsumerState<InventoryBottomSheet> createState() => _InventoryBottomSheetState();
}

class _InventoryBottomSheetState extends ConsumerState<InventoryBottomSheet> {
  int _quantity = 1;
  String _condition = 'NM';
  String _language = 'Deutsch';
  
  List<Binder> _availableBinders = [];
  
  List<String> _availableVariants = [];
  late String _variant; 

  final List<String> _conditions = ['NM', 'LP', 'MP', 'HP', 'DMG'];
  final List<String> _languages = ['Deutsch', 'Englisch', 'Japanisch'];

  @override
  void initState() {
    super.initState();
    _initVariants();
    _loadBinders(); 
  }

  Future<void> _loadBinders() async {
    final db = ref.read(databaseProvider);
    final binders = await db.select(db.binders).get();
    if (mounted) {
      setState(() {
        _availableBinders = binders;
      });
    }
  }

  void _initVariants() {
    List<String> detected = [];

    if (widget.card.hasNormal) detected.add('Normal');
    if (widget.card.hasHolo) detected.add('Holo');
    if (widget.card.hasReverse) detected.add('Reverse Holo');
    if (widget.card.hasFirstEdition) detected.add('1st Edition');
    if (widget.card.hasWPromo) detected.add('WPromo');

    if (detected.isEmpty) detected.add('Normal');
    
    final order = ['Normal', 'Holo', 'Reverse Holo', '1st Edition', 'WPromo'];
    detected.sort((a, b) {
      int indexA = order.indexOf(a);
      int indexB = order.indexOf(b);
      if (indexA == -1) indexA = 99;
      if (indexB == -1) indexB = 99;
      return indexA.compareTo(indexB);
    });

    setState(() {
      _availableVariants = detected;
      _variant = detected.first; 
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    // Wir lesen die zuletzt getätigte Auswahl aus dem Provider
    final selectedBinderId = ref.watch(lastSelectedBinderProvider);

    final bool idExists = selectedBinderId == null || 
                          selectedBinderId == -1 || 
                          _availableBinders.any((b) => b.id == selectedBinderId);
                          
    final safeBinderId = idExists ? selectedBinderId : -1;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Inventar verwalten", style: Theme.of(context).textTheme.titleLarge),
              if (widget.card.isOwned)
                const Chip(
                  label: Text("Bereits im Besitz", style: TextStyle(color: Colors.white, fontSize: 10)),
                  backgroundColor: Colors.green,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                )
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.card.nameDe ?? widget.card.name, style: const TextStyle(color: Colors.grey)),
          const Divider(),

          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  "Variante", 
                  _availableVariants, 
                  _variant, 
                  (val) => setState(() => _variant = val!)
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdown(
                  "Sprache", 
                  _languages, 
                  _language, 
                  (val) => setState(() => _language = val!)
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  "Zustand", 
                  _conditions, 
                  _condition, 
                  (val) => setState(() => _condition = val!)
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Anzahl", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  _buildCounter(),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          
          // --- BINDER AUSWAHL (Speichert Auswahl live im Provider) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.folder_special, color: Colors.blue, size: 16),
                    SizedBox(width: 6),
                    Text("In Binder einsortieren", style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: safeBinderId, // Aus dem Provider!
                    isExpanded: true,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("❌ Nicht in Binder einsortieren")),
                      const DropdownMenuItem(value: -1, child: Text("✨ Automatisch (Beliebiger Binder)")),
                      ..._availableBinders.map((b) => DropdownMenuItem(
                        value: b.id, 
                        child: Text("📂 ${b.name}"),
                      )),
                    ],
                    onChanged: (val) {
                      // Speichert die Auswahl für das nächste Mal
                      ref.read(lastSelectedBinderProvider.notifier).state = val;
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: const Text("Abbrechen"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Hinzufügen"),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    padding: const EdgeInsets.symmetric(vertical: 12)
                  ),
                  onPressed: _saveToInventory,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged) {
    final safeValue = items.contains(value) ? value : items.firstOrNull ?? value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: safeValue,
          isDense: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCounter() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      height: 48,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () => setState(() { if (_quantity > 1) _quantity--; }),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40),
          ),
          Container(
            width: 30,
            alignment: Alignment.center,
            child: Text("$_quantity", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => setState(() => _quantity++),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40),
          ),
        ],
      ),
    );
  }

Future<void> _saveToInventory() async {
    final db = ref.read(databaseProvider);
    final binderService = BinderService(db);
    final selectedBinderId = ref.read(lastSelectedBinderProvider);
    
    try {
      final existingEntry = await (db.select(db.userCards)
        ..where((tbl) => tbl.cardId.equals(widget.card.id))
        ..where((tbl) => tbl.variant.equals(_variant))
        ..where((tbl) => tbl.condition.equals(_condition))
        ..where((tbl) => tbl.language.equals(_language))
      ).getSingleOrNull();

      if (existingEntry != null) {
        final newQuantity = existingEntry.quantity + _quantity;
        await (db.update(db.userCards)..where((tbl) => tbl.id.equals(existingEntry.id))).write(
          UserCardsCompanion(quantity: drift.Value(newQuantity)),
        );
      } else {
        await db.into(db.userCards).insert(
          UserCardsCompanion.insert(
            cardId: widget.card.id,
            quantity: drift.Value(_quantity),
            condition: drift.Value(_condition),
            language: drift.Value(_language),
            variant: drift.Value(_variant),
          ),
        );
      }

      String binderMessage = "";
      bool showOrangeBanner = false;

      // =========================================================
      // BINDER / BULK BOX LOGIK
      // =========================================================
      if (selectedBinderId != null) {
        
        // --- 1. Check auf Bulk Box! ---
        if (selectedBinderId != -1) {
          final targetBinder = await (db.select(db.binders)..where((t) => t.id.equals(selectedBinderId))).getSingleOrNull();
          
          if (targetBinder != null) {
            if (targetBinder.isFull) {
               if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diese Box ist als "Voll" markiert! Karte wurde nur ins Inventar gelegt.'), backgroundColor: Colors.orange));
               _closeAndShowSuccess("", true);
               return; 
            } else if (targetBinder.rowsPerPage == 0) {
               // ES IST EINE BULK BOX! Einfach n-mal hinten anfügen
               for (int i = 0; i < _quantity; i++) {
                 await binderService.addCardToBulkBox(selectedBinderId, widget.card.id, _variant);
               }
               binderMessage = "\nund in die Bulk Box geworfen!";
               _closeAndShowSuccess(binderMessage, false);
               return; 
            }
          }
        }

        // --- 2. Normale Platzhalter-Suche für Bücher (Grid) ---
        final cardNameDe = (widget.card.nameDe ?? "").toLowerCase();
        final cardNameEn = widget.card.name.toLowerCase();
        
        final ignoreWords = [
          'ex', 'v', 'vmax', 'vstar', 'gx', 'team', 'rocket', "rocket's", 'rockets', 
          'dark', 'dunkles', 'light', 'helles', 'mega', 'm', 'lv', 'x', 'lvx', 'sp'
        ];

        List<String> getCoreWords(String text) {
          if (text.trim().isEmpty) return [];
          String spacedText = text.replaceAll('-', ' ');
          final cleaned = spacedText.replaceAll(RegExp(r'[^a-z0-9äöüß\s]'), '').toLowerCase();
          final words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
          final coreWords = words.where((w) => !ignoreWords.contains(w)).toList();
          return coreWords.isNotEmpty ? coreWords : words;
        }

        final cWordsDe = getCoreWords(cardNameDe);
        final cWordsEn = getCoreWords(cardNameEn);

        final query = db.select(db.binderCards).join([
          drift.innerJoin(db.binders, db.binders.id.equalsExp(db.binderCards.binderId))
        ]);

        if (selectedBinderId != -1) {
          // --- FIX: NUR LEERE PLATZHALTER SUCHEN ---
          query.where(db.binderCards.binderId.equals(selectedBinderId) & db.binderCards.isPlaceholder.equals(true));
        } else {
          // --- FIX: NUR BÜCHER SUCHEN, DIE NICHT VOLL SIND, UND NUR LEERE PLATZHALTER ---
          query.where(db.binders.isFull.equals(false) & db.binders.rowsPerPage.isBiggerThanValue(0) & db.binderCards.isPlaceholder.equals(true)); 
        }

        final allJoined = await query.get();
        final allSlots = allJoined.map((row) => row.readTable(db.binderCards)).toList();

        List<BinderCard> potentialSlots = allSlots.where((slot) {
          if (slot.placeholderLabel?.startsWith('DIVIDER:') ?? false) return false;

          String pLabel = slot.placeholderLabel ?? '';
          if (pLabel.contains(" ")) {
            final parts = pLabel.split(" ");
            if (parts.first.startsWith("#") || parts.first.startsWith("✨")) pLabel = parts.sublist(1).join(" ");
          }
          pLabel = pLabel.toLowerCase();
          if (pLabel.isEmpty) return false;
          
          final pWords = getCoreWords(pLabel);
          if (pWords.isEmpty) return false;

          bool matchDe = cWordsDe.isNotEmpty && (pWords.every((w) => cWordsDe.contains(w)) || cWordsDe.every((w) => pWords.contains(w)));
          bool matchEn = cWordsEn.isNotEmpty && (pWords.every((w) => cWordsEn.contains(w)) || cWordsEn.every((w) => pWords.contains(w)));

          return matchDe || matchEn;
        }).toList();

        if (potentialSlots.isNotEmpty) {
          potentialSlots.sort((a, b) {
            // Dies ist sicher, da wir oben schon auf isPlaceholder gefiltert haben
            final aLabel = a.placeholderLabel?.toLowerCase() ?? '';
            final bLabel = b.placeholderLabel?.toLowerCase() ?? '';
            
            bool aExact = (cardNameDe.isNotEmpty && aLabel == cardNameDe) || aLabel == cardNameEn;
            bool bExact = (cardNameDe.isNotEmpty && bLabel == cardNameDe) || bLabel == cardNameEn;
            
            if (aExact && !bExact) return -1;
            if (!aExact && bExact) return 1;
            return 0; 
          });

          int slotsFilled = 0;
          
          for (var i = 0; i < _quantity && i < potentialSlots.length; i++) {
            final slot = potentialSlots[i];
            await binderService.fillSlot(slot.id, widget.card.id, variant: _variant);
            slotsFilled++;
          }
          
          if (slotsFilled > 0) {
            binderMessage = "\nund in $slotsFilled Binder-Slot(s) einsortiert!";
          } else {
            binderMessage = "\n(Karten wurden nur ins Inventar gelegt)";
            showOrangeBanner = true; 
          }
        } else {
          binderMessage = "\n(Kein passender Platz in einem Buch gefunden)";
          showOrangeBanner = true; 
        }
      }

      // Zum Schluss aufrufen
      _closeAndShowSuccess(binderMessage, showOrangeBanner);

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fehler: $e"), backgroundColor: Colors.red));
    }
  }

  // Hilfsmethode, um doppelten Code am Ende zu vermeiden
  void _closeAndShowSuccess(String binderMessage, bool showOrangeBanner) {
      ref.invalidate(inventoryProvider); 
      ref.invalidate(searchResultsProvider);
      ref.invalidate(cardsForSetProvider(widget.card.setId));
      ref.invalidate(setStatsProvider(widget.card.setId));

      if (mounted) {
        Navigator.pop(context, true);
        final bannerColor = showOrangeBanner ? Colors.orange[800]! : Colors.green;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_quantity x $_variant hinzugefügt!$binderMessage'), 
            backgroundColor: bannerColor,
            duration: const Duration(seconds: 4),
          )
        );
      }

      createPortfolioSnapshot(ref);
      _refreshProviders();
  }

  void _refreshProviders() {
    ref.invalidate(searchResultsProvider);
    ref.invalidate(cardsForSetProvider(widget.card.setId));
    ref.invalidate(setStatsProvider(widget.card.setId));
  }
}