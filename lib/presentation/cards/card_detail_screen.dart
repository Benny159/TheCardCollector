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
import '../inventory/assign_to_binder_sheet.dart';
import 'price_history_chart.dart'; 

// --- PROVIDER ---

final cardInventoryProvider = StreamProvider.family<List<UserCard>, String>((ref, cardId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.userCards)..where((tbl) => tbl.cardId.equals(cardId))).watch();
});

final cardBindersProvider = StreamProvider.family<List<String>, String>((ref, cardId) {
  final db = ref.watch(databaseProvider);
  
  final query = db.select(db.binderCards).join([
    drift.innerJoin(db.binders, db.binders.id.equalsExp(db.binderCards.binderId))
  ]);
  
  query.where(db.binderCards.cardId.equals(cardId) & db.binderCards.isPlaceholder.equals(false));
  
  return query.watch().map((rows) {
    if (rows.isEmpty) return [];
    return rows.map((r) => r.readTable(db.binders).name).toSet().toList();
  });
});

// --- SCREEN ---

class CardDetailScreen extends ConsumerStatefulWidget {
  final ApiCard card;
  const CardDetailScreen({super.key, required this.card});

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  int _refreshId = 0;
  
  // --- NEU: Lokale Variablen für sofortiges UI Update ---
  late String _currentPreferredSource;
  late TextEditingController _customPriceController;
  double? _currentCustomPrice;

  @override
  void initState() {
    super.initState();
    _currentPreferredSource = widget.card.preferredPriceSource;
    _currentCustomPrice = widget.card.customPrice; // Holt den anfänglichen Preis
    _customPriceController = TextEditingController();
  }

  @override
  void dispose() {
    _customPriceController.dispose();
    super.dispose();
  }

  Future<void> _forceRefresh() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // --- SICHERHEITS-CHECK ---
    if (!mounted) return;

    ref.invalidate(cardBindersProvider(widget.card.id));
    ref.invalidate(searchResultsProvider);
    ref.invalidate(cardsForSetProvider(widget.card.setId));
    ref.invalidate(setStatsProvider(widget.card.setId));
    ref.invalidate(inventoryProvider); 
    createPortfolioSnapshot(ref);

