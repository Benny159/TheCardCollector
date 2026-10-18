import '../../data/database/app_database.dart';
import '../models/api_card.dart';

/// Service responsible for calculating card market prices across various sources.
///
/// Encapsulates business logic for evaluating variant pricing (e.g. Normal,
/// Holofoil, Reverse Holo, First Edition) across CardMarket, TCGPlayer, and
/// custom user prices, taking user source preferences into account.
class PriceCalculator {
  const PriceCalculator();

  /// Calculates the effective market price for a card given its variant and preferred source.
  ///
  /// [pref]: The preferred price source ('cardmarket', 'tcgplayer', 'custom').
  /// [variant]: The card variant name (e.g. 'Normal', 'Holo', 'Reverse Holo', '1st Edition').
  /// [hasFirstEdition]: Whether the card print supports a First Edition stamp.
  /// [hasNormal]: Whether the card has a standard non-holo variant.
  /// [hasHolo]: Whether the card has a holographic variant.
  /// [cmPrice]: The latest CardMarket price data row.
  /// [tcgPrice]: The latest TCGPlayer price data row.
  /// [customPrice]: An optional global or user-specific custom price override.
  double calculateCardPrice({
    required String pref,
    required String variant,
    required bool hasFirstEdition,
    required bool hasNormal,
    required bool hasHolo,
    CardMarketPrice? cmPrice,
    TcgPlayerPrice? tcgPrice,
    double? customPrice,
  }) {
    // 1. Check if custom price takes absolute precedence
    if (pref == 'custom' && customPrice != null && customPrice > 0) {
      return customPrice;
    }

    final bool baseIsHolo = !hasNormal && hasHolo;
    final String lowerVariant = variant.toLowerCase();
    final bool isFirstEd = lowerVariant.contains('1st') || lowerVariant.contains('first');
    final bool isHolo = lowerVariant.contains('holo') || baseIsHolo;
    final bool isReverse = variant == 'Reverse Holo';

    final double tcgCur = calculateTcgPrice(
      tcgPrice: tcgPrice,
      isReverse: isReverse,
      isHolo: isHolo,
    );

    final double cmCur = calculateCardMarketPrice(
      cmPrice: cmPrice,
      hasFirstEdition: hasFirstEdition,
      baseIsHolo: baseIsHolo,
      isFirstEd: isFirstEd,
      isHolo: isHolo,
      isReverse: isReverse,
    );

    // 2. Resolve preferred source
    if (pref == 'tcgplayer' && tcgCur > 0.0) {
      return tcgCur;
    }
    if (pref == 'cardmarket' && cmCur > 0.0) {
      return cmCur;
    }

    // 3. Fallback cascade
    if (cmCur > 0.0) {
      return cmCur;
    }
    if (tcgCur > 0.0) {
      return tcgCur;
    }
    if (customPrice != null && customPrice > 0) {
      return customPrice;
    }

    return 0.0;
  }

  /// Calculates the market price specifically from a TCGPlayer price record.
  ///
  /// Evaluates reverse holo, holo, and normal market tiers with fallback.
  double calculateTcgPrice({
    TcgPlayerPrice? tcgPrice,
    required bool isReverse,
    required bool isHolo,
  }) {
    if (tcgPrice == null) {
      return 0.0;
    }

    double price = 0.0;
    if (isReverse) {
      price = tcgPrice.reverseMarket ?? 0.0;
    } else if (isHolo) {
      price = tcgPrice.holoMarket ?? 0.0;
    } else {
      price = tcgPrice.normalMarket ?? 0.0;
    }

    // Fallback to any available market tier if chosen tier has 0.0
    if (price == 0.0) {
      price = tcgPrice.normalMarket ??
          tcgPrice.holoMarket ??
          tcgPrice.reverseMarket ??
          0.0;
    }
    return price;
  }

  /// Calculates the market price specifically from a CardMarket price record.
  ///
  /// Evaluates 1st Edition, reverse holo, holo, and regular trend tiers with fallback.
  double calculateCardMarketPrice({
    CardMarketPrice? cmPrice,
    required bool hasFirstEdition,
    required bool baseIsHolo,
    required bool isFirstEd,
    required bool isHolo,
    required bool isReverse,
  }) {
    if (cmPrice == null) {
      return 0.0;
    }

    double price = 0.0;
    if (hasFirstEdition) {
      price = isFirstEd
          ? (isHolo ? (cmPrice.trend ?? 0.0) : (cmPrice.trendHolo ?? 0.0))
          : (isHolo ? (cmPrice.trendHolo ?? 0.0) : (cmPrice.trend ?? 0.0));
    } else if (isReverse) {
      price = cmPrice.trendReverse ?? cmPrice.trendHolo ?? 0.0;
    } else if (isHolo && !baseIsHolo) {
      price = cmPrice.trendHolo ?? 0.0;
    } else {
      price = cmPrice.trend ?? 0.0;
    }

    // Fallback if specific tier is not populated
    if (price == 0.0) {
      price = cmPrice.trend ?? cmPrice.trendHolo ?? 0.0;
    }
    return price;
  }

