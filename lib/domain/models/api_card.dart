class ApiCard {
  final String id;
  final String name;
  final String supertype;
  final List<String> subtypes; // Jetzt als Liste!
  final List<String> types;    // Jetzt als Liste!
  final String setId;          // Wir holen uns nur die ID aus dem Set-Objekt
  final String number;
  final String artist;
  final String rarity;
  final String? flavorText;
  
  
  // Bilder
  final String smallImageUrl;
  final String largeImageUrl;

  // Preise (Verschachtelte Objekte)
  final ApiCardMarket? cardmarket;
  final ApiTcgPlayer? tcgplayer;
  final String? setPrintedTotal; // <--- Das brauchst du für die Anzeige "25/185"

  final bool isOwned; // NEU: Zeigt an, ob die Karte in deiner Sammlung ist

  ApiCard({
    required this.id,
    required this.name,
    required this.supertype,
    required this.subtypes,
    required this.types,
    required this.setId,
    required this.number,
    required this.artist,
    required this.rarity,
    this.flavorText,
    required this.smallImageUrl,
    required this.largeImageUrl,
    this.cardmarket,
    this.tcgplayer,
    this.setPrintedTotal,
    this.isOwned = false,
  });

  factory ApiCard.fromJson(Map<String, dynamic> json) {
    // Hilfsfunktion, um Listen sicher zu parsen (falls mal null kommt)
    List<String> parseList(dynamic list) {
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
      return [];
    }

    return ApiCard(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unbekannt',
      supertype: json['supertype'] ?? '',
      subtypes: parseList(json['subtypes']),
      types: parseList(json['types']),
      // WICHTIG: Die API gibt "set": { "id": "swsh4", ... } zurück.
      // Wir greifen direkt auf die ID zu.
      setId: json['set']?['id'] ?? '', 
      number: json['number'] ?? '',
      artist: json['artist'] ?? '',
      rarity: json['rarity'] ?? '',
      flavorText: json['flavorText'],
      smallImageUrl: json['images']?['small'] ?? '',
      largeImageUrl: json['images']?['large'] ?? '',
      
      // Hier erstellen wir die Unter-Objekte für die Preise
      cardmarket: json['cardmarket'] != null 
          ? ApiCardMarket.fromJson(json['cardmarket']) 
          : null,
      tcgplayer: json['tcgplayer'] != null 
          ? ApiTcgPlayer.fromJson(json['tcgplayer']) 
          : null,
      setPrintedTotal: json['set']?['printedTotal']?.toString(),
    );
  }
  
  // Getter für "Alte" Logik (falls du irgendwo noch schnell einen Preis brauchst)
  double? get priceEur => cardmarket?.trendPrice;
  double? get priceUsd => tcgplayer?.prices?.normal?.market ?? tcgplayer?.prices?.reverseHolofoil?.market;
}

// --- HILFSKLASSE FÜR CARDMARKET (EUROPA) ---
class ApiCardMarket {
  final String url;
  final String updatedAt;
  final double? trendPrice;
  final double? avg30;
  final double? lowPrice;
  final double? reverseHoloTrend;

  ApiCardMarket({
    required this.url,
    required this.updatedAt,
    this.trendPrice,
    this.avg30,
    this.lowPrice,
    this.reverseHoloTrend,
  });

  factory ApiCardMarket.fromJson(Map<String, dynamic> json) {
    final prices = json['prices'] as Map<String, dynamic>? ?? {};
    
    return ApiCardMarket(
      url: json['url'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      // Wir holen die Werte direkt aus dem "prices" Unter-Objekt
      trendPrice: (prices['trendPrice'] as num?)?.toDouble(),
      avg30: (prices['avg30'] as num?)?.toDouble(),
      lowPrice: (prices['lowPrice'] as num?)?.toDouble(),
      reverseHoloTrend: (prices['reverseHoloTrend'] as num?)?.toDouble(),
    );
  }
}

// --- HILFSKLASSE FÜR TCGPLAYER (USA) ---
class ApiTcgPlayer {
  final String url;
  final String? updatedAt;
  final ApiTcgPlayerPrices? prices;

  ApiTcgPlayer({required this.url, this.updatedAt, this.prices});

  factory ApiTcgPlayer.fromJson(Map<String, dynamic> json) {
    return ApiTcgPlayer(
      url: json['url'],
      updatedAt: json['updatedAt'],
      prices: json['prices'] != null ? ApiTcgPlayerPrices.fromJson(json['prices']) : null,
    );
  }
}

class ApiTcgPlayerPrices {
  final ApiPriceType? normal;
  final ApiPriceType? holofoil;
  final ApiPriceType? reverseHolofoil;

  ApiTcgPlayerPrices({this.normal, this.holofoil, this.reverseHolofoil});

  factory ApiTcgPlayerPrices.fromJson(Map<String, dynamic> json) {
    return ApiTcgPlayerPrices(
      normal: json['normal'] != null ? ApiPriceType.fromJson(json['normal']) : null,
      holofoil: json['holofoil'] != null ? ApiPriceType.fromJson(json['holofoil']) : null,
      reverseHolofoil: json['reverseHolofoil'] != null ? ApiPriceType.fromJson(json['reverseHolofoil']) : null,
    );
  }
}

class ApiPriceType {
  final double? low;
  final double? market;

  ApiPriceType({this.low, this.market});

  factory ApiPriceType.fromJson(Map<String, dynamic> json) {
    return ApiPriceType(
      low: (json['low'] as num?)?.toDouble(),
      market: (json['market'] as num?)?.toDouble(),
    );
  }
}
