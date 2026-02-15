import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database/app_database.dart';

enum PriceType { cmTrend, cmTrendHolo, cmReverse, tcgMarket, tcgMarketHolo }

class PriceHistoryChart extends StatefulWidget {
  final List<CardMarketPrice> cmHistory;
  final List<TcgPlayerPrice> tcgHistory;

  const PriceHistoryChart({super.key, required this.cmHistory, required this.tcgHistory});

  @override
  State<PriceHistoryChart> createState() => _PriceHistoryChartState();
}

class _PriceHistoryChartState extends State<PriceHistoryChart> {
  PriceType _selectedType = PriceType.cmTrend;
  int _monthsFilter = 3; // Standard: 3 Monate

  @override
  void initState() {
    super.initState();
    // Intelligenten Standard wählen: Wenn Holo Trend existiert, nimm den, sonst Normal
    if (widget.cmHistory.isNotEmpty && widget.cmHistory.last.trendHolo != null) {
      _selectedType = PriceType.cmTrendHolo;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Datenpunkte extrahieren
    final spots = _getSpots();

    if (spots.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: const Text("Keine Preisdaten verfügbar", style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: [
        // 1. Filter (Typ & Zeit)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTypeChip("CM Trend", PriceType.cmTrend),
              const SizedBox(width: 8),
              _buildTypeChip("CM Holo", PriceType.cmTrendHolo),
              const SizedBox(width: 8),
              _buildTypeChip("TCG Market", PriceType.tcgMarket),
              const SizedBox(width: 16),
              // Zeit Filter
              _buildTimeChip("1M", 1),
              const SizedBox(width: 4),
              _buildTimeChip("3M", 3),
              const SizedBox(width: 4),
              _buildTimeChip("1J", 12),
              const SizedBox(width: 4),
              _buildTimeChip("Alle", 999),
            ],
          ),
        ),
        
        const SizedBox(height: 16),

        // 2. Chart
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text("${value.toInt()}€", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: (spots.last.x - spots.first.x) / 4,
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      return Text(DateFormat('dd.MM.').format(date), style: const TextStyle(fontSize: 10, color: Colors.grey));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.blueAccent,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.blueAccent.withOpacity(0.3), Colors.transparent],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.blueGrey.shade800,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                      return LineTooltipItem(
                        "${DateFormat('dd.MM.yy').format(date)}\n${spot.y.toStringAsFixed(2)} €",
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _getSpots() {
    List<FlSpot> rawSpots = [];
    final now = DateTime.now();
    final cutoffDate = _monthsFilter == 999 
        ? DateTime(2000) 
        : now.subtract(Duration(days: _monthsFilter * 30));

    if (_selectedType == PriceType.cmTrend || _selectedType == PriceType.cmTrendHolo) {
      for (var p in widget.cmHistory) {
        if (p.fetchedAt.isBefore(cutoffDate)) continue;
        double? val;
        if (_selectedType == PriceType.cmTrend) val = p.trend;
        else if (_selectedType == PriceType.cmTrendHolo) val = p.trendHolo ?? p.trend; // Fallback
        
        if (val != null && val > 0) {
          rawSpots.add(FlSpot(p.fetchedAt.millisecondsSinceEpoch.toDouble(), val));
        }
      }
    } else {
      for (var p in widget.tcgHistory) {
        if (p.fetchedAt.isBefore(cutoffDate)) continue;
        double? val;
        if (_selectedType == PriceType.tcgMarket) val = p.normalMarket;
        else val = p.holoMarket;

        if (val != null && val > 0) {
          rawSpots.add(FlSpot(p.fetchedAt.millisecondsSinceEpoch.toDouble(), val));
        }
      }
    }
    return rawSpots;
  }

  Widget _buildTypeChip(String label, PriceType type) {
    final selected = _selectedType == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) { if (val) setState(() => _selectedType = type); },
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(fontSize: 12, color: selected ? Colors.white : Colors.black),
      selectedColor: Colors.blue[700],
    );
  }

  Widget _buildTimeChip(String label, int months) {
    final selected = _monthsFilter == months;
    return GestureDetector(
      onTap: () => setState(() => _monthsFilter = months),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.grey[800] : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}