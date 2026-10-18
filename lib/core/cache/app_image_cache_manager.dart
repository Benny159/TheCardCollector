import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Permanent, high-capacity image cache manager specifically configured for TCG card prints.
///
/// Features:
/// - 10-year retention (card artworks are immutable printed media)
/// - High capacity (up to 30,000 cached card images)
/// - Prevents Android/iOS from prematurely purging cached card images
class AppImageCacheManager {
  static const String key = 'tcg_permanent_card_cache';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 3650), // 10 years retention
      maxNrOfCacheObjects: 30000,              // Up to 30,000 cards & set symbols
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}
