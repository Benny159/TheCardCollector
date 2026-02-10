import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift; 

import '../../data/database/database_provider.dart';
import '../../data/database/app_database.dart'; 
import '../../domain/models/api_card.dart';
import '../../data/api/search_provider.dart'; 

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
  
  // Dynamische Liste
  List<String> _availableVariants = [];
  late String _variant; 

  final List<String> _conditions = ['NM', 'LP', 'MP', 'HP', 'DMG'];
  final List<String> _languages = ['Deutsch', 'Englisch', 'Japanisch'];

  @override
  void initState() {
    super.initState();
    _initVariants();
  }

  // --- INTELLIGENTE VARIANTE-ERKENNUNG ---
  void _initVariants() {
    final prices = widget.card.tcgplayer?.prices;
    List<String> detected = [];

    // 1. VERSUCH: Wir vertrauen den Preis-Daten (falls vorhanden)
    // Das ist am sichersten: Wenn TCGPlayer einen Preis für 'reverseHolofoil' hat, gibt es die Karte auch.


    // 2. FALLBACK: Wenn KEINE Preis-Daten da sind (oder nur unvollständige)
    // Das passiert oft. Dann raten wir basierend auf der Rarität.
    if (detected.isEmpty) {
      final r = widget.card.rarity.toLowerCase();

      if (r == 'common' || r == 'uncommon' || r == 'rare') {
         // Spezialkarten gibt es meist nur in einer Version.
         // Wir nennen sie Standardmäßig "Normal" (oder "Holo", je nach Geschmack).
         detected.add('Normal');
         detected.add('Reverse Holo');
      }
      // C) Standard Karten (Common, Uncommon, Rare)
      // Die haben Normal + Reverse Holo (außer ganz alte Sets, aber lieber eine Option zu viel als zu wenig)
      else {
         detected.add('Normal');
      }
    }

    // 3. Sicherheitsnetz & Sortierung
    if (detected.isEmpty) detected.add('Normal');
    
    // Duplikate entfernen (Set) und sortieren
    detected = detected.toSet().toList();
    final order = ['Normal', 'Holo', 'Reverse Holo', '1st Edition'];
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
    final bool isOwned = widget.card.isOwned;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Inventar verwalten", style: Theme.of(context).textTheme.titleLarge),
              if (isOwned)
                const Chip(
                  label: Text("Im Besitz", style: TextStyle(color: Colors.white, fontSize: 10)),
                  backgroundColor: Colors.green,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                )
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.card.name, style: const TextStyle(color: Colors.grey)),
          const Divider(),

          // 1. Variante & Sprache
          Row(
            children: [
              Expanded(
                child: _buildDropdown("Variante", _availableVariants, _variant, (val) => setState(() => _variant = val!)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdown("Sprache", _languages, _language, (val) => setState(() => _language = val!)),
              ),
            ],
          ),
          
          const SizedBox(height: 10),

          // 2. Zustand & Anzahl
          Row(
            children: [
              Expanded(
                child: _buildDropdown("Zustand", _conditions, _condition, (val) => setState(() => _condition = val!)),
              ),
              const SizedBox(width: 20),
              _buildCounter(),
            ],
          ),

          const SizedBox(height: 20),

          // 3. Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Abbrechen"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Hinzufügen"),
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
    // Sicherheit: Falls der aktuell gewählte Wert (z.B. "Reverse Holo") in der neuen Liste nicht existiert, nimm den ersten.
    final safeValue = items.contains(value) ? value : items.firstOrNull ?? value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        DropdownButtonFormField<String>(
          value: safeValue,
          isDense: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => setState(() { if (_quantity > 1) _quantity--; }),
          ),
          Text("$_quantity", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() => _quantity++)),
        ],
      ),
    );
  }

Future<void> _saveToInventory() async {
    final db = ref.read(databaseProvider);
    
    try {
      // 1. Prüfen: Gibt es diesen Eintrag schon? (Gleiche ID, Variante, Zustand, Sprache)
      final existingEntry = await (db.select(db.userCards)
        ..where((tbl) => tbl.cardId.equals(widget.card.id))
        ..where((tbl) => tbl.variant.equals(_variant))
        ..where((tbl) => tbl.condition.equals(_condition))
        ..where((tbl) => tbl.language.equals(_language))
      ).getSingleOrNull();

      if (existingEntry != null) {
        // A) JA: Anzahl erhöhen (UPDATE)
        final newQuantity = existingEntry.quantity + _quantity;
        await (db.update(db.userCards)..where((tbl) => tbl.id.equals(existingEntry.id))).write(
          UserCardsCompanion(quantity: drift.Value(newQuantity)),
        );
      } else {
        // B) NEIN: Neuen Eintrag erstellen (INSERT)
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

      // 2. UI Aktualisieren
      _refreshProviders();
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hinzugefügt!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fehler: $e")));
    }
  }

  void _refreshProviders() {
    ref.invalidate(searchResultsProvider);
    ref.invalidate(cardsForSetProvider(widget.card.setId));
    ref.invalidate(setStatsProvider(widget.card.setId));
  }
}