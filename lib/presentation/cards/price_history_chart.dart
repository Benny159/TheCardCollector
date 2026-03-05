import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database/app_database.dart';

enum PriceType { 
  cmTrend, cmTrendHolo, 
  tcgMarket, tcgMarketHolo, tcgMarketReverse,
  customPrice // <-- NEU
}

class PriceHistoryChart extends StatefulWidget {
  final List<CardMarketPrice> cmHistory;
  final List<TcgPlayerPrice> tcgHistory;
  final List<CustomCardPrice> customHistory; // <-- NEU

  const PriceHistoryChart({
    super.key, 
    required this.cmHistory, 
    required this.tcgHistory,
    required this.customHistory, // <-- NEU
  });

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

  // --- NEU: SOFORTIGES UPDATE BEI NEUEM PREIS ---
  @override
  void didUpdateWidget(PriceHistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Wenn ein neuer Custom-Preis dazukam, sofort darauf umschalten!
    if (widget.customHistory.length != oldWidget.customHistory.length) {
      if (widget.customHistory.isNotEmpty) {
        setState(() {
          _selectedType = PriceType.customPrice;
        });
      }
    }
  }

  void _determineBestInitialType() {
    if (_hasData(PriceType.customPrice)) {
      _selectedType = PriceType.customPrice;
      return;
    }
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
      case PriceType.cmTrend: return widget.cmHistory.any((p) => (p.trend ?? 0) > 0);
      case PriceType.cmTrendHolo: return widget.cmHistory.any((p) => (p.trendHolo ?? 0) > 0);
      case PriceType.tcgMarket: return widget.tcgHistory.any((p) => (p.normalMarket ?? 0) > 0);
      case PriceType.tcgMarketHolo: return widget.tcgHistory.any((p) => (p.holoMarket ?? 0) > 0);
      case PriceType.tcgMarketReverse: return widget.tcgHistory.any((p) => (p.reverseMarket ?? 0) > 0);
      case PriceType.customPrice: return widget.customHistory.any((p) => p.price > 0);
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
                gridData: const FlGridData(show: true, drawVerticalLine: false),
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
                      interval: (spots.last.x - spots.first.x) / 3 > 0 
                                ? (spots.last.x - spots.first.x) / 3 
                                : 1.0, 
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
              // --- NEU: Eigener Preis Chip (In Gold!) ---
              if (_hasData(PriceType.customPrice)) _buildTypeChip("Eigener Preis", PriceType.customPrice),
              
              if (_hasData(PriceType.customPrice) && (_hasAnyCmData() || _hasAnyTcgData()))
                Container(width: 1, height: 16, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 4)),

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

    final cmList = List.of(widget.cmHistory)..sort((a,b) => a.fetchedAt.compareTo(b.fetchedAt));
    final tcgList = List.of(widget.tcgHistory)..sort((a,b) => a.fetchedAt.compareTo(b.fetchedAt));
    final customList = List.of(widget.customHistory)..sort((a,b) => a.fetchedAt.compareTo(b.fetchedAt)); 

    final Map<String, double> dailyValues = {};

    void addValue(DateTime date, double? val) {
      if (val == null || val <= 0) return;
      if (date.isBefore(cutoffDate)) return;
      
      final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      dailyValues[dateKey] = val; // Der LETZTE Wert überschreibt den vorherigen am selben Tag
    }

    if (_selectedType == PriceType.customPrice) {
      for (var p in customList) {
        addValue(p.fetchedAt, p.price);
      }
    } else if (_selectedType.name.startsWith('cm')) {
      for (var p in cmList) {
        double? val;
        switch (_selectedType) {
          case PriceType.cmTrend: val = p.trend; break;
          case PriceType.cmTrendHolo: val = p.trendHolo; break;
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

    final sortedKeys = dailyValues.keys.toList()..sort(); 

    for (var key in sortedKeys) {
      final parts = key.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final val = dailyValues[key]!;
      rawSpots.add(FlSpot(date.millisecondsSinceEpoch.toDouble(), val));
    }

    return rawSpots;
  }

  Color _getColorForType(PriceType type) {
    if (type == PriceType.customPrice) return Colors.amber[700]!; 
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