import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/search_provider.dart';
import '../../../domain/models/api_card.dart';
import '../../cards/card_detail_screen.dart';
import '../../inventory/inventory_bottom_sheet.dart';

/// Card tile widget displaying a search result card thumbnail with pricing and binder assignment badges.
class SearchCardTile extends ConsumerWidget {
  /// The card domain model to render.
  final ApiCard card;

  /// Whether this tile is presented in modal picker mode (returning the selected card).
  final bool isPicker;

  /// Creates a [SearchCardTile] for [card].
  const SearchCardTile({
    required this.card,
    required this.isPicker,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isOwned = card.isOwned;

    double? displayPrice = card.cardmarket?.trendPrice;
    if (displayPrice == null || displayPrice == 0) {
      displayPrice = card.tcgplayer?.prices?.normal?.market ??
          card.tcgplayer?.prices?.holofoil?.market ??
          card.tcgplayer?.prices?.reverseHolofoil?.market;
    }

    final displayImage = card.displayImage;
    final binderLocationsAsync = ref.watch(cardBinderLocationProvider(card.id));

    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          if (isPicker) {
            Navigator.pop(context, card);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)),
            ).then((_) {
              ref.invalidate(searchResultsProvider);
              ref.invalidate(cardBinderLocationProvider(card.id));
            });
          }
        },
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => InventoryBottomSheet(card: card),
          ).then((_) {
            ref.invalidate(searchResultsProvider);
            ref.invalidate(cardBinderLocationProvider(card.id));
          });
        },
        child: Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: (isPicker && isOwned)
                ? const BorderSide(color: Colors.green, width: 2)
                : BorderSide.none,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: displayImage,
                memCacheWidth: 200,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                ),
                fadeInDuration: const Duration(milliseconds: 150),
              ),
              binderLocationsAsync.when(
                data: (binders) {
                  if (binders.isEmpty) {
                    return const SizedBox();
                  }

                  final badgeText = binders.length > 1
                      ? "${binders.first} (+${binders.length - 1})"
                      : binders.first;

                  return Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.folder_special, color: Colors.white, size: 10),
                          const SizedBox(width: 3),
                          Text(
                            badgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        card.number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (displayPrice != null && displayPrice > 0)
                        Text(
                          '${displayPrice.toStringAsFixed(2)}€',
                          style: const TextStyle(
                            color: Colors.lightGreenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