  /// Calculates the price from an [ApiCard] domain object (e.g. used in search and card details).
  double calculateFromApiCard({
    required ApiCard card,
    required String variant,
    String? preferredSourceOverride,
    double? customPriceOverride,
  }) {
    final String pref = preferredSourceOverride ?? card.preferredPriceSource;
    final double? custom = customPriceOverride ?? card.customPrice;

    if (pref == 'custom' && custom != null && custom > 0) {
      return custom;
    }

    final bool baseIsHolo = !card.hasNormal && card.hasHolo;
    final String lowerVariant = variant.toLowerCase();
    final bool isFirstEd = lowerVariant.contains('1st') || lowerVariant.contains('first');
    final bool isHolo = lowerVariant.contains('holo') || baseIsHolo;
    final bool isReverse = variant == 'Reverse Holo';

    double tcgCur = 0.0;
    final tcg = card.tcgplayer;
    if (tcg != null) {
      if (isReverse) {
        tcgCur = tcg.prices?.reverseHolofoil?.market ?? 0.0;
      } else if (isHolo) {
        tcgCur = tcg.prices?.holofoil?.market ?? 0.0;
      } else {
        tcgCur = tcg.prices?.normal?.market ?? 0.0;
      }
      if (tcgCur == 0.0) {
        tcgCur = tcg.prices?.normal?.market ??
            tcg.prices?.holofoil?.market ??
            tcg.prices?.reverseHolofoil?.market ??
            0.0;
      }
    }

    double cmCur = 0.0;
    final cm = card.cardmarket;
    if (cm != null) {
      if (card.hasFirstEdition) {
        cmCur = isFirstEd
            ? (isHolo ? (cm.trendPrice ?? 0.0) : (cm.trendHolo ?? 0.0))
            : (isHolo ? (cm.trendHolo ?? 0.0) : (cm.trendPrice ?? 0.0));
      } else if (isReverse) {
        cmCur = cm.reverseHoloTrend ?? cm.trendHolo ?? 0.0;
      } else if (isHolo && !baseIsHolo) {
        cmCur = cm.trendHolo ?? 0.0;
      } else {
        cmCur = cm.trendPrice ?? 0.0;
      }
      if (cmCur == 0.0) {
        cmCur = cm.trendPrice ?? cm.trendHolo ?? 0.0;
      }
    }

    if (pref == 'tcgplayer' && tcgCur > 0.0) {
      return tcgCur;
    }
    if (pref == 'cardmarket' && cmCur > 0.0) {
      return cmCur;
    }
    if (cmCur > 0.0) {
      return cmCur;
    }
    if (tcgCur > 0.0) {
      return tcgCur;
    }
    if (custom != null && custom > 0) {
      return custom;
    }

    return 0.0;
  }

  /// Resolves the historical market price of a card as of [targetDate] from historical price snapshots.
  ///
  /// Used to determine purchase-date valuations for portfolio performance calculations.
  double resolveHistoricalPrice({
    required String usedSource,
    required DateTime targetDate,
    required List<TcgPlayerPrice> tcgPrices,
    required List<CardMarketPrice> cmPrices,
    required bool hasFirstEdition,
    required bool hasNormal,
    required bool hasHolo,
    required String variant,
  }) {
    final bool baseIsHolo = !hasNormal && hasHolo;
    final String lowerVariant = variant.toLowerCase();
    final bool isFirstEd = lowerVariant.contains('1st') || lowerVariant.contains('first');
    final bool isHolo = lowerVariant.contains('holo') || baseIsHolo;
    final bool isReverse = variant == 'Reverse Holo';

    if (usedSource == 'tcgplayer' && tcgPrices.isNotEmpty) {
      final index = tcgPrices.lastIndexWhere((p) => !p.fetchedAt.isAfter(targetDate));
      final p = (index != -1) ? tcgPrices[index] : tcgPrices.first;
      return calculateTcgPrice(tcgPrice: p, isReverse: isReverse, isHolo: isHolo);
    } else if (usedSource == 'cardmarket' && cmPrices.isNotEmpty) {
      final index = cmPrices.lastIndexWhere((p) => !p.fetchedAt.isAfter(targetDate));
      final p = (index != -1) ? cmPrices[index] : cmPrices.first;
      return calculateCardMarketPrice(
        cmPrice: p,
        hasFirstEdition: hasFirstEdition,
        baseIsHolo: baseIsHolo,
        isFirstEd: isFirstEd,
        isHolo: isHolo,
        isReverse: isReverse,
      );
    }
    return 0.0;
  }
}

