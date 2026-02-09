import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart'; // WICHTIG: für die Links

import '../../data/api/search_provider.dart';
import '../../domain/models/api_card.dart';
import '../../domain/models/api_set.dart';
import '../sets/set_detail_screen.dart'; // Damit wir zum Set springen können
import '../search/card_search_screen.dart'; // Damit wir zur Suche springen können

class CardDetailScreen extends ConsumerWidget {
  final ApiCard card;

  const CardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wir laden die Infos zum Set dieser Karte (für Logo & Navigation)
    final setAsync = ref.watch(setByIdProvider(card.setId));

    return Scaffold(
      appBar: AppBar(
        title: Text(card.name, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {}, // Später Favoriten
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. SET HEADER (Verlinkung zum Set)
            setAsync.when(
              data: (set) => _buildSetHeader(context, set),
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 10),

            // 2. DAS BILD (Klickbar -> Fullscreen)
            GestureDetector(
              onTap: () => _openFullscreenImage(context),
              child: Hero(
                tag: card.id,
                child: Container(
                  height: 450,
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
            
            const SizedBox(height: 10),
            const Text(
              "(Tippen zum Vergrößern)",
              style: TextStyle(color: Colors.grey, fontSize: 10),
            ),
            const SizedBox(height: 20),

            // 3. EXTERNE LINKS (Buttons)
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

            // 4. PREIS ANALYSE (Cardmarket)
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

            // 5. PREIS ANALYSE (TCGPlayer)
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

            // 6. KARTEN DETAILS (Artist, Typen etc.)
            _buildInfoSection(context, ref),
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS & LOGIK ---

  // Header mit Logo und Klick-Event zum Set
  Widget _buildSetHeader(BuildContext context, ApiSet? set) {
    if (set == null) return const SizedBox.shrink();

    return InkWell(
      onTap: () {
        // Navigation zum Set
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SetDetailScreen(set: set)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.grey[100],
        child: Row(
          children: [
            // Set Logo
            SizedBox(
              height: 40,
              width: 80,
              child: CachedNetworkImage(
                imageUrl: set.logoUrl,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            // Set Name & Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    set.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
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

  // Preis-Tabelle
  Widget _buildPriceSection(BuildContext context, {required String title, required Color color, required Map<String, double?> data, String? lastUpdate}) {
    // Filtern: Nur Zeilen anzeigen, wo auch ein Preis da ist (nicht null)
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
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  if (lastUpdate != null)
                    Text(
                      lastUpdate.split('T')[0], // Nur Datum anzeigen
                      style: TextStyle(color: color.withOpacity(0.6), fontSize: 10),
                    ),
                ],
              ),
            ),
            // Preise Liste
            ...validEntries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: const TextStyle(color: Colors.black54)),
                    Text(
                      "${entry.value!.toStringAsFixed(2)} €",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              );
            }),
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
          // SPEZIAL-ZEILE FÜR KÜNSTLER (Klickbar!)
          _buildClickableArtistRow(context, ref),
          
          _buildDetailRow("Seltenheit", card.rarity),
          _buildDetailRow("Nummer", "${card.number} / ${card.setPrintedTotal ?? '?'}"),
          _buildDetailRow("Typen", card.types.join(", ")),
        ],
      ),
    );
  }

  // Die neue klickbare Zeile
  Widget _buildClickableArtistRow(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 100, child: Text("Künstler", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(
            child: InkWell(
              // Wenn man draufklickt:
              onTap: () {
                // 1. Modus auf Künstler setzen
                ref.read(searchModeProvider.notifier).state = SearchMode.artist;
                
                // 2. Suchtext setzen
                ref.read(searchQueryProvider.notifier).state = card.artist;

                // 3. Zur Suche springen
                // Wir pushen einfach den SearchScreen oben drauf, dann kann man "Zurück" zur Karte
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CardSearchScreen()),
                );
              },
              child: Row(
                children: [
                  Text(
                    card.artist,
                    style: const TextStyle(
                      color: Colors.blue, // Blau damit es wie ein Link aussieht
                      decoration: TextDecoration.underline, // Unterstrichen
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.search, size: 14, color: Colors.blue), // Kleines Icon
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

  // --- FULLSCREEN LOGIK ---
  void _openFullscreenImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer( // Erlaubt Zoomen mit zwei Fingern
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: card.largeImageUrl ?? card.smallImageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- URL LAUNCHER LOGIK ---
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}