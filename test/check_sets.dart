import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== 🚀 POKEMONTCG.IO API RAW DATA CHECK ===\n');

  // Wir testen das Base Set Glurak (ID: base1-4)
  final cardId = 'base1-4'; 
  final url = Uri.parse('https://api.pokemontcg.io/v2/cards/$cardId');

  print('Lade Daten von: $url');
  
  // Info: pokemontcg.io erlaubt ein paar Aufrufe ohne API-Key. Für mehr braucht man einen kostenlosen Key.
  final response = await http.get(url);
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print('\n🃏 KARTEN-DATEN (pokemontcg.io):');
    print(const JsonEncoder.withIndent('  ').convert(data['data']));
  } else {
    print('Fehler: ${response.statusCode} - ${response.body}');
  }
  
  print('\n=== CHECK BEENDET ===');
}