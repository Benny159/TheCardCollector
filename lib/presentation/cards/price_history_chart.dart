import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database/app_database.dart';

enum PriceType {
  cmTrend,
  cmTrendHolo,
  tcgMarket,
  tcgMarketHolo,
  tcgMarketReverse,
  customPrice
}

class PriceHistoryChart extends StatefulWidget {
  final List<CardMarketPrice> cmHistory;
  final List<TcgPlayerPrice> tcgHistory;
  final List<CustomCardPrice> customHistory;
  final List<UserCard> userCards;
  final String? preferredSource;

  // Set of card copies to hide from timeline annotations
  final Set<int> hiddenUserCardIds;

  const PriceHistoryChart({
    super.key,
    required this.cmHistory,
    required this.tcgHistory,
    required this.customHistory,
    this.userCards = const [],
    this.preferredSource,
    this.hiddenUserCardIds = const {}, // Empty by default
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

  @override
  void didUpdateWidget(PriceHistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.preferredSource != oldWidget.preferredSource) {
      _determineBestInitialType();
    } else if (widget.customHistory.length != oldWidget.customHistory.length) {
      if (widget.customHistory.isNotEmpty && widget.preferredSource == 'custom') {
        setState(() => _selectedType = PriceType.customPrice);
      }
    }
  }

  void _determineBestInitialType() {
    if (widget.preferredSource == 'custom' && _hasData(PriceType.customPrice)) {
      _selectedType = PriceType.customPrice;
      return;
    }
    if (widget.preferredSource == 'tcgplayer') {
      if (_hasData(PriceType.tcgMarket)) {
        _selectedType = PriceType.tcgMarket;
        return;
      }
      if (_hasData(PriceType.tcgMarketHolo)) {
        _selectedType = PriceType.tcgMarketHolo;
        return;
      }
      if (_hasData(PriceType.tcgMarketReverse)) {
        _selectedType = PriceType.tcgMarketReverse;
        return;
      }
    }
    // Default to CardMarket trend if available
    if (_hasData(PriceType.cmTrend)) {
      _selectedType = PriceType.cmTrend;
      return;
    }
    if (_hasData(PriceType.cmTrendHolo)) {
      _selectedType = PriceType.cmTrendHolo;
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
      case PriceType.cmTrend:
        return widget.cmHistory.any((p) => (p.trend ?? 0) > 0);
      case PriceType.cmTrendHolo:
        return widget.cmHistory.any((p) => (p.trendHolo ?? 0) > 0);
      case PriceType.tcgMarket:
        return widget.tcgHistory.any((p) => (p.normalMarket ?? 0) > 0);
      case PriceType.tcgMarketHolo:
        return widget.tcgHistory.any((p) => (p.holoMarket ?? 0) > 0);
      case PriceType.tcgMarketReverse:
        return widget.tcgHistory.any((p) => (p.reverseMarket ?? 0) > 0);
      case PriceType.customPrice:
        return widget.customHistory.any((p) => p.price > 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spots = _getSpots();

    double minX = spots.isNotEmpty ? spots.first.x : 0;
    double maxX = spots.isNotEmpty ? spots.last.x : 0;
    if (minX == maxX) {
      minX -= 86400000;
      maxX += 86400000;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CHART
        SizedBox(
          height: 180,
          child: spots.isEmpty
              ? Center(
                  child: Text("Keine Datenpunkte > 0€",
                      style: TextStyle(
                          fontSize: 10,
                          color: isDark ? const Color(0xFF94A3B8) : Colors.grey)))
              : LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: isDark
                            ? const Color(0xFF334155)
                            : Colors.grey.withValues(alpha: 0.15),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          getTitlesWidget: (value, meta) => Text(
                            "${value.toInt()}€",
                            style: TextStyle(
                              fontSize: 9,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : Colors.grey[600],
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval:
                              (maxX - minX) / 3 > 0 ? (maxX - minX) / 3 : 1.0,
                          getTitlesWidget: (value, meta) {
                            final date = DateTime.fromMillisecondsSinceEpoch(
                                value.toInt());
                            return Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                DateFormat('dd.MM').format(date),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : Colors.grey[600],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    extraLinesData: ExtraLinesData(
                      // Filter timeline markers using excluded card ID set
                      verticalLines: widget.userCards
                          .where(
                              (uc) => !widget.hiddenUserCardIds.contains(uc.id))
                          .map((uc) {
                            final xVal =
                                uc.createdAt.millisecondsSinceEpoch.toDouble();
                            if (xVal < minX || xVal > maxX) return null;
                            return VerticalLine(
                                x: xVal,
                                color: Colors.green.withValues(alpha: 0.6),
                                strokeWidth: 2,
                                dashArray: [4, 4],
                                label: VerticalLineLabel(
                                  show: true,
                                  alignment: Alignment.bottomRight,
                                  padding:
                                      const EdgeInsets.only(left: 4, bottom: 4),
                                  style: const TextStyle(
                                      fontSize: 8,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold),
                                  labelResolver: (line) => "Erworben",
                                ));
                          })
                          .whereType<VerticalLine>()
                          .toList(),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: _getColorForType(_selectedType, primaryColor),
                        barWidth: 2.5,
                        dotData: FlDotData(show: spots.length < 10),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _getColorForType(_selectedType, primaryColor)
                                  .withValues(alpha: 0.25),
                              Colors.transparent
                            ],
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.blueGrey.shade800,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final date = DateTime.fromMillisecondsSinceEpoch(
                                spot.x.toInt());
                            return LineTooltipItem(
                              "${DateFormat('dd.MM').format(date)}\n${spot.y.toStringAsFixed(2)} €",
                              const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
        ),

        const SizedBox(height: 8),

        // Filter chips for price data sources
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (_hasData(PriceType.customPrice))
                _buildTypeChip("Eigener Preis", PriceType.customPrice, primaryColor, isDark),
              if (_hasData(PriceType.customPrice) &&
                  (_hasAnyCmData() || _hasAnyTcgData()))
                Container(
                    width: 1,
                    height: 16,
                    color: isDark ? const Color(0xFF334155) : Colors.grey[300],
                    margin: const EdgeInsets.symmetric(horizontal: 4)),
              if (_hasData(PriceType.cmTrend))
                _buildTypeChip("CM Trend", PriceType.cmTrend, primaryColor, isDark),
              if (_hasData(PriceType.cmTrendHolo))
                _buildTypeChip("CM Holo", PriceType.cmTrendHolo, primaryColor, isDark),
              if (_hasAnyCmData() && _hasAnyTcgData())
                Container(
                    width: 1,
                    height: 16,
                    color: isDark ? const Color(0xFF334155) : Colors.grey[300],
                    margin: const EdgeInsets.symmetric(horizontal: 4)),
              if (_hasData(PriceType.tcgMarket))
                _buildTypeChip("TCG", PriceType.tcgMarket, primaryColor, isDark),
              if (_hasData(PriceType.tcgMarketHolo))
                _buildTypeChip("TCG Holo", PriceType.tcgMarketHolo, primaryColor, isDark),
              if (_hasData(PriceType.tcgMarketReverse))
                _buildTypeChip("TCG Rev.", PriceType.tcgMarketReverse, primaryColor, isDark),
              const SizedBox(width: 12),
              _buildTimeChip("1M", 1, primaryColor, isDark),
              const SizedBox(width: 4),
              _buildTimeChip("All", 999, primaryColor, isDark),
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
    return _hasData(PriceType.tcgMarket) ||
        _hasData(PriceType.tcgMarketHolo) ||
        _hasData(PriceType.tcgMarketReverse);
  }

  List<FlSpot> _getSpots() {
    List<FlSpot> rawSpots = [];
    final now = DateTime.now();
    final cutoffDate = _monthsFilter == 999
        ? DateTime(2000)
        : now.subtract(Duration(days: _monthsFilter * 30));

    final cmList = List.of(widget.cmHistory)
      ..sort((a, b) => a.fetchedAt.compareTo(b.fetchedAt));
    final tcgList = List.of(widget.tcgHistory)
      ..sort((a, b) => a.fetchedAt.compareTo(b.fetchedAt));
    final customList = List.of(widget.customHistory)
      ..sort((a, b) => a.fetchedAt.compareTo(b.fetchedAt));

    final Map<String, double> dailyValues = {};

    void addValue(DateTime date, double? val) {
      if (val == null || val <= 0) return;
      if (date.isBefore(cutoffDate)) return;

      final dateKey =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      dailyValues[dateKey] = val;
    }

    if (_selectedType == PriceType.customPrice) {
      for (var p in customList) {
        final dateKey =
            "${p.fetchedAt.year}-${p.fetchedAt.month.toString().padLeft(2, '0')}-${p.fetchedAt.day.toString().padLeft(2, '0')}";
        dailyValues[dateKey] = p.price;
      }
    } else if (_selectedType.name.startsWith('cm')) {
      for (var p in cmList) {
        double? val;
        switch (_selectedType) {
          case PriceType.cmTrend:
            val = p.trend;
            break;
          case PriceType.cmTrendHolo:
            val = p.trendHolo;
            break;
          default:
            break;
        }
        addValue(p.fetchedAt, val);
      }
    } else {
      for (var p in tcgList) {
        double? val;
        switch (_selectedType) {
          case PriceType.tcgMarket:
            val = p.normalMarket;
            break;
          case PriceType.tcgMarketHolo:
            val = p.holoMarket;
            break;
          case PriceType.tcgMarketReverse:
            val = p.reverseMarket;
            break;
          default:
            break;
        }
        addValue(p.fetchedAt, val);
      }
    }

    final sortedKeys = dailyValues.keys.toList()..sort();

    for (var key in sortedKeys) {
      final parts = key.split('-');
      final date = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final val = dailyValues[key]!;
      rawSpots.add(FlSpot(date.millisecondsSinceEpoch.toDouble(), val));
    }

    return rawSpots;
  }

  Color _getColorForType(PriceType type, Color primaryColor) {
    return primaryColor;
  }

  Widget _buildTypeChip(
      String label, PriceType type, Color primaryColor, bool isDark) {
    final selected = _selectedType == type;
    final color = _getColorForType(type, primaryColor);

    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (val) {
          if (val) setState(() => _selectedType = type);
        },
        visualDensity: VisualDensity.compact,
        labelStyle: TextStyle(
          fontSize: 10,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected
              ? Colors.white
              : (isDark ? const Color(0xFFCBD5E1) : Colors.black87),
        ),
        selectedColor: color,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        side: BorderSide(
          color: selected
              ? Colors.transparent
              : (isDark ? const Color(0xFF334155) : Colors.grey[300]!),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTimeChip(
      String label, int months, Color primaryColor, bool isDark) {
    final selected = _monthsFilter == months;
    return GestureDetector(
      onTap: () => setState(() => _monthsFilter = months),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor
              : (isDark ? const Color(0xFF1E293B) : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? primaryColor
                : (isDark ? const Color(0xFF334155) : Colors.grey[300]!),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : (isDark ? const Color(0xFFCBD5E1) : Colors.grey[700]),
            fontSize: 10,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
