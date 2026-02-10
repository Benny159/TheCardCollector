import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/api_card.dart';
import '../../domain/models/api_set.dart';

final apiClientProvider = Provider((ref) => TcgApiClient());

class TcgApiClient {
  // Dein API Key
  static const String _apiKey = '5941f408-9f09-4b60-9000-6726e7156816'; 

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.pokemontcg.io/v2/',
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      if (_apiKey.isNotEmpty) 'X-Api-Key': _apiKey, 
    },
  ));

  // Such-Funktion (Bleibt wie sie war)
  Future<List<ApiCard>> searchCards(String userInput) async {
    try {
      String finalQuery;
      if (userInput.contains(':')) {
        finalQuery = userInput;
      } else {
        finalQuery = 'name:$userInput*';
      }

      final response = await _dio.get(
        'cards',
        queryParameters: {
          'q': finalQuery, 
          'pageSize': 100, 
          'page': 1,
          'orderBy': '-set.releaseDate', 
        },
      );

      final data = response.data['data'] as List;
      return data.map((json) => ApiCard.fromJson(json)).toList();
    } catch (e) {
      print('API Such-Fehler: $e');
      throw Exception('Fehler bei der Suche: $e');
    }
  }

  // --- DIE NEUE "UNAUFHALTSAME" IMPORT FUNKTION ---
  Future<void> fetchAllCardsForSet(
    String setId, {
    required Future<void> Function(List<ApiCard> batch) onBatchLoaded,
  }) async {
    int page = 1;
    bool hasMore = true;
    const int batchSize = 200; // Kleine Häppchen bleiben sicherer

    print('Starte unendlichen Download-Loop für Set $setId...');

    while (hasMore) {
      bool success = false;
      int attempt = 1; // Nur für die Anzeige, nicht zum Abbrechen

      // DIESE SCHLEIFE LÄUFT EWIG, BIS SUCCESS = TRUE IST
      while (!success) {
        try {
          if (attempt > 1) {
            print('🔄 Lade Seite $page - Versuch Nr. $attempt ...');
          } else {
            print('Lade Seite $page...');
          }
          
          final response = await _dio.get(
            'cards',
            queryParameters: {
              'q': 'set.id:$setId',
              'pageSize': batchSize, 
              'page': page,
            },
          );

          final data = response.data['data'] as List;
          final newCards = data.map((json) => ApiCard.fromJson(json)).toList();
          
          // Speichern
          if (newCards.isNotEmpty) {
            await onBatchLoaded(newCards);
            print('✅ Seite $page (${newCards.length} Karten) gesichert.');
          }

          if (newCards.length < batchSize) {
            hasMore = false;
          } else {
            page++;
          }
          
          success = true; // Endlich geschafft! Raus aus der Retry-Schleife.
          
          // Kurze Pause als Belohnung für den Server
          await Future.delayed(const Duration(milliseconds: 50));

        } catch (e) {
          attempt++;
          print('⚠️ Fehler auf Seite $page (Versuch ${attempt - 1}): ${e.toString().split(']').last.trim()}');
          
          // Dynamische Wartezeit: Je öfter es fehlschlägt, desto länger warten wir (max 10 sek)
          // Versuch 1: 5s, Versuch 2: 5s, Versuch 10: 10s...
          final waitTime = (attempt < 5) ? 5 : 10;
          
          print('⏳ Der Server zickt. Warte $waitTime Sekunden und probiere es stumpf nochmal...');
          await Future.delayed(Duration(seconds: waitTime));
        }
      }
    }
  }

  Future<List<ApiSet>> fetchAllSets() async {
    print('Lade alle Sets...');
    try {
      final response = await _dio.get(
        'sets',
        queryParameters: {
          'orderBy': '-releaseDate', // Neueste Sets zuerst
          'pageSize': 500, // Sollte für fast alle reichen
        },
      );

      final data = response.data['data'] as List;
      return data.map((json) => ApiSet.fromJson(json)).toList();
    } catch (e) {
      print('Fehler beim Laden der Sets: $e');
      throw Exception('Sets konnten nicht geladen werden.');
    }
  }

  Future<ApiCard> fetchCard(String cardId) async {
    final response = await _dio.get('cards/$cardId');
  
    return ApiCard.fromJson(response.data['data']);
  }
}