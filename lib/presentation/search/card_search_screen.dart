import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; 

import '../../data/database/app_database.dart' as db; 
import '../../data/api/search_provider.dart'; 
import '../cards/card_detail_screen.dart';
import '../inventory/inventory_bottom_sheet.dart';


enum ChartFilter { week, month, year, all }
final chartFilterProvider = StateProvider<ChartFilter>((ref) => ChartFilter.week);

class CardSearchScreen extends ConsumerStatefulWidget {
  // --- NEUE PARAMETER ---
  final String? initialQuery;
  final bool pickerMode; 
  final bool onlyOwned; 

  const CardSearchScreen({
    super.key, 
    this.initialQuery,
    this.pickerMode = false,
    this.onlyOwned = false,
  });

  @override
  ConsumerState<CardSearchScreen> createState() => _CardSearchScreenState();
}

class _CardSearchScreenState extends ConsumerState<CardSearchScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();

    // 1. Initial Query setzen (entweder vom Parameter oder Provider)
    final startQuery = widget.initialQuery ?? ref.read(searchQueryProvider);
    _searchController = TextEditingController(text: startQuery);

    // 2. Wenn Parameter übergeben wurde, Suche sofort starten
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
       Future.delayed(Duration.zero, () {
         ref.read(searchQueryProvider.notifier).state = widget.initialQuery!;
       });
    }

    // Snapshot nur erstellen, wenn wir NICHT im Picker Modus sind (Performance)
    if (!widget.pickerMode) {
      Future.delayed(Duration.zero, () {
        createPortfolioSnapshot(ref);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final isSearching = searchQuery.isNotEmpty;
    final currentMode = ref.watch(searchModeProvider);

    // Im Picker Mode immer die Ergebnisse anzeigen, sonst Dashboard nur wenn nicht gesucht wird
    final showResults = isSearching || widget.pickerMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pickerMode ? 'Karte auswählen' : (isSearching ? 'Suche' : 'Dashboard')),
      ),
      body: Column(
        children: [
          // --- 1. SUCHLEISTE ---
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  // Fokus automatisch setzen im Picker Mode, wenn keine Query da ist
                  autofocus: widget.pickerMode && (widget.initialQuery?.isEmpty ?? true),
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
                              // Im Picker Mode nicht unfocusen, damit man direkt weitertippen kann
                              if (!widget.pickerMode) FocusScope.of(context).unfocus(); 
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (val) {
                    ref.read(searchQueryProvider.notifier).state = val;
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Filter Chips (Künstler Suche macht im Picker Mode wenig Sinn, aber lassen wir drin)
                Row(
                  children: [
                    _buildFilterChip("Karten Name", SearchMode.name, ref),
                    const SizedBox(width: 8),
                    _buildFilterChip("Künstler", SearchMode.artist, ref),
                    // Optional: Info Chip wenn "Nur Inventar" aktiv ist
                    if (widget.onlyOwned) ...[
                       const SizedBox(width: 8),
                       const Chip(
                         label: Text("Nur Inventar"), 
                         backgroundColor: Colors.greenAccent, 
                         visualDensity: VisualDensity.compact
                       ),
                    ]
                  ],
                ),
              ],
            ),
          ),

          // --- 2. INHALT ---
          Expanded(
            child: showResults 
              ? _SearchResultsView(pickerMode: widget.pickerMode, onlyOwned: widget.onlyOwned) // Parameter weitergeben 
              : const _DashboardView(),    
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
// VIEW 1: DASHBOARD
// =========================================================
class _DashboardView extends ConsumerWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(portfolioHistoryProvider);
    final top10Cards = ref.watch(top10CardsProvider); // Korrekter Provider Name
    final inventoryAsync = ref.watch(inventoryProvider);
    
    final double totalValue = inventoryAsync.valueOrNull?.fold(0.0, (sum, i) => sum! + i.totalValue) ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          _buildPortfolioHeader(context, totalValue, historyAsync),
          
          const SizedBox(height: 24),
          
          // CHART FILTER
          _buildChartFilterButtons(ref),

          const SizedBox(height: 16),

          // DIAGRAMM
          SizedBox(
            height: 200,
            child: historyAsync.when(
              data: (data) => _PortfolioChart(history: data, currentTotal: totalValue),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_,__) => const Center(child: Text("Keine Daten verfügbar")),
            ),
          ),

          const SizedBox(height: 32),

          // TOP 10 KARTEN
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

  Widget _buildPortfolioHeader(BuildContext context, double currentTotal, AsyncValue<List<db.PortfolioHistoryData>> historyAsync) {
    double change = 0.0;
    double percent = 0.0;
    final history = historyAsync.valueOrNull ?? [];
    double previousValue = 0.0;
    final today = DateTime.now();

    for (var i = history.length - 1; i >= 0; i--) {
      if (!_isSameDay(history[i].date, today)) {
        previousValue = history[i].totalValue;
        break; 
      }
    }

    change = currentTotal - previousValue;
    if (previousValue > 0) {
      percent = (change / previousValue) * 100;
    } else if (currentTotal > 0) {
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
    return SizedBox(
      height: 240, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal, 
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          // Bild-Logik: Deutsch wenn verfügbar
          final displayImage = item.card.displayImage;
          
          return Container(
            width: 160, 
            margin: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CardDetailScreen(card: item.card)));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              imageUrl: displayImage,
                              placeholder: (_,__) => Container(color: Colors.grey[200]),
                            ),
                          ),
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
// CHART LOGIK
// =========================================================
class _PortfolioChart extends ConsumerWidget {
  final List<db.PortfolioHistoryData> history;
  final double currentTotal;

  const _PortfolioChart({required this.history, required this.currentTotal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(chartFilterProvider);
    final now = DateTime.now();
    
    // 1. Daten kopieren und sortieren
    List<db.PortfolioHistoryData> chartData = List.from(history);
    chartData.sort((a, b) => a.date.compareTo(b.date)); // Sicherstellen, dass Sortierung stimmt

    // 2. Heutigen DB-Wert durch Live-Wert ersetzen (falls vorhanden)
    if (chartData.isNotEmpty && _isSameDay(chartData.last.date, now)) {
      chartData.removeLast(); 
    }
    // Live-Wert hinzufügen
    chartData.add(db.PortfolioHistoryData(id: -1, date: now, totalValue: currentTotal));

    // --- LOGIK FÜR START BEI NULL ---
    // Wir holen uns das Datum des allerersten Eintrags
    if (chartData.isNotEmpty) {
      final firstDate = chartData.first.date;
      final firstValue = chartData.first.totalValue;

      // Wenn der erste Wert größer als 0 ist, fügen wir EINEN TAG DAVOR eine 0 ein.
      // Das erzeugt den schönen Anstieg von der Basislinie.
      if (firstValue > 0) {
         chartData.insert(0, db.PortfolioHistoryData(
           id: -2, // Fake ID
           date: firstDate.subtract(const Duration(days: 1)), 
           totalValue: 0.0 
         ));
      }
    }

    // 3. Zeitraum filtern
    // Wichtig: Das Filtern passiert NACH dem Hinzufügen der 0.
    // Wenn "1 Woche" gewählt ist, fliegt die 0 raus, wenn der User schon länger sammelt.
    // Das ist korrekt so (die Kurve soll bei alten Nutzern nicht plötzlich auf 0 fallen).
    if (chartData.length > 1) {
      DateTime start = now;
      switch (filter) {
        case ChartFilter.week: start = now.subtract(const Duration(days: 7)); break;
        case ChartFilter.month: start = now.subtract(const Duration(days: 30)); break;
        case ChartFilter.year: start = now.subtract(const Duration(days: 365)); break;
        case ChartFilter.all: start = DateTime(2020); break;
      }
      chartData = chartData.where((d) => d.date.isAfter(start) || d.date.isAtSameMomentAs(start)).toList();
    }

    if (chartData.isEmpty) return const Center(child: Text("Warte auf Daten..."));

    // 4. Spots für FL Chart erstellen
    final spots = chartData.map((e) {
      return FlSpot(e.date.millisecondsSinceEpoch.toDouble(), e.totalValue);
    }).toList();

    // Min/Max Berechnung für schöne Skalierung
    double minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    
    // Wenn Linie flach ist oder leer
    if (minY == maxY) { 
        if (minY == 0) { maxY = 100; } 
        else { minY = minY * 0.5; maxY = maxY * 1.5; }
    }
    
    // Puffer hinzufügen (Y-Achse)
    final double yBuffer = (maxY - minY) * 0.1; // 10% Puffer
    minY -= yBuffer;
    if (minY < 0) minY = 0; // Nicht unter 0 gehen
    maxY += yBuffer;

    return Padding(
      // Padding rechts erhöht, damit die letzte Datums-Label nicht abgeschnitten wird
      padding: const EdgeInsets.only(right: 24.0, left: 6, top: 24, bottom: 10),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            // Horizontale Linien sehr dezent
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.15),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            
            // --- Y-ACHSE (LINKS) MIT PREISEN ---
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, // Hier auf TRUE setzen!
                reservedSize: 40, // Platz für Text reservieren
                interval: (maxY - minY) / 4, // Ca. 4 Labels
                getTitlesWidget: (value, meta) {
                  if (value < 0) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      "${value.toInt()}€",
                      style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            
            // --- X-ACHSE (UNTEN) MIT DATUM ---
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                // Dynamisches Intervall für bessere Lesbarkeit
                interval: (spots.last.x - spots.first.x) > 0 
                      ? (spots.last.x - spots.first.x) / 4 
                      : 1.0, 
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd.MM.').format(date), 
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: spots.first.x,
          maxX: spots.last.x,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25, // Kurven-Stärke
              color: Colors.blueAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false), // Punkte im Normalzustand aus
              belowBarData: BarAreaData(
                show: true,
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
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.blueGrey.shade800,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                  final dateStr = DateFormat('dd.MM.yyyy').format(date);
                  return LineTooltipItem(
                    "$dateStr\n${spot.y.toStringAsFixed(2)} €",
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.all(8),
              fitInsideHorizontally: true, 
              fitInsideVertically: true,
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// =========================================================
// VIEW 2: SUCHERGEBNISSE
// =========================================================
class _SearchResultsView extends ConsumerWidget {
  final bool pickerMode;
  final bool onlyOwned;

  const _SearchResultsView({this.pickerMode = false, this.onlyOwned = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchAsyncValue = ref.watch(searchResultsProvider);

    return searchAsyncValue.when(
      data: (allCards) {
        // --- FILTER: Wenn "Nur Inventar" aktiv ist ---
        final cards = onlyOwned 
            ? allCards.where((c) => c.isOwned).toList() 
            : allCards;

        if (cards.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Keine Karten gefunden.'),
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

            // Preisberechnung
            double? displayPrice = card.cardmarket?.trendPrice;
            if (displayPrice == null || displayPrice == 0) {
              displayPrice = card.tcgplayer?.prices?.normal?.market ?? 
                             card.tcgplayer?.prices?.holofoil?.market ?? 
                             card.tcgplayer?.prices?.reverseHolofoil?.market;
            }
            
            final displayImage = card.displayImage;

            return InkWell(
              onTap: () {
                if (pickerMode) {
                  // --- FIX: Wir geben das GANZE Karten-Objekt zurück, nicht nur die ID ---
                  Navigator.pop(context, card); 
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)))
                    .then((_) => ref.invalidate(searchResultsProvider));
                }
              },
              onLongPress: () {
                // Inventar Menü nur im Normalmodus oder wenn gewollt
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => InventoryBottomSheet(card: card),
                ).then((_) => ref.invalidate(searchResultsProvider));
              },
              child: Card(
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                // Visuelles Feedback im Picker Mode (z.B. grüner Rahmen wenn owned)
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: (pickerMode && isOwned) ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: card.id, // Tag beachten bei Picker Mode könnte Hero conflict machen, aber meist ok
                      child: CachedNetworkImage(
                        imageUrl: displayImage,
                        placeholder: (context, url) => Container(color: Colors.grey[200]),
                        errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
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
                            if (displayPrice != null && displayPrice > 0)
                              Text(
                                '${displayPrice.toStringAsFixed(2)}€',
                                style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Im Picker Mode Overlay, wenn nicht owned aber onlyOwned gefordert (sollte durch Filter weg sein, aber sicher ist sicher)
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