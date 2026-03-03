import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; 
import '../../data/database/database_provider.dart';
import '../../data/database/app_database.dart' as db; 
import '../../data/api/search_provider.dart'; 
import '../../domain/models/api_card.dart';
import '../cards/card_detail_screen.dart';
import '../inventory/inventory_bottom_sheet.dart';
import 'package:drift/drift.dart' hide Column;
import 'dart:async';


enum ChartFilter { week, month, year, all }
final chartFilterProvider = StateProvider<ChartFilter>((ref) => ChartFilter.week);

class CardSearchScreen extends ConsumerStatefulWidget {
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
  late FocusNode _focusNode; 
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    final startQuery = widget.initialQuery ?? ref.read(searchQueryProvider);
    _searchController = TextEditingController(text: startQuery);

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
       Future.delayed(Duration.zero, () {
         ref.read(searchQueryProvider.notifier).state = widget.initialQuery!;
       });
    }

    if (!widget.pickerMode) {
      Future.delayed(Duration.zero, () {
        createPortfolioSnapshot(ref);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final isSearching = searchQuery.isNotEmpty;
    final currentMode = ref.watch(searchModeProvider);

    // --- WICHTIG: Im Picker-Mode zeigen wir IMMER Ergebnisse, auch wenn Suche leer ist! ---
    final showResults = isSearching || widget.pickerMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pickerMode ? 'Karte auswählen' : (isSearching ? 'Suche' : 'Dashboard')),
        actions: [
          if (isSearching && !widget.pickerMode)
            IconButton(
              icon: const Icon(Icons.home),
              tooltip: "Zurück zum Start (Suche leeren)",
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state = '';
                _searchController.clear();
                FocusScope.of(context).unfocus();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // --- 1. SUCHLEISTE MIT AUTOCOMPLETE ---
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => RawAutocomplete<String>(
                    textEditingController: _searchController,
                    focusNode: _focusNode,
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      final query = textEditingValue.text.trim();
                      if (query.length < 2) return const Iterable<String>.empty();
                      
                      // Im Inventar-Picker brauchen wir kein Autocomplete von der ganzen DB
                      if (widget.onlyOwned) return const Iterable<String>.empty();

                      final dbInst = ref.read(databaseProvider);
                      final mode = ref.read(searchModeProvider);

                      final select = dbInst.select(dbInst.cards);
                      if (mode == SearchMode.name) {
                        select.where((t) => t.name.like('%$query%') | t.nameDe.like('%$query%'));
                      } else {
                        select.where((t) => t.artist.like('%$query%'));
                      }
                      select.limit(8); 
                      final rows = await select.get();
                      
                      final Set<String> results = {};
                      for (var r in rows) {
                        if (mode == SearchMode.name) {
                          if (r.nameDe != null && r.nameDe!.toLowerCase().contains(query.toLowerCase())) {
                            results.add(r.nameDe!);
                          } else if (r.name.toLowerCase().contains(query.toLowerCase())) {
                            results.add(r.name);
                          }
                        } else {
                          if (r.artist != null && r.artist!.toLowerCase().contains(query.toLowerCase())) {
                            results.add(r.artist!);
                          }
                        }
                      }
                      return results;
                    },
                    onSelected: (String selection) {
                      ref.read(searchQueryProvider.notifier).state = selection;
                      _focusNode.unfocus();
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        autofocus: widget.pickerMode && (widget.initialQuery?.isEmpty ?? true),
                        decoration: InputDecoration(
                          hintText: currentMode == SearchMode.name ? 'Suche Karte (z.B. Glurak)...' : 'Suche Künstler...',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: controller.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    controller.clear();
                                    ref.read(searchQueryProvider.notifier).state = '';
                                    if (!widget.pickerMode) focusNode.unfocus(); 
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(const Duration(milliseconds: 500), () {
                            if (mounted) ref.read(searchQueryProvider.notifier).state = val;
                          });
                        },
                        onSubmitted: (val) {
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          if (mounted) ref.read(searchQueryProvider.notifier).state = val;
                          focusNode.unfocus();
                          onFieldSubmitted();
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: 250, 
                              maxWidth: constraints.maxWidth, 
                            ),
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);
                                return ListTile(
                                  leading: const Icon(Icons.search, size: 18, color: Colors.grey),
                                  title: Text(option, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  visualDensity: VisualDensity.compact,
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    _buildFilterChip("Karten Name", SearchMode.name, ref),
                    const SizedBox(width: 8),
                    _buildFilterChip("Künstler", SearchMode.artist, ref),
                    if (widget.onlyOwned) ...[
                       const SizedBox(width: 8),
                       const Chip(
                         label: Text("Dein Inventar", style: TextStyle(fontWeight: FontWeight.bold)), 
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
              ? _SearchResultsView(pickerMode: widget.pickerMode, onlyOwned: widget.onlyOwned)
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
    final top10Cards = ref.watch(top10CardsProvider); 
    final inventoryAsync = ref.watch(inventoryProvider);
    
    final double totalValue = inventoryAsync.valueOrNull?.fold(0.0, (sum, i) => sum! + i.totalValue) ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPortfolioHeader(context, totalValue, historyAsync),
          const SizedBox(height: 24),
          _buildChartFilterButtons(ref),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: historyAsync.when(
              data: (data) => _PortfolioChart(history: data, currentTotal: totalValue),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_,__) => const Center(child: Text("Keine Daten verfügbar")),
            ),
          ),
          const SizedBox(height: 32),
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
                              memCacheWidth: 300, 
                              fadeOutDuration: const Duration(milliseconds: 100), 
                              fadeInDuration: const Duration(milliseconds: 100),
                              placeholder: (context, url) => Container(color: Colors.grey[200]),
                              errorWidget: (context, url, error) => const Icon(Icons.broken_image),
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
    
    List<db.PortfolioHistoryData> chartData = List.from(history);
    chartData.sort((a, b) => a.date.compareTo(b.date)); 

    if (chartData.isNotEmpty && _isSameDay(chartData.last.date, now)) {
      chartData.removeLast(); 
    }
    chartData.add(db.PortfolioHistoryData(id: -1, date: now, totalValue: currentTotal));

    if (chartData.isNotEmpty) {
      final firstDate = chartData.first.date;
      final firstValue = chartData.first.totalValue;

      if (firstValue > 0) {
         chartData.insert(0, db.PortfolioHistoryData(
           id: -2, 
           date: firstDate.subtract(const Duration(days: 1)), 
           totalValue: 0.0 
         ));
      }
    }

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

    final spots = chartData.map((e) {
      return FlSpot(e.date.millisecondsSinceEpoch.toDouble(), e.totalValue);
    }).toList();

    double minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    
    if (minY == maxY) { 
        if (minY == 0) { maxY = 100; } 
        else { minY = minY * 0.5; maxY = maxY * 1.5; }
    }
    
    final double yBuffer = (maxY - minY) * 0.1; 
    minY -= yBuffer;
    if (minY < 0) minY = 0; 
    maxY += yBuffer;

    return Padding(
      padding: const EdgeInsets.only(right: 24.0, left: 6, top: 24, bottom: 10),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.15),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, 
                reservedSize: 40, 
                interval: (maxY - minY) / 4, 
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
            
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
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
              curveSmoothness: 0.25, 
              color: Colors.blueAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false), 
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
// VIEW 2: SUCHERGEBNISSE ODER INVENTAR-PICKER
// =========================================================
class _SearchResultsView extends ConsumerWidget {
  final bool pickerMode;
  final bool onlyOwned;

  const _SearchResultsView({this.pickerMode = false, this.onlyOwned = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    // --- FALL 1: WIR SUCHEN NUR IM EIGENEN INVENTAR (Picker Mode) ---
    if (onlyOwned) {
      final inventoryAsync = ref.watch(inventoryProvider);
      final queryText = ref.watch(searchQueryProvider).toLowerCase();
      final mode = ref.watch(searchModeProvider);

      return inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Fehler: $e")),
        data: (items) {
          
          // 1. Duplikate entfernen und exakten Status berechnen
          // Status 0 = Komplett lose (in keinem Binder)
          // Status 1 = Teilweise lose (Du hast noch Reserve-Karten)
          // Status 2 = Komplett verplant (Alle stecken im Binder)
          final Map<String, ApiCard> uniqueCards = {};
          final Map<String, int> looseStatusMap = {}; 

          for (var item in items) {
             uniqueCards[item.card.id] = item.card;
             
             if (item.binderName == null) {
               // Karte ist lose
               if (looseStatusMap[item.card.id] == 2) {
                   looseStatusMap[item.card.id] = 1; // Hatten schon Binder -> jetzt Teilweise (1)
               } else {
                   looseStatusMap.putIfAbsent(item.card.id, () => 0); // Bisher nur lose gesehen -> (0)
               }
             } else {
               // Karte steckt im Binder
               if (looseStatusMap[item.card.id] == 0) {
                   looseStatusMap[item.card.id] = 1; // Hatten schon Lose -> jetzt Teilweise (1)
               } else {
                   looseStatusMap.putIfAbsent(item.card.id, () => 2); // Bisher nur Binder gesehen -> (2)
               }
             }
          }
          
          List<ApiCard> cards = uniqueCards.values.toList();

          // 2. Suche lokal filtern
          if (queryText.isNotEmpty) {
            cards = cards.where((c) {
              if (mode == SearchMode.name) {
                return c.name.toLowerCase().contains(queryText) || 
                      (c.nameDe?.toLowerCase().contains(queryText) ?? false);
              } else {
                return (c.artist.toLowerCase().contains(queryText));
              }
            }).toList();
          }

          // 3. 3-STUFEN-SORTIERUNG ANWENDEN
          cards.sort((a, b) {
            final statusA = looseStatusMap[a.id] ?? 2;
            final statusB = looseStatusMap[b.id] ?? 2;

            // Zuerst nach Status sortieren (0 -> 1 -> 2)
            final statusCompare = statusA.compareTo(statusB);
            if (statusCompare != 0) return statusCompare;
            
            // Wenn beide gleichen Status haben, alphabetisch sortieren
            return (a.nameDe ?? a.name).compareTo(b.nameDe ?? b.name);
          });

          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(queryText.isEmpty ? "Dein Inventar ist leer." : "Keine passende Karte gefunden."),
                ],
              ),
            );
          }

          return _buildGrid(cards, context, ref, pickerMode);
        },
      );
    } 
    // --- FALL 2: GLOBALE KARTEN SUCHE ---
    else {
      final searchAsyncValue = ref.watch(searchResultsProvider);
      final queryText = ref.watch(searchQueryProvider);

      if (queryText.isEmpty) {
         return const SizedBox(); 
      }

      return searchAsyncValue.when(
        data: (allCards) {
          if (allCards.isEmpty) {
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
          
          return _buildGrid(allCards, context, ref, pickerMode);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e,s) => Center(child: Text("Fehler: $e")),
      );
    }
  }

  // --- DAS GEMEINSAME GRID FÜR BEIDE FÄLLE ---
  Widget _buildGrid(List<ApiCard> cards, BuildContext context, WidgetRef ref, bool isPicker) {
    return GridView.builder(
      cacheExtent: 100, 
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

        double? displayPrice = card.cardmarket?.trendPrice;
        if (displayPrice == null || displayPrice == 0) {
          displayPrice = card.tcgplayer?.prices?.normal?.market ?? 
                         card.tcgplayer?.prices?.holofoil?.market ?? 
                         card.tcgplayer?.prices?.reverseHolofoil?.market;
        }
        
        final displayImage = card.displayImage;

        return Consumer(
          builder: (context, cardRef, child) {
            final binderLocationsAsync = cardRef.watch(cardBinderLocationProvider(card.id));
            
            return InkWell(
              onTap: () {
                if (isPicker) {
                  Navigator.pop(context, card); 
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)))
                    .then((_) {
                      ref.invalidate(searchResultsProvider);
                      ref.invalidate(cardBinderLocationProvider(card.id)); 
                    });
                }
              },
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => InventoryBottomSheet(card: card),
                ).then((_) {
                  ref.invalidate(searchResultsProvider);
                  ref.invalidate(cardBinderLocationProvider(card.id));
                });
              },
              child: Card(
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: (isPicker && isOwned) ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: displayImage,
                      memCacheWidth: 200, 
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                      fadeInDuration: const Duration(milliseconds: 150),
                    ),
                    
                    // --- BINDER BADGE ---
                    binderLocationsAsync.when(
                      data: (binders) {
                        if (binders.isEmpty) return const SizedBox();
                        
                        final badgeText = binders.length > 1 
                            ? "${binders.first} (+${binders.length - 1})" 
                            : binders.first;
                            
                        return Positioned(
                          top: 4, left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 2)],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.folder_special, color: Colors.white, size: 10),
                                const SizedBox(width: 3),
                                Text(
                                  badgeText,
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loading: () => const SizedBox(),
                      error: (_,__) => const SizedBox(),
                    ),

                    // --- PREIS LEISTE ---
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
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }
}