import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importiere den search_provider, wo jetzt setStatsProvider definiert ist
import '../../data/api/search_provider.dart'; 
import '../../data/api/tcg_api_client.dart';
import '../../data/database/database_provider.dart';
import '../../data/sync/set_importer.dart';
import '../../domain/models/api_set.dart';
import 'set_detail_screen.dart';

// Der Suchtext Provider bleibt hier (ist nur UI State)
final setListSearchProvider = StateProvider<String>((ref) => '');

// HINWEIS: setStatsProvider wurde hier ENTFERNT, da er jetzt aus search_provider.dart importiert wird!

class SetListScreen extends ConsumerWidget {
  const SetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(allSetsProvider);
    final searchQuery = ref.watch(setListSearchProvider); // Den Suchtext beobachten

    return Scaffold(
      appBar: AppBar(
        title: const Text("Alle Sets"),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: "Alles aktualisieren",
            onPressed: () => _startFullSync(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // 2. DIE SUCHLEISTE (Fest oben verankert)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Suche Set (z.B. 151, Evolving Skies)...',
                prefixIcon: const Icon(Icons.search),
                // Kleiner "Löschen" Button, wenn Text da ist
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref.read(setListSearchProvider.notifier).state = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              // Aktualisiert den State bei jedem Tastendruck
              onChanged: (value) {
                ref.read(setListSearchProvider.notifier).state = value;
              },
            ),
          ),

          // 3. DIE LISTE (Gefiltert)
          Expanded(
            child: setsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Fehler: $err')),
              data: (allSets) {
                // FILTER LOGIK:
                final filteredSets = allSets.where((set) {
                  return set.name.toLowerCase().contains(searchQuery.toLowerCase()) || 
                         set.series.toLowerCase().contains(searchQuery.toLowerCase());
                }).toList();

                if (filteredSets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Kein Set gefunden für "$searchQuery"',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredSets.length,
                  itemBuilder: (context, index) {
                    final set = filteredSets[index];
                    return _SetTile(set: set); // Wir nutzen ein eigenes Widget für bessere Performance
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _startFullSync(BuildContext context, WidgetRef ref) async {
    // Sicherheitsfrage
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Vollständiges Update?"),
        content: const Text(
          "Das lädt ALLE Karten aller Sets herunter.\n"
          "Das kann je nach Internetverbindung 10-30 Minuten dauern.\n\n"
          "Dank der neuen Logik bricht es aber nicht ab!"
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Abbrechen")),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Starten")),
        ],
      ),
    );

    if (confirm != true) return;

    final db = ref.read(databaseProvider);
    final api = ref.read(apiClientProvider);
    final importer = SetImporter(api, db);

    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Update läuft... Bitte warten."),
                  Text("Schau in die Konsole für Details.", style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      await importer.syncAllData(
        onProgress: (status) {
          print('SYNC STATUS: $status');
        }
      );

      if (context.mounted) {
        Navigator.pop(context);
        ref.refresh(allSetsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Alles erledigt!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// --- EIGENES WIDGET FÜR DAS SET-TILE (Für bessere Performance mit Riverpod) ---
class _SetTile extends ConsumerWidget {
  final ApiSet set;
  const _SetTile({required this.set});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hier beobachten wir den Stats-Provider NUR für dieses eine Set
    final statsAsync = ref.watch(setStatsProvider(set.id));

    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SetDetailScreen(set: set),
            ),
          ).then((_) {
             // Wenn wir zurückkommen, aktualisieren wir die Stats für dieses Set
             ref.refresh(setStatsProvider(set.id));
          });
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. LOGO
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CachedNetworkImage(
                      imageUrl: set.logoUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
                
                // 2. INFO & PROGRESS
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.grey[100],
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          set.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          set.releaseDate,
                          style: TextStyle(color: Colors.grey[600], fontSize: 10),
                        ),
                        
                        const Spacer(),

                        // STATISTIK ANZEIGE (Wird geladen)
                        statsAsync.when(
                          data: (ownedCount) {
                            final int totalCount = set.total; 
                            final double progress = totalCount > 0 ? (ownedCount / totalCount) : 0.0;
                            final double displayProgress = progress > 1.0 ? 1.0 : progress; 
                            final String percentage = (progress * 100).toStringAsFixed(1);

                            return Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: displayProgress,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("$ownedCount / $totalCount", style: TextStyle(fontSize: 10, color: Colors.grey[800], fontWeight: FontWeight.w500)),
                                    Text("$percentage%", style: const TextStyle(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            );
                          },
                          loading: () => const LinearProgressIndicator(minHeight: 6),
                          error: (_,__) => const SizedBox(), 
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Reload Button
            Positioned(
              top: 0, right: 0,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: const Icon(Icons.download_for_offline, color: Colors.grey),
                  tooltip: "Set erneut laden",
                  iconSize: 20,
                  onPressed: () => _reloadSet(context, ref, set),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reloadSet(BuildContext context, WidgetRef ref, ApiSet set) async {
    final db = ref.read(databaseProvider);
    final api = ref.read(apiClientProvider);
    final importer = SetImporter(api, db);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Aktualisiere ${set.name}...')),
    );

    try {
      await importer.importSet(set);
      // Wenn wir das Set neu laden, müssen wir auch die Stats refreshen!
      ref.invalidate(setStatsProvider(set.id));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fertig!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}