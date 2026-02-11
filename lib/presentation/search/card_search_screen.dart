import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart'; // WICHTIG: Für das Diagramm
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // WICHTIG: Für Datumsformatierung

// WICHTIG: "as db" verhindert den Konflikt zwischen UI-Card und Datenbank-Card!
import '../../data/database/app_database.dart' as db; 

import '../../data/api/search_provider.dart';        // Enthält historyProvider & top10Provider
import '../../data/api/tcg_api_client.dart';
import '../../data/database/database_provider.dart';
import '../../data/sync/set_importer.dart';
import '../cards/card_detail_screen.dart';
import '../inventory/inventory_bottom_sheet.dart';

// Filter für das Diagramm
enum ChartFilter { week, month, year, all }
final chartFilterProvider = StateProvider<ChartFilter>((ref) => ChartFilter.week);

class CardSearchScreen extends ConsumerStatefulWidget {
  const CardSearchScreen({super.key});

  @override
  ConsumerState<CardSearchScreen> createState() => _CardSearchScreenState();
}

class _CardSearchScreenState extends ConsumerState<CardSearchScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // Den aktuellen Suchtext laden
    final initialQuery = ref.read(searchQueryProvider);
    _searchController = TextEditingController(text: initialQuery);

    // Snapshot des Inventarwerts erstellen (für das Diagramm)
    Future.delayed(Duration.zero, () {
      createPortfolioSnapshot(ref);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Prüfen, ob wir gerade suchen
    final searchQuery = ref.watch(searchQueryProvider);
    final isSearching = searchQuery.isNotEmpty;
    final currentMode = ref.watch(searchModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isSearching ? 'Suche' : 'Dashboard'),
      ),
      body: Column(
        children: [
          // --- 1. SUCHLEISTE (Immer sichtbar) ---
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: currentMode == SearchMode.name 
                        ? 'Suche Karte (z.B. Glurak)...' 
                        : 'Suche Künstler...',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).state = '';
                              FocusScope.of(context).unfocus(); // Tastatur zu
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    // Optional: Live-Suche hier aktivieren
                  },
                  onSubmitted: (val) {
                    ref.read(searchQueryProvider.notifier).state = val;
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Filter Chips
                Row(
                  children: [
                    _buildFilterChip("Karten Name", SearchMode.name, ref),
                    const SizedBox(width: 8),
                    _buildFilterChip("Künstler", SearchMode.artist, ref),
                  ],
                ),
              ],
            ),
          ),

          // --- 2. INHALT (Entweder Suchergebnisse ODER Dashboard) ---
          Expanded(
            child: isSearching 
              ? const _SearchResultsView() // Zeigt die Karten Raster
              : const _DashboardView(),    // Zeigt Graph und Top 10
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, SearchMode mode, WidgetRef ref) {
    final current = ref.watch(searchModeProvider);
    final isSelected = current == mode;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: Colors.blue.withOpacity(0.2),
      onSelected: (val) {
        if (val) {
          ref.read(searchModeProvider.notifier).state = mode;
          if (ref.read(searchQueryProvider).isNotEmpty) {
            ref.refresh(searchResultsProvider);
          }
        }
      },
    );
  }
}

