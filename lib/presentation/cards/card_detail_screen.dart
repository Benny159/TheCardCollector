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

final cardInventoryProvider = StreamProvider.family<List<UserCard>, String>((ref, cardId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.userCards)..where((tbl) => tbl.cardId.equals(cardId))).watch();
});

// Wir nutzen FutureProvider in Kombination mit dem "Force Refresh" Key Trick
final cardBindersProvider = FutureProvider.family<List<String>, String>((ref, cardId) async {
  final db = ref.watch(databaseProvider);
  // Hole die Binder, in denen die Karte ECHT drin steckt (kein Platzhalter)
  return BinderService(db).getBindersForCard(cardId);
});

// --- SCREEN (Jetzt Stateful für den Refresh-Trick) ---

class CardDetailScreen extends ConsumerStatefulWidget {
  final ApiCard card;
  const CardDetailScreen({super.key, required this.card});

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  // Der Trick aus dem Binder Screen: Ein Zähler, der das Neuladen erzwingt
  int _refreshId = 0;

  // --- DIE "HOLZHAMMER" REFRESH METHODE ---
  Future<void> _forceRefresh() async {
    // 1. Kurz warten (Datenbank Zeit geben)
    await Future.delayed(const Duration(milliseconds: 300));

    // 2. Provider Cache leeren
    ref.invalidate(cardBindersProvider(widget.card.id));
    ref.invalidate(searchResultsProvider);
    ref.invalidate(cardsForSetProvider(widget.card.setId));
    ref.invalidate(setStatsProvider(widget.card.setId));
    ref.invalidate(inventoryProvider); 
    createPortfolioSnapshot(ref);

    // 3. UI neu bauen lassen (Binder Widget wird zerstört und neu erstellt)
    if (mounted) {
      setState(() {
        _refreshId++; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final setAsync = ref.watch(setByIdProvider(widget.card.setId));
    final inventoryAsync = ref.watch(cardInventoryProvider(widget.card.id));
    final historyAsync = ref.watch(cardPriceHistoryProvider(widget.card.id));
    final displayImage = widget.card.displayImage;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card.nameDe ?? widget.card.name, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => _updateCardData(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => InventoryBottomSheet(card: widget.card),
          ).then((_) {
            _forceRefresh();
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
            setAsync.when(
              data: (set) => _buildSetHeader(context, set),
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 10),

            // Bild
            GestureDetector(
              onTap: () => _openFullscreenImage(context, displayImage),
              child: Hero(
                tag: widget.card.id,
                child: Container(
                  height: 350, 
                  decoration: BoxDecoration(
                    boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(0, 10))],
                  ),
                  child: CachedNetworkImage(
                    imageUrl: displayImage,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // Inventar
            inventoryAsync.when(
              data: (items) => _buildInventorySection(context, ref, items),
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => Text("Fehler: $err"),
            ),

            // --- BINDER STANDORT ---
            // HIER IST DER TRICK: Der Key ändert sich bei jedem Refresh -> Widget lädt neu!
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: BinderLocationWidget(
                key: ValueKey(_refreshId), // <--- DAS IST DIE MAGIE
                cardId: widget.card.id
              ),
            ),

            const SizedBox(height: 20),
            _buildLinksSection(),
            const SizedBox(height: 30),
            _buildChartSection(historyAsync),
            const SizedBox(height: 30),
            if (widget.card.cardmarket != null) _buildCardmarketSection(context, widget.card.cardmarket!),
            if (widget.card.tcgplayer != null) _buildTcgPlayerSection(context, widget.card.tcgplayer!),
            const SizedBox(height: 20),
            _buildInfoSection(context, ref),
            const SizedBox(height: 80), 
          ],
        ),
      ),
    );
  }

  // --- LOGIK: LÖSCHEN & KONFLIKT ---

  Future<void> _decreaseOrDeleteItem(BuildContext context, WidgetRef ref, UserCard item) async {
    final db = ref.read(databaseProvider);
    final binderService = BinderService(db);
    bool shouldDelete = false;

    try {
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

      // Warten damit Dialog sicher zu ist
      await Future.delayed(const Duration(milliseconds: 150));

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

      if ((totalOwned - 1) < usedSlots.length) {
        int? slotToRemoveId;

        if (usedSlots.length == 1) {
          slotToRemoveId = usedSlots.first.id;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Auch aus Binder '${usedSlots.first.binderName}' entfernt."),
              duration: const Duration(seconds: 2),
            ));
          }
        } else if (usedSlots.length > 1) {
          if (context.mounted) {
            slotToRemoveId = await _showBinderSelectionDialog(context, usedSlots);
            if (slotToRemoveId == null) return; 
          }
        }

        if (slotToRemoveId != null) {
          await binderService.clearSlot(slotToRemoveId);
        }
      }

      if (shouldDelete) {
        await (db.delete(db.userCards)..where((t) => t.id.equals(item.id))).go();
      } else {
        await (db.update(db.userCards)..where((t) => t.id.equals(item.id)))
            .write(UserCardsCompanion(quantity: drift.Value(item.quantity - 1)));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("-1"), duration: Duration(milliseconds: 500)));
        }
      }

      // --- DER REFRESH AUFRUF ---
      await _forceRefresh();

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fehler: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // --- SICHERER DIALOG (Kein Absturz mehr) ---
  Future<int?> _showBinderSelectionDialog(BuildContext context, List<_BinderSlotInfo> slots) {
    return showDialog<int>(
      context: context,
      barrierDismissible: false, 
      builder: (ctx) => AlertDialog(
        title: const Text("Binder Konflikt"),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Diese Karte ist mehrfach in Bindern. Wähle, wo sie entfernt werden soll:"),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true, // Wichtig!
                  itemCount: slots.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final slot = slots[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.book, color: Colors.blue),
                      title: Text(slot.binderName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () => Navigator.pop(ctx, slot.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Abbrechen"),
          ),
        ],
      ),
    );
  }

  // --- HELPER & WIDGETS ---

  Widget _buildLinksSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          if (widget.card.cardmarket?.url.isNotEmpty == true)
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _launchURL(widget.card.cardmarket!.url),
                icon: const Icon(Icons.shopping_cart, size: 18),
                label: const Text("Cardmarket"),
                style: FilledButton.styleFrom(backgroundColor: Colors.blue[800]),
              ),
            ),
          if (widget.card.cardmarket?.url.isNotEmpty == true && widget.card.tcgplayer?.url.isNotEmpty == true)
            const SizedBox(width: 10),
          if (widget.card.tcgplayer?.url.isNotEmpty == true)
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _launchURL(widget.card.tcgplayer!.url),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text("TCGPlayer"),
                style: FilledButton.styleFrom(backgroundColor: Colors.teal[700]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartSection(AsyncValue historyAsync) {
    return Padding(
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
              error: (e, s) => Center(child: Text("Verlauf nicht verfügbar")),
            ),
          ),
        ],
      ),
    );
  }

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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withOpacity(0.2))),
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
                  if (lastUpdate.isNotEmpty) Text(lastUpdate.split('T')[0], style: TextStyle(color: color.withOpacity(0.6), fontSize: 10)),
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
      await importer.importCardsForSet(widget.card.setId);
      _forceRefresh();
      ref.invalidate(cardPriceHistoryProvider(widget.card.id));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Aktualisiert!'), backgroundColor: Colors.green));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red));
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
            if (logo != null) SizedBox(height: 40, width: 80, child: CachedNetworkImage(imageUrl: logo, fit: BoxFit.contain, errorWidget: (_,__,___) => const Icon(Icons.broken_image, size: 20))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(set.nameDe ?? set.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Set anzeigen (${set.printedTotal} Karten)", style: TextStyle(color: Colors.blue[700], fontSize: 12)),
            ])),
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
          _buildDetailRow("Seltenheit", widget.card.rarity),
          _buildDetailRow("Nummer", "${widget.card.number} / ${widget.card.setPrintedTotal}"),
          if (widget.card.flavorTextDe != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(widget.card.flavorTextDe!, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildClickableArtistRow(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const SizedBox(width: 100, child: Text("Künstler", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
        Expanded(child: InkWell(
          onTap: () {
            ref.read(searchModeProvider.notifier).state = SearchMode.artist;
            ref.read(searchQueryProvider.notifier).state = widget.card.artist;
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CardSearchScreen()));
          },
          child: Text(widget.card.artist, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
        )),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))), Expanded(child: Text(value))]));
  }

  void _openFullscreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)), body: Center(child: InteractiveViewer(child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain, errorWidget: (_,__,___) => const Icon(Icons.broken_image, size: 50, color: Colors.grey)))))));
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) throw 'Could not launch $url';
  }
}

// --- WIDGET FÜR BINDER LOCATION ---
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
          decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange[200]!)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Enthalten in Bindern:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
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