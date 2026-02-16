import 'package:flutter/material.dart';
import 'create_binder_dialog.dart';
import 'binder_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database_provider.dart';
import '../../data/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

// Provider um alle Binder zu laden
final allBindersProvider = StreamProvider<List<Binder>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.binders)
        ..orderBy([(t) => drift.OrderingTerm(expression: t.createdAt, mode: drift.OrderingMode.desc)]))
      .watch();
});

class BinderListScreen extends ConsumerWidget {
  const BinderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bindersAsync = ref.watch(allBindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meine Binder"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            // Hier den neuen Dialog nutzen
            builder: (context) => const CreateBinderDialog(), 
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Neuer Binder"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: bindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Fehler: $e")),
        data: (binders) {
          if (binders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("Erstelle deinen ersten Binder!", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 Spalten
              childAspectRatio: 0.75, // Hochkant wie ein Buch
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: binders.length,
            itemBuilder: (context, index) {
              return _BinderCard(binder: binders[index]);
            },
          );
        },
      ),
    );
  }

  void _showCreateBinderDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    Color selectedColor = Colors.blue;
    int rows = 3;
    int cols = 3;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder( // Stateful für Farb-Auswahl Update
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Neuen Binder erstellen"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Name (z.B. National Dex)", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  const Text("Farbe:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [Colors.blue, Colors.red, Colors.green, Colors.black, Colors.purple, Colors.orange].map((c) {
                      return GestureDetector(
                        onTap: () => setState(() => selectedColor = c),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: selectedColor == c ? Border.all(color: Colors.black, width: 3) : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text("Layout:", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: "$rows x $cols",
                    items: const [
                      DropdownMenuItem(value: "2 x 2", child: Text("2 x 2 (4 Karten/Seite)")),
                      DropdownMenuItem(value: "3 x 3", child: Text("3 x 3 (9 Karten/Seite)")),
                      DropdownMenuItem(value: "4 x 3", child: Text("4 x 3 (12 Karten/Seite)")),
                      DropdownMenuItem(value: "4 x 4", child: Text("4 x 4 (16 Karten/Seite)")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        final parts = val.split(' x ');
                        setState(() {
                          rows = int.parse(parts[0]);
                          cols = int.parse(parts[1]);
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Abbrechen")),
              FilledButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    final db = ref.read(databaseProvider);
                    await db.into(db.binders).insert(
                      BindersCompanion.insert(
                        name: nameController.text,
                        color: selectedColor.value,
                        rowsPerPage: drift.Value(rows),
                        columnsPerPage: drift.Value(cols),
                        type: const drift.Value('custom'), // Vorerst Custom
                      )
                    );
                    if (context.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text("Erstellen"),
              ),
            ],
          );
        }
      ),
    );
  }
}

class _BinderCard extends StatelessWidget {
  final Binder binder;
  const _BinderCard({required this.binder});

  @override
  Widget build(BuildContext context) {
    final color = Color(binder.color);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BinderDetailScreen(binder: binder),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
            bottomLeft: Radius.circular(4),
            topLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5, offset: const Offset(2, 4))
          ],
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              color.withOpacity(0.8), // Buchrücken Schatten
              color,
              color,
            ],
            stops: const [0.05, 0.1, 1.0],
          )
        ),
        child: Stack(
          children: [
            // Buchrücken Linie
            Positioned(
              left: 12, top: 0, bottom: 0,
              child: Container(width: 2, color: Colors.black12),
            ),
            
            // Inhalt
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)]
                    ),
                    child: Text(
                      binder.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Infos
                  Icon(Icons.grid_4x4, size: 16, color: Colors.white.withOpacity(0.7)),
                  Text(
                    "${binder.rowsPerPage}x${binder.columnsPerPage}", 
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}