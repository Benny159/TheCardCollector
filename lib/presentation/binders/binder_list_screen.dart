import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database_provider.dart';
import '../../data/database/app_database.dart';
import '../../domain/logic/binder_service.dart';
import 'binder_detail_screen.dart';
import 'bulk_box_detail_screen.dart';
import 'create_binder_dialog.dart';
import 'binder_detail_provider.dart'; 

// --- STATE PROVIDER FÜR SUCHE & SORTIERUNG ---
enum StorageSort { newest, name, value }
final storageSearchProvider = StateProvider<String>((ref) => '');
final storageSortProvider = StateProvider<StorageSort>((ref) => StorageSort.newest);

class BinderListScreen extends ConsumerWidget {
  const BinderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final search = ref.watch(storageSearchProvider);
    final sort = ref.watch(storageSortProvider);

    // Live-Stream aller Binder/Boxen
    final bindersStream = db.select(db.binders).watch();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Aufbewahrung"), // Umbenannt!
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showDialog(context: context, builder: (_) => const CreateBinderDialog()),
          )
        ],
      ),
      body: StreamBuilder<List<Binder>>(
         stream: bindersStream,
         builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            var binders = snapshot.data!;
            
            // 1. FILTERN (SUCHE)
            if (search.isNotEmpty) {
               binders = binders.where((b) => b.name.toLowerCase().contains(search.toLowerCase())).toList();
            }

            // 2. SORTIEREN
            binders.sort((a, b) {
               // Favoriten IMMER ganz oben!
               if (a.isFavorite && !b.isFavorite) return -1;
               if (!a.isFavorite && b.isFavorite) return 1;
               
               if (sort == StorageSort.value) return b.totalValue.compareTo(a.totalValue);
               if (sort == StorageSort.name) return a.name.toLowerCase().compareTo(b.name.toLowerCase());
               return b.createdAt.compareTo(a.createdAt); // Standard: Neueste zuerst
            });

            return Column(
              children: [
                // --- SUCHE & SORTIER LEISTE ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) => RawAutocomplete<String>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              final query = textEditingValue.text.trim().toLowerCase();
                              if (query.isEmpty) return const Iterable<String>.empty();
                              
                              final Set<String> results = {};
                              for (var b in binders) {
                                if (b.name.toLowerCase().contains(query)) {
                                  results.add(b.name);
                                }
                              }
                              return results.take(6);
                            },
                            onSelected: (String selection) {
                              ref.read(storageSearchProvider.notifier).state = selection;
                              FocusScope.of(context).unfocus();
                            },
                            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: "Box / Ordner suchen...",
                                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                  suffixIcon: search.isNotEmpty ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      controller.clear();
                                      ref.read(storageSearchProvider.notifier).state = '';
                                      focusNode.unfocus();
                                    },
                                  ) : null,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                ),
                                onChanged: (val) => ref.read(storageSearchProvider.notifier).state = val,
                                onSubmitted: (val) {
                                  focusNode.unfocus();
                                },
                              );
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(8),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxHeight: 200, maxWidth: constraints.maxWidth),
                                    child: ListView.separated(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                                      itemBuilder: (context, index) {
                                        final option = options.elementAt(index);
                                        return ListTile(
                                          leading: const Icon(Icons.folder, size: 18, color: Colors.blueGrey),
                                          title: Text(option, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                          visualDensity: VisualDensity.compact,
                                          onTap: () => onSelected(option),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<StorageSort>(
                            value: sort,
                            icon: const Icon(Icons.sort, size: 18),
                            style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold),
                            items: const [
                              DropdownMenuItem(value: StorageSort.newest, child: Text("Neu")),
                              DropdownMenuItem(value: StorageSort.name, child: Text("A-Z")),
                              DropdownMenuItem(value: StorageSort.value, child: Text("Preis")),
                            ],
                            onChanged: (val) => ref.read(storageSortProvider.notifier).state = val!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // --- DIE LISTE ---
                Expanded(
                  child: binders.isEmpty 
                    ? const Center(child: Text("Nichts gefunden.", style: TextStyle(color: Colors.grey)))
                    : GridView.builder(
                        padding: const EdgeInsets.only(left: 12, top: 12, right: 12, bottom: 100),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: binders.length,
                        itemBuilder: (ctx, i) => _BinderCard(binder: binders[i]),
                      ),
                ),
              ],
            );
         }
      ),
    );
  }
}

