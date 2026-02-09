class ApiSet {
  final String id;
  final String name;
  final String series;
  final int printedTotal;
  final int total;
  final String releaseDate;
  final String symbolUrl;
  final String logoUrl;
  final String? updatedAt; // Optional, falls die API es liefert

  ApiSet({
    required this.id,
    required this.name,
    required this.series,
    required this.printedTotal,
    required this.total,
    required this.releaseDate,
    required this.symbolUrl,
    required this.logoUrl,
    this.updatedAt,
  });

  factory ApiSet.fromJson(Map<String, dynamic> json) {
    return ApiSet(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unbekannt',
      series: json['series'] ?? '',
      printedTotal: json['printedTotal'] ?? 0,
      total: json['total'] ?? 0,
      releaseDate: json['releaseDate'] ?? '',
      updatedAt: json['updatedAt'], 
      symbolUrl: json['images']?['symbol'] ?? '',
      logoUrl: json['images']?['logo'] ?? '',
    );
  }
}