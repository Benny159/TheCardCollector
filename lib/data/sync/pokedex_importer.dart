import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:drift/drift.dart';
import '../database/app_database.dart';

class PokedexImporter {
  final AppDatabase db;

  PokedexImporter(this.db);

  Future<void> syncPokedex() async {
    // 1. Prüfen ob schon Daten da sind
    final count = await db.select(db.pokedex).get().then((l) => l.length);
    
    // Wenn wir schon viele Daten haben, brechen wir ab (spart Traffic)
    if (count > 1000) {
      print("✅ Pokedex ist bereits gefüllt ($count Einträge).");
      return; 
    }

    print("⏳ Lade Pokedex Liste von PokeAPI...");

    try {
      // 2. API Abfragen (limit=2000 holt alle auf einmal)
      final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=2000'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // WICHTIG: Die Liste steckt im Feld 'results'
        final List<dynamic> results = data['results'];
        
        final List<PokedexCompanion> inserts = [];

        // 3. Daten verarbeiten
        for (var item in results) {
          final String rawName = item['name'];
          final String url = item['url']; // z.B. "https://pokeapi.co/api/v2/pokemon/1/"

          // ID aus der URL extrahieren
          // Wir splitten bei '/' und nehmen das vorletzte Element (das ist die ID)
          final uriSegments = Uri.parse(url).pathSegments;
          // pathSegments bei '.../pokemon/1/' ist ['api', 'v2', 'pokemon', '1', '']
          // Die ID ist das vorletzte Element, wenn man die leeren ignoriert, oder IndexWhere.
          // Sicherer Weg:
          final idString = uriSegments.where((s) => s.isNotEmpty).last;
          final id = int.tryParse(idString);

          if (id != null) {
            // Name formatieren: "bulbasaur" -> "Bulbasaur"
            final formattedName = rawName[0].toUpperCase() + rawName.substring(1);

            inserts.add(PokedexCompanion(
              id: Value(id),
              name: Value(formattedName),
            ));
          }
        }

        // 4. In Datenbank schreiben (Batch)
        if (inserts.isNotEmpty) {
          await db.batch((batch) {
            batch.insertAllOnConflictUpdate(db.pokedex, inserts);
          });
          print("✅ ${inserts.length} Pokémon erfolgreich importiert!");
        }
        
      } else {
        print("❌ API Fehler: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Fehler beim Pokedex Import: $e");
    }
  }
}