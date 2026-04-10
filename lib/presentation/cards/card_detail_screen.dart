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
import '../binders/binder_detail_screen.dart'; // NEU: Für die Navigation
import 'price_history_chart.dart'; 

// --- PROVIDER ---

final cardInventoryProvider = StreamProvider.family<List<UserCard>, String>((ref, cardId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.userCards)..where((tbl) => tbl.cardId.equals(cardId))).watch();
});

// FIX: Provider gibt jetzt echte 'Binder' Objekte zurück, statt nur Namen, damit wir dorthin navigieren können!
final cardBindersProvider = StreamProvider.family<List<Binder>, String>((ref, cardId) {
  final db = ref.watch(databaseProvider);
  
  final query = db.select(db.binderCards).join([
    drift.innerJoin(db.binders, db.binders.id.equalsExp(db.binderCards.binderId))
  ]);
  
  query.where(db.binderCards.cardId.equals(cardId) & db.binderCards.isPlaceholder.equals(false));
  
  return query.watch().map((rows) {
    if (rows.isEmpty) return <Binder>[];
    
    final Map<int, Binder> uniqueBinders = {};
    for (var r in rows) {
       final b = r.readTable(db.binders);
       uniqueBinders[b.id] = b;
    }
    return uniqueBinders.values.toList();
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
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preisquelle aktualisiert!"), duration: Duration(milliseconds: 500)));
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
        // Größere Schrift im AppBar
        title: Text(widget.card.nameDe ?? widget.card.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.blue, size: 28),
            onPressed: () => _updateCardData(context, ref),
            tooltip: "Preisdaten aktualisieren",
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => InventoryBottomSheet(card: widget.card),
            ).then((_) => _forceRefresh());
          },
          icon: const Icon(Icons.add_card, size: 24),
          label: const Text("Hinzufügen", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
        ),
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
                                  memCacheHeight: 400,
                                  fit: BoxFit.contain,
                                  placeholder: (_, __) => const AspectRatio(aspectRatio: 0.7, child: Center(child: CircularProgressIndicator())),
                                  errorWidget: (_, __, ___) => const AspectRatio(aspectRatio: 0.7, child: Icon(Icons.broken_image, color: Colors.grey)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // 1. Block: Künstler (Mit Such-Lupe)
                        if (widget.card.artist.isNotEmpty) ...[
                          Center(
                            child: _buildTag(
                              Icons.brush, 
                              widget.card.artist, 
                              color: Colors.blue, 
                              suffixIcon: Icons.search, // Lupe am Ende!
                              onTap: () {
                                ref.read(searchModeProvider.notifier).state = SearchMode.artist;
                                ref.read(searchQueryProvider.notifier).state = widget.card.artist;
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const CardSearchScreen()));
                              }
                            ),
                          ),
                        ],

                        //2. Block: Externe Links (Mit Redirect-Symbol)
                        const Divider(height: 20, thickness: 0.5),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildTag(
                              Icons.shopping_cart, 
                              "Cardmarket", 
                              color: Colors.blue[800], 
                              suffixIcon: Icons.open_in_new, // Redirect Icon
                              onTap: () => _openCardmarket(widget.card)
                            ),
                            _buildTag(
                              Icons.storefront, 
                              "TCGPlayer", 
                              color: Colors.teal[700], 
                              suffixIcon: Icons.open_in_new, 
                              onTap: () => _openTcgPlayer(widget.card)
                            ),
                          ],
                        ),

                        if (widget.card.flavorTextDe != null) 
                          Padding(
                            padding: const EdgeInsets.only(top: 16), 
                            child: Text(
                              '"${widget.card.flavorTextDe!}"', 
                              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
                              textAlign: TextAlign.center,
                            )
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

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
            
            const SizedBox(height: 16),

            // 4. BESITZ BOX
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 12, right: 12, bottom: 100),
              child: inventoryAsync.when(
                data: (items) => _buildCollectionBox(context, ref, items, historyAsync.valueOrNull as Map<String, dynamic>?),
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => Text("Fehler: $err", style: const TextStyle(fontSize: 12)),
              ),
            ),

            const SizedBox(height: 80), 
          ],
        ),
      ),
    );
  }

  // --- WIDGETS FÜR DAS DASHBOARD ---

  Widget _buildTag(IconData icon, String text, {Color? color, VoidCallback? onTap, IconData? suffixIcon}) {
    final content = Container(
      // Padding vergrößert für leichteres Tippen
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (color ?? Colors.grey).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey[700]), // Icon vergrößert
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, color: color ?? Colors.grey[800], fontWeight: FontWeight.bold)), // Schrift vergrößert
          if (suffixIcon != null) ...[
             const SizedBox(width: 6),
             Icon(suffixIcon, size: 14, color: color ?? Colors.grey[700]),
          ]
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
            Text("Preisverlauf", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), // Vergrößert
            Text("Alle Quellen", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
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
                hiddenUserCardIds: _hiddenUserCardIds, 
              );
            },
            loading: () => const SizedBox(height: 250, child: Center(child: CircularProgressIndicator())),
            error: (e, s) => const SizedBox(height: 250, child: Center(child: Text("Verlauf nicht verfügbar", style: TextStyle(fontSize: 12)))),
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
      margin: const EdgeInsets.only(bottom: 12),
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
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(color: color.withOpacity(isSelected ? 0.2 : 0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
              child: Row(
                children: [
                  Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))),
                  if (lastUpdate != null && lastUpdate.isNotEmpty) 
                    Text(lastUpdate.split('T')[0], style: TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: children),
          )
        ],
      ),
    );
  }

  Widget _priceRow(String label, double price, {bool isLow = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          Text("${price.toStringAsFixed(2)} €", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isLow ? Colors.green[700] : Colors.black)),
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
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38, // Vergrößert
                  child: TextField(
                    controller: _customPriceController, 
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Neuer Preis (€)...",
                      hintStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))
                ),
                onPressed: () => _saveCustomPrice(_customPriceController.text, ref),
                child: const Text("Speichern", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
        const Divider(height: 12, thickness: 0.5),
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
        const Divider(height: 12, thickness: 0.5),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Vergrößert
        decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
        child: Row(
          children: [
            if (logo != null) SizedBox(height: 40, width: 80, child: CachedNetworkImage(imageUrl: logo, memCacheHeight: 400,fit: BoxFit.contain, errorWidget: (_,__,___) => const Icon(Icons.broken_image, size: 24))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(set.nameDe ?? set.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), // Vergrößert
              Text("Set anzeigen (${set.printedTotal} Karten)", style: TextStyle(color: Colors.blue[700], fontSize: 13)),
            ])),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 28)
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
          
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Eigener Preis gespeichert!"), behavior: SnackBarBehavior.floating, duration: Duration(milliseconds: 500)));
      }
    }
  }

  // --- DIE SAMMLUNGS-BOX ---

  double _calculateItemPrice(UserCard item) {
    if (item.customPrice != null && item.customPrice! > 0) return item.customPrice!;

    bool baseIsHolo = !widget.card.hasNormal && widget.card.hasHolo;
    final variant = item.variant;
    final isFirstEd = variant.toLowerCase().contains('1st') || variant.toLowerCase().contains('first');
    final isHolo = variant.toLowerCase().contains('holo') || baseIsHolo;
    final isReverse = variant == 'Reverse Holo';
    final pref = _currentPreferredSource;

    double getTcg() {
       final tcg = widget.card.tcgplayer;
       if (tcg == null) return 0.0;
       double p = 0.0;
       if (isReverse) p = tcg.prices?.reverseHolofoil?.market ?? 0.0;
       else if (isHolo) p = tcg.prices?.holofoil?.market ?? 0.0;
       else p = tcg.prices?.normal?.market ?? 0.0;
       if (p == 0.0) p = tcg.prices?.normal?.market ?? tcg.prices?.holofoil?.market ?? tcg.prices?.reverseHolofoil?.market ?? 0.0;
       return p;
    }

    double getCm() {
       final cm = widget.card.cardmarket;
       if (cm == null) return 0.0;
       double p = 0.0;
       if (widget.card.hasFirstEdition) {
          p = isFirstEd ? (isHolo ? cm.trendPrice ?? 0.0 : cm.trendHolo ?? 0.0) : (isHolo ? cm.trendHolo ?? 0.0 : cm.trendPrice ?? 0.0);
       } else if (isReverse) {
          p = cm.reverseHoloTrend ?? cm.trendHolo ?? 0.0;
       } else if (isHolo && !baseIsHolo) {
          p = cm.trendHolo ?? 0.0;
       } else {
          p = cm.trendPrice ?? 0.0;
       }
       if (p == 0.0) p = cm.trendPrice ?? cm.trendHolo ?? 0.0;
       return p;
    }

    double tcgCur = getTcg();
    double cmCur = getCm();

    // --- FIX: Der Eigene Preis wird wieder als erstes gecheckt! ---
    if (pref == 'custom' && _currentCustomPrice != null && _currentCustomPrice! > 0) return _currentCustomPrice!;
    if (pref == 'tcgplayer' && tcgCur > 0.0) return tcgCur;
    if (pref == 'cardmarket' && cmCur > 0.0) return cmCur;

    if (cmCur > 0.0) return cmCur;
    if (tcgCur > 0.0) return tcgCur;
    if (_currentCustomPrice != null && _currentCustomPrice! > 0) return _currentCustomPrice!;
    
    return 0.0;
  }

  double? _getHistoricalPrice(UserCard item, Map<String, dynamic>? historyData) {
    if (item.customPrice != null && item.customPrice! > 0) return item.customPrice; 
    if (historyData == null) return null;

    bool baseIsHolo = !widget.card.hasNormal && widget.card.hasHolo;
    final variant = item.variant;
    final isFirstEd = variant.toLowerCase().contains('1st') || variant.toLowerCase().contains('first');
    final isHolo = variant.toLowerCase().contains('holo') || baseIsHolo;
    final isReverse = variant == 'Reverse Holo';
    final pref = _currentPreferredSource;

    double tcgCur = 0.0;
    if (widget.card.tcgplayer != null) {
       final tcg = widget.card.tcgplayer!;
       if (isReverse) tcgCur = tcg.prices?.reverseHolofoil?.market ?? 0.0;
       else if (isHolo) tcgCur = tcg.prices?.holofoil?.market ?? 0.0;
       else tcgCur = tcg.prices?.normal?.market ?? 0.0;
       if (tcgCur == 0.0) tcgCur = tcg.prices?.normal?.market ?? tcg.prices?.holofoil?.market ?? tcg.prices?.reverseHolofoil?.market ?? 0.0;
    }

    double cmCur = 0.0;
    if (widget.card.cardmarket != null) {
       final cm = widget.card.cardmarket!;
       if (widget.card.hasFirstEdition) {
          cmCur = isFirstEd ? (isHolo ? cm.trendPrice ?? 0.0 : cm.trendHolo ?? 0.0) : (isHolo ? cm.trendHolo ?? 0.0 : cm.trendPrice ?? 0.0);
       } else if (isReverse) cmCur = cm.reverseHoloTrend ?? cm.trendHolo ?? 0.0;
       else if (isHolo && !baseIsHolo) cmCur = cm.trendHolo ?? 0.0;
       else cmCur = cm.trendPrice ?? 0.0;
       if (cmCur == 0.0) cmCur = cm.trendPrice ?? cm.trendHolo ?? 0.0;
    }

    // Selbe Entscheidung treffen wie der Preisrechner
    String usedSource = pref;
    // --- FIX: Auch hier den Eigenen Preis berücksichtigen! ---
    if (pref == 'custom' && _currentCustomPrice != null && _currentCustomPrice! > 0) usedSource = 'custom';
    else if (pref == 'tcgplayer' && tcgCur > 0.0) usedSource = 'tcgplayer';
    else if (pref == 'cardmarket' && cmCur > 0.0) usedSource = 'cardmarket';
    else {
        if (cmCur > 0.0) usedSource = 'cardmarket';
        else if (tcgCur > 0.0) usedSource = 'tcgplayer';
        else usedSource = 'custom';
    }

    DateTime targetDate = item.createdAt;

    if (usedSource == 'custom') {
      final list = (historyData['custom'] as List).cast<CustomCardPrice>();
      var closest = list.where((e) => e.fetchedAt.isBefore(targetDate) || e.fetchedAt.isAtSameMomentAs(targetDate)).toList();
      if (closest.isEmpty && list.isNotEmpty) {
        list.sort((a, b) => a.fetchedAt.compareTo(b.fetchedAt));
        closest = [list.first];
      }
      if (closest.isNotEmpty) {
        closest.sort((a,b) => b.fetchedAt.compareTo(a.fetchedAt));
        return closest.first.price;
      }
    } else if (usedSource == 'tcgplayer') {
      final list = (historyData['tcg'] as List).cast<TcgPlayerPrice>();
      var closest = list.where((e) => e.fetchedAt.isBefore(targetDate) || e.fetchedAt.isAtSameMomentAs(targetDate)).toList();
      if (closest.isEmpty && list.isNotEmpty) {
        list.sort((a, b) => a.fetchedAt.compareTo(b.fetchedAt));
        closest = [list.first];
      }
      if (closest.isNotEmpty) {
        closest.sort((a,b) => b.fetchedAt.compareTo(a.fetchedAt));
        final p = closest.first;
        double hp = 0.0;
        if (isReverse) hp = p.reverseMarket ?? 0.0;
        else if (isHolo) hp = p.holoMarket ?? 0.0;
        else hp = p.normalMarket ?? 0.0;
        if (hp == 0.0) hp = p.normalMarket ?? p.holoMarket ?? p.reverseMarket ?? 0.0;
        return hp;
      }
    } else {
      final list = (historyData['cm'] as List).cast<CardMarketPrice>();
      var closest = list.where((e) => e.fetchedAt.isBefore(targetDate) || e.fetchedAt.isAtSameMomentAs(targetDate)).toList();
      if (closest.isEmpty && list.isNotEmpty) {
        list.sort((a, b) => a.fetchedAt.compareTo(b.fetchedAt));
        closest = [list.first];
      }
      if (closest.isNotEmpty) {
        closest.sort((a,b) => b.fetchedAt.compareTo(a.fetchedAt));
        final p = closest.first;
        double hp = 0.0;
        if (widget.card.hasFirstEdition) {
           if (isHolo) hp = isFirstEd ? (p.trend ?? 0.0) : (p.trendHolo ?? 0.0);
           else hp = isFirstEd ? (p.trendHolo ?? 0.0) : (p.trend ?? 0.0);
        } else if (isReverse) {
           hp = p.trendReverse ?? p.trendHolo ?? 0.0;
        } else if (isHolo && !baseIsHolo) {
           hp = p.trendHolo ?? 0.0;
        } else {
           hp = p.trend ?? 0.0;
        }
        if (hp == 0.0) hp = p.trend ?? p.trendHolo ?? 0.0;
        return hp;
      }
    }
    return null;
  }

  Widget _buildCollectionBox(BuildContext context, WidgetRef ref, List<UserCard> items, Map<String, dynamic>? historyData) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16), // Vergrößert
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!)),
        child: const Center(child: Text("Nicht in Sammlung", style: TextStyle(color: Colors.grey, fontSize: 14), textAlign: TextAlign.center)),
      );
    }
    
    final totalCount = items.fold(0, (sum, item) => sum + item.quantity);
    double inventoryTotalValue = 0.0;
    for (var item in items) {
      inventoryTotalValue += (_calculateItemPrice(item) * item.quantity);
    }
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(10), 
        border: Border.all(color: Colors.green.withOpacity(0.4), width: 2),
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
                    const Icon(Icons.inventory_2_rounded, color: Colors.green, size: 20), // Vergrößert
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Besitz: $totalCount", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green), overflow: TextOverflow.ellipsis),
                          Text("Wert: ${inventoryTotalValue.toStringAsFixed(2)} €", style: TextStyle(fontSize: 13, color: Colors.green[800], fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // --- NEU: Großer Auffälliger Button zum Einsortieren ---
              if (widget.card.isOwned)
                FilledButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => AssignToBinderSheet(card: widget.card),
                    );
                  },
                  icon: const Icon(Icons.move_to_inbox, size: 16),
                  label: const Text("In Binder sortieren"),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const Divider(color: Colors.black12, height: 20, thickness: 1),
          
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280), 
            child: RawScrollbar(
              thumbColor: Colors.green.withOpacity(0.4),
              radius: const Radius.circular(4),
              thickness: 4,
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
                      margin: const EdgeInsets.only(bottom: 8.0),
                      padding: const EdgeInsets.all(10.0), // Vergrößert
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: Checkbox(
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
                          const SizedBox(width: 6),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${item.quantity}x ${item.variant}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(details, style: TextStyle(fontSize: 11, color: item.gradingCompany != null ? Colors.orange[800] : Colors.black54, fontWeight: item.gradingCompany != null ? FontWeight.bold : FontWeight.normal), overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text("Erworben: ${DateFormat('dd.MM.yyyy').format(item.createdAt)}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                          
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  if (hasSpecificPrice) const Icon(Icons.star, color: Colors.amber, size: 12),
                                  if (hasSpecificPrice) const SizedBox(width: 4),
                                  Text("${itemPrice.toStringAsFixed(2)} €", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: hasSpecificPrice ? Colors.amber[800] : Colors.black87)),
                                ],
                              ),
                              if (item.quantity > 1) 
                                Text("Gesamt: ${(itemPrice * item.quantity).toStringAsFixed(2)} €", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                
                              Builder(builder: (context) {
                                final purchasePrice = _getHistoricalPrice(item, historyData);
                                if (purchasePrice == null || purchasePrice == 0 || hasSpecificPrice) return const SizedBox.shrink(); 
                                
                                final change = itemPrice - purchasePrice;
                                final percent = (change / purchasePrice) * 100;
                                final isPositive = change >= 0;
                                final color = isPositive ? Colors.green : Colors.red;
                                final sign = isPositive ? "+" : "";

                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "$sign${change.toStringAsFixed(2)}€ ($sign${percent.toStringAsFixed(1)}%)", 
                                    style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(width: 12),

                          GestureDetector(
                            onTap: () => _editUserCard(context, ref, item),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: const Icon(Icons.edit, color: Colors.blue, size: 18),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          GestureDetector(
                            onTap: () => _decreaseOrDeleteItem(context, ref, item),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
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
          
          // --- NEU: BinderLocation Widget mit anklickbaren Elementen ---
          BinderLocationWidget(card: widget.card),
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
                              const Text("Erworben am", style: TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(DateFormat('dd.MM.yyyy').format(selectedDate), style: const TextStyle(fontSize: 14, color: Colors.black87)),
                            ],
                          ),
                          const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
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
                  const Text("Überschreibt alle globalen Berechnungen für diese spezifische Karte.", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Spezifischer Wert (€)",
                      hintText: "z.B. 15.50",
                      prefixIcon: const Icon(Icons.euro, size: 18),
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
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Auch aus Binder '${usedSlots.first.binderName}' entfernt."), behavior: SnackBarBehavior.floating, duration: const Duration(milliseconds: 500)));
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
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("-1"), behavior: SnackBarBehavior.floating, duration: const Duration(milliseconds: 500)));
      }
      await _forceRefresh();
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fehler: $e"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, duration: const Duration(milliseconds: 500)));
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
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aktualisiere Daten...'), behavior: SnackBarBehavior.floating, duration: const Duration(milliseconds: 500)));
    
    try {
      final setCardsQuery = await (dbInst.select(dbInst.cards)..where((t) => t.setId.equals(widget.card.setId))).get();
      final cardIds = setCardsQuery.map((c) => c.id).toList();
      
      Map<String, Map<String, dynamic>> latestCmPrices = {};
      Map<String, Map<String, dynamic>> latestTcgPrices = {};
      
      if (cardIds.isNotEmpty) {
         final allLatestCmQuery = await dbInst.customSelect(
            'SELECT cardId, trend, trendHolo, trendReverse FROM CardMarketPrices WHERE cardId IN (${cardIds.map((e) => "'$e'").join(',')}) GROUP BY cardId HAVING MAX(fetchedAt)'
         ).get();
         latestCmPrices = {
            for (var row in allLatestCmQuery) row.read<String>('cardId'): {
               'trend': row.read<double?>('trend'),
               'trendHolo': row.read<double?>('trendHolo'),
               'trendReverse': row.read<double?>('trendReverse'),
            }
         };

         final allLatestTcgQuery = await dbInst.customSelect(
            'SELECT cardId, normalMarket, holoMarket, reverseMarket FROM TcgPlayerPrices WHERE cardId IN (${cardIds.map((e) => "'$e'").join(',')}) GROUP BY cardId HAVING MAX(fetchedAt)'
         ).get();
         latestTcgPrices = {
            for (var row in allLatestTcgQuery) row.read<String>('cardId'): {
               'normalMarket': row.read<double?>('normalMarket'),
               'holoMarket': row.read<double?>('holoMarket'),
               'reverseMarket': row.read<double?>('reverseMarket'),
            }
         };
      }
      
      await importer.importCardsForSet(widget.card.setId, latestCmPrices, latestTcgPrices);

      _forceRefresh();
      ref.invalidate(cardPriceHistoryProvider(widget.card.id));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Aktualisiert!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, duration: const Duration(milliseconds: 500))
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, duration: const Duration(milliseconds: 500))
        );
      }
    }
  }

  void _openFullscreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => Scaffold(backgroundColor: Colors.black, appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)), body: Center(child: InteractiveViewer(child: CachedNetworkImage(imageUrl: imageUrl,fit: BoxFit.contain,errorWidget: (_,__,___) => const Icon(Icons.broken_image, size: 50, color: Colors.grey)))))));
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) throw 'Could not launch $url';
  }
}

