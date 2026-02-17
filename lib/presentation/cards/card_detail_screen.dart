import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drift/drift.dart' as drift; 

import '../../data/api/search_provider.dart';
import '../../data/api/tcgdex_api_client.dart';
import '../../data/database/app_database.dart'; 
import '../../data/database/database_provider.dart';
import '../../data/sync/set_importer.dart';
import '../../domain/logic/binder_service.dart';
import '../../domain/models/api_card.dart';
import '../../domain/models/api_set.dart';
import '../inventory/inventory_bottom_sheet.dart'; 
import '../search/card_search_screen.dart';
import '../sets/set_detail_screen.dart';
import 'price_history_chart.dart'; 

// --- PROVIDER ---

// 1. Live-Provider für das Inventar dieser Karte
final cardInventoryProvider = StreamProvider.family<List<UserCard>, String>((ref, cardId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.userCards)..where((tbl) => tbl.cardId.equals(cardId))).watch();
});

// 2. NEU: Provider für die Binder-Standorte (damit es sich automatisch aktualisiert!)
final cardBindersProvider = FutureProvider.family<List<String>, String>((ref, cardId) async {
  final db = ref.watch(databaseProvider);
  return BinderService(db).getBindersForCard(cardId);
});

class CardDetailScreen extends ConsumerWidget {
  final ApiCard card;

  const CardDetailScreen({super.key, required this.card});

