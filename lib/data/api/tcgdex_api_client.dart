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

  /// Internal request wrapper providing automatic retry with exponential backoff on 503, 429, and timeouts.
  Future<Response<dynamic>?> _getWithRetry(String path, {int maxRetries = 3}) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await _dio.get(path);
        return response;
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        // 404 Not Found is completely normal for sets/cards not released in a particular language (e.g. English-only sets on German endpoint)
        if (status == 404) {
          return null;
        }

        final isRetryable = status == 503 ||
            status == 429 ||
            status == 500 ||
            status == 502 ||
            status == 504 ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout;

        if (attempt < maxRetries - 1 && isRetryable) {
          final waitSeconds = (attempt + 1) * 2;
          debugPrint(
              '⚠️ TCGdex HTTP $status for $path. Warte ${waitSeconds}s vor erneutem Versuch (${attempt + 1}/$maxRetries)...');
          await Future.delayed(Duration(seconds: waitSeconds));
          continue;
        }
        rethrow;
      }
    }
    return null;
  }

  /// Fetches detailed metadata for a single expansion set by [setId].
  Future<Map<String, dynamic>?> fetchSet(String setId) async {
    try {
      final response = await _getWithRetry('/en/sets/$setId');
      return response?.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error loading set details for $setId: $e');
      return null;
    }
  }

  /// Fetches a list of all available sets for the given language code [lang] ('en', 'de').
  Future<List<dynamic>> fetchAllSets({required String lang}) async {
    final response = await _getWithRetry('/$lang/sets');
    return (response?.data as List?) ?? [];
  }

  /// Fetches the array of cards belonging to the set with [setId] in language [lang].
  Future<List<dynamic>> fetchCardsOfSet(String setId, {required String lang}) async {
    try {
      final response = await _getWithRetry('/$lang/sets/$setId');
      final data = response?.data;
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
      final response = await _getWithRetry('/$lang/cards/$cardId');
      return response?.data as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error fetching card details for $cardId ($lang): $e');
      return null;
    }
  }
}