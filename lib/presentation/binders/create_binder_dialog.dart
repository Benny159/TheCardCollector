import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database_provider.dart';
import '../../domain/logic/binder_service.dart';
import '../../domain/models/binder_templates.dart'; // Holt die Enums jetzt HIERHER!

class CreateBinderDialog extends ConsumerStatefulWidget {
  const CreateBinderDialog({super.key});

  @override
  ConsumerState<CreateBinderDialog> createState() => _CreateBinderDialogState();
}

class _CreateBinderDialogState extends ConsumerState<CreateBinderDialog> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String _bulkBoxShape = "box"; // 'box', 'etb', oder 'tin'

  // --- AUTOCOMPLETE DATEN ---
  List<String> _dbSetNames = [];
  List<String> _dbPokemonNames = [];
  List<String> _dbArtists = [];
  
  String _selectedSetName = "";
  String _selectedTarget = "";

  // --- BASIS EINSTELLUNGEN ---
  Color _selectedColor = Colors.blue;
  int _rows = 3;
  int _cols = 3;
  AdvancedBinderType _selectedType = AdvancedBinderType.custom;
  final BinderSortOrder _sortOrder = BinderSortOrder.leftToRight;

  // --- 1. CUSTOM EINSTELLUNGEN ---
  int _customPages = 10;

  // --- 2. DEX EINSTELLUNGEN ---
  final Set<int> _selectedGens = {1}; 
  bool _dexMegas = false;
  bool _dexGmax = false;
  bool _dexRegional = false;
  DexSortStyle _dexSort = DexSortStyle.inline;

  // --- 3. SET EINSTELLUNGEN ---
  SetCompletionType _setCompletion = SetCompletionType.standard;

  @override
  void initState() {
    super.initState();
    _loadAutocompleteData();
  }

  Future<void> _loadAutocompleteData() async {
    final db = ref.read(databaseProvider);
    final sets = await db.select(db.cardSets).get();
    final pokedex = await db.select(db.pokedex).get();
    final artistsQuery = await db.customSelect("SELECT DISTINCT artist FROM cards WHERE artist IS NOT NULL AND artist != ''").get();

    if (mounted) {
      setState(() {
        _dbSetNames = sets.map((s) => s.name).toList();
        _dbPokemonNames = pokedex.map((p) => p.name).toList();
        _dbArtists = artistsQuery.map((row) => row.read<String>('artist')).toList();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 500, 
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.blue[800], borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
              child: const Row(
                children: [
                  Icon(Icons.library_add, color: Colors.white),
                  SizedBox(width: 12),
                  Text("Neuen Binder erstellen", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // SCROLLBARER INHALT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Was möchtest du sammeln?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.5,
                      children: [
                        _buildTypeTile(AdvancedBinderType.custom, "Custom", "Leerer Binder", Icons.menu_book),
                        _buildTypeTile(AdvancedBinderType.dex, "Pokédex", "Nach Nummern", Icons.format_list_numbered),
                        _buildTypeTile(AdvancedBinderType.set, "Set", "Set vervollständigen", Icons.collections),
                        _buildTypeTile(AdvancedBinderType.pokemon, "Pokémon", "Z.B. alle Gluraks", Icons.catching_pokemon),
                        _buildTypeTile(AdvancedBinderType.artist, "Künstler", "Karten eines Zeichners", Icons.brush),
                        _buildTypeTile(AdvancedBinderType.bulkBox, "Bulk Box", "Lagerkarton", Icons.inventory_2),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      child: _buildDynamicSettings(),
                    ),

                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    const Text("Basis Einstellungen", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Name des Binders / der Box", border: OutlineInputBorder(), prefixIcon: Icon(Icons.edit)),
                    ),
                    const SizedBox(height: 16),

                    const Text("Farbe:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Colors.blue, Colors.red, Colors.green, Colors.black87, 
                          Colors.purple, Colors.orange, Colors.teal, Colors.brown
                        ].map((c) {
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = c),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: c, shape: BoxShape.circle,
                                border: _selectedColor == c ? Border.all(color: Colors.black, width: 3) : null,
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                              ),
                              child: _selectedColor == c ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_selectedType != AdvancedBinderType.bulkBox) ...[
                      const Text("Seiten-Layout:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10, runSpacing: 10,
                        children: [
                          _buildLayoutOption(2, 2),
                          _buildLayoutOption(3, 3),
                          _buildLayoutOption(4, 3),
                          _buildLayoutOption(4, 4),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // FOOTER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Abbrechen")),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                    label: const Text("Erstellen"),
                    onPressed: _isLoading ? null : _createBinder,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicSettings() {
    switch (_selectedType) {
      case AdvancedBinderType.custom:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Seitenanzahl:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _customPages.toDouble(),
                    min: 1, max: 100, divisions: 99,
                    label: _customPages.toString(),
                    onChanged: (val) => setState(() => _customPages = val.toInt()),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                  child: Text("$_customPages Seiten", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                )
              ],
            )
          ],
        );

      case AdvancedBinderType.dex:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Welche Generationen?", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: List.generate(9, (index) {
                final gen = index + 1;
                final isSel = _selectedGens.contains(gen);
                return FilterChip(
                  label: Text("Gen $gen", style: TextStyle(fontSize: 12, color: isSel ? Colors.white : Colors.black87)),
                  selected: isSel, selectedColor: Colors.blue[700],
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedGens.add(gen);
                      } else if (_selectedGens.length > 1) _selectedGens.remove(gen); 
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            const Text("Zusatz-Formen einschließen:", style: TextStyle(fontWeight: FontWeight.bold)),
            CheckboxListTile(
              title: const Text("Mega-Entwicklungen", style: TextStyle(fontSize: 14)),
              value: _dexMegas, dense: true, contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _dexMegas = val!),
            ),
            CheckboxListTile(
              title: const Text("Gigadynamax", style: TextStyle(fontSize: 14)),
              value: _dexGmax, dense: true, contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _dexGmax = val!),
            ),
            CheckboxListTile(
              title: const Text("Regionalformen (Alola, Galar...)", style: TextStyle(fontSize: 14)),
              value: _dexRegional, dense: true, contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _dexRegional = val!),
            ),
            const SizedBox(height: 12),
            if (_dexMegas || _dexGmax || _dexRegional) ...[
              const Text("Sortierung der Formen:", style: TextStyle(fontWeight: FontWeight.bold)),
              RadioListTile<DexSortStyle>(
                title: const Text("Direkt hinter das Original-Pokémon", style: TextStyle(fontSize: 12)),
                value: DexSortStyle.inline, groupValue: _dexSort, dense: true, contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _dexSort = val!),
              ),
              RadioListTile<DexSortStyle>(
                title: const Text("Als eigener Bereich am Ende des Binders", style: TextStyle(fontSize: 12)),
                value: DexSortStyle.appended, groupValue: _dexSort, dense: true, contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _dexSort = val!),
              ),
            ]
          ],
        );

      case AdvancedBinderType.set:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                return _dbSetNames.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) => _selectedSetName = selection,
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                return TextField(
                  controller: controller, focusNode: focusNode, onChanged: (val) => _selectedSetName = val,
                  decoration: const InputDecoration(labelText: "Set suchen (z.B. '151' oder 'Base Set')", border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text("Sammlungs-Ziel:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<SetCompletionType>(
              initialValue: _setCompletion,
              isExpanded: true, 
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              items: const [
                DropdownMenuItem(value: SetCompletionType.standard, child: Text("Standard (Nur reguläre Nummern)", overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: SetCompletionType.master, child: Text("Master Set (Inkl. Secret Rares)", overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: SetCompletionType.complete, child: Text("Complete (Alle Karten + Alle Reverse Holos)", overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (val) => setState(() => _setCompletion = val!),
            ),
          ],
        );

      case AdvancedBinderType.pokemon:
      case AdvancedBinderType.artist:
        final bool isPoke = _selectedType == AdvancedBinderType.pokemon;
        final label = isPoke ? "Pokémon (z.B. Glurak)" : "Künstler (z.B. Mitsuhiro Arita)";
        final listToSearch = isPoke ? _dbPokemonNames : _dbArtists;

        return Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
            return listToSearch.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: (String selection) => _selectedTarget = selection,
          fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
            return TextField(
              controller: controller, focusNode: focusNode, onChanged: (val) => _selectedTarget = val,
              decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.search)),
            );
          },
        );

      case AdvancedBinderType.bulkBox:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Art der Aufbewahrung:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildShapeOption("Standard Box", "box", Icons.inventory_2)),
                const SizedBox(width: 8),
                Expanded(child: _buildShapeOption("Elite Trainer Box", "etb", Icons.all_inbox)),
                const SizedBox(width: 8),
                Expanded(child: _buildShapeOption("Tin-Dose", "tin", Icons.takeout_dining)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(child: Text("Bulk Boxen haben kein Seitenlayout. Sie sind endlose Listen, die du mit Trennkarten strukturieren kannst.", style: TextStyle(fontSize: 12, color: Colors.black87))),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildTypeTile(AdvancedBinderType type, String title, String subtitle, IconData icon) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
          if (_nameController.text.isEmpty || _nameController.text == "Custom Binder") {
            _nameController.text = title; 
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey[300]!, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.blue[900] : Colors.black87)),
                  Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutOption(int r, int c) {
    final isSelected = _rows == r && _cols == c;
    return InkWell(
      onTap: () => setState(() { _rows = r; _cols = c; }),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(Icons.grid_on, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(height: 4),
            Text("$r x $c", style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            Text("${r*c} Slots", style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildShapeOption(String label, String shape, IconData icon) {
    final isSelected = _bulkBoxShape == shape;
    return InkWell(
      onTap: () => setState(() => _bulkBoxShape = shape),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[50] : Colors.white,
          border: Border.all(color: isSelected ? Colors.orange : Colors.grey[300]!, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.orange : Colors.grey),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Future<void> _createBinder() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bitte gib einen Namen ein.")));
      return;
    }

    if (_selectedType == AdvancedBinderType.set && _selectedSetName.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bitte wähle ein Set aus.")));
       return;
    }
    if ((_selectedType == AdvancedBinderType.pokemon || _selectedType == AdvancedBinderType.artist) && _selectedTarget.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bitte wähle ein Ziel aus.")));
       return;
    }

    setState(() => _isLoading = true);

    try {
      final db = ref.read(databaseProvider);
      final service = BinderService(db); 

      await service.createBinder(
        name: _nameController.text,
        color: _selectedColor.value,
        rows: _selectedType == AdvancedBinderType.bulkBox ? 0 : _rows,
        cols: _selectedType == AdvancedBinderType.bulkBox ? 0 : _cols,
        type: _selectedType,
        sortOrder: _sortOrder,
        icon: _selectedType == AdvancedBinderType.bulkBox ? _bulkBoxShape : null,
        customPages: _customPages,
        selectedGens: _selectedGens,
        dexMegas: _dexMegas,
        dexGmax: _dexGmax,
        dexRegional: _dexRegional,
        dexSort: _dexSort,
        setCompletion: _setCompletion,
        selectedSetName: _selectedSetName,
        selectedTarget: _selectedTarget,
      );

      if (mounted) Navigator.pop(context);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fehler: $e")));
        setState(() => _isLoading = false);
      }
    }
  }
}