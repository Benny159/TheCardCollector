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
  
  List<String> _availableVariants = [];
  late String _variant; 

  final List<String> _conditions = ['NM', 'LP', 'MP', 'HP', 'DMG'];
  final List<String> _languages = ['Deutsch', 'Englisch', 'Japanisch'];

  @override
  void initState() {
    super.initState();
    _initVariants();
  }

  // --- NEUE LOGIK: VARIANTEN AUS DB-FLAGS ---
  void _initVariants() {
    List<String> detected = [];

    // Wir schauen einfach auf die Flags, die wir von TCGdex/DB haben
    if (widget.card.hasNormal) detected.add('Normal');
    if (widget.card.hasHolo) detected.add('Holo');
    if (widget.card.hasReverse) detected.add('Reverse Holo');
    if (widget.card.hasFirstEdition) detected.add('1st Edition');
    if (widget.card.hasWPromo) detected.add('WPromo');

    // Fallback: Wenn gar nichts gesetzt ist (sollte nicht passieren), nehmen wir Normal
    if (detected.isEmpty) detected.add('Normal');
    
    // Sortierung für schöne UX
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
      _variant = detected.first; // Standardauswahl: Das erste verfügbare
    });
  }

  @override
  Widget build(BuildContext context) {
    // Padding für Tastatur
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

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
          // Header
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

          // 1. Variante & Sprache
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

          // 2. Zustand & Anzahl
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

          const SizedBox(height: 20),

          // 3. Actions
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
    // Sicherheit: Falls der aktuell gewählte Wert in der Liste nicht existiert
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
      height: 48, // Match dropdown height roughly
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
    
    try {
      // 1. DB Operationen (INSERT / UPDATE)
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

      // --- WICHTIG: ERST INVALIDIEREN, DANN SNAPSHOT ---
      
      // 2. Provider Cache leeren, damit der Snapshot frische Daten bekommt
      ref.invalidate(inventoryProvider); 
      
      // 3. Jetzt den Snapshot erstellen (berechnet sich neu aus der DB)
      await createPortfolioSnapshot(ref);

      // 4. Restliche UI aktualisieren (Liste, Stats, etc.)
      _refreshProviders();
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_quantity x $_variant hinzugefügt!'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fehler: $e"), backgroundColor: Colors.red));
    }
  }

  void _refreshProviders() {
    ref.invalidate(searchResultsProvider);
    ref.invalidate(cardsForSetProvider(widget.card.setId));
    ref.invalidate(setStatsProvider(widget.card.setId));
  }
}