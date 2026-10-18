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
import '../widgets/app_drawer.dart';
import 'widgets/search_card_tile.dart';
import 'package:drift/drift.dart' hide Column;
import 'dart:async';

enum ChartFilter { week, month, year, all }

final chartFilterProvider =
    StateProvider.autoDispose<ChartFilter>((ref) => ChartFilter.week);

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

    final showResults = isSearching || widget.pickerMode;

    return Scaffold(
      drawer: widget.pickerMode
          ? null
          : const AppDrawer(),
      appBar: AppBar(
        title: Text(widget.pickerMode
            ? 'Karte auswählen'
            : (isSearching ? 'Suche' : 'Dashboard')),
        leading: widget.pickerMode
            ? null
            : Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context)
                          .openDrawer();
                    },
                  );
                },
              ),
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
                      if (query.length < 2) {
                        return const Iterable<String>.empty();
                      }

                      if (widget.onlyOwned) {
                        return const Iterable<String>.empty();
                      }

                      final dbInst = ref.read(databaseProvider);
                      final mode = ref.read(searchModeProvider);

                      final select = dbInst.select(dbInst.cards);
                      if (mode == SearchMode.name) {
                        select.where((t) =>
                            t.name.like('%$query%') |
                            t.nameDe.like('%$query%'));
                      } else {
                        select.where((t) => t.artist.like('%$query%'));
                      }
                      select.limit(8);
                      final rows = await select.get();

                      final Set<String> results = {};
                      for (var r in rows) {
                        if (mode == SearchMode.name) {
                          if (r.nameDe != null &&
                              r.nameDe!
                                  .toLowerCase()
                                  .contains(query.toLowerCase())) {
                            results.add(r.nameDe!);
                          } else if (r.name
                              .toLowerCase()
                              .contains(query.toLowerCase())) {
                            results.add(r.name);
                          }
                        } else {
                          if (r.artist != null &&
                              r.artist!
                                  .toLowerCase()
                                  .contains(query.toLowerCase())) {
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
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        autofocus: widget.pickerMode &&
                            (widget.initialQuery?.isEmpty ?? true),
                        decoration: InputDecoration(
                          hintText: currentMode == SearchMode.name
                              ? 'Suche Karte (z.B. Glurak)...'
                              : 'Suche Künstler...',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: controller.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    controller.clear();
                                    ref
                                        .read(searchQueryProvider.notifier)
                                        .state = '';
                                    if (!widget.pickerMode) focusNode.unfocus();
                                  },
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          if (_debounce?.isActive ?? false) {
                            _debounce!.cancel();
                          }
                          _debounce =
                              Timer(const Duration(milliseconds: 500), () {
                            if (mounted) {
                              ref.read(searchQueryProvider.notifier).state =
                                  val;
                            }
                          });
                        },
                        onSubmitted: (val) {
                          if (_debounce?.isActive ?? false) {
                            _debounce!.cancel();
                          }
                          if (mounted) {
                            ref.read(searchQueryProvider.notifier).state = val;
                          }
                          focusNode.unfocus();
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
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                      height: 1, color: Colors.black12),
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);
                                return ListTile(
                                  leading: const Icon(Icons.search,
                                      size: 18, color: Colors.grey),
                                  title: Text(option,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
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
                          label: Text("Dein Inventar",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.greenAccent,
                          visualDensity: VisualDensity.compact),
                    ]
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: showResults
                ? _SearchResultsView(
                    pickerMode: widget.pickerMode, onlyOwned: widget.onlyOwned)
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
      selectedColor: Colors.blue.withValues(alpha: 0.2),
      onSelected: (val) {
        if (val) {
          ref.read(searchModeProvider.notifier).state = mode;
          if (ref.read(searchQueryProvider).isNotEmpty) {
            ref.invalidate(searchResultsProvider);
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
    final top10Gainers = ref.watch(top10GainersProvider);
    final top10Losers = ref.watch(top10LosersProvider);
    final inventoryAsync = ref.watch(inventoryProvider);

    final double totalValue = inventoryAsync.valueOrNull
            ?.fold(0.0, (sum, i) => sum! + i.totalValue) ??
        0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 100),
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
              data: (data) =>
                  _PortfolioChart(history: data, currentTotal: totalValue),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text("Keine Daten verfügbar")),
            ),
          ),
          const SizedBox(height: 32),
          const Text("Deine Top 10 (Gesamtwert)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (top10Cards.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12)),
              child: const Center(
                  child: Text("Noch keine wertvollen Karten im Inventar.",
                      style: TextStyle(color: Colors.grey))),
            )
          else
            _buildTop10List(top10Cards, context, showPerformance: false),
          const SizedBox(height: 32),
          const Text("Top Gewinner (Seit Kauf)",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green)),
          const SizedBox(height: 12),
          if (top10Gainers.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!)),
              child: const Center(
                  child: Text("Noch keine Karten mit Wertsteigerung.",
                      style: TextStyle(color: Colors.green))),
            )
          else
            _buildTop10List(top10Gainers, context, showPerformance: true),
          const SizedBox(height: 32),
          Text("Größte Verluste (Seit Kauf)",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700])),
          const SizedBox(height: 12),
          if (top10Losers.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!)),
              child: Center(
                  child: Text("Juhu! Keine Karten mit Wertverlust.",
                      style: TextStyle(color: Colors.red[700]))),
            )
          else
            _buildTop10List(top10Losers, context, showPerformance: true),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPortfolioHeader(BuildContext context, double currentTotal,
      AsyncValue<List<db.PortfolioHistoryData>> historyAsync) {
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

    // When portfolio was cleared or has zero value
    if (currentTotal == 0.0) {
      change = 0.0;
      percent = 0.0;
    } else {
      change = currentTotal - previousValue;
      if (previousValue > 0) {
        percent = (change / previousValue) * 100;
      } else if (currentTotal > 0) {
        percent = 100.0;
      }
    }

    final isPositive = change >= -0.01;
    final sign = isPositive ? "+" : "";
    final color = isPositive ? Colors.green : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Portfolio Wert",
            style: TextStyle(color: Colors.grey, fontSize: 14)),
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
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                      "$sign${change.toStringAsFixed(2)}€ ($sign${percent.toStringAsFixed(1)}%)",
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
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

  Widget _chartBtn(
      String label, ChartFilter filter, ChartFilter current, WidgetRef ref) {
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
        labelStyle:
            TextStyle(color: isSelected ? Colors.white : Colors.black87),
      ),
    );
  }

  Widget _buildTop10List(List<InventoryItem> items, BuildContext context,
      {required bool showPerformance}) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final displayImage = item.card.displayImage;

          return RepaintBoundary(
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CardDetailScreen(card: item.card)));
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Expanded(
                    child: Card(
                      elevation: 4,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag:
                                "top10_${showPerformance ? 'perf' : 'val'}_${item.card.id}_$index",
                            child: CachedNetworkImage(
                              imageUrl: displayImage,
                              memCacheWidth: 200,
                              fadeOutDuration:
                                  const Duration(milliseconds: 100),
                              fadeInDuration: const Duration(milliseconds: 100),
                              placeholder: (context, url) =>
                                  Container(color: Colors.grey[200]),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.broken_image),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.blue[800],
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text("${item.quantity}x",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
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
                      Builder(builder: (context) {
                        String textToShow =
                            "${item.totalValue.toStringAsFixed(2)}€";
                        Color textColor = Colors.green;

                        if (showPerformance) {
                          if (item.performance > 0) {
                            textToShow =
                                "+${item.performance.toStringAsFixed(2)}€";
                            textColor = Colors.green[700]!;
                          } else {
                            textToShow =
                                "${item.performance.toStringAsFixed(2)}€";
                            textColor = Colors.red[700]!;
                          }
                        }

                        return Text(
                          textToShow,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textColor),
                        );
                      }),
                    ],
                  ),
                ],
              ),
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

    // If user's portfolio is empty (currentTotal == 0), ignore legacy history points and draw flat baseline
    List<db.PortfolioHistoryData> chartData = [];

    if (currentTotal > 0.0) {
      chartData = List.from(history);
      chartData.sort((a, b) => a.date.compareTo(b.date));

      if (chartData.isNotEmpty && _isSameDay(chartData.last.date, now)) {
        chartData.removeLast();
      }
    }

    // Always append latest real-time point
    chartData.add(
        db.PortfolioHistoryData(id: -1, date: now, totalValue: currentTotal));

    if (chartData.isNotEmpty && currentTotal > 0.0) {
      final firstDate = chartData.first.date;
      final firstValue = chartData.first.totalValue;

      if (firstValue > 0) {
        chartData.insert(
            0,
            db.PortfolioHistoryData(
                id: -2,
                date: firstDate.subtract(const Duration(days: 1)),
                totalValue: 0.0));
      }
    }

    if (chartData.length > 1) {
      DateTime start = now;
      switch (filter) {
        case ChartFilter.week:
          start = now.subtract(const Duration(days: 7));
          break;
        case ChartFilter.month:
          start = now.subtract(const Duration(days: 30));
          break;
        case ChartFilter.year:
          start = now.subtract(const Duration(days: 365));
          break;
        case ChartFilter.all:
          start = DateTime(2020);
          break;
      }
      chartData = chartData
          .where((d) => d.date.isAfter(start) || d.date.isAtSameMomentAs(start))
          .toList();
    }

    // Render flat baseline when filtered down to a single point or empty
    if (chartData.isEmpty || chartData.length == 1) {
      chartData = [
        db.PortfolioHistoryData(
            id: -2,
            date: now.subtract(const Duration(days: 1)),
            totalValue: currentTotal),
        db.PortfolioHistoryData(id: -1, date: now, totalValue: currentTotal)
      ];
    }

    final spots = chartData.map((e) {
      return FlSpot(e.date.millisecondsSinceEpoch.toDouble(), e.totalValue);
    }).toList();

    double minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    if (minY == maxY) {
      if (minY == 0) {
        maxY = 100;
      } else {
        minY = minY * 0.5;
        maxY = maxY * 1.5;
      }
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
              color: Colors.grey.withValues(alpha: 0.15),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: (maxY - minY) > 0 ? (maxY - minY) / 4 : 1.0,
                getTitlesWidget: (value, meta) {
                  if (value < 0) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      "${value.toInt()}€",
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
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
                  final date =
                      DateTime.fromMillisecondsSinceEpoch(value.toInt());
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
                    Colors.blueAccent.withValues(alpha: 0.3),
                    Colors.blueAccent.withValues(alpha: 0.0),
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
                  final date =
                      DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                  final dateStr = DateFormat('dd.MM.yyyy').format(date);
                  return LineTooltipItem(
                    "$dateStr\n${spot.y.toStringAsFixed(2)} €",
                    const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
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

// View: Search Results or Inventory Picker
class _SearchResultsView extends ConsumerWidget {
  final bool pickerMode;
  final bool onlyOwned;

  const _SearchResultsView({this.pickerMode = false, this.onlyOwned = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Inventory picker mode
    if (onlyOwned) {
      final inventoryAsync = ref.watch(inventoryProvider);
      final queryText = ref.watch(searchQueryProvider).toLowerCase();
      final mode = ref.watch(searchModeProvider);

      return inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Fehler: $e")),
        data: (items) {
          final Map<String, ApiCard> uniqueCards = {};
          final Map<String, int> looseStatusMap = {};

          for (var item in items) {
            uniqueCards[item.card.id] = item.card;

            if (item.binderName == null) {
              if (looseStatusMap[item.card.id] == 2) {
                looseStatusMap[item.card.id] = 1;
              } else {
                looseStatusMap.putIfAbsent(item.card.id, () => 0);
              }
            } else {
              if (looseStatusMap[item.card.id] == 0) {
                looseStatusMap[item.card.id] = 1;
              } else {
                looseStatusMap.putIfAbsent(item.card.id, () => 2);
              }
            }
          }

          List<ApiCard> cards = uniqueCards.values.toList();

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

          cards.sort((a, b) {
            final statusA = looseStatusMap[a.id] ?? 2;
            final statusB = looseStatusMap[b.id] ?? 2;

            final statusCompare = statusA.compareTo(statusB);
            if (statusCompare != 0) return statusCompare;

            return (a.nameDe ?? a.name).compareTo(b.nameDe ?? b.name);
          });

          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(queryText.isEmpty
                      ? "Dein Inventar ist leer."
                      : "Keine passende Karte gefunden."),
                ],
              ),
            );
          }

          return _buildGrid(cards, context, ref, pickerMode);
        },
      );
    }
    // 2. Global card search
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
        error: (e, s) => Center(child: Text("Fehler: $e")),
      );
    }
  }

  Widget _buildGrid(
      List<ApiCard> cards, BuildContext context, WidgetRef ref, bool isPicker) {
    return GridView.builder(
      padding: const EdgeInsets.only(left: 10, top: 10, right: 10, bottom: 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.70,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return SearchCardTile(
          card: cards[index],
          isPicker: isPicker,
        );
      },
    );
  }
}
