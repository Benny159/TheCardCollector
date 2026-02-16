import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../binder_detail_provider.dart';

class BinderSlotWidget extends StatelessWidget {
  final BinderSlotData slotData;
  final VoidCallback onTap;

  const BinderSlotWidget({super.key, required this.slotData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = slotData.binderCard.isPlaceholder;
    final card = slotData.card;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, spreadRadius: 1, offset: const Offset(1, 1))
          ]
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // --- BILD ANZEIGE ---
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
                    
                    // Speicher sparen (hast du schon, sehr gut!)
                    memCacheWidth: 250, 

                    // --- ÄNDERUNG HIER ---
                    // Wir stellen die Animationen ab. Das Bild soll SOFORT da sein.
                    fadeInDuration: Duration.zero, 
                    fadeOutDuration: Duration.zero,
                    
                    // Platzhalter
                    placeholder: (context, url) =>Container(
                      color: Colors.transparent, // Kein Loading Spinner beim schnellen Blättern
                    ),
                    
                    // Error Widget
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              )
            else
              const Center(child: Icon(Icons.add, color: Colors.grey)),

            // --- LABEL ---
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

            // --- STATUS ---
            if (!isPlaceholder)
              const Positioned(
                top: 2, right: 2,
                child: Icon(Icons.check_circle, color: Colors.green, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}