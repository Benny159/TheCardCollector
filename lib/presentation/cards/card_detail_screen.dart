import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drift/drift.dart' as drift; // Für DB Updates

import '../../data/api/search_provider.dart';
import '../../data/api/tcg_api_client.dart';
import '../../data/api/tcgdex_api_client.dart';
import '../../data/database/app_database.dart'; // WICHTIG: Für die UserCard Klasse
import '../../data/database/database_provider.dart';
import '../../data/sync/set_importer.dart';
import '../../domain/models/api_card.dart';
import '../../domain/models/api_set.dart';
import '../inventory/inventory_bottom_sheet.dart'; // WICHTIG: Dein BottomSheet Import
import '../search/card_search_screen.dart';
import '../sets/set_detail_screen.dart';

// --- NEU: Ein Live-Provider für das Inventar dieser EINEN Karte ---
final cardInventoryProvider = StreamProvider.family<List<UserCard>, String>((ref, cardId) {
  final db = ref.watch(databaseProvider);
  // Wir beobachten die Tabelle 'userCards' für diese ID
  return (db.select(db.userCards)..where((tbl) => tbl.cardId.equals(cardId))).watch();
});

class CardDetailScreen extends ConsumerWidget {
  final ApiCard card;

  const CardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Set Infos laden
    final setAsync = ref.watch(setByIdProvider(card.setId));
    
    // 2. NEU: Inventar-Daten live laden
    final inventoryAsync = ref.watch(cardInventoryProvider(card.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(card.name, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: "Daten & Preise aktualisieren",
            onPressed: () async {
              _updateCardData(context, ref);
            },
          ),
        ],
      ),
      // NEU: Der Button unten rechts zum Hinzufügen
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => InventoryBottomSheet(card: card),
          ).then((_) {
            // UI neu laden (damit Listen aktualisiert werden)
            ref.invalidate(searchResultsProvider);
            ref.invalidate(cardsForSetProvider(card.setId));
            // Set-Statistik auch neu laden
            ref.invalidate(setStatsProvider(card.setId));
          });
        },
        icon: const Icon(Icons.add_card),
        label: const Text("Hinzufügen"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. SET HEADER
            setAsync.when(
              data: (set) => _buildSetHeader(context, set),
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 10),

            // 2. DAS BILD
            GestureDetector(
              onTap: () => _openFullscreenImage(context),
              child: Hero(
                tag: card.id,
                child: Container(
                  height: 400,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: CachedNetworkImage(
                    imageUrl: card.largeImageUrl ?? card.smallImageUrl,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 100),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // --- NEU: INVENTAR BOX ---
            // Zeigt an, wie viele du hast (und welche Varianten)
            inventoryAsync.when(
              data: (items) => _buildInventorySection(context, ref, items),
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => Text("Fehler beim Laden des Inventars: $err"),
            ),

            const SizedBox(height: 20),

            // 3. EXTERNE LINKS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  if (card.cardmarket?.url != null)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _launchURL(card.cardmarket!.url),
                        icon: const Icon(Icons.shopping_cart, size: 18),
                        label: const Text("Cardmarket"),
                        style: FilledButton.styleFrom(backgroundColor: Colors.blue[800]),
                      ),
                    ),
                  const SizedBox(width: 10),
                  if (card.tcgplayer?.url != null)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _launchURL(card.tcgplayer!.url),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text("TCGPlayer"),
                        style: FilledButton.styleFrom(backgroundColor: Colors.teal[700]),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. PREIS ANALYSE
            if (card.cardmarket != null)
              _buildPriceSection(
                context, 
                title: "Cardmarket Preise", 
                color: Colors.blue[800]!,
                data: {
                  "Trend": card.cardmarket!.trendPrice,
                  "Durchschnitt (30 Tage)": card.cardmarket!.avg30,
                  "Ab (Low Price)": card.cardmarket!.lowPrice,
                  "Reverse Holo Trend": card.cardmarket!.reverseHoloTrend,
                },
                lastUpdate: card.cardmarket!.updatedAt,
              ),

            if (card.tcgplayer != null)
              _buildPriceSection(
                context, 
                title: "TCGPlayer Market", 
                color: Colors.teal[700]!,
                data: {
                  "Market (Normal)": card.tcgplayer!.prices?.normal?.market,
                  "Market (Holofoil)": card.tcgplayer!.prices?.holofoil?.market,
                  "Market (Reverse)": card.tcgplayer!.prices?.reverseHolofoil?.market,
                },
                lastUpdate: card.tcgplayer!.updatedAt,
              ),

            const SizedBox(height: 20),

            // 5. DETAILS
            _buildInfoSection(context, ref),
            
            const SizedBox(height: 80), // Platz für FAB
          ],
        ),
      ),
    );
  }

  // --- NEUE WIDGETS ---

