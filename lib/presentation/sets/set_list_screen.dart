import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/search_provider.dart'; 
import '../../data/api/tcgdex_api_client.dart';
import '../../data/database/database_provider.dart';
import '../../data/sync/set_importer.dart';
import '../../domain/models/api_set.dart';
import 'set_detail_screen.dart';

// Provider für den UI Such-State innerhalb der Set-Liste
final setListSearchProvider = StateProvider<String>((ref) => '');

class SetListScreen extends ConsumerWidget {
  const SetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(allSetsProvider);
    final searchQuery = ref.watch(setListSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Alle Sets"),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: "Set-Liste & Daten aktualisieren",
            onPressed: () => _startSetSync(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. SUCHLEISTE
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Suche Set (z.B. 151, Evolving Skies)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref.read(setListSearchProvider.notifier).state = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                ref.read(setListSearchProvider.notifier).state = value;
              },
            ),
          ),

          // 2. GRID DER SETS
          Expanded(
            child: setsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Fehler: $err')),
              data: (allSets) {
                // Filterlogik für Name (DE/EN) und Serie
                final filteredSets = allSets.where((set) {
                  final nameEn = set.name.toLowerCase();
                  final nameDe = set.nameDe?.toLowerCase() ?? '';
                  final query = searchQuery.toLowerCase();
                  
                  return nameEn.contains(query) || 
                         nameDe.contains(query) || 
                         set.series.toLowerCase().contains(query);
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
                    return _SetTile(set: filteredSets[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Sync-Logik (Kompletter Daten-Sync)
  void _startSetSync(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Vollständiges Update?"),
        content: const Text(
          "Das lädt ALLE Sets inklusive Release-Daten und Karten herunter.\n"
          "Dieser Vorgang kann eine Weile dauern.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Abbrechen")),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Starten")),
        ],
      ),
    );

    if (confirm != true) return;

    final db = ref.read(databaseProvider);
    final dexApi = ref.read(tcgDexApiClientProvider);
    final importer = SetImporter(dexApi, db);

    if (!context.mounted) return;

    // Ladeanzeige öffnen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Nutzt die neue Logik im Importer (inkl. Datum & Karten)
      await importer.syncAllData(
        onProgress: (status) => print('SYNC: $status'),
      );

      if (context.mounted) {
        Navigator.pop(context); // Ladeanzeige schließen
        ref.refresh(allSetsProvider); // Liste neu laden
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Alles erfolgreich aktualisiert!')),
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

class _SetTile extends ConsumerWidget {
  final ApiSet set;
  const _SetTile({required this.set});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(setStatsProvider(set.id));
    
    // Bild Logik: Nutze deutsches Logo wenn verfügbar, sonst Englisch
    final logoUrl = set.logoUrlDe ?? set.logoUrl;

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
             // Statistiken beim Zurückkehren refreshen
             ref.refresh(setStatsProvider(set.id));
          });
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LOGO BEREICH
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: logoUrl != null 
                        ? CachedNetworkImage(
                            imageUrl: logoUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                          )
                        : const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
                
                // INFO BEREICH
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.grey[100],
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          set.nameDe ?? set.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis,
                        ),
                        // DATUM ANZEIGEN (wenn vorhanden)
                        if (set.releaseDate.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              set.releaseDate,
                              style: TextStyle(color: Colors.grey[600], fontSize: 10),
                            ),
                          ),
                        
                        const Spacer(),

                        // FORTSCHRITTS-ANZEIGE
                        statsAsync.when(
                          data: (ownedCount) {
                            // Wir nutzen total (Master-Set) für den Fortschritt
                            final int totalCount = set.total; 
                            final double progress = totalCount > 0 ? (ownedCount / totalCount) : 0.0;
                            final double displayProgress = progress > 1.0 ? 1.0 : progress; 

                            return Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: displayProgress,
                                    minHeight: 5,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("$ownedCount/$totalCount", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500)),
                                    Text("${(progress * 100).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 9, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            );
                          },
                          loading: () => const LinearProgressIndicator(minHeight: 5),
                          error: (_,__) => const SizedBox(), 
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // DOWNLOAD BUTTON (Karten dieses Sets laden)
            Positioned(
              top: 0, right: 0,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: const Icon(Icons.download_for_offline, color: Colors.grey),
                  tooltip: "Karten für dieses Set laden",
                  iconSize: 20,
                  onPressed: () => _importCards(context, ref, set),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _importCards(BuildContext context, WidgetRef ref, ApiSet set) async {
    final db = ref.read(databaseProvider);
    final dexApi = ref.read(tcgDexApiClientProvider);
    final importer = SetImporter(dexApi, db);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lade Karten für ${set.nameDe ?? set.name}...')),
    );

    try {
      // Lädt alle Karten-Details und Preise von TCGdex herunter
      await importer.importCardsForSet(set.id);
      
      // Cache der Provider zurücksetzen, damit die UI die neuen Karten zeigt
      ref.invalidate(cardsForSetProvider(set.id));
      ref.invalidate(setStatsProvider(set.id));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Karten erfolgreich geladen!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Download: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}