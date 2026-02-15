import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database/app_database.dart';

// KORREKTUR: cmReverse entfernt, da nicht in der DB
enum PriceType { 
  cmTrend, cmTrendHolo, 
  tcgMarket, tcgMarketHolo, tcgMarketReverse 
}

class PriceHistoryChart extends StatefulWidget {
  final List<CardMarketPrice> cmHistory;
  final List<TcgPlayerPrice> tcgHistory;

  const PriceHistoryChart({super.key, required this.cmHistory, required this.tcgHistory});

  @override
  State<PriceHistoryChart> createState() => _PriceHistoryChartState();
}

class _PriceHistoryChartState extends State<PriceHistoryChart> {
  late PriceType _selectedType;
  int _monthsFilter = 3; 

  @override
  void initState() {
    super.initState();
    _determineBestInitialType();
  }

  void _determineBestInitialType() {
    for (var type in PriceType.values) {
      if (_hasData(type)) {
        _selectedType = type;
        return;
      }
    }
    _selectedType = PriceType.cmTrend; // Fallback
  }

  bool _hasData(PriceType type) {
    switch (type) {
      case PriceType.cmTrend:
        return widget.cmHistory.any((p) => (p.trend ?? 0) > 0);
      case PriceType.cmTrendHolo:
        return widget.cmHistory.any((p) => (p.trendHolo ?? 0) > 0);
      
      // cmReverse ENTFERNT
      
      case PriceType.tcgMarket:
        return widget.tcgHistory.any((p) => (p.normalMarket ?? 0) > 0);
      case PriceType.tcgMarketHolo:
        return widget.tcgHistory.any((p) => (p.holoMarket ?? 0) > 0);
      case PriceType.tcgMarketReverse:
        return widget.tcgHistory.any((p) => (p.reverseMarket ?? 0) > 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spots = _getSpots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CHART
        SizedBox(
          height: 180, 
          child: spots.isEmpty 
            ? const Center(child: Text("Keine Datenpunkte > 0€", style: TextStyle(fontSize: 10, color: Colors.grey)))
            : LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) => Text(
                        "${value.toInt()}€", 
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (spots.last.x - spots.first.x) / 3, 
                      getTitlesWidget: (value, meta) {
                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(DateFormat('dd.MM').format(date), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: _getColorForType(_selectedType),
                    barWidth: 2,
                    dotData: FlDotData(show: spots.length < 10),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _getColorForType(_selectedType).withOpacity(0.2), 
                          Colors.transparent
                        ],
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
                          "${DateFormat('dd.MM').format(date)}\n${spot.y.toStringAsFixed(2)} €",
                          const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
        ),
        
        const SizedBox(height: 8),

        // FILTER CHIPS
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Cardmarket
              if (_hasData(PriceType.cmTrend)) _buildTypeChip("CM Trend", PriceType.cmTrend),
              if (_hasData(PriceType.cmTrendHolo)) _buildTypeChip("CM Holo", PriceType.cmTrendHolo),
              
              // Trenner
              if (_hasAnyCmData() && _hasAnyTcgData())
                Container(width: 1, height: 16, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 4)),

              // TCGPlayer
              if (_hasData(PriceType.tcgMarket)) _buildTypeChip("TCG", PriceType.tcgMarket),
              if (_hasData(PriceType.tcgMarketHolo)) _buildTypeChip("TCG Holo", PriceType.tcgMarketHolo),
              if (_hasData(PriceType.tcgMarketReverse)) _buildTypeChip("TCG Rev.", PriceType.tcgMarketReverse),

              const SizedBox(width: 12),
              
              // Zeitfilter
              _buildTimeChip("1M", 1),
              const SizedBox(width: 4),
              _buildTimeChip("All", 999),
            ],
          ),
        ),
      ],
    );
  }

  bool _hasAnyCmData() {
    return _hasData(PriceType.cmTrend) || _hasData(PriceType.cmTrendHolo);
  }

  bool _hasAnyTcgData() {
    return _hasData(PriceType.tcgMarket) || _hasData(PriceType.tcgMarketHolo) || _hasData(PriceType.tcgMarketReverse);
  }

  List<FlSpot> _getSpots() {
    List<FlSpot> rawSpots = [];
    final now = DateTime.now();
    final cutoffDate = _monthsFilter == 999 
        ? DateTime(2000) 
        : now.subtract(Duration(days: _monthsFilter * 30));

    // Listen kopieren & sortieren
    final cmList = List.of(widget.cmHistory)..sort((a,b) => a.fetchedAt.compareTo(b.fetchedAt));
    final tcgList = List.of(widget.tcgHistory)..sort((a,b) => a.fetchedAt.compareTo(b.fetchedAt));

    // --- HELPER: NUR EINEN WERT PRO TAG ---
    // Diese Map speichert nur den *letzten* Wert für einen Tag (Key: "2026-02-15")
    final Map<String, double> dailyValues = {};

    void addValue(DateTime date, double? val) {
      if (val == null || val <= 0) return;
      if (date.isBefore(cutoffDate)) return;
      
      // Datum ohne Uhrzeit als Key (z.B. "2024-10-30")
      final dateKey = "${date.year}-${date.month}-${date.day}";
      // Überschreibt vorherige Werte desselben Tages -> Nur der letzte bleibt!
      dailyValues[dateKey] = val; 
    }
    // --------------------------------------

    if (_selectedType.name.startsWith('cm')) {
      for (var p in cmList) {
        double? val;
        switch (_selectedType) {
          case PriceType.cmTrend: val = p.trend; break;
          case PriceType.cmTrendHolo: val = p.trendHolo; break;
          // case PriceType.cmReverse: val = p.reverseHoloTrend; break; // Falls DB erweitert wird
          default: break;
        }
        addValue(p.fetchedAt, val);
      }
    } else {
      for (var p in tcgList) {
        double? val;
        switch (_selectedType) {
          case PriceType.tcgMarket: val = p.normalMarket; break;
          case PriceType.tcgMarketHolo: val = p.holoMarket; break;
          case PriceType.tcgMarketReverse: val = p.reverseMarket; break;
          default: break;
        }
        addValue(p.fetchedAt, val);
      }
    }

    // Map in Spots umwandeln und sortieren
    // Wir müssen das Datum aus dem String key rekonstruieren oder wir speichern es besser separat.
    // Einfacher: Wir iterieren über die Keys, parsen das Datum und bauen den Spot.
    
    final sortedKeys = dailyValues.keys.toList()..sort(); // Datum-Strings sortieren (YYYY-MM-DD sortiert sich korrekt lexikalisch)

    for (var key in sortedKeys) {
      final parts = key.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final val = dailyValues[key]!;
      rawSpots.add(FlSpot(date.millisecondsSinceEpoch.toDouble(), val));
    }

    return rawSpots;
  }

  Color _getColorForType(PriceType type) {
    if (type.name.startsWith('cm')) return Colors.blue[700]!;
    return Colors.teal[700]!;
  }

  Widget _buildTypeChip(String label, PriceType type) {
    final selected = _selectedType == type;
    final color = _getColorForType(type);

    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (val) { if (val) setState(() => _selectedType = type); },
        visualDensity: VisualDensity.compact,
        labelStyle: TextStyle(fontSize: 10, color: selected ? Colors.white : Colors.black),
        selectedColor: color,
        backgroundColor: Colors.grey[100],
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        side: BorderSide(color: selected ? Colors.transparent : Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!)
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey, fontSize: 10)),
      ),
    );
  }
}