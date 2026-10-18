import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../data/api/search_provider.dart';
import '../../cards/card_detail_screen.dart';
import '../inventory_bottom_sheet.dart';

/// Presentation card tile displaying an inventory item with foil effects, grading badges, and pricing indicators.
class InventoryCardTile extends ConsumerWidget {
  /// The inventory item to render.
  final InventoryItem item;

  /// Creates an [InventoryCardTile] for [item].
  const InventoryCardTile({required this.item, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isReverseHolo = item.variant == 'Reverse Holo';
    final bool isHolo = item.variant == 'Holo';
    final bool showEffect = isReverseHolo || isHolo;

    final bool isGraded = item.userCard.gradingCompany != null &&
        item.userCard.gradingCompany != 'Kein Grading';

    final displayImage = item.card.displayImage;

    // Price and performance resolution
    final double singlePrice =
        item.totalValue / (item.quantity > 0 ? item.quantity : 1);
    final double singlePerformance =
        item.performance / (item.quantity > 0 ? item.quantity : 1);

    final bool hasSpecificPrice =
        item.userCard.customPrice != null && item.userCard.customPrice! > 0;
    final bool isNeutral = singlePerformance.abs() < 0.01;
    final bool isPositive = singlePerformance > 0;

    final Color perfColor = isNeutral
        ? Colors.grey[400]!
        : (isPositive ? Colors.greenAccent : Colors.redAccent);
    final IconData perfIcon = isNeutral
        ? Icons.remove
        : (isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down);

    final String dateStr =
        DateFormat('dd.MM.yy').format(item.userCard.createdAt);
    final String variantStr = _getVariantAbbreviation(item.variant);
    final String conditionStr =
        _getConditionAbbreviation(item.userCard.condition);
    final Color conditionColor = _getConditionColor(item.userCard.condition);

    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CardDetailScreen(card: item.card),
            ),
          );
        },
        onLongPress: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => InventoryBottomSheet(card: item.card),
          );
        },
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: isGraded ? 6 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isGraded
                ? BorderSide(color: Colors.orange[400]!, width: 1.5)
                : BorderSide.none,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Card artwork background
              Builder(
                builder: (context) {
                  final Widget imageWidget = CachedNetworkImage(
                    imageUrl: displayImage,
                    memCacheHeight: 250,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                    ),
                  );
                  if (showEffect) {
                    return HoloEffect(isReverse: isReverseHolo, child: imageWidget);
                  }
                  return imageWidget;
                },
              ),

              // 2. Top header overlay with card name and variant
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Text(
                              item.card.nameDe ?? item.card.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 1.0
                                  ..color = Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item.card.nameDe ?? item.card.name,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        variantStr,
                        style: TextStyle(
                          color: showEffect ? Colors.amberAccent : Colors.white70,
                          fontSize: 9,
                          fontWeight: showEffect ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Grading score badge
              if (isGraded)
                Positioned(
                  top: 30,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[800],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${item.userCard.gradingCompany} ${item.userCard.gradingScore ?? ''}".trim(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Quantity counter badge
              Positioned(
                top: 30,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${item.quantity}x",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Card condition pill
              Positioned(
                bottom: 20,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: conditionColor,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    conditionStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Bottom gradient footer with acquisition date and valuation
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.9),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(6, 16, 6, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          "Am: $dateStr",
                          style: const TextStyle(color: Colors.white70, fontSize: 9),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!hasSpecificPrice)
                            Row(
                              children: [
                                Icon(perfIcon, color: perfColor, size: 12),
                                Text(
                                  "${singlePerformance.abs().toStringAsFixed(2)}€",
                                  style: TextStyle(
                                    color: perfColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          if (!hasSpecificPrice) const SizedBox(height: 2),
                          Row(
                            children: [
                              if (hasSpecificPrice)
                                const Icon(Icons.star, color: Colors.amber, size: 10),
                              if (hasSpecificPrice) const SizedBox(width: 2),
                              Text(
                                "${singlePrice.toStringAsFixed(2)}€",
                                style: TextStyle(
                                  color: hasSpecificPrice
                                      ? Colors.amberAccent
                                      : Colors.greenAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
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

  String _getVariantAbbreviation(String variant) {
    if (variant == 'Reverse Holo') return 'Rev.';
    if (variant == 'Normal') return 'Norm.';
    if (variant == 'Holo') return 'Holo';
    if (variant == '1st Edition') return '1.Ed';
    return variant;
  }

  String _getConditionAbbreviation(String condition) {
    switch (condition) {
      case 'Mint':
        return 'MINT';
      case 'Near Mint':
        return 'NM';
      case 'Excellent':
        return 'EX';
      case 'Good':
        return 'GD';
      case 'Light Played':
        return 'LP';
      case 'Played':
        return 'PL';
      case 'Poor':
        return 'POOR';
      default:
        return condition;
    }
  }

  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'Mint':
      case 'Near Mint':
        return Colors.green[700]!;
      case 'Excellent':
      case 'Good':
        return Colors.blue[700]!;
      case 'Light Played':
      case 'Played':
        return Colors.orange[700]!;
      case 'Poor':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
}

/// Dynamic animated holographic shimmer effect widget.
class HoloEffect extends StatefulWidget {
  final Widget child;
  final bool isReverse;

  const HoloEffect({super.key, required this.child, this.isReverse = false});

  @override
  State<HoloEffect> createState() => _HoloEffectState();
}

class _HoloEffectState extends State<HoloEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  transform: GradientRotation(_controller.value * 2 * 3.1415926535),
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.1),
                    Colors.purple.withValues(alpha: 0.15),
                    Colors.blue.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.45, 0.55, 0.7, 1.0],
                ),
                backgroundBlendMode: BlendMode.overlay,
              ),
            );
          },
        ),
        if (widget.isReverse)
          Opacity(
            opacity: 0.1,
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.3, -0.5),
                  radius: 1.0,
                  colors: [Colors.white, Colors.transparent],
                ),
                backgroundBlendMode: BlendMode.screen,
              ),
            ),
          ),
      ],
    );
  }
}

/// Rotates a linear gradient sweep for card holographic animations.
class GradientRotation extends GradientTransform {
  final double radians;
  const GradientRotation(this.radians);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.rotationZ(radians);
  }
}
