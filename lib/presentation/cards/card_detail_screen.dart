import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drift/drift.dart' as drift; 
import 'package:intl/intl.dart'; 

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
import '../binders/binder_list_screen.dart';
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
  
  late String _currentPreferredSource;
  late TextEditingController _customPriceController;
  double? _currentCustomPrice;
  
  // --- NEU: Die Blacklist! IDs, die in diesem Set stehen, werden im Graphen NICHT angezeigt. ---
  final Set<int> _hiddenUserCardIds = {};

  @override
  void initState() {
    super.initState();
    _currentPreferredSource = widget.card.preferredPriceSource;
    _currentCustomPrice = widget.card.customPrice; 
    _customPriceController = TextEditingController();
    
    _loadLatestCustomPrice();
  }

  Future<void> _loadLatestCustomPrice() async {
    final db = ref.read(databaseProvider);
    final latest = await (db.select(db.customCardPrices)
      ..where((t) => t.cardId.equals(widget.card.id))
      ..orderBy([(t) => drift.OrderingTerm(expression: t.fetchedAt, mode: drift.OrderingMode.desc)])
      ..limit(1)
    ).getSingleOrNull();
    
    if (latest != null && mounted) {
      setState(() => _currentCustomPrice = latest.price);
    }
  }

  @override
  void dispose() {
    _customPriceController.dispose();
    super.dispose();
  }

  Future<void> _forceRefresh() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;

    ref.invalidate(cardBindersProvider(widget.card.id));
    ref.invalidate(searchResultsProvider);
    ref.invalidate(cardsForSetProvider(widget.card.setId));
    ref.invalidate(setStatsProvider(widget.card.setId));
    ref.invalidate(inventoryProvider); 

    setState(() {
      _refreshId++; 
    });
  }

  Future<void> _updatePreferredSource(String source) async {
    setState(() => _currentPreferredSource = source);
    final dbInst = ref.read(databaseProvider);
    
    await (dbInst.update(dbInst.cards)..where((t) => t.id.equals(widget.card.id)))
        .write(CardsCompanion(preferredPriceSource: drift.Value(source)));
    
    await BinderService(dbInst).recalculateBindersForCard(widget.card.id);
    
    if (!mounted) return;
    
    ref.invalidate(cardPriceHistoryProvider(widget.card.id));
    ref.invalidate(searchResultsProvider);
    ref.invalidate(inventoryProvider);
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preisquelle aktualisiert!"), duration: Duration(seconds: 1)));
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
            setAsync.when(
              data: (set) => _buildSetHeader(context, set),
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (_, __) => const SizedBox.shrink(),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // --- LINKE SPALTE (Karte, Tags) ---
                  Expanded(
                    flex: 4, 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                            
                            _buildTag(
                              Icons.shopping_cart, 
                              "Cardmarket", 
                              color: Colors.blue[800], 
                              onTap: () => _openCardmarket(widget.card)
                            ),
                            _buildTag(
                              Icons.storefront, 
                              "TCGPlayer", 
                              color: Colors.teal[700], 
                              onTap: () => _openTcgPlayer(widget.card)
                            ),
                          ],
                        ),

                        if (widget.card.flavorTextDe != null) 
                          Padding(
                            padding: const EdgeInsets.only(top: 10), 
                            child: Text(
                              '"${widget.card.flavorTextDe!}"', 
                              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 10),
                              textAlign: TextAlign.center,
                            )
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // --- RECHTE SPALTE (PREIS-TABELLEN) ---
                  Expanded(
                    flex: 5, 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCustomPriceSection(),
                        if (widget.card.cardmarket != null) 
                          _buildCardmarketSection(context, widget.card.cardmarket!),
                        if (widget.card.tcgplayer != null) 
                          _buildTcgPlayerSection(context, widget.card.tcgplayer!),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // 3. CHART BEREICH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: _buildChartSection(historyAsync, inventoryAsync),
            ),
            
            const SizedBox(height: 12),

            // 4. BESITZ BOX
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: inventoryAsync.when(
                data: (items) => _buildCollectionBox(context, ref, items, historyAsync.valueOrNull as Map<String, dynamic>?),
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => Text("Fehler: $err", style: const TextStyle(fontSize: 10)),
              ),
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

  void _openCardmarket(ApiCard card) {
    String baseUrl = card.cardmarket?.url ?? "";
    if (baseUrl.isNotEmpty) {
      if (baseUrl.contains('?')) {
        baseUrl += "&sellerCountry=7&language=3";
      } else {
        baseUrl += "?sellerCountry=7&language=3";
      }
    } else {
      String fullSearchTerm = card.nameDe != null && card.nameDe!.isNotEmpty ? card.nameDe! : card.name;
      if (card.number.isNotEmpty) fullSearchTerm += " ${card.number}";
      final safeQuery = Uri.encodeQueryComponent(fullSearchTerm);
      baseUrl = "https://www.cardmarket.com/de/Pokemon/Products/Singles?searchString=$safeQuery&sellerCountry=7&language=3";
    }
    _launchURL(baseUrl);
  }

  void _openTcgPlayer(ApiCard card) {
    String baseUrl = card.tcgplayer?.url ?? "";
    if (baseUrl.isEmpty) {
      String fullSearchTerm = card.name;
      if (card.number.isNotEmpty) fullSearchTerm += " ${card.number}";
      final safeQuery = Uri.encodeQueryComponent(fullSearchTerm);
      baseUrl = "https://www.tcgplayer.com/search/pokemon/product?productLineName=pokemon&q=$safeQuery";
    }
    _launchURL(baseUrl);
  }

  Widget _buildChartSection(AsyncValue historyAsync, AsyncValue inventoryAsync) {
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
            data: (data) {
              final userCards = inventoryAsync.valueOrNull ?? [];
              return PriceHistoryChart(
                cmHistory: (data['cm'] as List).cast<CardMarketPrice>(),
                tcgHistory: (data['tcg'] as List).cast<TcgPlayerPrice>(),
                customHistory: (data['custom'] as List).cast<CustomCardPrice>(),
                userCards: userCards.cast<UserCard>(),
                hiddenUserCardIds: _hiddenUserCardIds, // --- NEU: Blacklist übergeben! ---
              );
            },
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

  Widget _buildCustomPriceSection() {
    return _buildPriceSectionContainer(
      context, 
      title: "Eigener Preis", 
      color: Colors.amber[800]!, 
      sourceKey: 'custom',
      children: [
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
                    controller: _customPriceController, 
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

  Future<void> _saveCustomPrice(String value, WidgetRef ref) async {
    if (value.isEmpty) return;
    final double? parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed != null && parsed >= 0) {
      final dbInst = ref.read(databaseProvider);
      
      await dbInst.into(dbInst.customCardPrices).insert(
        CustomCardPricesCompanion.insert(
          cardId: widget.card.id,
          fetchedAt: DateTime.now(),
          price: parsed,
        )
      );

      setState(() => _currentCustomPrice = parsed);
      _customPriceController.clear();
      FocusScope.of(context).unfocus(); 
      
      await (dbInst.update(dbInst.cards)..where((t) => t.id.equals(widget.card.id)))
          .write(CardsCompanion(preferredPriceSource: drift.Value(_currentPreferredSource)));

      if (_currentPreferredSource != 'custom') {
          await _updatePreferredSource('custom'); 
      } else {
          await BinderService(dbInst).recalculateBindersForCard(widget.card.id);
          if (!mounted) return;
          
          ref.invalidate(cardPriceHistoryProvider(widget.card.id));
          ref.invalidate(searchResultsProvider);
          ref.invalidate(inventoryProvider);
          
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Eigener Preis gespeichert!")));
      }
    }
  }

  // --- DIE SAMMLUNGS-BOX ---

  double _calculateItemPrice(UserCard item) {
    if (item.customPrice != null && item.customPrice! > 0) return item.customPrice!;

    double price = 0.0;
    final cmPrice = widget.card.cardmarket;
    final tcgPrice = widget.card.tcgplayer;
    bool baseIsHolo = !widget.card.hasNormal && widget.card.hasHolo;
    final variant = item.variant;

    final isFirstEd = variant.toLowerCase().contains('1st') || variant.toLowerCase().contains('first');
    final isHolo = variant.toLowerCase().contains('holo') || baseIsHolo;
    final isReverse = variant == 'Reverse Holo';

    final pref = _currentPreferredSource;

    if (pref == 'custom' && _currentCustomPrice != null && _currentCustomPrice! > 0) {
      price = _currentCustomPrice!;
    } else if (pref == 'tcgplayer') {
      if (isReverse) {
        price = tcgPrice?.prices?.reverseHolofoil?.market ?? 0.0;
      } else if (isHolo) price = tcgPrice?.prices?.holofoil?.market ?? 0.0;
      else price = tcgPrice?.prices?.normal?.market ?? 0.0;
    } else {
      if (widget.card.hasFirstEdition) {
         if (isHolo) {
           price = isFirstEd ? (cmPrice?.trendPrice ?? 0.0) : (cmPrice?.trendHolo ?? 0.0);
         } else {
           price = isFirstEd ? (cmPrice?.trendHolo ?? 0.0) : (cmPrice?.trendPrice ?? 0.0);
         }
      } else if (isReverse) {
         price = cmPrice?.reverseHoloTrend ?? cmPrice?.trendHolo ?? 0.0;
      } else if (isHolo && !baseIsHolo) {
         price = cmPrice?.trendHolo ?? 0.0;
      } else {
         price = cmPrice?.trendPrice ?? 0.0;
      }
    }

    if (price == 0.0) price = (isHolo ? tcgPrice?.prices?.holofoil?.market : tcgPrice?.prices?.normal?.market) ?? cmPrice?.trendPrice ?? _currentCustomPrice ?? 0.0;
    return price;
  }

  double? _getHistoricalPrice(UserCard item, Map<String, dynamic>? historyData) {
    if (item.customPrice != null && item.customPrice! > 0) return item.customPrice; 
    if (historyData == null) return null;

    final pref = _currentPreferredSource;
    bool baseIsHolo = !widget.card.hasNormal && widget.card.hasHolo;
    final variant = item.variant;
    
    final isFirstEd = variant.toLowerCase().contains('1st') || variant.toLowerCase().contains('first');
    final isHolo = variant.toLowerCase().contains('holo') || baseIsHolo;
    final isReverse = variant == 'Reverse Holo';

    DateTime targetDate = item.createdAt;

    if (pref == 'custom') {
      final list = (historyData['custom'] as List).cast<CustomCardPrice>();
      var closest = list.where((e) => e.fetchedAt.isBefore(targetDate) || e.fetchedAt.isAtSameMomentAs(targetDate)).toList();
      if (closest.isEmpty) closest = list; 
      if (closest.isNotEmpty) {
        closest.sort((a,b) => b.fetchedAt.compareTo(a.fetchedAt));
        return closest.first.price;
      }
    } else if (pref == 'tcgplayer') {
      final list = (historyData['tcg'] as List).cast<TcgPlayerPrice>();
      var closest = list.where((e) => e.fetchedAt.isBefore(targetDate) || e.fetchedAt.isAtSameMomentAs(targetDate)).toList();
      if (closest.isEmpty) closest = list;
      if (closest.isNotEmpty) {
        closest.sort((a,b) => b.fetchedAt.compareTo(a.fetchedAt));
        final p = closest.first;
        if (isReverse) return p.reverseMarket ?? 0.0;
        if (isHolo) return p.holoMarket ?? 0.0;
        return p.normalMarket ?? 0.0;
      }
    } else {
      final list = (historyData['cm'] as List).cast<CardMarketPrice>();
      var closest = list.where((e) => e.fetchedAt.isBefore(targetDate) || e.fetchedAt.isAtSameMomentAs(targetDate)).toList();
      if (closest.isEmpty) closest = list;
      if (closest.isNotEmpty) {
        closest.sort((a,b) => b.fetchedAt.compareTo(a.fetchedAt));
        final p = closest.first;
        if (widget.card.hasFirstEdition) {
           if (isHolo) {
             return isFirstEd ? (p.trend ?? 0.0) : (p.trendHolo ?? 0.0);
           } else {
             return isFirstEd ? (p.trendHolo ?? 0.0) : (p.trend ?? 0.0);
           }
        } else if (isReverse) {
           return p.trendReverse ?? p.trendHolo ?? 0.0;
        } else if (isHolo && !baseIsHolo) {
           return p.trendHolo ?? 0.0;
        } else {
           return p.trend ?? 0.0;
        }
      }
    }
    return null;
  }

  // --- DIE NEUE SAMMLUNGS-TABELLE MIT CHECKBOXEN ---
  Widget _buildCollectionBox(BuildContext context, WidgetRef ref, List<UserCard> items, Map<String, dynamic>? historyData) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)),
        child: const Center(child: Text("Nicht in Sammlung", style: TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center)),
      );
    }
    
    final totalCount = items.fold(0, (sum, item) => sum + item.quantity);
    double inventoryTotalValue = 0.0;
    for (var item in items) {
      inventoryTotalValue += (_calculateItemPrice(item) * item.quantity);
    }
    
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
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Besitz: $totalCount", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green), overflow: TextOverflow.ellipsis),
                          Text("Wert: ${inventoryTotalValue.toStringAsFixed(2)} €", style: TextStyle(fontSize: 10, color: Colors.green[800], fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.move_to_inbox, size: 16, color: Colors.blueGrey),
                    ),
                  ),
                ),
            ],
          ),
          const Divider(color: Colors.black12, height: 16),
          
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280), 
            child: RawScrollbar(
              thumbColor: Colors.green.withOpacity(0.4),
              radius: const Radius.circular(4),
              thickness: 3,
              child: SingleChildScrollView(
                child: Column(
                  children: items.map((item) {
                    final itemPrice = _calculateItemPrice(item);
                    final hasSpecificPrice = item.customPrice != null && item.customPrice! > 0;
                    
                    String details = "${item.condition} • ${item.language}";
                    if (item.gradingCompany != null && item.gradingCompany != 'Kein Grading') {
                       details += " • ${item.gradingCompany} ${item.gradingScore ?? ''}";
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6.0),
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          
                          // --- NEU: DIE CHECKBOX FÜR DEN GRAPHEN ---
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: Checkbox(
                              visualDensity: VisualDensity.compact,
                              value: !_hiddenUserCardIds.contains(item.id),
                              activeColor: Colors.green,
                              side: BorderSide(color: Colors.grey[400]!),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _hiddenUserCardIds.remove(item.id);
                                  } else {
                                    _hiddenUserCardIds.add(item.id);
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          // ------------------------------------------

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${item.quantity}x ${item.variant}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11), overflow: TextOverflow.ellipsis),
                                Text(details, style: TextStyle(fontSize: 9, color: item.gradingCompany != null ? Colors.orange[800] : Colors.black54, fontWeight: item.gradingCompany != null ? FontWeight.bold : FontWeight.normal), overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text("Erworben: ${DateFormat('dd.MM.yyyy').format(item.createdAt)}", style: const TextStyle(fontSize: 8, color: Colors.grey)),
                              ],
                            ),
                          ),
                          
                          // Preis-Anzeige
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  if (hasSpecificPrice) const Icon(Icons.star, color: Colors.amber, size: 10),
                                  if (hasSpecificPrice) const SizedBox(width: 2),
                                  Text("${itemPrice.toStringAsFixed(2)} €", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: hasSpecificPrice ? Colors.amber[800] : Colors.black87)),
                                ],
                              ),
                              if (item.quantity > 1) 
                                Text("Gesamt: ${(itemPrice * item.quantity).toStringAsFixed(2)} €", style: const TextStyle(fontSize: 8, color: Colors.grey)),
                                
                              Builder(builder: (context) {
                                final purchasePrice = _getHistoricalPrice(item, historyData);
                                if (purchasePrice == null || purchasePrice == 0 || hasSpecificPrice) return const SizedBox.shrink(); 
                                
                                final change = itemPrice - purchasePrice;
                                final percent = (change / purchasePrice) * 100;
                                final isPositive = change >= 0;
                                final color = isPositive ? Colors.green : Colors.red;
                                final sign = isPositive ? "+" : "";

                                return Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    "$sign${change.toStringAsFixed(2)}€ ($sign${percent.toStringAsFixed(1)}%)", 
                                    style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold)
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(width: 8),

                          GestureDetector(
                            onTap: () => _editUserCard(context, ref, item),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: const Icon(Icons.edit, color: Colors.blue, size: 14),
                            ),
                          ),
                          const SizedBox(width: 6),
                          
                          GestureDetector(
                            onTap: () => _decreaseOrDeleteItem(context, ref, item),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: const Icon(Icons.delete_outline, color: Colors.red, size: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          
          BinderLocationWidget(cardId: widget.card.id),
        ],
      ),
    );
  }

  Future<void> _editUserCard(BuildContext context, WidgetRef ref, UserCard item) async {
    final priceController = TextEditingController(text: item.customPrice?.toString() ?? '');
    final scoreController = TextEditingController(text: item.gradingScore ?? '');
    
    String selectedCompany = item.gradingCompany ?? 'Kein Grading';
    String selectedCond = item.condition;
    String selectedLang = item.language;
    String selectedVariant = item.variant;
    
    DateTime selectedDate = item.createdAt;

    List<String> companies = ['Kein Grading', 'PSA', 'Beckett (BGS)', 'CGC', 'AP', 'PCA', 'GSG', 'EGS'];
    List<String> conditions = ['Mint' , 'Near Mint' , 'Excellent' , 'Good' , 'Light Played' , 'Played' , 'Poor'];
    List<String> languages = ['Englisch', 'Deutsch', 'Japanisch', 'Französisch', 'Italienisch', 'Spanisch', 'Koreanisch'];
    
    if (!companies.contains(selectedCompany)) companies.add(selectedCompany);
    if (!conditions.contains(selectedCond)) conditions.add(selectedCond);
    if (!languages.contains(selectedLang)) languages.add(selectedLang);

    List<String> validVariants = [];
    if (widget.card.hasNormal) validVariants.add('Normal');
    if (widget.card.hasHolo) validVariants.add('Holo');
    if (widget.card.hasReverse) validVariants.add('Reverse Holo');
    if (widget.card.hasFirstEdition) validVariants.add('1st Edition');
    if (validVariants.isEmpty) validVariants.add('Normal');
    if (!validVariants.contains(selectedVariant)) validVariants.add(selectedVariant);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Inventar-Eintrag bearbeiten", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  const Text("Kartendetails", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedVariant,
                    decoration: InputDecoration(labelText: "Variante", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                    items: validVariants.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) => setStateDialog(() => selectedVariant = val!),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedLang,
                          decoration: InputDecoration(labelText: "Sprache", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                          items: languages.map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (val) => setStateDialog(() => selectedLang = val!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedCond,
                          decoration: InputDecoration(labelText: "Zustand", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                          items: conditions.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
                          onChanged: (val) => setStateDialog(() => selectedCond = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(1996), 
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        final newDateTime = DateTime(
                          picked.year, picked.month, picked.day, 
                          selectedDate.hour, selectedDate.minute, selectedDate.second
                        );
                        setStateDialog(() => selectedDate = newDateTime);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Erworben am", style: TextStyle(fontSize: 9, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(DateFormat('dd.MM.yyyy').format(selectedDate), style: const TextStyle(fontSize: 13, color: Colors.black87)),
                            ],
                          ),
                          const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  const Text("Grading (Optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCompany,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                    items: companies.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) => setStateDialog(() => selectedCompany = val!),
                  ),
                  const SizedBox(height: 10),
                  if (selectedCompany != 'Kein Grading')
                    TextField(
                      controller: scoreController,
                      decoration: InputDecoration(labelText: "Bewertung (z.B. 10, 9.5, GEM MT)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                    ),
                  if (selectedCompany != 'Kein Grading') const SizedBox(height: 16),
                  
                  if (selectedCompany == 'Kein Grading') const SizedBox(height: 6),
                  const Divider(),
                  const SizedBox(height: 8),

                  const Text("Individueller Wert (Optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber)),
                  const SizedBox(height: 4),
                  const Text("Überschreibt alle globalen Berechnungen für diese spezifische Karte.", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Spezifischer Wert (€)",
                      hintText: "z.B. 15.50",
                      prefixIcon: const Icon(Icons.euro, size: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Abbrechen")),
              FilledButton(
                onPressed: () async {
                  final db = ref.read(databaseProvider);
                  double? newPrice = double.tryParse(priceController.text.replaceAll(',', '.'));
                  
                  String? comp = selectedCompany == 'Kein Grading' ? null : selectedCompany;
                  String? score = comp != null ? scoreController.text.trim() : null;

                  await (db.update(db.userCards)..where((t) => t.id.equals(item.id))).write(
                    UserCardsCompanion(
                      variant: drift.Value(selectedVariant),
                      language: drift.Value(selectedLang),
                      condition: drift.Value(selectedCond),
                      customPrice: drift.Value(newPrice),
                      gradingCompany: drift.Value(comp),
                      gradingScore: drift.Value(score),
                      createdAt: drift.Value(selectedDate),
                    )
                  );

                  BinderService(db).recalculateBindersForCard(widget.card.id);

                  if (mounted) {
                    ref.invalidate(cardInventoryProvider(widget.card.id));
                    ref.invalidate(inventoryProvider); 
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("Speichern"),
              ),
            ],
          );
        },
      ),
    );
  }

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