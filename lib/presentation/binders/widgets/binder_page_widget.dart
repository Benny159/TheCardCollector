import 'package:flutter/material.dart';
import '../binder_detail_provider.dart';
import 'binder_slot_widget.dart';

class BinderPageWidget extends StatelessWidget {
  final List<BinderSlotData> slots;
  final int rows;
  final int cols;
  final int pageNumber; 
  final int totalPages;
  final Function(BinderSlotData) onSlotTap;
  final VoidCallback onNextPage;
  final VoidCallback onPrevPage;

  const BinderPageWidget({
    super.key,
    required this.slots,
    required this.rows,
    required this.cols,
    required this.pageNumber,
    required this.totalPages,
    required this.onSlotTap,
    required this.onNextPage,
    required this.onPrevPage,
  });

  @override
  Widget build(BuildContext context) {
    // --- NEU: Seitenwert berechnen ---
    // Wir zählen nur die Preise von echten Karten (keine Platzhalter) zusammen
    final double pageTotal = slots.fold(0.0, (sum, slot) {
      if (!slot.binderCard.isPlaceholder) {
        return sum + slot.marketPrice;
      }
      return sum;
    });

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: pageNumber % 2 == 0 ? const Offset(5, 0) : const Offset(-5, 0),
          )
        ]
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / cols;
                final itemHeight = constraints.maxHeight / rows;
                final ratio = itemWidth / itemHeight;

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: ratio, 
                  ),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    return BinderSlotWidget(
                      slotData: slots[index],
                      onTap: () => onSlotTap(slots[index]),
                    );
                  },
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // --- NAVIGATION UND WERT ---
          // Ein Stack eignet sich hier super, um die Seitenzahl exakt in der Mitte
          // zu halten, während der Preis unabhängig davon rechts am Rand klebt.
          // --- NAVIGATION UND WERT ---
          SizedBox(
            width: double.infinity, // FIX: Nimmt jetzt die volle Bildschirmbreite!
            height: 30, // Etwas mehr Platz
            child: Stack(
              children: [
                // 1. In der Mitte die Seitenzahl mit Pfeilen
                Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (pageNumber > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey),
                          onPressed: onPrevPage,
                          tooltip: "Vorherige Seite",
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        )
                      else
                        const SizedBox(width: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "- ${pageNumber + 1} -", 
                          style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12)
                        ),
                      ),

                      if (pageNumber < totalPages - 1)
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onPressed: onNextPage,
                          tooltip: "Nächste Seite",
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        )
                      else
                         const SizedBox(width: 16),
                    ],
                  ),
                ),
                
                // 2. Rechts in der Ecke der Seitenwert
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${pageTotal.toStringAsFixed(2)} €",
                      style: const TextStyle(
                        color: Colors.green, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 10
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}