// --- BINDER CARD (Mit ETB, Favoriten & Fortschrittsbalken) ---
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
          Navigator.push(context, MaterialPageRoute(builder: (context) => BulkBoxDetailScreen(binder: binder)));
        } else {
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
                ? [color.withOpacity(0.6), color, Colors.white.withOpacity(0.4), color] 
                : (isBulkBox 
                    ? [color.withOpacity(0.9), color, color.withOpacity(0.7)] 
                    : [color.withOpacity(0.8), color, color]), 
            stops: shape == 'tin' ? const [0.0, 0.4, 0.5, 1.0] : const [0.0, 0.5, 1.0],
          ),
          border: shape == 'tin' ? Border.all(color: Colors.white.withOpacity(0.5), width: 1.5) : null,
        ),
        child: Stack(
          children: [
            // --- DEKORATIONEN BASIEREND AUF DEM TYP ---
            if (!isBulkBox) 
              Positioned(left: 12, top: 0, bottom: 0, child: Container(width: 2, color: Colors.black12)),

            if (isBulkBox && shape == 'etb') 
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
              
            if (isBulkBox && shape == 'box') 
              Positioned(
                left: 0, right: 0, top: 0,
                child: Row(
                  children: [
                    Expanded(child: Container(height: 10, decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), border: Border.all(color: Colors.black12)))),
                    Expanded(child: Container(height: 10, decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), border: Border.all(color: Colors.black12)))),
                  ],
                ),
              ),

            // --- FAVORITEN STERN ---
            Positioned(
              top: isBulkBox && shape == 'etb' ? 24 : 0,
              right: 0,
              child: IconButton(
                icon: Icon(
                  binder.isFavorite ? Icons.star : Icons.star_border, 
                  color: binder.isFavorite ? Colors.amberAccent : Colors.white54,
                  size: 20,
                  shadows: [if (binder.isFavorite) const Shadow(color: Colors.black54, blurRadius: 4)],
                ),
                onPressed: () async {
                  final db = ref.read(databaseProvider);
                  await BinderService(db).toggleBinderFavorite(binder.id, !binder.isFavorite);
                },
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
                    data: (stats) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                          child: Text("${stats.value.toStringAsFixed(2)} €", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        
                        // --- FORTSCHRITTSBALKEN ---
                        if (!isBulkBox && stats.total > 0) ...[
                           const SizedBox(height: 8),
                           ClipRRect(
                             borderRadius: BorderRadius.circular(2),
                             child: LinearProgressIndicator(
                               value: stats.progress,
                               backgroundColor: Colors.black26,
                               valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                               minHeight: 4,
                             ),
                           ),
                           const SizedBox(height: 2),
                           Text("${stats.filled} / ${stats.total}", style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                        ] else if (isBulkBox) ...[
                           const SizedBox(height: 8),
                           Text("${stats.filled} Karten", style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        ]
                      ],
                    ),
                    loading: () => const SizedBox(), error: (_,__) => const SizedBox(),
                  ),

                  const Spacer(),
                  
                  Row(
                    children: [
                      Icon(isBulkBox ? Icons.inventory_2 : Icons.menu_book, size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isBulkBox 
                              ? (shape == 'etb' ? "Elite Trainer Box" : (shape == 'tin' ? "Tin-Dose" : "Lagerkarton")) 
                              : "${binder.rowsPerPage}x${binder.columnsPerPage} Buch", 
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
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