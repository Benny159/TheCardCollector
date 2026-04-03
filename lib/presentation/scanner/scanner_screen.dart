import 'dart:convert';
import 'dart:io'; 
import 'package:camera/camera.dart';
import 'package:flutter/material.dart' hide Card; 
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:drift/drift.dart' hide Column; 
import 'package:cached_network_image/cached_network_image.dart'; // --- NEU: Für das Set-Logo

// Deine Datenbank Provider
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';

// UI Import
import 'scanner_overlay_mask.dart';
import '../inventory/inventory_bottom_sheet.dart'; 
import '../../domain/models/api_card.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer = TextRecognizer();
  
  bool _isProcessingImage = false; 
  bool _cameraInitialized = false;
  List<CameraDescription>? _cameras;
  
  String _scanStatus = "Lade Datenbank...";
  Card? _scannedCard; 

  // --- NEU: Metadaten für die schicke Ergebnis-Anzeige ---
  CardSet? _scannedSet;
  int _scannedOwnedQuantity = 0;
  double _scannedCardPrice = 0.0;
  double _scannedSetProgress = 0.0;
  int _scannedSetOwned = 0;
  int _scannedSetTotal = 0;

  // Der Datenbank-Cache für den Heuhaufen-Algorithmus
  List<Card>? _allCardsCache;
  final Map<String, int> _setPrintedTotalMap = {}; 

  @override
  void initState() {
    super.initState();
    _loadDatabaseIntoMemory();
    _initializeCamera();
  }

  Future<void> _loadDatabaseIntoMemory() async {
    final db = ref.read(databaseProvider);
    final cards = await db.select(db.cards).get();
    
    cards.sort((a, b) => b.name.length.compareTo(a.name.length));
    
    final sets = await db.select(db.cardSets).get();
    for (var s in sets) {
       if (s.printedTotal != null) {
          _setPrintedTotalMap[s.id] = s.printedTotal!;
       }
    }
    
    setState(() {
       _allCardsCache = cards;
       if (_cameraInitialized) _scanStatus = "Halte die Karte in den Rahmen...";
    });
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) setState(() => _scanStatus = "❌ Keine Kamera gefunden.");
        return;
      }

      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      
      if (!mounted) return;
      
      setState(() {
        _cameraInitialized = true;
        if (_allCardsCache != null) _scanStatus = "Halte die Karte in den Rahmen...";
      });

      _cameraController!.startImageStream(_processCameraFrame);

    } catch (e) {
      debugPrint("❌ Kamera Fehler: $e");
      if (mounted) setState(() => _scanStatus = "❌ Kamera Fehler.");
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final int sensorOrientation = _cameraController!.value.description.sensorOrientation;
    final InputImageRotation? imageRotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (imageRotation == null) return null;

    final InputImageFormat? inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
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
                nv21Bytes.setRange(pos, pos + width, yBuffer.sublist(row * yRowStride, row * yRowStride + width));
                pos += width;
            }
        }

        final Uint8List uBuffer = image.planes[1].bytes;
        final Uint8List vBuffer = image.planes[2].bytes;
        int nv21Index = ySize;

        for (int row = 0; row < height ~/ 2; row++) {
            for (int col = 0; col < width ~/ 2; col++) {
                final int uvIndex = row * uvRowStride + col * uvPixelStride;
                nv21Bytes[nv21Index++] = vBuffer[uvIndex];
                nv21Bytes[nv21Index++] = uBuffer[uvIndex];
            }
        }

        final inputImageData = InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: imageRotation,
          format: InputImageFormat.nv21,
          bytesPerRow: width,
        );

        return InputImage.fromBytes(bytes: nv21Bytes, metadata: inputImageData);
    } else {
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();

        final inputImageData = InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes.first.bytesPerRow,
        );

        return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
    }
  }

  @override
  void dispose() {
    if (_cameraController != null) {
      if (_cameraController!.value.isStreamingImages) {
        _cameraController!.stopImageStream();
      }
      _cameraController!.dispose();
    }
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _resumeScanning() async {
    setState(() {
      _scannedCard = null;
      _scannedSet = null;
      _scanStatus = "Halte die Karte in den Rahmen...";
    });
    if (_cameraController != null && !_cameraController!.value.isStreamingImages) {
      await _cameraController!.startImageStream(_processCameraFrame);
    }
  }

  Future<void> _processCameraFrame(CameraImage image) async {
    if (_isProcessingImage || _allCardsCache == null) return; 
    _isProcessingImage = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
         _isProcessingImage = false; return;
      }
      
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      if (recognizedText.text.isEmpty) {
        _isProcessingImage = false; return;
      }

      String rawText = recognizedText.text;
      String rawClean = rawText.toLowerCase().replaceAll(RegExp(r'[^a-z0-9äöüß]'), '');

      // 1. WERTE EXTRAHIEREN
      int? recognizedHP;
      String? recognizedCardNum;
      String? recognizedMaxNum;
      
      RegExp hpRegEx = RegExp(r'\b(?:HP|KP)\s*(\d{2,3})\b|\b(\d{2,3})\s*(?:HP|KP)\b', caseSensitive: false);
      for (final match in hpRegEx.allMatches(rawText)) {
        int? hp = int.tryParse(match.group(1) ?? match.group(2) ?? '');
        if (hp != null && hp >= 30 && hp <= 350 && hp % 10 == 0) {
          recognizedHP = hp;
          break; 
        }
      }

      RegExp slashPattern = RegExp(r'\b([A-Za-z]*\d+)\s*/\s*([A-Za-z]*\d+)\b');
      Match? numMatch = slashPattern.firstMatch(rawText);
      if (numMatch != null) {
        recognizedCardNum = numMatch.group(1)!.replaceAll(RegExp(r'^0+'), '').toLowerCase();
        recognizedMaxNum = numMatch.group(2)!.replaceAll(RegExp(r'^0+'), '').toLowerCase();
      }

      // 2. HEUHAUFEN
      List<Card> nameMatches = [];
      for (final card in _allCardsCache!) {
          bool matchEn = _isNameInText(card.name, rawClean, rawText);
          bool matchDe = card.nameDe != null && _isNameInText(card.nameDe!, rawClean, rawText);
          if (matchEn || matchDe) nameMatches.add(card);
      }

      if (nameMatches.isEmpty && recognizedCardNum != null && recognizedMaxNum != null) {
          int? ocrMax = int.tryParse(recognizedMaxNum);
          if (ocrMax != null) {
             for (final card in _allCardsCache!) {
                 String dbNum = card.number.replaceAll(RegExp(r'^0+'), '').toLowerCase();
                 int? dbMax = _setPrintedTotalMap[card.setId];
                 bool isNumMatch = dbNum == recognizedCardNum || 
                                  (int.tryParse(dbNum) != null && int.tryParse(recognizedCardNum) != null && int.parse(dbNum) == int.parse(recognizedCardNum));
                 if (isNumMatch && dbMax == ocrMax) nameMatches.add(card);
             }
          }
      }

      if (nameMatches.isEmpty) {
          _isProcessingImage = false;
          return; 
      }

      // 3. SCORING
      Card? bestCard;
      int bestScore = -1;

      for (final card in nameMatches) {
          int score = 0;
          if (recognizedHP != null && card.hp == recognizedHP) score += 20;
          if (recognizedCardNum != null && card.number.isNotEmpty) {
              String dbNum = card.number.replaceAll(RegExp(r'^0+'), '').toLowerCase();
              if (dbNum == recognizedCardNum) score += 50; 
              else if (int.tryParse(dbNum) != null && int.tryParse(recognizedCardNum) != null && int.parse(dbNum) == int.parse(recognizedCardNum)) score += 50; 
          }
          if (recognizedMaxNum != null) {
              int? ocrMax = int.tryParse(recognizedMaxNum);
              int? dbMax = _setPrintedTotalMap[card.setId];
              if (ocrMax != null && dbMax != null && ocrMax == dbMax) score += 40;
          }
          String setIdLower = card.setId.toLowerCase(); 
          if (rawText.toLowerCase().contains(setIdLower)) score += 30; 

          if (score > bestScore) {
              bestScore = score;
              bestCard = card;
          }
      }

      setState(() => _scanStatus = "Analysiere: ${bestCard?.name}...");

      // 4. TREFFER BESTÄTIGEN & DATEN LADEN
      if (bestCard != null && (bestScore > 0 || nameMatches.length == 1)) {
          HapticFeedback.vibrate(); 
          await _cameraController!.stopImageStream(); 
          
          // --- NEU: WIR LADEN ALLE ZUSATZDATEN FÜR DIE ANZEIGE ---
          final db = ref.read(databaseProvider);
          
          // 1. Set Info
          final setObj = await (db.select(db.cardSets)..where((t) => t.id.equals(bestCard!.setId))).getSingleOrNull();
          
          // 2. Set Fortschritt
          final setCardsQuery = await (db.select(db.cards)..where((t) => t.setId.equals(bestCard!.setId))).get();
          final setCardIds = setCardsQuery.map((c) => c.id).toList();
          int uniqueOwnedInSet = 0;
          if (setCardIds.isNotEmpty) {
             final ownedInSet = await (db.select(db.userCards)..where((t) => t.cardId.isIn(setCardIds))).get();
             uniqueOwnedInSet = ownedInSet.map((u) => u.cardId).toSet().length;
          }
          
          // 3. Eigener Besitz
          final myCards = await (db.select(db.userCards)..where((t) => t.cardId.equals(bestCard!.id))).get();
          final int myQuantity = myCards.fold(0, (sum, c) => sum + c.quantity);

          // 4. Preis
          final cmPrice = await (db.select(db.cardMarketPrices)..where((t) => t.cardId.equals(bestCard!.id))..orderBy([(t) => OrderingTerm(expression: t.fetchedAt, mode: OrderingMode.desc)])..limit(1)).getSingleOrNull();
          final tcgPrice = await (db.select(db.tcgPlayerPrices)..where((t) => t.cardId.equals(bestCard!.id))..orderBy([(t) => OrderingTerm(expression: t.fetchedAt, mode: OrderingMode.desc)])..limit(1)).getSingleOrNull();
          
          double displayPrice = 0.0;
          bool isHolo = bestCard!.hasHolo && !bestCard!.hasNormal; 
          
          if (bestCard!.preferredPriceSource == 'tcgplayer') {
              displayPrice = isHolo ? (tcgPrice?.holoMarket ?? 0.0) : (tcgPrice?.normalMarket ?? 0.0);
              if (displayPrice == 0.0) displayPrice = tcgPrice?.normalMarket ?? tcgPrice?.holoMarket ?? cmPrice?.trend ?? 0.0;
          } else {
              displayPrice = isHolo ? (cmPrice?.trendHolo ?? 0.0) : (cmPrice?.trend ?? 0.0);
              if (displayPrice == 0.0) displayPrice = cmPrice?.trend ?? cmPrice?.trendHolo ?? tcgPrice?.normalMarket ?? 0.0;
          }

          if (!mounted) return;
          setState(() {
            _scanStatus = "✅ Gefunden!";
            _scannedCard = bestCard; 
            _scannedSet = setObj;
            _scannedOwnedQuantity = myQuantity;
            _scannedCardPrice = displayPrice;
            _scannedSetProgress = setCardsQuery.isNotEmpty ? uniqueOwnedInSet / setCardsQuery.length : 0.0;
            _scannedSetOwned = uniqueOwnedInSet;
            _scannedSetTotal = setCardsQuery.length;
          });
      }

    } catch (e) {
      debugPrint("OCR Fehler: $e");
    } finally {
      _isProcessingImage = false;
    }
  }

  bool _isNameInText(String dbName, String rawClean, String rawFullText) {
      if (dbName.isEmpty) return false;
      String nameClean = dbName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9äöüß]'), '');
      if (nameClean.length < 3) return false;

      if (nameClean.length <= 3) {
          return RegExp(r'\b' + RegExp.escape(dbName) + r'\b', caseSensitive: false).hasMatch(rawFullText);
      } else {
          return rawClean.contains(nameClean);
      }
  }

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
      hasNormal: card.hasNormal ?? true,
      hasReverse: card.hasReverse ?? false,
      hasHolo: card.hasHolo ?? false,
      hasFirstEdition: card.hasFirstEdition ?? false,
      hasWPromo: card.hasWPromo ?? false,
      isOwned: false, 
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InventoryBottomSheet(card: apiCard),
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
          Expanded(
            flex: 65,
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
                            height: MediaQuery.of(context).size.width * _cameraController!.value.aspectRatio,
                            child: CameraPreview(_cameraController!),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                   Center(child: Text(_scanStatus, style: const TextStyle(color: Colors.white))),
                
                if (_cameraInitialized && _cameraController != null)
                   const Positioned.fill(child: ScannerOverlayMask()),

                Positioned(
                  top: 50, left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              ],
            ),
          ),

          Expanded(
            flex: 35,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -2))
                ]
              ),
              child: _scannedCard == null 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_allCardsCache == null) const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(_scanStatus, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        ],
                      ),
                    )
                  : _buildResultArea(context, theme),
            ),
          )
        ],
      ),
    );
  }

  // --- NEU: DIE SCHICKE ERGEBNIS-ANZEIGE ---
  Widget _buildResultArea(BuildContext context, ThemeData theme) {
    final card = _scannedCard!;
    final bool isNewCard = _scannedOwnedQuantity == 0;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Das Kartenbild
                AspectRatio(
                  aspectRatio: 0.716, 
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: card.imageUrlDe ?? card.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_,__) => Container(color: Colors.grey[200]),
                        errorWidget: (c, e, s) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // 2. Die Details daneben
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Nummer
                      Text(card.nameDe ?? card.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text("${card.number} / ${_scannedSet?.printedTotal ?? '?'}", style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
                      
                      const SizedBox(height: 12),
                      
                      // Badges für Besitz & Preis
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Besitz-Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isNewCard ? Colors.amber[600] : Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isNewCard ? Colors.amber[800]! : Colors.blue[300]!)
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isNewCard ? Icons.star : Icons.inventory_2, size: 14, color: isNewCard ? Colors.white : Colors.blue[900]),
                                const SizedBox(width: 4),
                                Text(
                                  isNewCard ? "NEUE KARTE" : "In Sammlung: $_scannedOwnedQuantity x",
                                  style: TextStyle(
                                    color: isNewCard ? Colors.white : Colors.blue[900], 
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 11
                                  )
                                ),
                              ],
                            ),
                          ),
                          
                          // Preis-Badge
                          if (_scannedCardPrice > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[400]!)
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.euro, size: 12, color: Colors.green[800]),
                                  const SizedBox(width: 2),
                                  Text(
                                    _scannedCardPrice.toStringAsFixed(2),
                                    style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold, fontSize: 11)
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // 3. Die hübsche Set-Box ganz unten
                      if (_scannedSet != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!)
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (_scannedSet!.logoUrl != null || _scannedSet!.logoUrlDe != null)
                                    SizedBox(
                                      height: 20, width: 40,
                                      child: CachedNetworkImage(
                                        imageUrl: _scannedSet!.logoUrlDe ?? _scannedSet!.logoUrl!,
                                        fit: BoxFit.contain,
                                        errorWidget: (_,__,___) => const SizedBox(),
                                      )
                                    ),
                                  if (_scannedSet!.logoUrl != null || _scannedSet!.logoUrlDe != null)
                                    const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _scannedSet!.nameDe ?? _scannedSet!.name, 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: _scannedSetProgress,
                                        backgroundColor: Colors.grey[300],
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text("$_scannedSetOwned / $_scannedSetTotal", style: TextStyle(fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.bold)),
                                ],
                              )
                            ],
                          ),
                        )
                    ],
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Die unteren Aktions-Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resumeScanning,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Falsch"),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2, 
                child: FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    _openInventorySheet(context, card);
                  },
                  icon: const Icon(Icons.add_task),
                  label: const Text("Bestätigen"),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}