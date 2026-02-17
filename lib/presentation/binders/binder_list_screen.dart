import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../data/database/database_provider.dart';
import '../../data/database/app_database.dart';
import 'create_binder_dialog.dart';
import 'binder_detail_screen.dart';
// WICHTIG: Hier importieren wir jetzt den Provider!
import 'binder_detail_provider.dart'; 

// --- HAUPT SCREEN ---
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
              crossAxisCount: 2, 
              childAspectRatio: 0.70, 
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
}

// --- BINDER CARD ---
class _BinderCard extends ConsumerWidget {
  final Binder binder;
  const _BinderCard({required this.binder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(binder.color);
    
    // Hier laden wir jetzt den StreamProvider aus binder_detail_provider.dart
    // Da es ein Stream ist, aktualisiert er sich automatisch!
    final statsAsync = ref.watch(binderStatsProvider(binder.id));

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
              color.withOpacity(0.8),
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
              padding: const EdgeInsets.fromLTRB(24, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER: Name ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            binder.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),

                  // WERT ANZEIGE
                  statsAsync.when(
                    data: (stats) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${stats.value.toStringAsFixed(2)} €",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    loading: () => const SizedBox(), // Kein Platzhalter mehr, flackert sonst
                    error: (_,__) => const SizedBox(),
                  ),

                  const Spacer(),
                  
                  // --- FOOTER: Progress & Infos ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${binder.rowsPerPage}x${binder.columnsPerPage} Grid", 
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)
                      ),
                      const SizedBox(height: 4),

                      // Progress Bar
                      statsAsync.when(
                        data: (stats) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: stats.progress,
                                backgroundColor: Colors.black26,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "${stats.filled} / ${stats.total}",
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        loading: () => const LinearProgressIndicator(minHeight: 6),
                        error: (_,__) => Container(),
                      ),
                    ],
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