// =========================================================
// VIEW 1: DASHBOARD (Graph & Top 10)
// =========================================================
class _DashboardView extends ConsumerWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(portfolioHistoryProvider);
    final top10Cards = ref.watch(top10CardsProvider);
    final inventoryAsync = ref.watch(inventoryProvider);
    final double totalValue = inventoryAsync.valueOrNull?.fold(0.0, (sum, i) => sum! + i.totalValue) ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER
          _buildPortfolioHeader(context, totalValue, historyAsync),
          
          const SizedBox(height: 24),
          
          // 2. CHART FILTER
          _buildChartFilterButtons(ref),

          const SizedBox(height: 16),

          // 3. DIAGRAMM (MIT FIX FÜR 0-LINIE)
          SizedBox(
            height: 200,
            child: historyAsync.when(
              data: (data) => _PortfolioChart(history: data, currentTotal: totalValue),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_,__) => const Center(child: Text("Keine Daten verfügbar")),
            ),
          ),

          const SizedBox(height: 32),

          // 4. TOP 10 KARTEN (Horizontales Karussell)
          const Text("Deine Top 10 Karten", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          if (top10Cards.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text("Noch keine wertvollen Karten im Inventar.", style: TextStyle(color: Colors.grey))),
            )
          else
            _buildTop10List(top10Cards, context),
            
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- LOGIK-UPDATE: VERGLEICH ZUM VORTAG ---
  Widget _buildPortfolioHeader(BuildContext context, double currentTotal, AsyncValue<List<db.PortfolioHistoryData>> historyAsync) {
    double change = 0.0;
    double percent = 0.0;
    
    final history = historyAsync.valueOrNull ?? [];
    
    // 1. Wir suchen den Wert von "Gestern" (oder dem letzten Tag, der NICHT heute ist)
    double previousValue = 0.0;
    final today = DateTime.now();

    // Liste rückwärts durchgehen
    for (var i = history.length - 1; i >= 0; i--) {
      // Wenn das Datum NICHT heute ist, haben wir unseren Vergleichswert
      if (!_isSameDay(history[i].date, today)) {
        previousValue = history[i].totalValue;
        break; // Gefunden, Abbruch
      }
    }

    // 2. Berechnung: Heute (Live) minus Letzter anderer Tag
    // Wenn es keinen anderen Tag gibt (erster Tag der Nutzung), ist previousValue 0.
    // Dann ist der Gewinn = gesamter Inventarwert.
    change = currentTotal - previousValue;
    
    if (previousValue > 0) {
      percent = (change / previousValue) * 100;
    } else if (currentTotal > 0) {
      // Wenn wir bei 0 gestartet sind und jetzt was haben -> 100% Gewinn
      percent = 100.0; 
    }

    final isPositive = change >= -0.01; 
    final sign = isPositive ? "+" : "";
    final color = isPositive ? Colors.green : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Portfolio Wert", style: TextStyle(color: Colors.grey, fontSize: 14)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${currentTotal.toStringAsFixed(2)} €",
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text("$sign${change.toStringAsFixed(2)}€ ($sign${percent.toStringAsFixed(1)}%)", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildChartFilterButtons(WidgetRef ref) {
    final current = ref.watch(chartFilterProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _chartBtn("1W", ChartFilter.week, current, ref),
        _chartBtn("1M", ChartFilter.month, current, ref),
        _chartBtn("1J", ChartFilter.year, current, ref),
        _chartBtn("Max", ChartFilter.all, current, ref),
      ],
    );
  }

  Widget _chartBtn(String label, ChartFilter filter, ChartFilter current, WidgetRef ref) {
    final isSelected = filter == current;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) ref.read(chartFilterProvider.notifier).state = filter;
        },
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        selectedColor: Colors.blueAccent,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      ),
    );
  }

  Widget _buildTop10List(List<InventoryItem> items, BuildContext context) {
    // Feste Höhe für die horizontale Liste (Kartenhöhe + Text)
    return SizedBox(
      height: 240, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // <--- SEITLICH SCROLLEN
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          
          return Container(
            width: 140, // Feste Breite pro Karte
            margin: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CardDetailScreen(card: item.card)));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DAS BILD (Groß wie in der Suche)
                  Expanded(
                    child: Card(
                      elevation: 4,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: "top10_${item.card.id}",
                            child: CachedNetworkImage(
                              imageUrl: item.card.smallImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_,__) => Container(color: Colors.grey[200]),
                            ),
                          ),
                          // Menge Badge (oben rechts)
                          Positioned(
                            top: 4, right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.blue[800], borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                "${item.quantity}x", 
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // TEXT INFOS (Unter der Karte)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.variant == 'Reverse Holo' ? 'Rev.' : item.variant,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      Text(
                        "${item.totalValue.toStringAsFixed(2)}€",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// =========================================================
// CHART LOGIK (fl_chart)
// =========================================================
class _PortfolioChart extends ConsumerWidget {
  final List<db.PortfolioHistoryData> history;
  final double currentTotal; // Live Wert übergeben!

  const _PortfolioChart({required this.history, required this.currentTotal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(chartFilterProvider);
    final now = DateTime.now();
    
    // 1. Daten vorbereiten (Kopie der Liste)
    // Wir nehmen die History aus der DB.
    List<db.PortfolioHistoryData> filteredData = List.from(history);

    // 2. Den "Live"-Wert als allerletzten Punkt hinzufügen, falls er noch nicht in DB ist (oder abweicht)
    // Damit das Diagramm wirklich "jetzt" anzeigt.
    if (filteredData.isEmpty || !isSameDay(filteredData.last.date, now)) {
        filteredData.add(db.PortfolioHistoryData(id: -1, date: now, totalValue: currentTotal));
    } else {
        // Falls für heute schon was in DB steht, aktualisieren wir den Wert visuell mit dem Live-Wert
        // (Wir erstellen ein temporäres Objekt dafür, da DB Objekte oft final sind)
        filteredData.removeLast();
        filteredData.add(db.PortfolioHistoryData(id: -1, date: now, totalValue: currentTotal));
    }

    // 3. Filtern nach Zeit
    if (filteredData.isNotEmpty) {
      DateTime start = now;
      switch (filter) {
        case ChartFilter.week: start = now.subtract(const Duration(days: 7)); break;
        case ChartFilter.month: start = now.subtract(const Duration(days: 30)); break;
        case ChartFilter.year: start = now.subtract(const Duration(days: 365)); break;
        case ChartFilter.all: start = DateTime(2000); break;
      }
      filteredData = filteredData.where((d) => d.date.isAfter(start)).toList();
    }

    // 4. FIX: Wenn nur 1 Punkt da ist (Heute), fügen wir "Gestern" mit 0€ hinzu
    // Damit eine Linie entsteht, die bei 0 startet.
    if (filteredData.length == 1) {
      final firstDate = filteredData.first.date;
      filteredData.insert(0, db.PortfolioHistoryData(
        id: -2, 
        date: firstDate.subtract(const Duration(days: 1)), 
        totalValue: 0.0 // Start bei 0!
      ));
    } else if (filteredData.isEmpty) {
      // Fallback für komplett leeres System
      return const Center(child: Text("Sammle Daten..."));
    }

    // 5. Spots erstellen
    final spots = filteredData.map((e) {
      // X-Achse: Millisekunden seit Epoch (als double)
      return FlSpot(e.date.millisecondsSinceEpoch.toDouble(), e.totalValue);
    }).toList();

    // Min/Max für Y-Achse
    double minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    
    if (maxY == 0) maxY = 10; // Verhindert Crash bei leerem Graphen
    minY = minY * 0.9;
    maxY = maxY * 1.1;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false), // Achsenbeschriftung aus für cleaneren Look
        borderData: FlBorderData(show: false),
        minX: spots.first.x,
        maxX: spots.last.x,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              // Verlauf unter der Linie
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blueAccent.withOpacity(0.3),
                  Colors.blueAccent.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                final dateStr = DateFormat('dd.MM.').format(date);
                return LineTooltipItem(
                  "$dateStr\n${spot.y.toStringAsFixed(2)}€",
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
  
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// =========================================================
// VIEW 2: SUCHERGEBNISSE (Grid View)
// =========================================================
class _SearchResultsView extends ConsumerWidget {
  const _SearchResultsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchAsyncValue = ref.watch(searchResultsProvider);

    return searchAsyncValue.when(
      data: (cards) {
        if (cards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Keine Karten gefunden.'),
              ],
            ),
          );
        }
        
        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.70,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            final bool isOwned = card.isOwned;

            // --- PREIS BERECHNUNG ---
            double? displayPrice = card.cardmarket?.trendPrice;
            if (displayPrice == null || displayPrice == 0) {
              displayPrice = card.tcgplayer?.prices?.normal?.market ?? 
                             card.tcgplayer?.prices?.holofoil?.market ?? 
                             card.tcgplayer?.prices?.reverseHolofoil?.market;
            }

            return InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)))
                  .then((_) => ref.invalidate(searchResultsProvider));
              },
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => InventoryBottomSheet(card: card),
                ).then((_) => ref.invalidate(searchResultsProvider));
              },
              child: Card(
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // BILD
                    Hero(
                      tag: card.id,
                      child: CachedNetworkImage(
                        imageUrl: card.smallImageUrl,
                        placeholder: (context, url) => Container(color: Colors.grey[200]),
                        errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                        fit: BoxFit.cover,
                      ),
                    ),
                    
                    // INFO-BALKEN UNTEN
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
                            if (isOwned)
                              const Icon(Icons.check_circle, color: Colors.green, size: 12)
                            else if (displayPrice != null && displayPrice > 0)
                              Text(
                                '${displayPrice.toStringAsFixed(2)}€',
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
      error: (e,s) => Center(child: Text("Fehler: $e")),
    );
  }
}