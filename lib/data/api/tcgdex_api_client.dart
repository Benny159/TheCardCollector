import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider für den Client
final tcgDexApiClientProvider = Provider((ref) => TcgDexApiClient());

class TcgDexApiClient {
  static const String _baseUrl = 'https://api.tcgdex.net/v2';

  // Hole Kartendetails (für Künstler, deutsche Namen etc.)
  Future<Map<String, dynamic>?> fetchCardDetails(String setId, String cardNumber, {String lang = 'en'}) async {
    // TCGdex IDs sind oft "setid-nummer", z.B. "swsh3-136".
    // Manchmal muss man die SetID anpassen (z.B. bei Promos), aber meistens passt es.
    // Wir bauen die ID lowercase, da TCGdex das bevorzugt.
    final tcgDexId = "${setId.toLowerCase()}-$cardNumber";
    
    final url = Uri.parse('$_baseUrl/$lang/cards/$tcgDexId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        // Karte nicht gefunden oder ID-Format anders
        print('TCGdex Warning: Card $tcgDexId not found (Status ${response.statusCode})');
        return null;
      }
    } catch (e) {
      print('TCGdex Error fetching card $tcgDexId: $e');
      return null;
    }
  }
}