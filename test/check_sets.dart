import 'package:dio/dio.dart';
import 'dart:convert';

// Ausführen mit: flutter test test/inspect_api.dart

void main() async {
  final dio = Dio();
  // Schön formatierte Ausgabe
  final encoder = JsonEncoder.withIndent('  '); 

  print('\n🔵 --- TEIL 1: ALLE SETS LADEN (TCGdex) ---');
  print('Request: GET https://api.tcgdex.net/v2/de/sets');
  
  List<dynamic> sets = [];
  
  try {
    final response = await dio.get('https://api.tcgdex.net/v2/de/sets');
    sets = response.data as List;
    print('✅ Erfolg! ${sets.length} Sets gefunden.');
    
    if (sets.isNotEmpty) {
      print('\n👉 BEISPIEL: Das allerneueste Set in der Liste:');
      // Wir nehmen das letzte Element, da die Liste oft chronologisch ist (oder das erste, je nach API)
      print(encoder.convert(sets.last));
      
      print('\n👉 ID-CHECK: Suche nach "151" (wegen me2.5 vs me2pt5 Problematik):');
      final set151 = sets.firstWhere(
        (s) => s['name'].toString().contains('151'), 
        orElse: () => null
      );
      if (set151 != null) {
        print('Name: ${set151['name']}');
        print('ID:   "${set151['id']}"  <-- Das ist die ID, die wir brauchen!');
      }
    }
  } catch (e) {
    print('❌ Fehler beim Laden der Sets: $e');
  }

  print('\n\n🔵 --- TEIL 2: EINZELNE KARTE LADEN ---');
  // Wir nehmen eine Karte aus Schwert & Schild (swsh3 - Darkness Ablaze)
  // TCGdex nutzt meist "setid-nummer"
  final cardId = 'me01-001'; // Glurak V
  final url = 'https://api.tcgdex.net/v2/de/cards/$cardId';
  
  print('Request: GET $url');

  try {
    final response = await dio.get(url);
    final data = response.data;
    
    print('\n📦 KOMPLETTE JSON ANTWORT:');
    print(encoder.convert(data));
    
    print('\n📋 --- ANALYSE FÜR DEINE DATENBANK ---');
    print('Diese Felder kannst du nutzen, um deine DB zu ergänzen:');
    print('-------------------------------------------------------');
    print('Name (DE):        ${data['name']}');
    print('Illustrator:      ${data['illustrator']} (Falls bei der anderen API fehlt)');
    
    // TCGdex ist hier etwas inkonsistent:
    // Pokémon haben oft "description", Trainer/Energien "effect"
    String? flavorText = data['description'] ?? data['effect'];
    print('Flavor/Effekt:    $flavorText');
    
    print('Seltenheit:       ${data['rarity']}');
    print('Bild URL (High):  ${data['image']}/high.png');
    
  } catch (e) {
    print('❌ Fehler beim Laden der Karte: $e');
  }
}