import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/app_image_cache_manager.dart';
import '../../../data/api/search_provider.dart';
import '../../../data/api/tcgdex_api_client.dart';
import '../../../data/database/database_provider.dart';
import '../../../data/sync/set_importer.dart';
import '../../../domain/models/api_set.dart';
import '../set_detail_screen.dart';

/// Card tile widget displaying expansion set metadata, logo, collection progress bar, and card download action.
class SetCardTile extends ConsumerWidget {
  /// The expansion set data model.
  final ApiSet set;

  /// Creates a [SetCardTile] for [set].
  const SetCardTile({required this.set, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(setStatsProvider(set.id));
    final logoUrl = set.logoUrlDe ?? set.logoUrl;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return RepaintBoundary(
      child: Card(
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SetDetailScreen(set: set),
              ),
            ).then((_) {
              // Refresh set stats upon navigating back
              ref.invalidate(allSetStatsProvider);
            });
          },
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Expansion logo
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: logoUrl != null 
                          ? CachedNetworkImage(
                              cacheManager: AppImageCacheManager.instance,
                              imageUrl: logoUrl,
                              memCacheHeight: 200,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            )
                          : const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                  
                  // Metadata and progress
                  Expanded(
                    flex: 2,
                    child: Container(
                      color: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            set.nameDe ?? set.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (set.releaseDate.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                set.releaseDate,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          
                          const Spacer(),

                          // Collection completion progress bar
                          statsAsync.when(
                            data: (ownedCount) {
                              final int totalCount = set.total; 
                              final double progress = totalCount > 0 ? (ownedCount / totalCount) : 0.0;
                              final double displayProgress = progress > 1.0 ? 1.0 : progress; 

                              return Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: displayProgress,
                                      minHeight: 5,
                                      backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "$ownedCount/$totalCount",
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? const Color(0xFFCBD5E1) : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "${(progress * 100).toStringAsFixed(0)}%",
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                            loading: () => LinearProgressIndicator(
                              minHeight: 5,
                              backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            ),
                            error: (_, __) => const SizedBox(), 
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Direct download button for offline card data
              Positioned(
                top: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(Icons.download_for_offline, color: Colors.grey),
                    tooltip: "Karten für dieses Set laden",
                    iconSize: 20,
                    onPressed: () => _importCards(context, ref, set),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _importCards(BuildContext context, WidgetRef ref, ApiSet set) async {
    final db = ref.read(databaseProvider);
    final dexApi = ref.read(tcgDexApiClientProvider);
    final importer = SetImporter(dexApi, db);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lade Karten für ${set.nameDe ?? set.name}...'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 500),
      ),
    );

    try {
      // Pre-fetch latest prices for diffing
      final setCardsQuery = await (db.select(db.cards)..where((t) => t.setId.equals(set.id))).get();
      final cardIds = setCardsQuery.map((c) => c.id).toList();
      
      Map<String, Map<String, dynamic>> latestCmPrices = {};
      Map<String, Map<String, dynamic>> latestTcgPrices = {};
      
      if (cardIds.isNotEmpty) {
        final allLatestCmQuery = await db.customSelect(
          'SELECT card_id, trend, trend_holo, trend_reverse FROM card_market_prices WHERE card_id IN (${cardIds.map((e) => "'$e'").join(',')}) GROUP BY card_id HAVING MAX(fetched_at)'
        ).get();
        latestCmPrices = {
          for (final row in allLatestCmQuery) row.read<String>('card_id'): {
            'trend': row.read<double?>('trend'),
            'trendHolo': row.read<double?>('trend_holo'),
            'trendReverse': row.read<double?>('trend_reverse'),
          }
        };

        final allLatestTcgQuery = await db.customSelect(
          'SELECT card_id, normal_market, holo_market, reverse_market FROM tcg_player_prices WHERE card_id IN (${cardIds.map((e) => "'$e'").join(',')}) GROUP BY card_id HAVING MAX(fetched_at)'
        ).get();
        latestTcgPrices = {
          for (final row in allLatestTcgQuery) row.read<String>('card_id'): {
            'normalMarket': row.read<double?>('normal_market'),
            'holoMarket': row.read<double?>('holo_market'),
            'reverseMarket': row.read<double?>('reverse_market'),
          }
        };
      }

      await importer.importCardsForSet(set.id, latestCmPrices, latestTcgPrices);
      
      ref.invalidate(cardsForSetProvider(set.id));
      ref.invalidate(allSetStatsProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Karten erfolgreich geladen!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Download: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    }
  }
}
