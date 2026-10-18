import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:drift/drift.dart' hide Column;

import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';
import '../../domain/logic/card_scanner_matcher.dart';
import '../../domain/logic/price_calculator.dart';
import '../../domain/models/api_card.dart';
import '../inventory/inventory_bottom_sheet.dart';
import '../search/card_search_screen.dart';
import 'scanner_overlay_mask.dart';
import 'scanner_result_card.dart';

/// Presentation screen hosting real-time camera scanning, OCR text extraction,
/// and live Pokémon card recognition.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer = TextRecognizer();
  final CardScannerMatcher _matcher = const CardScannerMatcher();
  final PriceCalculator _priceCalculator = const PriceCalculator();

  bool _isProcessingImage = false;
  bool _cameraInitialized = false;
  List<CameraDescription>? _cameras;

  String _scanStatus = "Lade Datenbank...";
  Card? _scannedCard;

  // Metadata for the result card panel
  CardSet? _scannedSet;
  int _scannedOwnedQuantity = 0;
  double _scannedCardPrice = 0.0;
  double _scannedSetProgress = 0.0;
  int _scannedSetOwned = 0;
  int _scannedSetTotal = 0;

  List<Card> _alternativeCards = [];

  // In-memory cache for high-speed candidate lookup
  List<Card>? _allCardsCache;
  final Map<String, int> _setPrintedTotalMap = {};

  @override
  void initState() {
    super.initState();
    _loadDatabaseIntoMemory();
    _initializeCamera();
  }

  /// Pre-caches cards and set sizes in memory to allow 60 FPS OCR matching without SQLite disk latency.
  Future<void> _loadDatabaseIntoMemory() async {
    final db = ref.read(databaseProvider);
    final cards = await db.select(db.cards).get();

    // Sort descending by name length to favor longer, specific matches first
    cards.sort((a, b) => b.name.length.compareTo(a.name.length));

    final sets = await db.select(db.cardSets).get();
    for (final s in sets) {
      if (s.printedTotal != null) {
        _setPrintedTotalMap[s.id] = s.printedTotal!;
      }
    }

    if (!mounted) return;
    setState(() {
      _allCardsCache = cards;
      if (_cameraInitialized) {
        _scanStatus = "Halte die Karte in den Rahmen...";
      }
    });
  }

  /// Initializes the device camera for OCR image stream processing.
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          setState(() => _scanStatus = "❌ Keine Kamera gefunden.");
        }
        return;
      }

      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _cameraInitialized = true;
        if (_allCardsCache != null) {
          _scanStatus = "Halte die Karte in den Rahmen...";
        }
      });

      _cameraController!.startImageStream(_processCameraFrame);
    } catch (e) {
      debugPrint("❌ Kamera Fehler: $e");
      if (mounted) {
        setState(() => _scanStatus = "❌ Kamera Fehler.");
      }
    }
  }

  /// Converts a [CameraImage] frame into a ML Kit compatible [InputImage].
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final int sensorOrientation =
        _cameraController!.value.description.sensorOrientation;
    final InputImageRotation? imageRotation =
        InputImageRotationValue.fromRawValue(sensorOrientation);
    if (imageRotation == null) return null;

    final InputImageFormat? inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return null;

    if (Platform.isAndroid) {
      if (image.format.group != ImageFormatGroup.yuv420) return null;

      final int width = image.width;
      final int height = image.height;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

      final int ySize = width * height;
      final int uvSize = width * height ~/ 4;
      final int nv21Size = ySize + uvSize * 2;

      final Uint8List nv21Bytes = Uint8List(nv21Size);

      final Uint8List yBuffer = image.planes[0].bytes;
      final int yRowStride = image.planes[0].bytesPerRow;

      if (yRowStride == width) {
        nv21Bytes.setRange(0, ySize, yBuffer);
      } else {
        int pos = 0;
        for (int row = 0; row < height; row++) {
          nv21Bytes.setRange(
            pos,
            pos + width,
            yBuffer.sublist(row * yRowStride, row * yRowStride + width),
          );
          pos += width;
        }
      }

      final Uint8List uBuffer = image.planes[1].bytes;
      final Uint8List vBuffer = image.planes[2].bytes;

      int uvOffset = ySize;
      for (int row = 0; row < height ~/ 2; row++) {
        for (int col = 0; col < width ~/ 2; col++) {
          final int uIndex = row * uvRowStride + col * uvPixelStride;
          final int vIndex = row * image.planes[2].bytesPerRow +
              col * (image.planes[2].bytesPerPixel ?? 1);

          nv21Bytes[uvOffset++] = vBuffer[vIndex];
          nv21Bytes[uvOffset++] = uBuffer[uIndex];
        }
      }

      return InputImage.fromBytes(
        bytes: nv21Bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: imageRotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width,
        ),
      );
    } else {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  /// Resets scan state and resumes camera preview streaming.
  Future<void> _resumeScanning() async {
    setState(() {
      _scannedCard = null;
      _scannedSet = null;
      _scannedCardPrice = 0.0;
      _alternativeCards.clear();
      _scanStatus = "Halte die Karte in den Rahmen...";
    });
    if (_cameraController != null &&
        !_cameraController!.value.isStreamingImages) {
      await _cameraController!.startImageStream(_processCameraFrame);
    }
  }

  /// Processes camera frame through ML Kit Text Recognizer and delegates to domain matcher.
  Future<void> _processCameraFrame(CameraImage image) async {
    if (_isProcessingImage || _allCardsCache == null) return;
    _isProcessingImage = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isProcessingImage = false;
        return;
      }

      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);
      if (recognizedText.text.isEmpty) {
        _isProcessingImage = false;
        return;
      }

      // Delegate pure matching logic to Domain service
      final matchResult = _matcher.evaluateRawText(
        rawText: recognizedText.text,
        allCards: _allCardsCache!,
        setPrintedTotalMap: _setPrintedTotalMap,
      );

      if (!matchResult.hasConfidentMatch) {
        _isProcessingImage = false;
        return;
      }

      final bestCard = matchResult.bestCard!;
      setState(() => _scanStatus = "Analysiere: ${bestCard.name}...");

      HapticFeedback.vibrate();
      await _cameraController!.stopImageStream();
      await _loadCardDataAndShow(bestCard);
    } catch (e) {
      debugPrint("OCR Fehler: $e");
    } finally {
      _isProcessingImage = false;
    }
  }

  /// Fetches card details, set progression, and market pricing for the recognized card.
  Future<void> _loadCardDataAndShow(Card bestCard) async {
    final db = ref.read(databaseProvider);

    // 1. Set Info
    final setObj = await (db.select(db.cardSets)
          ..where((t) => t.id.equals(bestCard.setId)))
        .getSingleOrNull();

    // 2. Set Progress
    final setCardsQuery = await (db.select(db.cards)
          ..where((t) => t.setId.equals(bestCard.setId)))
        .get();
    final setCardIds = setCardsQuery.map((c) => c.id).toList();
    int uniqueOwnedInSet = 0;
    if (setCardIds.isNotEmpty) {
      final ownedInSet = await (db.select(db.userCards)
            ..where((t) => t.cardId.isIn(setCardIds)))
          .get();
      uniqueOwnedInSet = ownedInSet.map((u) => u.cardId).toSet().length;
    }

    // 3. User Ownership
    final myCards = await (db.select(db.userCards)
          ..where((t) => t.cardId.equals(bestCard.id)))
        .get();
    final int myQuantity = myCards.fold(0, (sum, c) => sum + c.quantity);

    // 4. Latest Pricing via Domain PriceCalculator
    final cmPrice = await (db.select(db.cardMarketPrices)
          ..where((t) => t.cardId.equals(bestCard.id))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.fetchedAt, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();

    final tcgPrice = await (db.select(db.tcgPlayerPrices)
          ..where((t) => t.cardId.equals(bestCard.id))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.fetchedAt, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();

    final displayPrice = _priceCalculator.calculateCardPrice(
      pref: bestCard.preferredPriceSource,
      variant: bestCard.hasHolo && !bestCard.hasNormal ? 'Holo' : 'Normal',
      hasFirstEdition: bestCard.hasFirstEdition,
      hasNormal: bestCard.hasNormal,
      hasHolo: bestCard.hasHolo,
      cmPrice: cmPrice,
      tcgPrice: tcgPrice,
      customPrice: null,
    );

    // 5. Alternative variants within the same set
    final altCards = await (db.select(db.cards)
          ..where((t) =>
              t.setId.equals(bestCard.setId) &
              t.name.equals(bestCard.name) &
              t.id.isNotValue(bestCard.id))
          ..limit(10))
        .get();

    if (!mounted) return;
    setState(() {
      _scanStatus = "✅ Gefunden!";
      _scannedCard = bestCard;
      _scannedSet = setObj;
      _scannedOwnedQuantity = myQuantity;
      _scannedCardPrice = displayPrice;
      _scannedSetProgress = setCardsQuery.isNotEmpty
          ? uniqueOwnedInSet / setCardsQuery.length
          : 0.0;
      _scannedSetOwned = uniqueOwnedInSet;
      _scannedSetTotal = setCardsQuery.length;
      _alternativeCards = altCards;
    });
  }

  /// Opens the manual search picker dialog when OCR identifies a wrong card variant.
  Future<void> _handleManualSearch(Card card) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardSearchScreen(
          initialQuery: card.name,
          pickerMode: true,
        ),
      ),
    );

    if (result != null && result is ApiCard) {
      final db = ref.read(databaseProvider);
      await db.into(db.cards).insertOnConflictUpdate(
            CardsCompanion(
              id: Value(result.id),
              setId: Value(result.setId),
              name: Value(result.name),
              nameDe: Value(result.nameDe),
              number: Value(result.number),
              imageUrl: Value(result.smallImageUrl),
              imageUrlDe:
                  Value(result.imageUrlDe ?? result.smallImageUrl),
              rarity: Value(result.rarity),
            ),
          );
      final dbCard = await (db.select(db.cards)
            ..where((t) => t.id.equals(result.id)))
          .getSingle();
      await _loadCardDataAndShow(dbCard);
    }
  }

  /// Opens the inventory addition bottom sheet for the identified card.
  void _openInventorySheet(BuildContext context, Card card) {
    final apiCard = ApiCard(
      id: card.id,
      name: card.name,
      nameDe: card.nameDe,
      supertype: 'Pokémon',
      subtypes: [],
      types: card.cardType != null ? [card.cardType!] : [],
      setId: card.setId,
      number: card.number,
      cardType: card.cardType,
      setPrintedTotal: '???',
      artist: card.artist ?? 'Unbekannt',
      rarity: card.rarity ?? 'Unbekannt',
      smallImageUrl: card.imageUrl,
      largeImageUrl: card.imageUrl,
      imageUrlDe: card.imageUrlDe,
      hasNormal: card.hasNormal,
      hasReverse: card.hasReverse,
      hasHolo: card.hasHolo,
      hasFirstEdition: card.hasFirstEdition,
      hasWPromo: card.hasWPromo,
      isOwned: false,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InventoryBottomSheet(card: apiCard),
    ).then((_) {
      _resumeScanning();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Camera Preview Area
          Expanded(
            flex: 60,
            child: Stack(
              children: [
                if (_cameraInitialized && _cameraController != null)
                  Positioned.fill(
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.width *
                                _cameraController!.value.aspectRatio,
                            child: CameraPreview(_cameraController!),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Center(
                    child: Text(
                      _scanStatus,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                if (_cameraInitialized && _cameraController != null)
                  const Positioned.fill(child: ScannerOverlayMask()),

                // Animated Price Overlay Banner
                if (_scannedCard != null && _scannedCardPrice > 0)
                  Positioned.fill(
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        builder: (context, val, child) {
                          return Transform.scale(
                            scale: val,
                            child: Opacity(
                              opacity: val.clamp(0.0, 1.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[600]!
                                      .withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.greenAccent
                                          .withValues(alpha: 0.6),
                                      blurRadius: 25 * val,
                                      spreadRadius: 5 * val,
                                    )
                                  ],
                                ),
                                child: Text(
                                  "${_scannedCardPrice.toStringAsFixed(2)} €",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Back Button
                Positioned(
                  top: 50,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              ],
            ),
          ),

          // Result Sheet Area
          Expanded(
            flex: 40,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  )
                ],
              ),
              child: _scannedCard == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_allCardsCache == null)
                            const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            _scanStatus,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ScannerResultCard(
                      card: _scannedCard!,
                      scannedSet: _scannedSet,
                      ownedQuantity: _scannedOwnedQuantity,
                      cardPrice: _scannedCardPrice,
                      setProgress: _scannedSetProgress,
                      setOwned: _scannedSetOwned,
                      setTotal: _scannedSetTotal,
                      alternativeCards: _alternativeCards,
                      onSelectCard: (alt) => _loadCardDataAndShow(alt),
                      onRescan: _resumeScanning,
                      onConfirm: () {
                        HapticFeedback.heavyImpact();
                        _openInventorySheet(context, _scannedCard!);
                      },
                      onManualSearch: () =>
                          _handleManualSearch(_scannedCard!),
                    ),
            ),
          )
        ],
      ),
    );
  }
}