// Füge oben bei den imports (falls nicht da) noch das hier hinzu:
// import 'dart:math';

class _BinderTagInfo {
  final Binder binder;
  final int page;
  final int row;
  final int col;
  
  _BinderTagInfo(this.binder, this.page, this.row, this.col);
}

// Der neue Provider lädt Binder + Slot-Informationen!
final cardBinderDetailsProvider = FutureProvider.family<List<_BinderTagInfo>, String>((ref, cardId) async {
  final db = ref.watch(databaseProvider);
  
  final query = db.select(db.binderCards).join([
    drift.innerJoin(db.binders, db.binders.id.equalsExp(db.binderCards.binderId))
  ]);
  
  query.where(db.binderCards.cardId.equals(cardId) & db.binderCards.isPlaceholder.equals(false));
  
  final rows = await query.get();
  
  List<_BinderTagInfo> results = [];
  for (var r in rows) {
     final binder = r.readTable(db.binders);
     final slot = r.readTable(db.binderCards);
     
     // Berechnung wie beim Einsortieren
     final page = slot.pageIndex + 1;
     int row = 1;
     int col = 1;
     
     if (binder.sortOrder == 'topToBottom') {
         row = (slot.slotIndex % binder.rowsPerPage) + 1;
         col = (slot.slotIndex / binder.rowsPerPage).floor() + 1;
     } else {
         row = (slot.slotIndex / binder.columnsPerPage).floor() + 1;
         col = (slot.slotIndex % binder.columnsPerPage) + 1;
     }
     results.add(_BinderTagInfo(binder, page, row, col));
  }
  
  return results;
});


class BinderLocationWidget extends ConsumerWidget {
  final ApiCard card;
  const BinderLocationWidget({required this.card, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bindersAsync = ref.watch(cardBinderDetailsProvider(card.id));
    
    return bindersAsync.when(
      data: (binders) {
        if (binders.isEmpty) return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Einsortiert in:", style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: binders.map((info) => InkWell(
                  onTap: () {
                     // Navigiere zum Binder und suche nach dieser Karte!
                     Navigator.push(context, MaterialPageRoute(
                       builder: (_) => BinderDetailScreen(
                         binder: info.binder, 
                         initialSearchQuery: card.nameDe ?? card.name
                       )
                     ));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08), 
                      borderRadius: BorderRadius.circular(8), 
                      border: Border.all(color: Colors.orange.withOpacity(0.3))
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.book, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(info.binder.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange[900])),
                             Text("S. ${info.page} • Z. ${info.row} • Sp. ${info.col}", style: TextStyle(fontSize: 10, color: Colors.orange[700])),
                          ]
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.orange),
                      ],
                    ),
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