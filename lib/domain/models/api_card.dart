/// Domain representation of a Pokémon trading card.
///
/// Models card identities, localized nomenclature, artwork URLs, printed attributes,
/// print variant capabilities, and embedded market pricing structures.
class ApiCard {
  /// Unique identifier of the card in the database and API (e.g. 'sv04-025').
  final String id;

  /// English card name.
  final String name;

  /// German card name, if available in the database.
  final String? nameDe;

  /// Card classification supertype (e.g. 'Pokémon', 'Trainer', 'Energy').
  final String supertype;

  /// Card subtypes (e.g. 'Basic', 'Stage 1', 'Item', 'Supporter').
  final List<String> subtypes;

  /// Elemental types (e.g. 'Lightning', 'Fire', 'Water').
  final List<String> types;

  /// Identifier of the set this card belongs to (e.g. 'sv04').
  final String setId;

  /// Local card number within the set (e.g. '25' or '025').
  final String number;

  /// Primary card elemental type or category (e.g. 'Grass', 'Trainer').
  final String? cardType;

  /// Total number of printed cards in the set (e.g. '198').
  final String setPrintedTotal;

  /// Name of the card's illustrator.
  final String artist;

  /// Rarity label (e.g. 'Common', 'Rare Holo', 'Special Illustration Rare').
  final String rarity;

  /// English flavor text / Pokédex entry.
  final String? flavorText;

  /// German flavor text / Pokédex entry.
  final String? flavorTextDe;

  /// The user's preferred pricing source ('cardmarket', 'tcgplayer', 'custom').
  final String preferredPriceSource;

  /// User-defined override price, if configured.
  final double? customPrice;

  /// URL pointing to the lower resolution thumbnail image.
  final String smallImageUrl;

  /// URL pointing to the high resolution English image.
  final String? largeImageUrl;

  /// URL pointing to the localized German card image, if available.
  final String? imageUrlDe;

  /// Whether a normal (non-holo) variant of this card exists.
  final bool hasNormal;

  /// Whether a holofoil variant of this card exists.
  final bool hasHolo;

  /// Whether a reverse holofoil variant exists.
  final bool hasReverse;

  /// Whether a W-Promo / stamped promotional variant exists.
  final bool hasWPromo;

  /// Whether a First Edition stamped variant exists.
  final bool hasFirstEdition;

  /// Whether the current user owns at least one copy of this card.
  final bool isOwned;

  /// CardMarket pricing data.
  final ApiCardMarket? cardmarket;

  /// TCGPlayer pricing data.
  final ApiTcgPlayer? tcgplayer;

  /// Returns the highest-priority display image (prefers localized German, then English large, then small).
  String get displayImage {
    if (imageUrlDe != null && imageUrlDe!.isNotEmpty) {
      return imageUrlDe!;
    }
    if (largeImageUrl != null && largeImageUrl!.isNotEmpty) {
      return largeImageUrl!;
    }
    if (smallImageUrl.isNotEmpty) {
      return smallImageUrl;
    }
    return '';
  }

  ApiCard({
    required this.id,
    required this.name,
    this.nameDe,
    required this.supertype,
    required this.subtypes,
    required this.types,
    required this.setId,
    required this.number,
    this.cardType,
    required this.setPrintedTotal,
    required this.artist,
    required this.rarity,
    this.flavorText,
    this.flavorTextDe,
    this.preferredPriceSource = 'cardmarket',
    this.customPrice,
    required this.smallImageUrl,
    this.largeImageUrl,
    this.imageUrlDe,
    this.hasNormal = true,
    this.hasHolo = false,
    this.hasReverse = false,
    this.hasWPromo = false,
    this.hasFirstEdition = false,
    this.isOwned = false,
    this.cardmarket,
    this.tcgplayer,
  });

