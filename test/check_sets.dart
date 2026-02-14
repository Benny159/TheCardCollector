import 'package:dio/dio.dart';
import 'dart:convert';

// Ausführen mit: flutter test test/inspect_api.dart

void main() async {
  final dio = Dio();
  const encoder = JsonEncoder.withIndent('  ');

  const String targetId = 'A1'; // Das Pocket Set "Genetic Apex"
  const String url = 'https://api.tcgdex.net/v2/en/sets/$targetId';

  print('\n🔍 --- DETAIL-CHECK FÜR SET: $targetId ---');
  print('Request: GET $url');
  
  try {
    final response = await dio.get(url);
    
    // Wir kopieren die Daten in eine Map, um sie zu bearbeiten
    Map<String, dynamic> data = Map<String, dynamic>.from(response.data);

    // Wir entfernen das Karten-Array für die Anzeige, damit es übersichtlich bleibt
    if (data.containsKey('cards')) {
      int cardCount = (data['cards'] as List).length;
      data['cards'] = "... [$cardCount Karten versteckt für bessere Übersicht] ...";
    }

    print('\n📦 SET METADATEN (Ohne Kartenliste):');
    print(encoder.convert(data));

    print('\n-------------------------------------------------------');
    print('ANALYSE FÜR FILTER:');
    if (data.containsKey('serie')) {
      print('Serie Name:  ${data['serie']['name']}');
      print('Serie ID:    ${data['serie']['id']}');
    } else {
      print('Keine Serie gefunden!');
    }
    print('-------------------------------------------------------');

  } catch (e) {
    if (e is DioException && e.response?.statusCode == 404) {
      print('❌ Fehler: Set ID "$targetId" wurde nicht gefunden (404).');
    } else {
      print('❌ Fehler beim Laden: $e');
    }
  }
}