import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database/app_database.dart';

enum PriceType { 
  cmTrend, cmTrendHolo, 
  tcgMarket, tcgMarketHolo, tcgMarketReverse,
  customPrice 
}

class PriceHistoryChart extends StatefulWidget {
  final List<CardMarketPrice> cmHistory;
  final List<TcgPlayerPrice> tcgHistory;
  final List<CustomCardPrice> customHistory;
  // --- NEU: Wir übergeben die Inventar-Karten an den Graphen! ---
  final List<UserCard> userCards; 

  const PriceHistoryChart({
    super.key, 
    required this.cmHistory, 
    required this.tcgHistory,
    required this.customHistory,
    this.userCards = const [], 
  });

  @override
  State<PriceHistoryChart> createState() => _PriceHistoryChartState();
}

class _PriceHistoryChartState extends State<PriceHistoryChart> {
  late PriceType _selectedType;
  int _monthsFilter = 3; 
  
  // --- NEU: Checkbox State für die Kauf-Markierungen ---
  Set<int> _selectedUserCardIds = {};

  @override
  void initState() {
    super.initState();
    _determineBestInitialType();
    // Standardmäßig zeigen wir die Kaufpunkte aller Karten an!
    _selectedUserCardIds = widget.userCards.map((c) => c.id).toSet();
  }

  @override
  void didUpdateWidget(PriceHistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.customHistory.length != oldWidget.customHistory.length) {
      if (widget.customHistory.isNotEmpty) {
        setState(() => _selectedType = PriceType.customPrice);
      }
    }
    // Wenn neue Karten hinzukommen, Boxen updaten
    if (widget.userCards.length != oldWidget.userCards.length) {
      final newIds = widget.userCards.map((c) => c.id).toSet();
      _selectedUserCardIds.retainAll(newIds); 
      final addedIds = newIds.difference(oldWidget.userCards.map((c) => c.id).toSet());
      _selectedUserCardIds.addAll(addedIds);
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
    _selectedType = PriceType.cmTrend; 
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

    // Wir brauchen minX und maxX, damit die neuen Kauf-Linien den Graphen nicht sprengen!
    double minX = spots.isNotEmpty ? spots.first.x : 0;
    double maxX = spots.isNotEmpty ? spots.last.x : 0;
    if (minX == maxX) {
      minX -= 86400000;
      maxX += 86400000;
    }

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
                      interval: (maxX - minX) / 3 > 0 ? (maxX - minX) / 3 : 1.0, 
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
                
                // --- NEU: KAUF-MARKIERUNGEN (Gestrichelte Linie) ---
                extraLinesData: ExtraLinesData(
                  verticalLines: widget.userCards
                      .where((uc) => _selectedUserCardIds.contains(uc.id))
                      .map((uc) {
                        final xVal = uc.createdAt.millisecondsSinceEpoch.toDouble();
                        // Nur einzeichnen, wenn sie im Zeitfilter liegt!
                        if (xVal < minX || xVal > maxX) return null;
                        return VerticalLine(
                          x: xVal,
                          color: Colors.green.withOpacity(0.6),
                          strokeWidth: 2,
                          dashArray: [4, 4],
                          label: VerticalLineLabel(
                            show: true,
                            alignment: Alignment.bottomRight,
                            padding: const EdgeInsets.only(left: 4, bottom: 4),
                            style: const TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.bold),
                            labelResolver: (line) => "Erworben",
                          )
                        );
                  }).whereType<VerticalLine>().toList(),
                ),
                // --------------------------------------------------

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

        // --- NEU: FILTER-CHECKBOXEN FÜR DIE INVENTAR-KARTEN ---
        if (widget.userCards.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.userCards.map((uc) {
                  final isSelected = _selectedUserCardIds.contains(uc.id);
                  String label = "${uc.variant} (${uc.condition})";
                  if (uc.gradingCompany != null && uc.gradingCompany != 'Kein Grading') {
                    label += " ${uc.gradingScore ?? ''}".trim();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: FilterChip(
                      label: Text(label, style: TextStyle(fontSize: 9, color: isSelected ? Colors.white : Colors.black87)),
                      selected: isSelected,
                      selectedColor: Colors.green[600],
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.grey[100],
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onSelected: (val) {
                        setState(() {
                          if (val) _selectedUserCardIds.add(uc.id);
                          else _selectedUserCardIds.remove(uc.id);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        // ------------------------------------------------------

        // FILTER CHIPS (Datenquellen)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (_hasData(PriceType.customPrice)) _buildTypeChip("Eigener Preis", PriceType.customPrice),
              if (_hasData(PriceType.customPrice) && (_hasAnyCmData() || _hasAnyTcgData()))
                Container(width: 1, height: 16, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 4)),
              if (_hasData(PriceType.cmTrend)) _buildTypeChip("CM Trend", PriceType.cmTrend),
              if (_hasData(PriceType.cmTrendHolo)) _buildTypeChip("CM Holo", PriceType.cmTrendHolo),
              if (_hasAnyCmData() && _hasAnyTcgData())
                Container(width: 1, height: 16, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 4)),
              if (_hasData(PriceType.tcgMarket)) _buildTypeChip("TCG", PriceType.tcgMarket),
              if (_hasData(PriceType.tcgMarketHolo)) _buildTypeChip("TCG Holo", PriceType.tcgMarketHolo),
              if (_hasData(PriceType.tcgMarketReverse)) _buildTypeChip("TCG Rev.", PriceType.tcgMarketReverse),
              const SizedBox(width: 12),
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
      dailyValues[dateKey] = val;
    }

    if (_selectedType == PriceType.customPrice) {
      for (var p in customList) {
        final dateKey = "${p.fetchedAt.year}-${p.fetchedAt.month.toString().padLeft(2, '0')}-${p.fetchedAt.day.toString().padLeft(2, '0')}";
        dailyValues[dateKey] = p.price;
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