  /// Factory constructor to parse an [ApiCard] from raw API JSON payloads.
  factory ApiCard.fromJson(Map<String, dynamic> json) {
    return ApiCard(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameDe: json['nameDe'],
      supertype: json['supertype'] ?? 'Pokémon',
      subtypes: (json['subtypes'] as List?)?.map((e) => e.toString()).toList() ?? [],
      types: (json['types'] as List?)?.map((e) => e.toString()).toList() ?? [],
      setId: json['set']?['id'] ?? '',
      number: json['number'] ?? '0',
      cardType: (json['types'] as List?)?.isNotEmpty == true
          ? (json['types'] as List).first.toString()
          : (json['supertype'] == 'Trainer' || json['supertype'] == 'Energy'
              ? json['supertype']
              : null),
      setPrintedTotal: json['set']?['printedTotal']?.toString() ?? '???',
      artist: json['artist'] ?? 'Unbekannt',
      rarity: json['rarity'] ?? 'Unbekannt',
      flavorText: json['flavorText'],
      flavorTextDe: json['flavorTextDe'],
      preferredPriceSource: json['preferredPriceSource'] ?? 'cardmarket',
      customPrice: (json['customPrice'] as num?)?.toDouble(),
      smallImageUrl: json['images']?['small'] ?? '',
      largeImageUrl: json['images']?['large'],
      imageUrlDe: json['imageUrlDe'],
      hasNormal: true,
      hasHolo: false,
      hasReverse: false,
      hasWPromo: false,
      hasFirstEdition: false,
      cardmarket: json['cardmarket'] != null
          ? ApiCardMarket(
              url: json['cardmarket']['url'] ?? '',
              updatedAt: json['cardmarket']['updatedAt'] ?? '',
              trendPrice: (json['cardmarket']['prices']?['trendPrice'] as num?)?.toDouble(),
            )
          : null,
      tcgplayer: json['tcgplayer'] != null
          ? ApiTcgPlayer(
              url: json['tcgplayer']['url'] ?? '',
              updatedAt: json['tcgplayer']['updatedAt'] ?? '',
              prices: ApiTcgPlayerPrices(
                normal: ApiPriceType(
                  market: (json['tcgplayer']['prices']?['normal']?['market'] as num?)?.toDouble(),
                ),
                holofoil: ApiPriceType(
                  market: (json['tcgplayer']['prices']?['holofoil']?['market'] as num?)?.toDouble(),
                ),
                reverseHolofoil: ApiPriceType(
                  market: (json['tcgplayer']['prices']?['reverseHolofoil']?['market'] as num?)?.toDouble(),
                ),
              ),
            )
          : null,
    );
  }
}

/// Represents CardMarket European market pricing information.
class ApiCardMarket {
  /// Direct URL to the product on CardMarket.
  final String url;

  /// Timestamp string when this data was fetched or updated.
  final String updatedAt;

  /// Overall trend price for regular cards.
  final double? trendPrice;

  /// 30-day average price.
  final double? avg30;

  /// 7-day average price.
  final double? avg7;

  /// 1-day average price.
  final double? avg1;

  /// Lowest current listing price.
  final double? lowPrice;

  /// Trend price for holofoil copies.
  final double? trendHolo;

  /// 30-day average price for holofoil copies.
  final double? avg30Holo;

  /// 7-day average price for holofoil copies.
  final double? avg7Holo;

  /// 1-day average price for holofoil copies.
  final double? avg1Holo;

  /// Lowest listing price for holofoil copies.
  final double? lowHolo;

  /// Trend price for reverse holofoil copies.
  final double? reverseHoloTrend;

  ApiCardMarket({
    required this.url,
    required this.updatedAt,
    this.trendPrice,
    this.avg30,
    this.avg7,
    this.avg1,
    this.lowPrice,
    this.trendHolo,
    this.avg30Holo,
    this.avg7Holo,
    this.avg1Holo,
    this.lowHolo,
    this.reverseHoloTrend,
  });
}

/// Represents TCGPlayer US market pricing information.
class ApiTcgPlayer {
  /// Direct URL to the product on TCGPlayer.
  final String url;

  /// Timestamp string when this data was updated.
  final String updatedAt;

  /// Sub-tier price points across variants.
  final ApiTcgPlayerPrices? prices;

  ApiTcgPlayer({
    required this.url,
    required this.updatedAt,
    this.prices,
  });
}

/// Variant pricing tiers from TCGPlayer.
class ApiTcgPlayerPrices {
  /// Regular non-foil pricing metrics.
  final ApiPriceType? normal;

  /// Holofoil pricing metrics.
  final ApiPriceType? holofoil;

  /// Reverse holofoil pricing metrics.
  final ApiPriceType? reverseHolofoil;

  /// First Edition pricing metrics.
  final ApiPriceType? firstEdition;

  ApiTcgPlayerPrices({
    this.normal,
    this.holofoil,
    this.reverseHolofoil,
    this.firstEdition,
  });
}

/// Specific market points for a given price tier.
class ApiPriceType {
  /// Lowest recorded price.
  final double? low;

  /// Mid-point price.
  final double? mid;

  /// High price.
  final double? high;

  /// TCGPlayer market consensus price.
  final double? market;

  /// Direct program low price.
  final double? directLow;

  ApiPriceType({
    this.low,
    this.mid,
    this.high,
    this.market,
    this.directLow,
  });
}