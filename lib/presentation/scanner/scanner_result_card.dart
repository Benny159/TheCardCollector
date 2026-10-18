import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide Card;
import '../../data/database/app_database.dart';

/// Presentation widget displaying the recognition results of a scanned Pokémon card.
///
/// Features thumbnail previews, ownership badges, alternative set variants,
/// an expansion completion progress indicator, and action triggers.
class ScannerResultCard extends StatelessWidget {
  /// The recognized card.
  final Card card;

  /// The expansion set containing the card.
  final CardSet? scannedSet;

  /// Number of copies already owned by the user.
  final int ownedQuantity;

  /// Evaluated market price for display.
  final double cardPrice;

  /// Completion ratio (0.0 to 1.0) of the containing set.
  final double setProgress;

  /// Count of unique cards owned in this set.
  final int setOwned;

  /// Total count of cards in this set.
  final int setTotal;

  /// Alternative printings/variants found within the same set.
  final List<Card> alternativeCards;

  /// Callback when user selects an alternative variant card.
  final ValueChanged<Card> onSelectCard;

  /// Callback to resume camera scanning.
  final VoidCallback onRescan;

  /// Callback when user confirms the scanned card.
  final VoidCallback onConfirm;

  /// Callback to trigger a manual search dialog.
  final VoidCallback onManualSearch;

  const ScannerResultCard({
    super.key,
    required this.card,
    required this.scannedSet,
    required this.ownedQuantity,
    required this.cardPrice,
    required this.setProgress,
    required this.setOwned,
    required this.setTotal,
    required this.alternativeCards,
    required this.onSelectCard,
    required this.onRescan,
    required this.onConfirm,
    required this.onManualSearch,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNewCard = ownedQuantity == 0;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Card image with aspect ratio
                  AspectRatio(
                    aspectRatio: 0.716,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: card.imageUrlDe ?? card.imageUrl,
                        memCacheHeight: 200,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: Colors.grey[200]),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 2. Metadata column
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name & Number
                          Text(
                            card.nameDe ?? card.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${card.number} / ${scannedSet?.printedTotal ?? '?'}",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Ownership Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isNewCard ? Colors.amber[600] : Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isNewCard ? Colors.amber[800]! : Colors.blue[300]!,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isNewCard ? Icons.star : Icons.inventory_2,
                                  size: 14,
                                  color: isNewCard ? Colors.white : Colors.blue[900],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isNewCard
                                      ? "NEUE KARTE"
                                      : "In Sammlung: $ownedQuantity x",
                                  style: TextStyle(
                                    color: isNewCard ? Colors.white : Colors.blue[900],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Alternative Variants
                          if (alternativeCards.isNotEmpty) ...[
                            Text(
                              "Andere Variante erkannt?",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: alternativeCards
                                    .map(
                                      (alt) => GestureDetector(
                                        onTap: () => onSelectCard(alt),
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: CachedNetworkImage(
                                              memCacheHeight: 200,
                                              imageUrl: alt.imageUrlDe ?? alt.imageUrl,
                                              width: 45,
                                              height: 63,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Container(
                                                width: 45,
                                                height: 63,
                                                color: Colors.grey[300],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Manual Search Action Button
                          SizedBox(
                            height: 28,
                            child: TextButton.icon(
                              onPressed: onManualSearch,
                              icon: const Icon(Icons.search, size: 14),
                              label: const Text(
                                "Falsches Pokémon? Suchen",
                                style: TextStyle(fontSize: 11),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                backgroundColor:
                                    Colors.blueAccent.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Set Info & Progress Box
                          if (scannedSet != null)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (scannedSet!.logoUrl != null ||
                                          scannedSet!.logoUrlDe != null) ...[
                                        SizedBox(
                                          height: 20,
                                          width: 40,
                                          child: CachedNetworkImage(
                                            imageUrl: scannedSet!.logoUrlDe ??
                                                scannedSet!.logoUrl!,
                                            memCacheHeight: 200,
                                            fit: BoxFit.contain,
                                            errorWidget: (_, __, ___) =>
                                                const SizedBox(),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(
                                        child: Text(
                                          scannedSet!.nameDe ?? scannedSet!.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: setProgress,
                                            backgroundColor: Colors.grey[300],
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.blue[400]!,
                                            ),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "$setOwned / $setTotal",
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Bottom Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRescan,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Erneut"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.add_task),
                    label: const Text("Bestätigen"),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
