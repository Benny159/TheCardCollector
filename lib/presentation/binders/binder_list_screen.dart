import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../data/database/database_provider.dart';
import '../../data/database/app_database.dart';
import 'create_binder_dialog.dart';
import 'binder_detail_screen.dart';
import 'bulk_box_detail_screen.dart';
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

// --- BINDER CARD (Jetzt mit ETB, Tin und Buch Look!) ---
class _BinderCard extends ConsumerWidget {
  final Binder binder;
  const _BinderCard({required this.binder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(binder.color);
    final statsAsync = ref.watch(binderStatsProvider(binder.id));
    
    final isBulkBox = binder.rowsPerPage == 0 || binder.columnsPerPage == 0;
    final shape = binder.icon ?? 'box'; // 'etb', 'tin', 'box'

    return GestureDetector(
      onTap: () {
        if (isBulkBox) {
          // --- ÖFFNET DIE LISTEN-ANSICHT ---
          Navigator.push(context, MaterialPageRoute(builder: (context) => BulkBoxDetailScreen(binder: binder)));
        } else {
          // --- ÖFFNET DIE BUCH-ANSICHT ---
          Navigator.push(context, MaterialPageRoute(builder: (context) => BinderDetailScreen(binder: binder)));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: isBulkBox 
              ? (shape == 'tin' ? BorderRadius.circular(20) : BorderRadius.circular(8))
              : const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12), bottomLeft: Radius.circular(4), topLeft: Radius.circular(4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5, offset: const Offset(2, 4))],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: shape == 'tin' 
                ? [color.withOpacity(0.6), color, Colors.white.withOpacity(0.4), color] // Metallischer Glanz
                : (isBulkBox 
                    ? [color.withOpacity(0.9), color, color.withOpacity(0.7)] // Box Shading
                    : [color.withOpacity(0.8), color, color]), // Buch Shading
            stops: shape == 'tin' ? const [0.0, 0.4, 0.5, 1.0] : const [0.0, 0.5, 1.0],
          ),
          border: shape == 'tin' ? Border.all(color: Colors.white.withOpacity(0.5), width: 1.5) : null,
        ),
        child: Stack(
          children: [
            // --- DEKORATIONEN BASIEREND AUF DEM TYP ---
            if (!isBulkBox) // Buchrücken
              Positioned(left: 12, top: 0, bottom: 0, child: Container(width: 2, color: Colors.black12)),

            if (isBulkBox && shape == 'etb') // ETB Deckel (Oben abgeschnitten)
              Positioned(
                left: 0, right: 0, top: 0,
                child: Container(
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.4), width: 2))
                  ),
                ),
              ),
              
            if (isBulkBox && shape == 'box') // Pappkarton-Klappen
              Positioned(
                left: 0, right: 0, top: 0,
                child: Row(
                  children: [
                    Expanded(child: Container(height: 10, decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), border: Border.all(color: Colors.black12)))),
                    Expanded(child: Container(height: 10, decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), border: Border.all(color: Colors.black12)))),
                  ],
                ),
              ),

            // --- INHALT ---
            Padding(
              padding: EdgeInsets.fromLTRB(isBulkBox ? 16 : 24, isBulkBox && shape == 'etb' ? 32 : 16, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      binder.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 8),
                  statsAsync.when(
                    data: (stats) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                      child: Text("${stats.value.toStringAsFixed(2)} €", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    loading: () => const SizedBox(), error: (_,__) => const SizedBox(),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(isBulkBox ? Icons.inventory_2 : Icons.menu_book, size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        isBulkBox 
                            ? (shape == 'etb' ? "Elite Trainer Box" : (shape == 'tin' ? "Tin-Dose" : "Lagerkarton")) 
                            : "${binder.rowsPerPage}x${binder.columnsPerPage} Buch", 
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold)
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