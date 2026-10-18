import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider exposing the singleton HTTP client for the TCGdex REST API.
final tcgDexApiClientProvider = Provider((ref) => TcgDexApiClient());

/// REST API client for interacting with the public TCGdex endpoint (v2).
class TcgDexApiClient {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.tcgdex.net/v2',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// Fetches detailed metadata for a single expansion set by [setId].
  Future<Map<String, dynamic>?> fetchSet(String setId) async {
    try {
      final response = await _dio.get('/en/sets/$setId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading set details for $setId: $e');
      return null;
    }
  }

  /// Fetches a list of all available sets for the given language code [lang] ('en', 'de').
  Future<List<dynamic>> fetchAllSets({required String lang}) async {
    final response = await _dio.get('/$lang/sets');
    return response.data as List;
  }

  /// Fetches the array of cards belonging to the set with [setId] in language [lang].
  Future<List<dynamic>> fetchCardsOfSet(String setId, {required String lang}) async {
    try {
      final response = await _dio.get('/$lang/sets/$setId');
      final data = response.data;
      if (data is Map && data['cards'] is List) {
        return data['cards'] as List;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching cards for set $setId ($lang): $e');
      return [];
    }
  }

  /// Fetches full card details (attacks, weaknesses, legalities) for [cardId] in language [lang].
  Future<Map<String, dynamic>?> fetchCardDetails(String cardId, {required String lang}) async {
    try {
      final response = await _dio.get('/$lang/cards/$cardId');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error fetching card details for $cardId ($lang): $e');
      return null;
    }
  }
}