    setState(() {
      _refreshId++; 
    });
  }

  // --- NEU: Aktualisiert Quelle UND rechnet alle Binder neu durch! ---
  Future<void> _updatePreferredSource(String source) async {
    setState(() => _currentPreferredSource = source);
    final dbInst = ref.read(databaseProvider);
    
    // 1. In Datenbank speichern
    await (dbInst.update(dbInst.cards)..where((t) => t.id.equals(widget.card.id)))
        .write(CardsCompanion(preferredPriceSource: drift.Value(source)));
    
    // 2. WICHTIG: Alle Binder-Werte neu berechnen!
    await BinderService(dbInst).recalculateAllBinders();
    
    // --- SICHERHEITS-CHECK ---
    if (!mounted) return;
    
    // 3. Provider aktualisieren
    ref.invalidate(cardPriceHistoryProvider(widget.card.id));
    ref.invalidate(searchResultsProvider);
    ref.invalidate(inventoryProvider);
    ref.invalidate(cardsForSetProvider(widget.card.setId));
    createPortfolioSnapshot(ref); 
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preisquelle für Berechnungen aktualisiert!"), duration: Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final setAsync = ref.watch(setByIdProvider(widget.card.setId));
    final inventoryAsync = ref.watch(cardInventoryProvider(widget.card.id));
    final historyAsync = ref.watch(cardPriceHistoryProvider(widget.card.id));
    final displayImage = widget.card.displayImage;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.card.nameDe ?? widget.card.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.blue),
            onPressed: () => _updateCardData(context, ref),
            tooltip: "Preisdaten aktualisieren",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => InventoryBottomSheet(card: widget.card),
          ).then((_) => _forceRefresh());
        },
        icon: const Icon(Icons.add_card),
        label: const Text("Hinzufügen", style: TextStyle(fontWeight: FontWeight.bold)),
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
            
            // 2. OBERER BEREICH: Karte & Tabellen (Side-by-Side)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // --- LINKE SPALTE (Karte, Tags & Links) ---
                  Expanded(
                    flex: 4, 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Bild
                        GestureDetector(
                          onTap: () => _openFullscreenImage(context, displayImage),
                          child: Hero(
                            tag: widget.card.id,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: displayImage,
                                  fit: BoxFit.contain,
                                  placeholder: (_, __) => const AspectRatio(aspectRatio: 0.7, child: Center(child: CircularProgressIndicator())),
                                  errorWidget: (_, __, ___) => const AspectRatio(aspectRatio: 0.7, child: Icon(Icons.broken_image, color: Colors.grey)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Info-Tags unter dem Bild
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            if (widget.card.artist.isNotEmpty)
                              _buildTag(Icons.brush, widget.card.artist, color: Colors.blue, onTap: () {
                                ref.read(searchModeProvider.notifier).state = SearchMode.artist;
                                ref.read(searchQueryProvider.notifier).state = widget.card.artist;
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const CardSearchScreen()));
                              }),
                            if (widget.card.rarity.isNotEmpty)
                              _buildTag(Icons.star, widget.card.rarity, color: Colors.orange[800]),
                            if (widget.card.number.isNotEmpty)
                              _buildTag(Icons.numbers, "${widget.card.number} / ${widget.card.setPrintedTotal}", color: Colors.purple),
                          ],
                        ),

                        // Flavor Text
                        if (widget.card.flavorTextDe != null) 
                          Padding(
                            padding: const EdgeInsets.only(top: 10), 
                            child: Text(
                              '"${widget.card.flavorTextDe!}"', 
                              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 10),
                              textAlign: TextAlign.center,
                            )
                          ),

                        // Shop Links kompakt nebeneinander
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (widget.card.cardmarket?.url.isNotEmpty == true)
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _launchURL(widget.card.cardmarket!.url),
                                  icon: const Icon(Icons.shopping_cart, size: 12),
                                  label: const Text("CM", style: TextStyle(fontSize: 10)),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.blue[800],
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 32),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 6),
                            if (widget.card.tcgplayer?.url.isNotEmpty == true)
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _launchURL(widget.card.tcgplayer!.url),
                                  icon: const Icon(Icons.open_in_new, size: 12),
                                  label: const Text("TCG", style: TextStyle(fontSize: 10)),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.teal[700],
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 32),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // --- RECHTE SPALTE (Preis-Tabellen & Besitz) ---
                  Expanded(
                    flex: 5, 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        // 1. EIGENER PREIS TABELLE
                        _buildCustomPriceSection(),

                        // 2. CARDMARKET TABELLE
                        if (widget.card.cardmarket != null) 
                          _buildCardmarketSection(context, widget.card.cardmarket!),
                        
                        // 3. TCGPLAYER TABELLE
                        if (widget.card.tcgplayer != null) 
                          _buildTcgPlayerSection(context, widget.card.tcgplayer!),
                        
                        // 4. BESITZ BOX
                        inventoryAsync.when(
                          data: (items) => _buildCollectionBox(context, ref, items),
                          loading: () => const SizedBox.shrink(),
                          error: (err, stack) => Text("Fehler: $err", style: const TextStyle(fontSize: 10)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // 3. CHART BEREICH (Unten, Volle Breite)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: _buildChartSection(historyAsync),
            ),

            const SizedBox(height: 80), 
          ],
        ),
      ),
    );
  }

  // --- WIDGETS FÜR DAS DASHBOARD ---

  Widget _buildTag(IconData icon, String text, {Color? color, VoidCallback? onTap}) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: (color ?? Colors.grey).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color ?? Colors.grey[700]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 9, color: color ?? Colors.grey[800], fontWeight: FontWeight.bold)),
        ],
      ),
    );

    if (onTap != null) return GestureDetector(onTap: onTap, child: content);
    return content;
  }

  Widget _buildChartSection(AsyncValue historyAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("Preisverlauf", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text("Alle Quellen", style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: historyAsync.when(
            data: (data) => PriceHistoryChart(
              cmHistory: (data['cm'] as List).cast<CardMarketPrice>(),
              tcgHistory: (data['tcg'] as List).cast<TcgPlayerPrice>(),
              customHistory: (data['custom'] as List).cast<CustomCardPrice>(),
            ),
            loading: () => const SizedBox(height: 250, child: Center(child: CircularProgressIndicator())),
            error: (e, s) => const SizedBox(height: 250, child: Center(child: Text("Verlauf nicht verfügbar", style: TextStyle(fontSize: 10)))),
          ),
        ),
      ],
    );
  }

  // --- DIE PREIS TABELLEN ---

  Widget _buildPriceSectionContainer(BuildContext context, {required String title, required Color color, required String sourceKey, String? lastUpdate, required List<Widget> children}) {
    if (children.isEmpty) return const SizedBox.shrink();
    
    final bool isSelected = _currentPreferredSource == sourceKey;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(10), 
        border: Border.all(color: isSelected ? color : color.withOpacity(0.3), width: isSelected ? 2.0 : 1.0),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Header mit Klick-Funktion, um es auszuwählen
          GestureDetector(
            onTap: () => _updatePreferredSource(sourceKey),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(color: color.withOpacity(isSelected ? 0.2 : 0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
              child: Row(
                children: [
                  Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: color, size: 14),
                  const SizedBox(width: 6),
                  Expanded(child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11))),
                  if (lastUpdate != null && lastUpdate.isNotEmpty) 
                    Text(lastUpdate.split('T')[0], style: TextStyle(color: color.withOpacity(0.6), fontSize: 9)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: children),
          )
        ],
      ),
    );
  }

  Widget _priceRow(String label, double price, {bool isLow = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 10)),
          Text("${price.toStringAsFixed(2)} €", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isLow ? Colors.green[700] : Colors.black)),
        ],
      ),
    );
  }

  // --- DIE NEUE CUSTOM PREIS TABELLE ---
  Widget _buildCustomPriceSection() {
    return _buildPriceSectionContainer(
      context, 
      title: "Eigener Preis", 
      color: Colors.amber[800]!, 
      sourceKey: 'custom',
      children: [
        // Wir nutzen hier die lokale Variable, damit das UI SOFORT updatet!
        if (_currentCustomPrice != null && _currentCustomPrice! > 0)
           _priceRow("Aktueller Wert", _currentCustomPrice!),
        
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    controller: _customPriceController, // <-- Controller verbunden!
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 11),
                    decoration: InputDecoration(
                      hintText: "Neuer Preis (€)...",
                      hintStyle: const TextStyle(fontSize: 10),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (val) => _saveCustomPrice(val, ref),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // --- SPEICHERN BUTTON FÜRS HANDY ---
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber[800],
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                ),
                onPressed: () => _saveCustomPrice(_customPriceController.text, ref),
                child: const Text("Speichern", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardmarketSection(BuildContext context, ApiCardMarket cm) {
    return _buildPriceSectionContainer(
      context, title: "Cardmarket (EU)", color: Colors.blue[800]!, sourceKey: 'cardmarket', lastUpdate: cm.updatedAt,
      children: [
        if (cm.trendPrice != null && cm.trendPrice! > 0) _priceRow("Trend (Normal)", cm.trendPrice!),
        if (cm.trendHolo != null && cm.trendHolo! > 0) _priceRow("Trend (Holo)", cm.trendHolo!),
        if (cm.reverseHoloTrend != null && cm.reverseHoloTrend! > 0) _priceRow("Trend (Reverse)", cm.reverseHoloTrend!),
        const Divider(height: 8, thickness: 0.5),
        if (cm.avg30 != null && cm.avg30! > 0) _priceRow("Ø 30 Tage", cm.avg30!),
        if (cm.lowPrice != null && cm.lowPrice! > 0) _priceRow("Ab (Low)", cm.lowPrice!, isLow: true),
      ],
    );
  }

  Widget _buildTcgPlayerSection(BuildContext context, ApiTcgPlayer tcg) {
    return _buildPriceSectionContainer(
      context, title: "TCGPlayer (US)", color: Colors.teal[700]!, sourceKey: 'tcgplayer', lastUpdate: tcg.updatedAt,
      children: [
        if (tcg.prices?.normal?.market != null && tcg.prices!.normal!.market! > 0) _priceRow("Market (Normal)", tcg.prices!.normal!.market!),
        if (tcg.prices?.holofoil?.market != null && tcg.prices!.holofoil!.market! > 0) _priceRow("Market (Holo)", tcg.prices!.holofoil!.market!),
        if (tcg.prices?.reverseHolofoil?.market != null && tcg.prices!.reverseHolofoil!.market! > 0) _priceRow("Market (Reverse)", tcg.prices!.reverseHolofoil!.market!),
        const Divider(height: 8, thickness: 0.5),
        if (tcg.prices?.normal?.directLow != null && tcg.prices!.normal!.directLow! > 0) _priceRow("Direct Low", tcg.prices!.normal!.directLow!, isLow: true),
      ],
    );
  }

  // --- SET HEADER ---

  Widget _buildSetHeader(BuildContext context, ApiSet? set) {
    if (set == null) return const SizedBox.shrink();
    final logo = set.logoUrlDe ?? set.logoUrl;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SetDetailScreen(set: set))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
        child: Row(
          children: [
            if (logo != null) SizedBox(height: 35, width: 70, child: CachedNetworkImage(imageUrl: logo, fit: BoxFit.contain, errorWidget: (_,__,___) => const Icon(Icons.broken_image, size: 20))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(set.nameDe ?? set.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text("Set anzeigen (${set.printedTotal} Karten)", style: TextStyle(color: Colors.blue[700], fontSize: 11)),
            ])),
            const Icon(Icons.chevron_right, color: Colors.grey)
          ],
        ),
      ),
    );
  }

  // --- NEU: EIGENER PREIS SPEICHER LOGIK ---
