import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tcg_collector/data/database/app_database.dart' as db;
import 'package:tcg_collector/domain/models/api_card.dart';
import 'package:tcg_collector/presentation/widgets/card_image_widget.dart';

void main() {
  group('CardFallbackPreview Tests', () {
    testWidgets('renders card name and formatted number', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: CardFallbackPreview(
                cardName: 'Glurak',
                cardNumber: '004/102',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Glurak'), findsOneWidget);
      expect(find.text('#004/102'), findsOneWidget);
      expect(find.byIcon(Icons.style), findsOneWidget);
    });

    testWidgets('adapts smoothly to tiny dimensions without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 50,
              height: 70,
              child: CardFallbackPreview(
                cardName: 'Pikachu',
                cardNumber: '25',
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Pikachu'), findsOneWidget);
      expect(find.text('#25'), findsOneWidget);
    });
  });

  group('CardImageWidget Fallback Tests', () {
    testWidgets('renders CardFallbackPreview immediately when no image exists in DB (ApiCard)', (tester) async {
      final card = ApiCard(
        id: 'test-1',
        name: 'Charizard',
        nameDe: 'Glurak',
        supertype: 'Pokémon',
        subtypes: ['Stage 2'],
        types: ['Fire'],
        setId: 'base1',
        number: '4',
        setPrintedTotal: '102',
        artist: 'Mitsuhiro Arita',
        rarity: 'Rare Holo',
        smallImageUrl: '',
        largeImageUrl: null,
        imageUrlDe: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150,
              height: 210,
              child: CardImageWidget.fromApiCard(card: card),
            ),
          ),
        ),
      );

      // Since both German and English URLs are empty, it immediately displays fallback preview
      expect(find.byType(CardFallbackPreview), findsOneWidget);
      expect(find.text('Glurak'), findsOneWidget);
      expect(find.text('#4'), findsOneWidget);
    });

    testWidgets('renders CardFallbackPreview immediately when no image exists in DB (db.Card)', (tester) async {
      const card = db.Card(
        id: 'test-2',
        setId: 'base1',
        name: 'Blastoise',
        nameDe: 'Turtok',
        number: '2',
        imageUrl: '',
        imageUrlDe: null,
        hasFirstEdition: false,
        hasNormal: true,
        hasHolo: true,
        hasReverse: false,
        hasWPromo: false,
        hasManualVariants: false,
        hasManualImages: false,
        hasManualTranslations: false,
        hasManualStats: false,
        preferredPriceSource: 'cardmarket',
        sortNumber: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150,
              height: 210,
              child: CardImageWidget.fromDbCard(card: card),
            ),
          ),
        ),
      );

      expect(find.byType(CardFallbackPreview), findsOneWidget);
      expect(find.text('Turtok'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
    });
  });
}
