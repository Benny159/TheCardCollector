import 'package:flutter/material.dart';

class ScannerOverlayMask extends StatelessWidget {
  const ScannerOverlayMask({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Ein echtes Pokémon-Karten-Format (63x88 -> 0.716)
        // Deutlich schmaler als vorher!
        final cardWidth = width * 0.65; // Nur noch 65% der Bildschirmbreite
        final cardHeight = cardWidth / 0.716;

        final left = (width - cardWidth) / 2;
        final top = (height - cardHeight) / 2;
        final cardRect = Rect.fromLTWH(left, top, cardWidth, cardHeight);

        final topZoneRect = Rect.fromLTWH(left + 10, top + 10, cardWidth - 20, cardHeight * 0.15);
        final bottomZoneRect = Rect.fromLTWH(left + 10, top + cardHeight - (cardHeight * 0.15) - 10, cardWidth - 20, cardHeight * 0.15);

        return Stack(
          children: [
            CustomPaint(
              size: Size(width, height),
              painter: MaskPainter(
                cardRect: cardRect,
                topZoneRect: topZoneRect,
                bottomZoneRect: bottomZoneRect,
              ),
            ),
            
            Positioned(
              top: topZoneRect.top + (topZoneRect.height / 2) - 10,
              left: 0, right: 0,
              child: const Center(
                child: Text("Name & KP", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)]))
              ),
            ),
             Positioned(
              top: bottomZoneRect.top + (bottomZoneRect.height / 2) - 10,
              left: 0, right: 0,
              child: const Center(
                child: Text("Nr. & Künstler", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)]))
              ),
            ),
          ],
        );
      },
    );
  }
}

class MaskPainter extends CustomPainter {
  final Rect cardRect;
  final Rect topZoneRect;
  final Rect bottomZoneRect;

  MaskPainter({required this.cardRect, required this.topZoneRect, required this.bottomZoneRect});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Sehr transparente Maske
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.4); 
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cardRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, backgroundPaint);

    // 2. Dünner Rahmen um die Karte
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(RRect.fromRectAndRadius(cardRect, const Radius.circular(12)), borderPaint);

    // 3. Fast unsichtbare Fokus-Zonen INNERHALB der Karte
    final zonePaint = Paint()
      ..color = Colors.white.withOpacity(0.1) 
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(topZoneRect, const Radius.circular(8)), zonePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(bottomZoneRect, const Radius.circular(8)), zonePaint);

    // Dünner Rahmen um die Zonen
    final zoneBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(RRect.fromRectAndRadius(topZoneRect, const Radius.circular(8)), zoneBorderPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(bottomZoneRect, const Radius.circular(8)), zoneBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}