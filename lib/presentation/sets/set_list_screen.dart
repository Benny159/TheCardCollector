import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/search_provider.dart'; 
import '../../data/api/tcgdex_api_client.dart';
import '../../data/database/database_provider.dart';
import '../../data/sync/set_importer.dart';
import '../../data/sync/ptcg_importer.dart';
import 'widgets/set_card_tile.dart';

/// Ephemeral state provider holding the active text query for filtering expansion sets.
final setListSearchProvider = StateProvider.autoDispose<String>((ref) => '');

/// Overview screen presenting a searchable grid of all available card expansions.
class SetListScreen extends ConsumerStatefulWidget {
  const SetListScreen({super.key});

  @override
  ConsumerState<SetListScreen> createState() => _SetListScreenState();
}

class _SetListScreenState extends ConsumerState<SetListScreen> {
  late TextEditingController _searchController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _searchController = TextEditingController(
      text: ref.read(setListSearchProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
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
          // 1. Search bar with autocomplete
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: LayoutBuilder(
              builder: (context, constraints) => RawAutocomplete<String>(
                textEditingController: _searchController,
                focusNode: _focusNode,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final query = textEditingValue.text.trim().toLowerCase();
                  if (query.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  
                  final allSets = ref.read(allSetsProvider).valueOrNull ?? [];
                  final Set<String> results = {};
                  
                  for (final set in allSets) {
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
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E293B)
                          : Colors.grey[100],
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
                      color: Theme.of(context).cardColor,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 250, maxWidth: constraints.maxWidth),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Theme.of(context).dividerColor),
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

          // 2. Expansion sets grid view
          Expanded(
            child: setsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Fehler: $err')),
              data: (allSets) {
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
                    return SetCardTile(set: filteredSets[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Full synchronization workflow trigger
  void _startSetSync(BuildContext context, WidgetRef ref) async {
    final syncType = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Update auswählen"),
        content: const Text(
          "Standard Update:\nLädt neue Sets und Karten von TCGdex (Schnell).\n\n"
          "Deep Sync:\nLädt zusätzlich exklusive Promo-Sets, fehlende Bilder und Preise von PokemonTCG.io (Dauert länger).",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 0),
            child: const Text("Abbrechen", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 1),
            child: const Text("Standard"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 2),
            child: const Text("Deep Sync"),
          ),
        ],
      ),
    );

    if (syncType == null || syncType == 0) return;

    final db = ref.read(databaseProvider);
    final dexApi = ref.read(tcgDexApiClientProvider);
    final setImporter = SetImporter(dexApi, db);
    final ptcgImporter = PtcgImporter(db);

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (syncType == 1 || syncType == 2) {
        await setImporter.syncAllData(
          onProgress: (status) => debugPrint('TCGDEX SYNC: $status'),
        );
      }

      if (syncType == 2) {
        await ptcgImporter.syncMissingData(
          onProgress: (status) => debugPrint('PTCG SYNC: $status'),
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Alles erfolgreich aktualisiert!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ref.invalidate(allSetsProvider);
        ref.invalidate(allSetStatsProvider);
      }
    }
  }
}