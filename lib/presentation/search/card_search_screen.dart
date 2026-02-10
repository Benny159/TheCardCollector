import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- WICHTIGE IMPORTS ---
import '../../data/api/search_provider.dart';       // Für die Suche
import '../../data/api/tcg_api_client.dart';        // Für den API Client Provider
import '../../data/database/database_provider.dart'; // Für den Datenbank Provider
import '../../data/sync/set_importer.dart';         // Für die Import-Logik
import '../cards/card_detail_screen.dart';
import '../inventory/inventory_bottom_sheet.dart';

class CardSearchScreen extends ConsumerWidget {
  const CardSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Wir beobachten das Ergebnis der Suche
    final searchAsyncValue = ref.watch(searchResultsProvider);
    
    // 2. Wir beobachten den aktuellen Such-Modus (Name vs Künstler)
    final currentMode = ref.watch(searchModeProvider);
    
    // 3. Controller mit dem aktuellen Suchtext initialisieren (damit er beim Zurückgehen nicht leer ist)
    final initialQuery = ref.read(searchQueryProvider);
    final searchController = TextEditingController(text: initialQuery);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TCG Suche'),
        actions: [
          // --- DER DOWNLOAD BUTTON ---
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Set 151 importieren",
            onPressed: () async {
              // (Dein Download Code bleibt unverändert)
              final db = ref.read(databaseProvider);
              final api = ref.read(apiClientProvider);
              final importer = SetImporter(api, db);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starte Download für Set 151... Bitte warten.')),
              );

              try {
                final api = ref.read(apiClientProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lade Set-Informationen für "Base"...')),
                );

                final allSets = await api.fetchAllSets();
                final mySet = allSets.firstWhere((s) => s.id == 'base1');

                await importer.importSet(mySet);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Fertig! Base Set ist offline verfügbar.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fehler: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          // --- SUCHLEISTE & FILTER ---
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Textfeld
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    // Dynamischer Hint Text je nach Modus
                    hintText: currentMode == SearchMode.name 
                        ? 'Suche Karte (z.B. Glurak, Mew)...' 
                        : 'Suche Künstler (z.B. Arita)...',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    ),
                  ),
                  onSubmitted: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                  },
                ),
                
                const SizedBox(height: 10),

                // Filter Chips (Name vs Künstler)
                Row(
                  children: [
                    const Text("Suchen nach: ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 8),
                    
                    // Chip: Name
                    FilterChip(
                      label: const Text("Karten Name"),
                      selected: currentMode == SearchMode.name,
                      showCheckmark: false,
                      selectedColor: Colors.blue.withOpacity(0.2),
                      onSelected: (bool selected) {
                        if (selected) {
                          ref.read(searchModeProvider.notifier).state = SearchMode.name;
                          // Optional: Suche neu auslösen, falls Text im Feld steht
                          ref.refresh(searchResultsProvider);
                        }
                      },
                    ),
                    
                    const SizedBox(width: 8),

                    // Chip: Künstler
                    FilterChip(
                      label: const Text("Künstler"),
                      selected: currentMode == SearchMode.artist,
                      showCheckmark: false,
                      selectedColor: Colors.purple.withOpacity(0.2),
                      onSelected: (bool selected) {
                        if (selected) {
                          ref.read(searchModeProvider.notifier).state = SearchMode.artist;
                          ref.refresh(searchResultsProvider);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- ERGEBNIS LISTE ---
          Expanded(
            child: searchAsyncValue.when(
              data: (cards) {
                if (cards.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Keine Karten gefunden.'),
                        const SizedBox(height: 8),
                        Text(
                          'Hast du das Set schon importiert?\n(Button oben rechts)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                
                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,      // 3 Karten nebeneinander
                    childAspectRatio: 0.70, // Pokémon-Format
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    
                    final bool isOwned = card.isOwned;
                    // InkWell für Klick zur Detailseite
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CardDetailScreen(card: card),
                          ),
                        ).then((_) {
                           // Wenn man zurückkommt: Suche aktualisieren (falls man im Detail-Screen was geändert hat)
                           ref.invalidate(searchResultsProvider);
                        });
                      },
                      onLongPress: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => InventoryBottomSheet(card: card),
                        ).then((_) {
                          // Nach dem Schließen: Suche neu laden, damit der Status (isOwned) aktualisiert wird
                          ref.invalidate(searchResultsProvider);
                        });
                      },
                      child: Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 1. Bild (JETZT IMMER BUNT - KEIN ColorFiltered mehr)
                            Hero(
                              tag: card.id,
                              child: CachedNetworkImage(
                                imageUrl: card.smallImageUrl,
                                placeholder: (context, url) => Container(color: Colors.grey[200]),
                                errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                                fit: BoxFit.cover,
                              ),
                            ),
                            
                            // Info-Balken unten
                            Positioned(
                              bottom: 0, left: 0, right: 0,
                              child: Container(
                                color: Colors.black.withOpacity(0.7),
                                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      card.number,
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    // Kleines Icon für Besitz-Status
                                    if (isOwned)
                                      const Icon(Icons.check_circle, color: Colors.green, size: 12)
                                    else if (card.priceEur != null)
                                      Text(
                                        '${card.priceEur!.toStringAsFixed(2)}€',
                                        style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Fehler: $err')),
            ),
          ),
        ],
      ),
    );
  }
}