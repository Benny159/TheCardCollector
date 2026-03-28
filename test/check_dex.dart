import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== 🕵️ TCGDEX API RAW DATA CHECK ===\n');

  // Wir testen das Base Set Glurak (ID: base1-4) auf Englisch, 
  // da das Base Set bei TCGdex oft besser auf Englisch abgedeckt ist für alte Karten.
  const cardId = 'base1-4'; 
  final url = Uri.parse('https://api.tcgdex.net/v2/en/cards/$cardId');

  print('Lade Daten von: $url');
  
  final response = await http.get(url);
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    
    // Um die Konsolenausgabe übersichtlich zu halten, blenden wir riesige Listen aus
    data.remove('attacks');
    data.remove('weaknesses');
    data.remove('retreat');
    data.remove('legal');
    data.remove('description');

    print('\n🃏 KARTEN-DATEN (TCGdex):');
    print(const JsonEncoder.withIndent('  ').convert(data));
  } else {
    print('Fehler: ${response.statusCode} - ${response.body}');
  }
  
  print('\n=== CHECK BEENDET ===');
}