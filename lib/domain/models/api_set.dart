/// Domain representation of a card expansion set.
///
/// Encapsulates set metadata, card counts, release dates, and logos.
class ApiSet {
  /// Unique identifier of the expansion set (e.g. 'base1', 'sv04').
  final String id;

  /// English set name (e.g. 'Paradox Rift').
  final String name;

  /// German set name, if available (e.g. 'Paradox-Gefüge').
  final String? nameDe;

  /// Overall franchise series or era (e.g. 'Scarlet & Violet', 'Sword & Shield').
  final String series;

  /// Number of standard printed cards within the set numbering sequence.
  final int printedTotal;

  /// Total number of cards including secret rares.
  final int total;

  /// Official release date string in 'YYYY/MM/DD' format.
  final String releaseDate;

  /// Timestamp string when this set was last modified.
  final String updatedAt;

  /// URL pointing to the set icon / expansion symbol.
  final String? symbolUrl;

  /// URL pointing to the standard English expansion logo.
  final String? logoUrl;

  /// URL pointing to the localized German expansion logo, if available.
  final String? logoUrlDe;

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
    this.logoUrlDe,
  });

  /// Factory constructor to parse an [ApiSet] from PokemonTCG.io legacy payloads.
  factory ApiSet.fromOldApiJson(Map<String, dynamic> json) {
    return ApiSet(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unbekannt',
      nameDe: null,
      series: json['series'] ?? '',
      printedTotal: json['printedTotal'] ?? 0,
      total: json['total'] ?? 0,
      releaseDate: json['releaseDate'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      symbolUrl: json['images']?['symbol'],
      logoUrl: json['images']?['logo'],
      logoUrlDe: null,
    );
  }
}