Future<void> _saveCustomPrice(String value, WidgetRef ref) async {
    if (value.isEmpty) return;
    
    final double? parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed != null && parsed >= 0) {
      final dbInst = ref.read(databaseProvider);
      
      // 1. Neuen Preis in die Historie einfügen
      await dbInst.into(dbInst.customCardPrices).insert(
        CustomCardPricesCompanion.insert(
          cardId: widget.card.id,
          fetchedAt: DateTime.now(),
          price: parsed,
        )
      );

      // 2. DAS IST DER FIX: Ein Update auf der Haupt-Karte erzwingen!
      // Das teilt der Datenbank und allen Riverpod-Streams mit, dass sich die Karte 
      // geändert hat. Die vorherige Seite lädt dadurch neu und reicht beim 
      // nächsten Klick die aktuellen Daten rein.
      await (dbInst.update(dbInst.cards)..where((t) => t.id.equals(widget.card.id)))
          .write(const CardsCompanion(preferredPriceSource: drift.Value('custom')));

      setState(() {
        _currentCustomPrice = parsed;
        _currentPreferredSource = 'custom';
      });
      _customPriceController.clear();
      FocusScope.of(context).unfocus(); 
      
      // 3. Binder Werte anpassen
      await BinderService(dbInst).recalculateAllBinders();
      
      // --- SICHERHEITS-CHECK ---
      if (!mounted) return;
      
      // 4. Das zwingt das Diagramm sich exakt JETZT neu zu zeichnen
      ref.invalidate(cardPriceHistoryProvider(widget.card.id));
      
      ref.invalidate(searchResultsProvider);
      ref.invalidate(cardsForSetProvider(widget.card.setId));
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Eigener Preis gespeichert!")));
    }
  }

  // --- DIE SAMMLUNGS-BOX ---

  Widget _buildCollectionBox(BuildContext context, WidgetRef ref, List<UserCard> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)),
        child: const Center(child: Text("Nicht in Sammlung", style: TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center)),
      );
    }
    
    final totalCount = items.fold(0, (sum, item) => sum + item.quantity);
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(10), 
        border: Border.all(color: Colors.green.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_rounded, color: Colors.green, size: 14),
                    const SizedBox(width: 4),
                    Expanded(child: Text("Besitz: $totalCount", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              if (widget.card.isOwned)
                Tooltip(
                  message: "In Binder einsortieren",
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => AssignToBinderSheet(card: widget.card),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6)
                      ),
                      child: const Icon(Icons.move_to_inbox, size: 14, color: Colors.blueGrey),
                    ),
                  ),
                ),
            ],
          ),
          const Divider(color: Colors.black12, height: 16),
          
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120), 
            child: RawScrollbar(
              thumbColor: Colors.green.withOpacity(0.4),
              radius: const Radius.circular(4),
              thickness: 3,
              child: SingleChildScrollView(
                child: Column(
                  children: items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${item.quantity}x ${item.variant}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11), overflow: TextOverflow.ellipsis),
                              Text("${item.condition} • ${item.language}", style: const TextStyle(fontSize: 9, color: Colors.black54), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _decreaseOrDeleteItem(context, ref, item),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 4.0, right: 8.0),
                            child: Icon(Icons.remove_circle_outline, color: Colors.red, size: 16),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ),
          ),
          
          BinderLocationWidget(cardId: widget.card.id),
        ],
      ),
    );
  }

  // --- DIE ALTE LOGIK FÜR LÖSCHEN ETC. ---

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

      await Future.delayed(const Duration(milliseconds: 150));
      final allEntries = await (db.select(db.userCards)..where((t) => t.cardId.equals(item.cardId))).get();
      final int totalOwned = allEntries.fold(0, (sum, e) => sum + e.quantity);

      final usedSlotsQuery = db.select(db.binderCards).join([
        drift.innerJoin(db.binders, db.binders.id.equalsExp(db.binderCards.binderId))
      ]);
      usedSlotsQuery.where(db.binderCards.cardId.equals(item.cardId) & db.binderCards.isPlaceholder.equals(false));
      
      final usedRows = await usedSlotsQuery.get();
      final usedSlots = usedRows.map((r) => _BinderSlotInfo(r.readTable(db.binderCards).id, r.readTable(db.binders).name)).toList();

      if ((totalOwned - 1) < usedSlots.length) {
        int? slotToRemoveId;
        if (usedSlots.length == 1) {
          slotToRemoveId = usedSlots.first.id;
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Auch aus Binder '${usedSlots.first.binderName}' entfernt."), duration: const Duration(seconds: 2)));
        } else if (usedSlots.length > 1) {
          if (context.mounted) {
            slotToRemoveId = await _showBinderSelectionDialog(context, usedSlots);
            if (slotToRemoveId == null) return; 
          }
        }
        if (slotToRemoveId != null) await binderService.clearSlot(slotToRemoveId);
      }

      if (shouldDelete) {
        await (db.delete(db.userCards)..where((t) => t.id.equals(item.id))).go();
      } else {
        await (db.update(db.userCards)..where((t) => t.id.equals(item.id))).write(UserCardsCompanion(quantity: drift.Value(item.quantity - 1)));
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("-1"), duration: Duration(milliseconds: 500)));
      }
      await _forceRefresh();
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fehler: $e"), backgroundColor: Colors.red));
    }
  }

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
                  shrinkWrap: true,
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
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, null), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text("Abbrechen"))],
      ),
    );
  }

  Future<void> _updateCardData(BuildContext context, WidgetRef ref) async {
    final dbInst = ref.read(databaseProvider);
    final dexApi = ref.read(tcgDexApiClientProvider);
    final importer = SetImporter(dexApi, dbInst);
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
        
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("In Bindern:", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: binders.map((name) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(4), 
                    border: Border.all(color: Colors.orange.withOpacity(0.3))
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.book, size: 8, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(name, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange[900])),
                    ],
                  ),
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