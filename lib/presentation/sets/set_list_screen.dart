import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/search_provider.dart'; 
import '../../data/api/tcgdex_api_client.dart';
import '../../data/database/database_provider.dart';
import '../../data/sync/set_importer.dart';
import '../../data/sync/ptcg_importer.dart';
import '../../domain/models/api_set.dart';
import 'set_detail_screen.dart';

// Provider für den UI Such-State innerhalb der Set-Liste
final setListSearchProvider = StateProvider<String>((ref) => '');

// ÄNDERUNG: Jetzt ConsumerStatefulWidget, um den Controller zu halten
class SetListScreen extends ConsumerStatefulWidget {
  const SetListScreen({super.key});

  @override
  ConsumerState<SetListScreen> createState() => _SetListScreenState();
}

class _SetListScreenState extends ConsumerState<SetListScreen> {
  late TextEditingController _searchController;
  late FocusNode _focusNode; // <--- NEU

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(); // <--- NEU
    // Controller mit dem aktuellen Wert aus dem Provider initialisieren
    _searchController = TextEditingController(
      text: ref.read(setListSearchProvider)
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose(); // <--- NEU
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          // 1. SUCHLEISTE MIT AUTOCOMPLETE
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: LayoutBuilder(
              builder: (context, constraints) => RawAutocomplete<String>(
                textEditingController: _searchController,
                focusNode: _focusNode,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final query = textEditingValue.text.trim().toLowerCase();
                  if (query.isEmpty) return const Iterable<String>.empty();
                  
                  // Wir holen uns die bereits geladenen Sets aus dem Provider
                  final allSets = ref.read(allSetsProvider).valueOrNull ?? [];
                  final Set<String> results = {};
                  
                  for (var set in allSets) {
                    if (set.nameDe != null && set.nameDe!.toLowerCase().contains(query)) {
                      results.add(set.nameDe!);
                    } else if (set.name.toLowerCase().contains(query)) {
                      results.add(set.name);
                    }
                  }
                  return results.take(8);
                },
                onSelected: (String selection) {
                  ref.read(setListSearchProvider.notifier).state = selection;
                  FocusScope.of(context).unfocus();
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Suche Set (z.B. 151, Evolving Skies)...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                controller.clear();
                                ref.read(setListSearchProvider.notifier).state = '';
                                focusNode.unfocus();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) => ref.read(setListSearchProvider.notifier).state = value,
                    onSubmitted: (value) {
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
                        constraints: BoxConstraints(maxHeight: 250, maxWidth: constraints.maxWidth),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              leading: const Icon(Icons.search, size: 18, color: Colors.grey),
                              title: Text(option, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
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
    // --- NEU: Dialog mit Auswahlmöglichkeiten ---
    final syncType = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Update auswählen"),
        content: const Text(
          "Standard Update:\nLädt neue Sets und Karten von TCGdex (Schnell).\n\n"
          "Deep Sync:\nLädt zusätzlich exklusive Promo-Sets, fehlende Bilder und Preise von PokemonTCG.io (Dauert länger).",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 0), child: const Text("Abbrechen", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, 1), child: const Text("Standard")),
          FilledButton(onPressed: () => Navigator.pop(ctx, 2), child: const Text("Deep Sync")),
        ],
      ),
    );

    if (syncType == null || syncType == 0) return;

    final db = ref.read(databaseProvider);
    final dexApi = ref.read(tcgDexApiClientProvider);
    final setImporter = SetImporter(dexApi, db);
    // Den neuen Importer laden! (Vergiss nicht ihn oben zu importieren: import '../../data/sync/ptcg_importer.dart';)
    final ptcgImporter = PtcgImporter(db);

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (syncType == 1 || syncType == 2) {
        // TCGdex Sync immer zuerst ausführen!
        await setImporter.syncAllData(
          onProgress: (status) => print('TCGDEX SYNC: $status'),
        );
      }

      if (syncType == 2) {
        // Danach den Lückenfüller drüberschicken!
        await ptcgImporter.syncMissingData(
          onProgress: (status) => print('PTCG SYNC: $status'),
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Alles erfolgreich aktualisiert!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, duration: Duration(milliseconds: 500)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, duration: const Duration(milliseconds: 500)),
        );
      }
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ref.refresh(allSetsProvider);
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

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lade Karten für ${set.nameDe ?? set.name}...'), behavior: SnackBarBehavior.floating, duration: const Duration(milliseconds: 500)),
    );

    try {
      // --- NEU: WIR BAUEN DEN PREIS-CACHE FÜR DEN EINZEL-DOWNLOAD ---
      // Hole alle aktuellen Karten dieses Sets
      final setCardsQuery = await (db.select(db.cards)..where((t) => t.setId.equals(set.id))).get();
      final cardIds = setCardsQuery.map((c) => c.id).toList();
      
      Map<String, Map<String, dynamic>> latestCmPrices = {};
      Map<String, Map<String, dynamic>> latestTcgPrices = {};
      
      if (cardIds.isNotEmpty) {
         final allLatestCmQuery = await db.customSelect(
            'SELECT card_id, trend, trend_holo, trend_reverse FROM card_market_prices WHERE card_id IN (${cardIds.map((e) => "'$e'").join(',')}) GROUP BY card_id HAVING MAX(fetched_at)'
         ).get();
         latestCmPrices = {
            for (var row in allLatestCmQuery) row.read<String>('card_id'): {
               'trend': row.read<double?>('trend'),
               'trendHolo': row.read<double?>('trend_holo'),
               'trendReverse': row.read<double?>('trend_reverse'),
            }
         };

         final allLatestTcgQuery = await db.customSelect(
            'SELECT card_id, normal_market, holo_market, reverse_market FROM tcg_player_prices WHERE card_id IN (${cardIds.map((e) => "'$e'").join(',')}) GROUP BY card_id HAVING MAX(fetched_at)'
         ).get();
         latestTcgPrices = {
            for (var row in allLatestTcgQuery) row.read<String>('card_id'): {
               'normalMarket': row.read<double?>('normal_market'),
               'holoMarket': row.read<double?>('holo_market'),
               'reverseMarket': row.read<double?>('reverse_market'),
            }
         };
      }
      // -------------------------------------------------------------

      // Lädt alle Karten-Details und Preise von TCGdex herunter
      await importer.importCardsForSet(set.id, latestCmPrices, latestTcgPrices);
      
      // Cache der Provider zurücksetzen, damit die UI die neuen Karten zeigt
      ref.invalidate(cardsForSetProvider(set.id));
      ref.invalidate(setStatsProvider(set.id));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Karten erfolgreich geladen!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, duration: Duration(milliseconds: 500)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Download: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, duration: const Duration(milliseconds: 500)),
        );
      }
    }
  }
}