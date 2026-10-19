import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/cache/app_image_cache_manager.dart';
import '../../data/database/app_database.dart' as db;
import '../../domain/models/api_card.dart';

/// Reusable fallback widget shown when no card artwork is available in the database
/// or when remote network images fail to load.
///
/// Styled identically to the card detail view with a dark blue-grey background,
/// golden amber icon, bold card name, and card number.
class CardFallbackPreview extends StatelessWidget {
  /// Localized or English card name.
  final String cardName;

  /// Printed card number (e.g. '025' or '123/198').
  final String cardNumber;

  /// Optional custom icon size override.
  final double? customIconSize;

  /// Optional custom font size override for the card title.
  final double? customFontSize;

  /// Optional custom font size override for the card number.
  final double? customNumberSize;

  /// Optional padding override.
  final EdgeInsetsGeometry? padding;

  /// Optional border radius.
  final BorderRadius? borderRadius;

  const CardFallbackPreview({
    super.key,
    required this.cardName,
    required this.cardNumber,
    this.customIconSize,
    this.customFontSize,
    this.customNumberSize,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxH = constraints.maxHeight;
        final double maxW = constraints.maxWidth;
        final bool isTiny = (maxH > 0 && maxH < 90) || (maxW > 0 && maxW < 70);
        final bool isSmall = (maxH > 0 && maxH < 150) || (maxW > 0 && maxW < 110);

        final double iconSize =
            customIconSize ?? (isTiny ? 18.0 : (isSmall ? 24.0 : 36.0));
        final double fontSize =
            customFontSize ?? (isTiny ? 8.0 : (isSmall ? 10.0 : 13.0));
        final double numberSize =
            customNumberSize ?? (isTiny ? 7.0 : (isSmall ? 8.5 : 11.0));
        final double spacing = isTiny ? 2.0 : (isSmall ? 4.0 : 8.0);
        final EdgeInsetsGeometry effectivePadding = padding ??
            (isTiny
                ? const EdgeInsets.symmetric(horizontal: 2, vertical: 2)
                : (isSmall
                    ? const EdgeInsets.symmetric(horizontal: 4, vertical: 4)
                    : const EdgeInsets.all(12)));

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF263238), // Colors.blueGrey[900]
            borderRadius: borderRadius,
          ),
          alignment: Alignment.center,
          padding: effectivePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.style, color: Colors.amber, size: iconSize),
              SizedBox(height: spacing),
              Flexible(
                child: Text(
                  cardName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (cardNumber.isNotEmpty) ...[
                SizedBox(height: spacing / 2),
                Text(
                  cardNumber.startsWith('#') ? cardNumber : '#$cardNumber',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: numberSize,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Unified card artwork component with automatic multi-tier fallback:
/// 1. Tries primary localized image (German, `imageUrlDe`).
/// 2. If German is missing or network loading fails, falls back to English (`imageUrl` / `largeImageUrl`).
/// 3. If English is also missing or fails, or if no image exists in the database,
///    renders [CardFallbackPreview].
class CardImageWidget extends StatelessWidget {
  /// Primary remote artwork URL (usually German).
  final String? primaryUrl;

  /// Secondary fallback remote artwork URL (usually English).
  final String? fallbackUrl;

  /// Card name for the fallback preview.
  final String cardName;

  /// Card number for the fallback preview.
  final String cardNumber;

  /// Image box fit mode (defaults to [BoxFit.contain]).
  final BoxFit fit;

  /// Maximum decoded memory cache height.
  final int? memCacheHeight;

  /// Maximum decoded memory cache width.
  final int? memCacheWidth;

  /// Fade-in duration when transitioning from placeholder.
  final Duration fadeInDuration;

  /// Custom placeholder widget shown while loading.
  final Widget? placeholder;

  /// Optional border radius clipping.
  final BorderRadius? borderRadius;

  /// Creates a [CardImageWidget] from an [ApiCard].
  CardImageWidget.fromApiCard({
    super.key,
    required ApiCard card,
    this.fit = BoxFit.contain,
    this.memCacheHeight,
    this.memCacheWidth,
    this.fadeInDuration = const Duration(milliseconds: 150),
    this.placeholder,
    this.borderRadius,
  })  : primaryUrl = (card.imageUrlDe != null && card.imageUrlDe!.trim().isNotEmpty)
            ? card.imageUrlDe!.trim()
            : null,
        fallbackUrl = (card.largeImageUrl != null && card.largeImageUrl!.trim().isNotEmpty)
            ? card.largeImageUrl!.trim()
            : (card.smallImageUrl.trim().isNotEmpty ? card.smallImageUrl.trim() : null),
        cardName = card.nameDe ?? card.name,
        cardNumber = card.number;

  /// Creates a [CardImageWidget] from a database [db.Card].
  CardImageWidget.fromDbCard({
    super.key,
    required db.Card card,
    this.fit = BoxFit.contain,
    this.memCacheHeight,
    this.memCacheWidth,
    this.fadeInDuration = const Duration(milliseconds: 150),
    this.placeholder,
    this.borderRadius,
  })  : primaryUrl = (card.imageUrlDe != null && card.imageUrlDe!.trim().isNotEmpty)
            ? card.imageUrlDe!.trim()
            : null,
        fallbackUrl = card.imageUrl.trim().isNotEmpty ? card.imageUrl.trim() : null,
        cardName = card.nameDe ?? card.name,
        cardNumber = card.number;

  const CardImageWidget({
    super.key,
    this.primaryUrl,
    this.fallbackUrl,
    required this.cardName,
    required this.cardNumber,
    this.fit = BoxFit.contain,
    this.memCacheHeight,
    this.memCacheWidth,
    this.fadeInDuration = const Duration(milliseconds: 150),
    this.placeholder,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePrimary = (primaryUrl != null && primaryUrl!.trim().isNotEmpty)
        ? primaryUrl!.trim()
        : null;
    final effectiveFallback = (fallbackUrl != null && fallbackUrl!.trim().isNotEmpty)
        ? fallbackUrl!.trim()
        : null;

    final fallbackWidget = CardFallbackPreview(
      cardName: cardName,
      cardNumber: cardNumber,
      borderRadius: borderRadius,
    );

    // If no primary image, try fallback (English) directly
    final firstUrl = effectivePrimary ?? effectiveFallback;
    // If second url exists and is different from first, it will be used on error
    final secondUrl = (effectivePrimary != null &&
            effectiveFallback != null &&
            effectivePrimary != effectiveFallback)
        ? effectiveFallback
        : null;

    if (firstUrl == null) {
      // Neither German nor English image exists in DB!
      return fallbackWidget;
    }

    Widget content = CachedNetworkImage(
      cacheManager: AppImageCacheManager.instance,
      imageUrl: firstUrl,
      memCacheHeight: memCacheHeight,
      memCacheWidth: memCacheWidth,
      fit: fit,
      fadeInDuration: fadeInDuration,
      placeholder: (ctx, url) =>
          placeholder ?? Container(color: Colors.transparent),
      errorWidget: (ctx, url, error) {
        if (secondUrl != null) {
          // Primary (e.g. German) failed, fallback to English image!
          return CachedNetworkImage(
            cacheManager: AppImageCacheManager.instance,
            imageUrl: secondUrl,
            memCacheHeight: memCacheHeight,
            memCacheWidth: memCacheWidth,
            fit: fit,
            fadeInDuration: fadeInDuration,
            placeholder: (c, u) =>
                placeholder ?? Container(color: Colors.transparent),
            errorWidget: (c, u, e) => fallbackWidget,
          );
        }
        return fallbackWidget;
      },
    );

    if (borderRadius != null) {
      content = ClipRRect(borderRadius: borderRadius!, child: content);
    }

    return content;
  }
}

/// Convenience extension on database [db.Card] for image resolution.
extension DbCardImageExtension on db.Card {
  /// Returns the highest-priority image URL (German -> English -> empty string).
  String get displayImage {
    if (imageUrlDe != null && imageUrlDe!.trim().isNotEmpty) {
      return imageUrlDe!.trim();
    }
    if (imageUrl.trim().isNotEmpty) {
      return imageUrl.trim();
    }
    return '';
  }
}
