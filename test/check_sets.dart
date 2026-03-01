import 'package:dio/dio.dart';
import 'dart:convert';

// Ausführen im Terminal mit: 
// dart test/inspect_api.dart
// (oder flutter test test/inspect_api.dart)

void main() async {
  final dio = Dio();
  const encoder = JsonEncoder.withIndent('  ');

  // Wir nehmen Glurak (Charizard) aus dem Base Set als perfektes Beispiel
  const String targetId = 'base1-4'; 
  const String url = 'https://api.tcgdex.net/v2/en/cards/$targetId';

  print('\n🔍 --- DETAIL-CHECK FÜR KARTE: $targetId ---');
  print('Request: GET $url');
  
  try {
    final response = await dio.get(url);
    Map<String, dynamic> data = Map<String, dynamic>.from(response.data);

    // Große Listen (wie Attacken) kürzen, damit das Terminal nicht platzt
    if (data.containsKey('attacks')) data['attacks'] = '[... Attacken versteckt ...]';
    if (data.containsKey('weaknesses')) data['weaknesses'] = '[... Schwächen versteckt ...]';
    if (data.containsKey('retreat')) data['retreat'] = '[... Rückzug versteckt ...]';
    if (data.containsKey('legal')) data['legal'] = '[... Legalität versteckt ...]';

    print('\n📦 KARTEN METADATEN:');
    print(encoder.convert(data));

    print('\n-------------------------------------------------------');
    print('ANALYSE FÜR FILTER/SORTIERUNG:');
    print('Kategorie: ${data['category']}'); // Wichtig für: Pokemon, Trainer, Energy
    if (data.containsKey('types')) {
      print('Typen:     ${data['types']}'); // Wichtig für: [Fire], [Water], etc.
    } else {
      print('Kein Element-Typ gefunden (wahrscheinlich Trainer-Karte).');
    }
    print('-------------------------------------------------------');

  } catch (e) {
    if (e is DioException && e.response?.statusCode == 404) {
      print('❌ Fehler: Karte "$targetId" wurde nicht gefunden (404).');
    } else {
      print('❌ Fehler beim Laden: $e');
    }
  }
}