// Zeigt deine Sammlung dieser Karte an
  Widget _buildInventorySection(BuildContext context, WidgetRef ref, List<UserCard> items) {
    if (items.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.grey),
            SizedBox(width: 8),
            Text("Nicht in deiner Sammlung", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final totalCount = items.fold(0, (sum, item) => sum + item.quantity);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                "In deinem Besitz: $totalCount Stück",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
              ),
            ],
          ),
          const Divider(),
          
          // --- HIER IST DIE ÄNDERUNG: LISTE MIT LÖSCH-BUTTON ---
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                // Infos (Anzahl, Variante, Zustand)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${item.quantity}x ${item.variant}", 
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Text(
                          "${item.condition} • ${item.language}", 
                          style: TextStyle(fontSize: 11, color: Colors.grey[700])
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Der Löschen-Button (Mülleimer/Minus)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  tooltip: "Eins entfernen",
                  onPressed: () => _decreaseOrDeleteItem(context, ref, item),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // --- BESTEHENDE LOGIK (leicht ausgelagert) ---

  Future<void> _updateCardData(BuildContext context, WidgetRef ref) async {
    final api = ref.read(apiClientProvider);
    final db = ref.read(databaseProvider);
    final dexApi = ref.read(tcgDexApiClientProvider);
    final importer = SetImporter(api, dexApi, db);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aktualisiere Karte...')));

    try {
      ref.invalidate(searchResultsProvider);
      ref.invalidate(cardsForSetProvider(card.setId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Preise aktualisiert!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // ... (Der Rest deiner Methoden: _buildSetHeader, _buildPriceSection, _buildInfoSection, _openFullscreenImage, _launchURL bleiben hier unverändert) ...
  
  // (Ich kopiere sie hier rein, damit die Datei vollständig ist)
  Widget _buildSetHeader(BuildContext context, ApiSet? set) {
    if (set == null) return const SizedBox.shrink();
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => SetDetailScreen(set: set)));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.grey[100],
        child: Row(
          children: [
            SizedBox(height: 40, width: 80, child: CachedNetworkImage(imageUrl: set.logoUrl, fit: BoxFit.contain)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(set.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    children: [
                      Text("Zu Set ${set.id} wechseln", style: TextStyle(color: Colors.blue[700], fontSize: 12)),
                      Icon(Icons.arrow_forward_ios, size: 10, color: Colors.blue[700]),
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

  Widget _buildPriceSection(BuildContext context, {required String title, required Color color, required Map<String, double?> data, String? lastUpdate}) {
    final validEntries = data.entries.where((e) => e.value != null).toList();
    if (validEntries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  if (lastUpdate != null) Text(lastUpdate.split('T')[0], style: TextStyle(color: color.withOpacity(0.6), fontSize: 10)),
                ],
              ),
            ),
            ...validEntries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: const TextStyle(color: Colors.black54)),
                  Text("${entry.value!.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          _buildClickableArtistRow(context, ref),
          _buildDetailRow("Seltenheit", card.rarity),
          _buildDetailRow("Nummer", "${card.number} / ${card.setPrintedTotal ?? '?'}"),
          _buildDetailRow("Typen", card.types.join(", ")),
        ],
      ),
    );
  }

  Widget _buildClickableArtistRow(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 100, child: Text("Künstler", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(
            child: InkWell(
              onTap: () {
                ref.read(searchModeProvider.notifier).state = SearchMode.artist;
                ref.read(searchQueryProvider.notifier).state = card.artist;
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CardSearchScreen()));
              },
              child: Row(
                children: [
                  Text(card.artist, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  const Icon(Icons.search, size: 14, color: Colors.blue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _openFullscreenImage(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(child: InteractiveViewer(
        panEnabled: true, boundaryMargin: const EdgeInsets.all(20), minScale: 0.5, maxScale: 4,
        child: CachedNetworkImage(imageUrl: card.largeImageUrl ?? card.smallImageUrl, fit: BoxFit.contain),
      )),
    )));
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) throw Exception('Could not launch $url');
  }

  // --- LOGIK: VERRINGERN ODER LÖSCHEN ---
  Future<void> _decreaseOrDeleteItem(BuildContext context, WidgetRef ref, UserCard item) async {
    final db = ref.read(databaseProvider);

    if (item.quantity > 1) {
      // Wenn mehr als 1 da ist: Einfach Anzahl verringern
      final newQuantity = item.quantity - 1;
      
      await (db.update(db.userCards)..where((t) => t.id.equals(item.id))).write(
        UserCardsCompanion(quantity: drift.Value(newQuantity)),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("-1"), duration: Duration(milliseconds: 500)));
    } else {
      // Wenn nur noch 1 da ist: Fragen und dann löschen
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Entfernen?"),
          content: Text("Möchtest du das letzte Exemplar (${item.variant}) aus deiner Sammlung löschen?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Abbrechen"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Löschen"),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await (db.delete(db.userCards)..where((t) => t.id.equals(item.id))).go();
        
        // Listen aktualisieren (wichtig wenn es die letzte Karte war -> wird grau)
        ref.invalidate(searchResultsProvider);
        ref.invalidate(cardsForSetProvider(card.setId));
        // Set-Statistik auch neu laden
        ref.invalidate(setStatsProvider(card.setId));
        await createPortfolioSnapshot(ref);
      }
    }
  }
}