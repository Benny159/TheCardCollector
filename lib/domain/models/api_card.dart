class ApiCard {
  final String id;
  final String name;
  final String? nameDe;
  final String supertype;
  final List<String> subtypes;
  final List<String> types;
  final String setId;
  final String number;
  final String? cardType;
  final String setPrintedTotal;
  final String artist;
  final String rarity;
  final String? flavorText;
  final String? flavorTextDe;
  
  // Bilder
  final String smallImageUrl;
  final String? largeImageUrl;
  final String? imageUrlDe; // <--- NEU: Deutsches Bild

  // Varianten Flags (NEU) - Default: Normal=true, Rest=false
  final bool hasNormal;
  final bool hasHolo;
  final bool hasReverse;
  final bool hasWPromo;
  final bool hasFirstEdition;

  final bool isOwned;
  
  final ApiCardMarket? cardmarket;
  final ApiTcgPlayer? tcgplayer;

  String get displayImage {
    // Prüft, ob ein DE Bild da ist UND ob es nicht einfach nur leerer Text ist
    if (imageUrlDe != null && imageUrlDe!.isNotEmpty) {
      return imageUrlDe!;
    }
    // Fallback auf Englisch (Large wenn da, sonst Small)
    else if (largeImageUrl != null && largeImageUrl!.isNotEmpty) {
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
    
    required this.smallImageUrl,
    this.largeImageUrl,
    this.imageUrlDe, // <---
    
    // Default-Werte für Sicherheit
    this.hasNormal = true,
    this.hasHolo = false,
    this.hasReverse = false,
    this.hasWPromo = false,
    this.hasFirstEdition = false,

    this.isOwned = false,
    this.cardmarket,
    this.tcgplayer,
  });
  
  // Alte Getter für Abwärtskompatibilität (optional)
  double? get priceEur => cardmarket?.trendPrice;
  double? get priceUsd => tcgplayer?.prices?.normal?.market;

  // --- Factory für die ALTE API (PokemonTCG.io) ---
  factory ApiCard.fromOldApiJson(Map<String, dynamic> json) {
    // Helper für Listen
    List<String> parseList(dynamic list) => (list is List) ? list.map((e) => e.toString()).toList() : [];

    return ApiCard(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unbekannt',
      nameDe: null, // Alte API hat keine DE Namen
      
      supertype: json['supertype'] ?? '',
      subtypes: parseList(json['subtypes']),
      types: parseList(json['types']),
      
      setId: json['set']?['id'] ?? '',
      number: json['number'] ?? '',
      setPrintedTotal: json['set']?['printedTotal']?.toString() ?? '',
      
      artist: json['artist'] ?? '',
      rarity: json['rarity'] ?? '',
      flavorText: json['flavorText'],
      flavorTextDe: null,
      
      // Bilder Mapping
      smallImageUrl: json['images']?['small'] ?? '',
      largeImageUrl: json['images']?['large'],
      imageUrlDe: null, // Alte API hat keine DE Bilder
      
      // Flags (Alte API liefert das nicht direkt so sauber wie TCGdex)
      hasNormal: true, 
      hasHolo: false,
      hasReverse: false,
      hasWPromo: false,
      hasFirstEdition: false,

      // Preise (Alte API Struktur -> Neue Struktur mappen)
      cardmarket: json['cardmarket'] != null ? ApiCardMarket(
          url: json['cardmarket']['url'] ?? '',
          updatedAt: json['cardmarket']['updatedAt'] ?? '',
          trendPrice: (json['cardmarket']['prices']?['trendPrice'] as num?)?.toDouble(),
      ) : null,
      
      tcgplayer: json['tcgplayer'] != null ? ApiTcgPlayer(
          url: json['tcgplayer']['url'] ?? '',
          updatedAt: json['tcgplayer']['updatedAt'] ?? '',
          prices: ApiTcgPlayerPrices(
             normal: ApiPriceType(market: (json['tcgplayer']['prices']?['normal']?['market'] as num?)?.toDouble()),
             holofoil: ApiPriceType(market: (json['tcgplayer']['prices']?['holofoil']?['market'] as num?)?.toDouble()),
             reverseHolofoil: ApiPriceType(market: (json['tcgplayer']['prices']?['reverseHolofoil']?['market'] as num?)?.toDouble()),
          )
      ) : null,
    );
  }
}

// --- CARDMARKET (EUROPA) ---
class ApiCardMarket {
  final String url;
  final String updatedAt;
  
  // Normal Prices
  final double? trendPrice;
  final double? avg30;
  final double? avg7;  // <--- NEU
  final double? avg1;
  final double? lowPrice;
  
  // Holo Prices (NEU)
  final double? trendHolo;
  final double? avg30Holo;
  final double? avg7Holo;
  final double? avg1Holo;
  final double? lowHolo;

  // Reverse Holo
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

// --- TCGPLAYER (USA) ---
class ApiTcgPlayer {
  final String url;
  final String updatedAt;
  final ApiTcgPlayerPrices? prices;

  ApiTcgPlayer({
    required this.url,
    required this.updatedAt,
    this.prices,
  });
}

class ApiTcgPlayerPrices {
  final ApiPriceType? normal;
  final ApiPriceType? holofoil; // <--- NEU
  final ApiPriceType? reverseHolofoil;
  final ApiPriceType? firstEdition; 

  ApiTcgPlayerPrices({
    this.normal,
    this.holofoil,
    this.reverseHolofoil,
    this.firstEdition,
  });
}

class ApiPriceType {
  final double? low;
  final double? mid;       // <--- NEU
  final double? high;
  final double? market;
  final double? directLow; // <--- NEU

  ApiPriceType({
    this.low,
    this.mid,
    this.high,
    this.market,
    this.directLow,
  });
}