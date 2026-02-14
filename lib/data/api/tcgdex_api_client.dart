import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tcgDexApiClientProvider = Provider((ref) => TcgDexApiClient());

class TcgDexApiClient {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.tcgdex.net/v2',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
  static const String _baseUrl = 'https://api.tcgdex.net/v2';

  Future<Map<String, dynamic>?> fetchSet(String setId) async {
    try {
      final response = await _dio.get('/en/sets/$setId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Fehler beim Laden von Set-Details $setId: $e');
      return null;
    }
  }

  // 1. Alle Sets laden (Liste)
  Future<List<dynamic>> fetchAllSets({required String lang}) async {
    final response = await _dio.get('/$lang/sets');
    return response.data as List;
  }

Future<List<dynamic>> fetchCardsOfSet(String setId, {required String lang}) async {
    try {
      final response = await _dio.get('/$lang/sets/$setId');
      // TCGdex gibt hier das Set-Objekt zurück, die Karten sind im Feld 'cards'
      final data = response.data;
      if (data is Map && data['cards'] is List) {
        return data['cards'] as List;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchCardDetails(String cardId, {required String lang}) async {
    try {
      final response = await _dio.get('/$lang/cards/$cardId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}