  // --- ZENTRALE REFRESH METHODE ---
  void _refreshAllProviders(WidgetRef ref) {
    ref.invalidate(searchResultsProvider);
    ref.invalidate(cardsForSetProvider(card.setId));
    ref.invalidate(setStatsProvider(card.setId));
    ref.invalidate(inventoryProvider);
    ref.invalidate(cardBindersProvider(card.id)); // WICHTIG: Binder Infos neu laden!
    createPortfolioSnapshot(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setAsync = ref.watch(setByIdProvider(card.setId));
    final inventoryAsync = ref.watch(cardInventoryProvider(card.id));
    final historyAsync = ref.watch(cardPriceHistoryProvider(card.id));
    final displayImage = card.displayImage;

    return Scaffold(
      appBar: AppBar(
        title: Text(card.nameDe ?? card.name, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: "Daten & Preise aktualisieren",
            onPressed: () => _updateCardData(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => InventoryBottomSheet(card: card),
          ).then((_) {
            _refreshAllProviders(ref);
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
              onTap: () => _openFullscreenImage(context, displayImage),
              child: Hero(
                tag: card.id,
                child: Container(
                  height: 350, 
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
                    imageUrl: displayImage,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, dynamic error) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // 3. INVENTAR
            inventoryAsync.when(
              data: (items) => _buildInventorySection(context, ref, items),
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => Text("Fehler: $err"),
            ),

            // 4. BINDER STANDORT (Jetzt Live-Aktualisiert!)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: BinderLocationWidget(cardId: card.id),
            ),

            const SizedBox(height: 20),

            // 5. EXTERNE LINKS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  if (card.cardmarket?.url.isNotEmpty == true)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _launchURL(card.cardmarket!.url),
                        icon: const Icon(Icons.shopping_cart, size: 18),
                        label: const Text("Cardmarket"),
                        style: FilledButton.styleFrom(backgroundColor: Colors.blue[800]),
                      ),
                    ),
                  if (card.cardmarket?.url.isNotEmpty == true && card.tcgplayer?.url.isNotEmpty == true)
                    const SizedBox(width: 10),
                  if (card.tcgplayer?.url.isNotEmpty == true)
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

            const SizedBox(height: 30),

            // 6. PREISVERLAUF
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Preisverlauf", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  const Text("Historische Preisentwicklung (Quelle: TCGdex)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    height: 320, 
                    child: historyAsync.when(
                      data: (data) => PriceHistoryChart(
                        cmHistory: (data['cm'] as List).cast<CardMarketPrice>(),
                        tcgHistory: (data['tcg'] as List).cast<TcgPlayerPrice>(),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Center(child: Text("Konnte Verlauf nicht laden: $e")),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 7. PREIS TABELLEN
            if (card.cardmarket != null) _buildCardmarketSection(context, card.cardmarket!),
            if (card.tcgplayer != null) _buildTcgPlayerSection(context, card.tcgplayer!),

            const SizedBox(height: 20),

            // 8. DETAILS
            _buildInfoSection(context, ref),
            
            const SizedBox(height: 80), 
          ],
        ),
      ),
    );
  }

  // --- LOGIK & HELPER ---

  Future<void> _decreaseOrDeleteItem(BuildContext context, WidgetRef ref, UserCard item) async {
    final db = ref.read(databaseProvider);
    final binderService = BinderService(db);
    bool shouldDelete = false;

    try {
      // A) Abfrage: Wirklich löschen?
      if (item.quantity == 1) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Entfernen?"),
            content: Text("Möchtest du ${item.variant} aus deiner Sammlung löschen?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Abbrechen")),
              TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text("Löschen")),
            ],
          ),
        );
        if (confirm != true) return;
        shouldDelete = true;
      }

      // B) BINDER CHECK
      final allEntries = await (db.select(db.userCards)..where((t) => t.cardId.equals(item.cardId))).get();
      final int totalOwned = allEntries.fold(0, (sum, e) => sum + e.quantity);

      final usedSlotsQuery = db.select(db.binderCards).join([
        drift.innerJoin(db.binders, db.binders.id.equalsExp(db.binderCards.binderId))
      ]);
      usedSlotsQuery.where(db.binderCards.cardId.equals(item.cardId) & db.binderCards.isPlaceholder.equals(false));
      
      final usedRows = await usedSlotsQuery.get();
      final usedSlots = usedRows.map((r) => _BinderSlotInfo(
        r.readTable(db.binderCards).id, 
        r.readTable(db.binders).name
      )).toList();

      // Wenn wir weniger Karten haben als wir benutzen -> Konflikt
      if ((totalOwned - 1) < usedSlots.length) {
        int? slotToRemoveId;

        if (usedSlots.length == 1) {
          // Automatisch entfernen, wenn nur in einem Binder
          slotToRemoveId = usedSlots.first.id;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Auch aus Binder '${usedSlots.first.binderName}' entfernt."),
              duration: const Duration(seconds: 2),
            ));
          }
        } else if (usedSlots.length > 1) {
          // Dialog anzeigen
          if (context.mounted) {
            slotToRemoveId = await _showBinderSelectionDialog(context, usedSlots);
            // Wenn User abbricht (null), brechen wir alles ab!
            if (slotToRemoveId == null) return; 
          }
        }

        if (slotToRemoveId != null) {
          await binderService.clearSlot(slotToRemoveId);
        }
      }

      // C) DATENBANK UPDATE
      if (shouldDelete) {
        await (db.delete(db.userCards)..where((t) => t.id.equals(item.id))).go();
      } else {
        await (db.update(db.userCards)..where((t) => t.id.equals(item.id)))
            .write(UserCardsCompanion(quantity: drift.Value(item.quantity - 1)));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("-1"), duration: Duration(milliseconds: 500)));
        }
      }

      // D) UI AKTUALISIEREN
      _refreshAllProviders(ref);

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fehler: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<int?> _showBinderSelectionDialog(BuildContext context, List<_BinderSlotInfo> slots) {
    return showDialog<int>(
      context: context,
      barrierDismissible: false, 
      builder: (ctx) => SimpleDialog(
        title: const Text("Binder Konflikt"),
        contentPadding: const EdgeInsets.all(20),
        children: [
          const Text("Du entfernst eine Karte, die in mehreren Bindern verwendet wird.\n\nBitte wähle, aus welchem Binder sie entfernt werden soll:"),
          const SizedBox(height: 20),
          
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: slots.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final slot = slots[i];
                return SimpleDialogOption(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  onPressed: () => Navigator.pop(ctx, slot.id), 
                  child: Row(
                    children: [
                      const Icon(Icons.book, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(slot.binderName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
          
          TextButton(
            onPressed: () => Navigator.pop(ctx, null), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Abbrechen (Karte behalten)"),
          ),
        ],
      ),
    );
  }

  // --- STANDARD WIDGETS (Unverändert) ---

  Widget _buildCardmarketSection(BuildContext context, ApiCardMarket cm) {
    return _buildPriceSectionContainer(
      context,
      title: "Cardmarket (Europa)",
      color: Colors.blue[800]!,
      lastUpdate: cm.updatedAt,
      children: [
        if (cm.trendPrice != null && cm.trendPrice! > 0) _priceRow("Trend (Normal)", cm.trendPrice!),
        if (cm.trendHolo != null && cm.trendHolo! > 0) _priceRow("Trend (Holo)", cm.trendHolo!),
        if (cm.reverseHoloTrend != null && cm.reverseHoloTrend! > 0) _priceRow("Trend (Reverse)", cm.reverseHoloTrend!),
        const Divider(),
        if (cm.avg30 != null && cm.avg30! > 0) _priceRow("Ø 30 Tage", cm.avg30!),
        if (cm.avg7 != null && cm.avg7! > 0) _priceRow("Ø 7 Tage", cm.avg7!),
        if (cm.lowPrice != null && cm.lowPrice! > 0) _priceRow("Ab (Low)", cm.lowPrice!, isLow: true),
      ],
    );
  }

  Widget _buildTcgPlayerSection(BuildContext context, ApiTcgPlayer tcg) {
    return _buildPriceSectionContainer(
      context,
      title: "TCGPlayer (USA)",
      color: Colors.teal[700]!,
      lastUpdate: tcg.updatedAt,
      children: [
        if (tcg.prices?.normal?.market != null && tcg.prices!.normal!.market! > 0) 
           _priceRow("Market (Normal)", tcg.prices!.normal!.market!),
        if (tcg.prices?.holofoil?.market != null && tcg.prices!.holofoil!.market! > 0) 
           _priceRow("Market (Holo)", tcg.prices!.holofoil!.market!),
        if (tcg.prices?.reverseHolofoil?.market != null && tcg.prices!.reverseHolofoil!.market! > 0) 
           _priceRow("Market (Reverse)", tcg.prices!.reverseHolofoil!.market!),
        const Divider(),
        if (tcg.prices?.normal?.mid != null && tcg.prices!.normal!.mid! > 0) 
           _priceRow("Mid Price", tcg.prices!.normal!.mid!),
        if (tcg.prices?.normal?.directLow != null && tcg.prices!.normal!.directLow! > 0) 
           _priceRow("Direct Low", tcg.prices!.normal!.directLow!, isLow: true),
      ],
    );
  }

  Widget _buildPriceSectionContainer(BuildContext context, {required String title, required Color color, required String lastUpdate, required List<Widget> children}) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
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
                  if (lastUpdate.isNotEmpty) 
                    Text(lastUpdate.split('T')[0], style: TextStyle(color: color.withOpacity(0.6), fontSize: 10)),
                ],
              ),
            ),
            ...children
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, double price, {bool isLow = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text("${price.toStringAsFixed(2)} €", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isLow ? Colors.green[700] : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildInventorySection(BuildContext context, WidgetRef ref, List<UserCard> items) {
    if (items.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: const Center(child: Text("Nicht in deiner Sammlung", style: TextStyle(color: Colors.grey))),
      );
    }
    final totalCount = items.fold(0, (sum, item) => sum + item.quantity);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("In deinem Besitz: $totalCount Stück", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
          const Divider(),
          ...items.map((item) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text("${item.quantity}x ${item.variant}", style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text("${item.condition} • ${item.language}"),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _decreaseOrDeleteItem(context, ref, item),
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _updateCardData(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final dexApi = ref.read(tcgDexApiClientProvider);
    final importer = SetImporter(dexApi, db);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aktualisiere Daten...')));

    try {
      await importer.importCardsForSet(card.setId);
      _refreshAllProviders(ref);
      ref.invalidate(cardPriceHistoryProvider(card.id));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Aktualisiert!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildSetHeader(BuildContext context, ApiSet? set) {
    if (set == null) return const SizedBox.shrink();
    final logo = set.logoUrlDe ?? set.logoUrl;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SetDetailScreen(set: set))),
      child: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.grey[100],
        child: Row(
          children: [
            if (logo != null) SizedBox(
              height: 40, width: 80, 
              child: CachedNetworkImage(
                imageUrl: logo, 
                fit: BoxFit.contain,
                errorWidget: (context, url, dynamic error) => const Icon(Icons.broken_image, size: 20, color: Colors.grey),
              )
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(set.nameDe ?? set.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Set anzeigen (${set.printedTotal} Karten)", style: TextStyle(color: Colors.blue[700], fontSize: 12)),
                ],
              ),
            ),
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
          _buildDetailRow("Nummer", "${card.number} / ${card.setPrintedTotal}"),
          if (card.flavorTextDe != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(card.flavorTextDe!, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildClickableArtistRow(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const SizedBox(width: 100, child: Text("Künstler", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
        Expanded(
          child: InkWell(
            onTap: () {
              ref.read(searchModeProvider.notifier).state = SearchMode.artist;
              ref.read(searchQueryProvider.notifier).state = card.artist;
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CardSearchScreen()));
            },
            child: Text(card.artist, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _openFullscreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(child: InteractiveViewer(
        child: CachedNetworkImage(
          imageUrl: imageUrl, 
          fit: BoxFit.contain,
          errorWidget: (context, url, dynamic error) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
        )
      )),
    )));
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) throw 'Could not launch $url';
  }
}

// --- WIDGET FÜR BINDER LOCATION (Jetzt mit Provider) ---
class BinderLocationWidget extends ConsumerWidget {
  final String cardId;
  const BinderLocationWidget({required this.cardId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bindersAsync = ref.watch(cardBindersProvider(cardId));
    
    return bindersAsync.when(
      data: (binders) {
        if (binders.isEmpty) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enthalten in Bindern:", 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: binders.map((name) => Chip(
                  label: Text(name),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.orange[100]!),
                  avatar: const Icon(Icons.book, size: 16, color: Colors.orange),
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_,__) => const SizedBox.shrink(),
    );
  }
}

class _BinderSlotInfo {
  final int id;
  final String binderName;
  _BinderSlotInfo(this.id, this.binderName);
}