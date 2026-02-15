import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database_provider.dart';
import '../../domain/models/binder_templates.dart';
import '../../domain/logic/binder_service.dart';

class CreateBinderDialog extends ConsumerStatefulWidget {
  const CreateBinderDialog({super.key});

  @override
  ConsumerState<CreateBinderDialog> createState() => _CreateBinderDialogState();
}

class _CreateBinderDialogState extends ConsumerState<CreateBinderDialog> {
  final _nameController = TextEditingController();
  Color _selectedColor = Colors.blue;
  int _rows = 3;
  int _cols = 3;
  BinderType _selectedType = BinderType.custom;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Neuen Binder erstellen", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),

              // 1. VORLAGE
              const Text("Vorlage:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              DropdownButtonFormField<BinderType>(
                value: _selectedType,
                isExpanded: true, // Wichtig damit Text Platz hat
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                itemHeight: null, // Erlaubt variable Höhe im Menü
                isDense: true,
                
                // --- FIX: selectedItemBuilder ---
                // Das bestimmt, was angezeigt wird, wenn das Menü ZU ist.
                // Wir zeigen hier NUR den Titel an, damit nichts überläuft.
                selectedItemBuilder: (BuildContext context) {
                  return availableTemplates.map<Widget>((t) {
                    return Text(
                      t.label, 
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis, // Falls Titel zu lang
                    );
                  }).toList();
                },
                
                // Das bestimmt, was im AUFGEKLAPPTEN Menü angezeigt wird (Titel + Beschreibung)
                items: availableTemplates.map((t) {
                  return DropdownMenuItem(
                    value: t.type,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(t.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            t.description, 
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                      // Auto-Name setzen
                      if (_nameController.text.isEmpty && val != BinderType.custom) {
                         _nameController.text = availableTemplates.firstWhere((t) => t.type == val).label;
                      }
                    });
                  }
                },
              ),
              
              const SizedBox(height: 16),

              // 2. NAME
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Name des Binders", 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
              ),

              const SizedBox(height: 16),

              // 3. FARBE
              const Text("Farbe:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Colors.blue, Colors.red, Colors.green, Colors.black, 
                    Colors.purple, Colors.orange, Colors.teal, Colors.brown
                  ].map((c) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = c),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: _selectedColor == c ? Border.all(color: Colors.black, width: 3) : null,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                        ),
                        child: _selectedColor == c ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // 4. LAYOUT
              const Text("Layout (Fächer pro Seite):", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildLayoutOption(2, 2),
                  _buildLayoutOption(3, 3),
                  _buildLayoutOption(4, 3),
                  _buildLayoutOption(4, 4),
                ],
              ),

              const SizedBox(height: 24),

              // BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context), 
                    child: const Text("Abbrechen")
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isLoading ? null : _createBinder,
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text("Erstellen"),
                  ),
                ],
              )
            ],
          ),
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

  Future<void> _createBinder() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final db = ref.read(databaseProvider);
      final service = BinderService(db); 

      await service.createBinder(
        name: _nameController.text,
        color: _selectedColor.value,
        rows: _rows,
        cols: _cols,
        type: _selectedType,
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