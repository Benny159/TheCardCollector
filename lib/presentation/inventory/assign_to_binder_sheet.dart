import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../data/database/database_provider.dart';
import '../../data/database/app_database.dart';
import '../../domain/models/api_card.dart';
import '../../domain/logic/binder_service.dart';
import '../../presentation/binders/binder_detail_provider.dart';
import 'inventory_bottom_sheet.dart'; 

class AssignToBinderSheet extends ConsumerStatefulWidget {
  final ApiCard card;

  const AssignToBinderSheet({super.key, required this.card});

  @override
  ConsumerState<AssignToBinderSheet> createState() => _AssignToBinderSheetState();
}

class _AssignToBinderSheetState extends ConsumerState<AssignToBinderSheet> {
  List<Binder> _availableBinders = [];
  List<String> _ownedVariants = [];
  String? _selectedVariant;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(databaseProvider);
    final binderService = BinderService(db);
    
    // 1. Lade alle Binder
    final binders = await db.select(db.binders).get();
    
    // 2. Lade NUR die Varianten, die noch NICHT in einem Binder stecken!
    final availableVariants = await binderService.getAvailableVariantsForCard(widget.card.id);

    if (mounted) {
      setState(() {
        _availableBinders = binders;
        _ownedVariants = availableVariants; // <--- HIER: Nur noch freie Varianten!
        if (_ownedVariants.isNotEmpty) _selectedVariant = _ownedVariants.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final selectedBinderId = ref.watch(lastSelectedBinderProvider);

    final bool idExists = selectedBinderId == null || 
                          selectedBinderId == -1 || 
                          _availableBinders.any((b) => b.id == selectedBinderId);
    final safeBinderId = idExists ? selectedBinderId : -1;

    if (_ownedVariants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Text("Lade Daten oder Karte nicht im Besitz..."),
      );
    }

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
            children: [
              const Icon(Icons.move_to_inbox, color: Colors.blue),
              const SizedBox(width: 10),
              Text("In Binder verschieben", style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.card.nameDe ?? widget.card.name, style: const TextStyle(color: Colors.grey)),
          const Divider(),

          const Text("Welche deiner Karten?", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: _selectedVariant,
            isDense: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: _ownedVariants.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => setState(() => _selectedVariant = val),
          ),
          const SizedBox(height: 16),

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
                const Text("Ziel-Binder", style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: safeBinderId,
                    isExpanded: true,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                    items: [
                      const DropdownMenuItem(value: -1, child: Text("✨ Automatisch (Beliebiger Binder)")),
                      ..._availableBinders.map((b) {
                        String prefix = "📂 ";
                        if (b.rowsPerPage == 0) prefix = "📦 ";
                        if (b.isFull) prefix = "🚫 (Voll) ";
                        return DropdownMenuItem(value: b.id, child: Text("$prefix${b.name}", style: TextStyle(color: b.isFull ? Colors.red : Colors.black)));
                      }),
                    ],
                    onChanged: (val) => ref.read(lastSelectedBinderProvider.notifier).state = val,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Abbrechen")),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text("Einsortieren"),
                  style: FilledButton.styleFrom(backgroundColor: Colors.blue[800]),
                  onPressed: _assignCard,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _assignCard() async {
    final db = ref.read(databaseProvider);
    final binderService = BinderService(db);
    final targetBinderId = ref.read(lastSelectedBinderProvider);
    
    if (targetBinderId == null || _selectedVariant == null) return;

    try {
      // --- NEU: IST DAS ZIEL EINE BULK BOX? ---
      if (targetBinderId != -1) {
        final selectedBinder = await (db.select(db.binders)..where((t) => t.id.equals(targetBinderId))).getSingle();
        
        if (selectedBinder.isFull) {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diese Box ist als "Voll" markiert!'), backgroundColor: Colors.red));
           return;
        }

        // Ist es eine Bulk Box? (Rows == 0)
        // Dann einfach HINTEN REINWERFEN (keine Namenssuche!)
        if (selectedBinder.rowsPerPage == 0) {
           await binderService.addCardToBulkBox(targetBinderId, widget.card.id, _selectedVariant!);
           if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('In Bulk Box geworfen!'), backgroundColor: Colors.green));
              ref.invalidate(binderDetailProvider(targetBinderId));
           }
           return;
        }
      }

      // --- NORMALE PLATZHALTER-SUCHE (Wird nur für BÜCHER ausgeführt!) ---
      final cardNameDe = (widget.card.nameDe ?? "").toLowerCase();
      final cardNameEn = widget.card.name.toLowerCase();
      final ignoreWords = ['ex', 'v', 'vmax', 'vstar', 'gx', 'team', 'rocket', "rocket's", 'rockets', 'dark', 'dunkles', 'light', 'helles', 'mega', 'm', 'lv', 'x', 'lvx', 'sp'];

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
      
      if (targetBinderId != -1) {
        query.where(db.binderCards.binderId.equals(targetBinderId) & db.binderCards.isPlaceholder.equals(true));
      } else {
        query.where(db.binders.isFull.equals(false) & db.binders.rowsPerPage.isBiggerThanValue(0) & db.binderCards.isPlaceholder.equals(true)); 
      }

      final allJoined = await query.get();
      final allSlots = allJoined.map((row) => row.readTable(db.binderCards)).toList();

      List<BinderCard> potentialSlots = allSlots.where((slot) {
        // Ein Divider ist KEIN gültiger Platzhalter zum automatischen Befüllen!
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
        final slot = potentialSlots.first;
        await binderService.fillSlot(slot.id, widget.card.id, variant: _selectedVariant);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Karte erfolgreich in den perfekten Slot einsortiert!'), backgroundColor: Colors.green));
          ref.invalidate(binderDetailProvider(slot.binderId));
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kein passender Platz in einem Buch gefunden!'), backgroundColor: Colors.orange));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fehler: $e"), backgroundColor: Colors.red));
    }
  }
}