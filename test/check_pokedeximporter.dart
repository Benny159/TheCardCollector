import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print("🔍 Teste PokeAPI auf deutsche Namen...");
  
  try {
    // Wir testen das mit ID 1 (Bisasam), ID 6 (Glurak) und ID 25 (Pikachu)
    for (int id in [1, 6, 25]) {
      final url = Uri.parse('https://pokeapi.co/api/v2/pokemon-species/$id/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> namesList = data['names'];

        // Wir suchen in der Liste aller Sprachen gezielt nach "de"
        final deEntry = namesList.firstWhere(
          (entry) => entry['language']['name'] == 'de',
          orElse: () => null,
        );
        
        // Wir suchen zum Vergleich auch mal Englisch ("en")
        final enEntry = namesList.firstWhere(
          (entry) => entry['language']['name'] == 'en',
          orElse: () => null,
        );

        if (deEntry != null) {
          print("✅ ID $id -> Englisch: ${enEntry?['name']} | Deutsch: ${deEntry['name']}");
        } else {
          print("❌ ID $id -> Kein deutscher Name gefunden!");
        }
      } else {
        print("❌ Fehler beim Abrufen der ID $id: ${response.statusCode}");
      }
    }
  } catch (e) {
    print("❌ Exception: $e");
  }
}