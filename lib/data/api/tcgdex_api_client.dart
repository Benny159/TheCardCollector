import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tcgDexApiClientProvider = Provider((ref) => TcgDexApiClient());

class TcgDexApiClient {
  static const String _baseUrl = 'https://api.tcgdex.net/v2';

  /// Holt eine Liste aller Sets von TCGdex (nur IDs und Namen)
  /// Wichtig für das Mapping der IDs.
  Future<List<dynamic>> fetchAllSets({String lang = 'en'}) async {
    final url = Uri.parse('$_baseUrl/$lang/sets');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('TCGdex Error fetching sets: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchCardDetails(String setId, String cardNumber, {String lang = 'en'}) async {
    // Wir bauen die ID lowercase, da TCGdex das bevorzugt.
    final tcgDexId = "${setId.toLowerCase()}-$cardNumber";
    
    // ... (restliche Methode bleibt gleich wie vorher) ...
    final url = Uri.parse('$_baseUrl/$lang/cards/$tcgDexId');
    // ...
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } 
      // ... Fehlerbehandlung ...
      return null;
    } catch (e) {
      return null;
    }
  }
}