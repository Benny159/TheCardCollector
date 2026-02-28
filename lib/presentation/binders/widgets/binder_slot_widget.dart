import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../binder_detail_provider.dart';

class BinderSlotWidget extends StatelessWidget {
  final BinderSlotData slotData;
  final VoidCallback onTap;
  final VoidCallback? onLongPress; 
  final bool isHighlightedForSwap; // <--- NEU

  const BinderSlotWidget({
    super.key, 
    required this.slotData, 
    required this.onTap, 
    this.onLongPress,
    this.isHighlightedForSwap = false, // <--- NEU
  });

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = slotData.binderCard.isPlaceholder;
    final card = slotData.card;

    return GestureDetector(
      key: ValueKey("${slotData.binderCard.id}_${isPlaceholder}_${card?.id ?? 'null'}"),
      onTap: onTap,
      onLongPress: onLongPress, 
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(4),
          // --- HIGHLIGHT RAHMEN BEIM TAUSCHEN ---
          border: Border.all(
            color: isHighlightedForSwap ? Colors.redAccent : Colors.grey.withOpacity(0.3),
            width: isHighlightedForSwap ? 3 : 1,
          ),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, spreadRadius: 1, offset: const Offset(1, 1))
          ]
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (card != null)
              Opacity(
                opacity: isPlaceholder ? 0.4 : 1.0, 
                child: ColorFiltered(
                  colorFilter: isPlaceholder 
                      ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                      : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                  child: CachedNetworkImage(
                    imageUrl: card.imageUrl,
                    fit: BoxFit.contain,
                    memCacheWidth: 250, 
                    fadeInDuration: const Duration(milliseconds: 250), 
                    fadeOutDuration: const Duration(milliseconds: 250),
                    placeholder: (context, url) => Container(color: Colors.transparent),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              )
            else
              const Center(child: Icon(Icons.add, color: Colors.grey)),

            if (slotData.binderCard.placeholderLabel != null)
              Positioned(
                bottom: 2, left: 2, right: 2,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  child: Text(
                    slotData.binderCard.placeholderLabel!,
                    style: const TextStyle(color: Colors.white, fontSize: 8),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

            if (!isPlaceholder)
            Positioned(
              top: 4, right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(4)),
                child: Text(
                  "${slotData.marketPrice.toStringAsFixed(2)} €",
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}