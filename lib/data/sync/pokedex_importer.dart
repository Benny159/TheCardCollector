import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Importer service for synchronizing National Pokédex species names and German translations.
class PokedexImporter {
  /// Local database instance.
  final AppDatabase db;

  /// Creates a [PokedexImporter] with the designated database instance.
  const PokedexImporter(this.db);

  /// Synchronizes the initial list of Pokémon species names from PokéAPI.
  ///
  /// Early returns if the local Pokédex already contains over 1,000 entries.
  Future<void> syncPokedex() async {
    // 1. Check if Pokédex data already exists locally with lightweight COUNT query
    final countRow = await db.customSelect('SELECT COUNT(*) AS c FROM pokedex').getSingle();
    final count = countRow.read<int>('c');
    
    // Skip remote download if database already populated
    if (count > 1000) {
      debugPrint("✅ Pokédex is already populated ($count entries).");
      return; 
    }

    debugPrint("⏳ Loading Pokédex list from PokéAPI...");

    try {
      // 2. Fetch all species entries in a single request
      final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=2000'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        final List<PokedexCompanion> inserts = [];

        // 3. Process entries and extract numeric species IDs
        for (final item in results) {
          final String rawName = item['name'];
          final String url = item['url'];

          final uriSegments = Uri.parse(url).pathSegments;
          final idString = uriSegments.where((s) => s.isNotEmpty).last;
          final id = int.tryParse(idString);

          if (id != null) {
            final formattedName = rawName[0].toUpperCase() + rawName.substring(1);
            inserts.add(PokedexCompanion(
              id: Value(id),
              name: Value(formattedName),
            ));
          }
        }

        // 4. Batch insert into SQLite database
        if (inserts.isNotEmpty) {
          await db.batch((batch) {
            batch.insertAllOnConflictUpdate(db.pokedex, inserts);
          });
          debugPrint("✅ Successfully imported ${inserts.length} Pokémon.");
        }
      } else {
        debugPrint("❌ PokéAPI error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error during Pokédex import: $e");
    }
  }

  /// Builds the localized German species dictionary from PokéAPI species endpoints.
  ///
  /// Processes missing translations in parallel batches of 20 to prevent rate limiting.
  Future<void> buildTranslationDictionary({Function(String status)? onProgress}) async {
    onProgress?.call("Lade Pokedex-Daten aus der Datenbank...");
    final allDex = await db.select(db.pokedex).get();
    
    // Filter species records that lack German translations
    final missingTranslations = allDex.where((p) => p.nameDe == null || p.nameDe!.isEmpty).toList();
    
    if (missingTranslations.isEmpty) {
      onProgress?.call("✅ Das Wörterbuch ist bereits zu 100% vollständig!");
      return;
    }

    int current = 0;
    final int total = missingTranslations.length;
    final List<PokedexCompanion> updates = [];

    onProgress?.call("Lade $total deutsche Namen von PokeAPI herunter...");

    // Query in 20-item chunks to avoid HTTP timeouts and rate limits
    for (int i = 0; i < total; i += 20) {
      final end = (i + 20 < total) ? i + 20 : total;
      final batch = missingTranslations.sublist(i, end);

      final futures = batch.map((pokemon) async {
        try {
          final res = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon-species/${pokemon.id}/'));
          if (res.statusCode == 200) {
            final data = json.decode(res.body);
            final names = data['names'] as List;
            final deNameObj = names.firstWhere((n) => n['language']['name'] == 'de', orElse: () => null);
            
            if (deNameObj != null) {
              return PokedexCompanion(
                id: Value(pokemon.id),
                name: Value(pokemon.name),
                nameDe: Value(deNameObj['name']),
              );
            }
          }
        } catch (e) {
          debugPrint("Error fetching German name for ${pokemon.name}: $e");
        }
        return null;
      });

      final batchResults = await Future.wait(futures);
      updates.addAll(batchResults.whereType<PokedexCompanion>());
      
      current += batch.length;
      onProgress?.call("Wörterbuch aufbauen: $current / $total ...");
    }

    if (updates.isNotEmpty) {
      onProgress?.call("Speichere ${updates.length} Übersetzungen in der Datenbank...");
      await db.batch((batch) {
        batch.insertAllOnConflictUpdate(db.pokedex, updates);
      });
    }
    
    onProgress?.call("✅ Wörterbuch erfolgreich aufgebaut!");
  }
}