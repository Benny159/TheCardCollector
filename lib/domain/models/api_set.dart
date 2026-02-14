class ApiSet {
  final String id;
  final String name;
  final String? nameDe;
  final String series;
  final int printedTotal;
  final int total;
  final String releaseDate;
  final String updatedAt;
  
  final String? symbolUrl; // Nullable, da manche Sets kein Symbol haben
  final String? logoUrl;   // Nullable (Englisch)
  final String? logoUrlDe; // <--- NEU: Nullable (Deutsch)

  ApiSet({
    required this.id,
    required this.name,
    this.nameDe,
    required this.series,
    required this.printedTotal,
    required this.total,
    required this.releaseDate,
    required this.updatedAt,
    this.symbolUrl,
    this.logoUrl,
    this.logoUrlDe, // <--- NEU
  });

  // --- WICHTIG: Diese Factory ist NUR für die "Alte API" (PokemonTCG.io) ---
  // Wir nutzen sie im TcgApiClient, um eine Liste zu laden, aus der wir
  // uns dann NUR das 'releaseDate' klauen.
  factory ApiSet.fromOldApiJson(Map<String, dynamic> json) {
    return ApiSet(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unbekannt',
      nameDe: null, // Alte API hat kein Deutsch
      series: json['series'] ?? '',
      printedTotal: json['printedTotal'] ?? 0,
      total: json['total'] ?? 0,
      releaseDate: json['releaseDate'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      
      // Die Alte API hat Logos in einem Unter-Objekt 'images'
      symbolUrl: json['images']?['symbol'],
      logoUrl: json['images']?['logo'],
      logoUrlDe: null, // Alte API hat kein DE Logo
    );
  }
}