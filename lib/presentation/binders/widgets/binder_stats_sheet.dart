import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../binder_detail_provider.dart';

/// Modal bottom sheet content displaying historical valuation charts and completion stats for a binder or bulk box.
class BinderStatsSheet extends ConsumerWidget {
  /// The database ID of the binder or bulk box.
  final int binderId;

  /// The current state snapshot containing slot counts and total valuation.
  final BinderDetailState currentState;

  /// Callback executed when the user confirms deletion of the binder.
  final VoidCallback onDelete;

  /// Whether the parent storage entity is a bulk box rather than a binder.
  final bool isBulkBox;

  const BinderStatsSheet({
    super.key,
    required this.binderId,
    required this.currentState,
    required this.onDelete,
    this.isBulkBox = false,
  });

  /// Displays the statistics sheet as a modal bottom sheet.
  static void show(
    BuildContext context, {
    required int binderId,
    required BinderDetailState currentState,
    required VoidCallback onDelete,
    bool isBulkBox = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final bottomPadding = MediaQuery.of(sheetContext).padding.bottom;
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.88,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            24 + bottomPadding + bottomInset,
          ),
          child: BinderStatsSheet(
            binderId: binderId,
            currentState: currentState,
            onDelete: onDelete,
            isBulkBox: isBulkBox,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(binderHistoryProvider(binderId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Statistik & Verlauf",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 5),
        historyAsync.when(
          data: (history) {
            double change = 0;
            double percent = 0;
            final current = currentState.totalValue;

            if (history.length >= 2) {
              final last = history.last.value;
              final prev = history[history.length - 2].value;
              change = last - prev;

              if (prev > 0) {
                percent = (change / prev) * 100;
              } else if (change > 0) {
                percent = 100.0;
              }
            }

            final isPositive = change >= -0.01;
            final color = isPositive ? Colors.green : Colors.red;
            final sign = isPositive ? "+" : "";

            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${current.toStringAsFixed(2)} €",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "$sign${change.toStringAsFixed(2)}€ ($sign${percent.toStringAsFixed(1)}%)",
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Text(
            "Lade Historie...",
            style: TextStyle(color: Colors.grey),
          ),
          error: (e, s) => const SizedBox(),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: historyAsync.when(
            data: (history) {
              if (history.length < 2) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.show_chart,
                          size: 48,
                          color: isDark
                              ? const Color(0xFF334155)
                              : Colors.grey[300]),
                      Text(
                        "Zu wenig Daten für einen Graphen",
                        style: TextStyle(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              return BinderHistoryChart(history: history);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text("Fehler beim Laden: $e")),
          ),
        ),
        const SizedBox(height: 20),
        const Divider(),
        ListTile(
          leading: Icon(
            isBulkBox ? Icons.inventory_2 : Icons.pie_chart,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            isBulkBox ? "Karten im Karton" : "Vervollständigung",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Text(
            isBulkBox
                ? "${currentState.filledSlots}"
                : "${currentState.filledSlots} / ${currentState.totalSlots}",
            style: TextStyle(
              color: isDark ? const Color(0xFFCBD5E1) : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: isBulkBox
              ? null
              : ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: currentState.filledSlots /
                        (currentState.totalSlots == 0
                            ? 1
                            : currentState.totalSlots),
                    backgroundColor: isDark
                        ? const Color(0xFF334155)
                        : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary),
                    minHeight: 8,
                  ),
                ),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: Text(
            isBulkBox ? "Ganze Box löschen" : "Binder löschen",
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: onDelete,
        ),
      ],
    );
  }
}

/// Line chart displaying value fluctuation points over time.
class BinderHistoryChart extends StatelessWidget {
  /// Ordered price history points.
  final List<BinderHistoryPoint> history;

  const BinderHistoryChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    List<FlSpot> spots = [];
    final Set<double> seenX = {};
    for (final p in history) {
      final double x = p.date.millisecondsSinceEpoch.toDouble();
      if (!seenX.contains(x)) {
        spots.add(FlSpot(x, p.value));
        seenX.add(x);
      }
    }

    if (spots.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch.toDouble();
      spots = [FlSpot(now - 86400000, 0), FlSpot(now, 0)];
    } else if (spots.length == 1) {
      final alone = spots.first;
      spots = [FlSpot(alone.x - 86400000, 0), alone];
    }

    double minX = spots.first.x;
    double maxX = spots.last.x;
    if (minX == maxX) {
      minX -= 86400000;
      maxX += 86400000;
    }

    double minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    if (minY == maxY) {
      if (minY == 0) {
        maxY = 10;
      } else {
        minY = minY * 0.8;
        maxY = maxY * 1.2;
      }
    }

    final deltaY = maxY - minY;
    minY -= deltaY * 0.1;
    maxY += deltaY * 0.1;
    if (minY < 0) minY = 0;

    double xInterval = (maxX - minX) / 3;
    if (xInterval <= 0) xInterval = 86400000;

    double yInterval = (maxY - minY) / 4;
    if (yInterval <= 0) yInterval = 1.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: isDark ? const Color(0xFF334155) : Colors.grey[200], strokeWidth: 1),
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
              interval: yInterval,
              getTitlesWidget: (val, _) {
                if (val < 0) return const SizedBox();
                return Text(
                  "${val.toInt()}€",
                  style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey[500],
                      fontSize: 10),
                  textAlign: TextAlign.right,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: xInterval,
              getTitlesWidget: (val, _) {
                final date = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('dd.MM').format(date),
                    style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey[500],
                        fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withValues(alpha: 0.35),
                  primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor:
                isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                return LineTooltipItem(
                  "${DateFormat('dd.MM').format(date)}\n${spot.y.toStringAsFixed(2)} €",
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
