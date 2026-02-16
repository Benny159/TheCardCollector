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
      // Weniger Padding, damit mehr Platz für Karten ist
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        children: [
          // FIX: Expanded + LayoutBuilder garantiert, dass ALLES sichtbar ist
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Wir berechnen das optimale Verhältnis dynamisch
                // Verfügbare Breite / Anzahl Spalten
                final itemWidth = constraints.maxWidth / cols;
                // Verfügbare Höhe / Anzahl Reihen
                final itemHeight = constraints.maxHeight / rows;
                
                // Verhältnis berechnen
                final ratio = itemWidth / itemHeight;

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    // Hier nutzen wir das berechnete Verhältnis!
                    // Das zwingt das Grid dazu, exakt in die Box zu passen.
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
          // --- NEUE NAVIGATION ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Zurück Button (nur wenn nicht Seite 0)
              if (pageNumber > 0)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey),
                  onPressed: onPrevPage,
                  tooltip: "Vorherige Seite",
                  constraints: const BoxConstraints(), // Kompakt
                  padding: EdgeInsets.zero,
                )
              else
                const SizedBox(width: 24), // Platzhalter damit die Zahl mittig bleibt

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "- ${pageNumber + 1} -", 
                  style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12)
                ),
              ),

              // Vor Button (nur wenn nicht letzte Seite)
              if (pageNumber < totalPages - 1)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onPressed: onNextPage,
                  tooltip: "Nächste Seite",
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                )
              else
                 const SizedBox(width: 24),
            ],
          ),
        ],
      ),
    );
  }
}