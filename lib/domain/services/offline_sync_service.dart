import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';
import '../../core/cache/app_image_cache_manager.dart';

/// State of an active offline image download operation.
class OfflineSyncProgress {
  final bool isSyncing;
  final int current;
  final int total;
  final String? currentTask;

  const OfflineSyncProgress({
    this.isSyncing = false,
    this.current = 0,
    this.total = 0,
    this.currentTask,
  });

  double get percentage => total == 0 ? 0.0 : (current / total).clamp(0.0, 1.0);
}

/// Service managing offline image pre-caching for collections, binders, and expansion sets.
class OfflineSyncService {
  final AppDatabase db;
  final Ref ref;

  OfflineSyncService(this.db, this.ref);

  /// Downloads all card images for owned cards and cards placed in binders.
  Future<void> prefetchCollectionAndBinders({Function(int current, int total)? onProgress}) async {
    try {
      final rows = await db.customSelect('''
        SELECT DISTINCT c.image_url, c.image_url_de 
        FROM cards c
        WHERE c.id IN (SELECT card_id FROM user_cards)
           OR c.id IN (SELECT card_id FROM binder_cards WHERE is_placeholder = 0 AND card_id IS NOT NULL)
      ''').get();

      final Set<String> urls = {};
      for (final row in rows) {
        final enUrl = row.read<String?>('image_url');
        final deUrl = row.read<String?>('image_url_de');
        if (enUrl != null && enUrl.isNotEmpty) urls.add(enUrl);
        if (deUrl != null && deUrl.isNotEmpty) urls.add(deUrl);
      }

      int done = 0;
      final total = urls.length;

      for (final url in urls) {
        try {
          final fileInfo = await AppImageCacheManager.instance.getFileFromCache(url);
          if (fileInfo == null) {
            await AppImageCacheManager.instance.downloadFile(url);
          }
        } catch (e) {
          debugPrint('Offline cache skip for $url: $e');
        }
        done++;
        onProgress?.call(done, total);
      }
    } catch (e) {
      debugPrint('Error during prefetchCollectionAndBinders: $e');
    }
  }

  /// Downloads all card images belonging to expansion set [setId].
  Future<void> prefetchSet(String setId, {Function(int current, int total)? onProgress}) async {
    try {
      final cards = await (db.select(db.cards)..where((t) => t.setId.equals(setId))).get();
      final Set<String> urls = {};
      for (final c in cards) {
        if (c.imageUrl.isNotEmpty) urls.add(c.imageUrl);
        if (c.imageUrlDe != null && c.imageUrlDe!.isNotEmpty) urls.add(c.imageUrlDe!);
      }

      int done = 0;
      final total = urls.length;

      for (final url in urls) {
        try {
          final fileInfo = await AppImageCacheManager.instance.getFileFromCache(url);
          if (fileInfo == null) {
            await AppImageCacheManager.instance.downloadFile(url);
          }
        } catch (e) {
          debugPrint('Set image download skip for $url: $e');
        }
        done++;
        onProgress?.call(done, total);
      }
    } catch (e) {
      debugPrint('Error during prefetchSet for $setId: $e');
    }
  }

  /// Checks how many cards in set [setId] are currently cached locally.
  Future<double> getSetOfflineRatio(String setId) async {
    try {
      final cards = await (db.select(db.cards)..where((t) => t.setId.equals(setId))).get();
      if (cards.isEmpty) return 0.0;

      int cached = 0;
      for (final c in cards) {
        final info = await AppImageCacheManager.instance.getFileFromCache(c.imageUrl);
        if (info != null) cached++;
      }
      return cached / cards.length;
    } catch (_) {
      return 0.0;
    }
  }
}

final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  final db = ref.watch(databaseProvider);
  return OfflineSyncService(db, ref);
});

class OfflineSyncNotifier extends StateNotifier<OfflineSyncProgress> {
  final OfflineSyncService _service;

  OfflineSyncNotifier(this._service) : super(const OfflineSyncProgress());

  Future<void> syncCollectionAndBinders() async {
    state = const OfflineSyncProgress(isSyncing: true, current: 0, total: 1, currentTask: 'Sammlung & Binder');
    await _service.prefetchCollectionAndBinders(
      onProgress: (current, total) {
        state = OfflineSyncProgress(isSyncing: true, current: current, total: total, currentTask: 'Sammlung & Binder');
      },
    );
    state = const OfflineSyncProgress(isSyncing: false);
  }

  Future<void> syncSet(String setId, String setName) async {
    state = OfflineSyncProgress(isSyncing: true, current: 0, total: 1, currentTask: setName);
    await _service.prefetchSet(
      setId,
      onProgress: (current, total) {
        state = OfflineSyncProgress(isSyncing: true, current: current, total: total, currentTask: setName);
      },
    );
    state = const OfflineSyncProgress(isSyncing: false);
  }
}

final offlineSyncProgressProvider = StateNotifierProvider<OfflineSyncNotifier, OfflineSyncProgress>((ref) {
  final service = ref.watch(offlineSyncServiceProvider);
  return OfflineSyncNotifier(service);
});
