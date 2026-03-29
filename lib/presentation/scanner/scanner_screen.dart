import 'dart:convert';
import 'dart:io'; 
import 'package:camera/camera.dart';
import 'package:flutter/material.dart' hide Card; 
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:drift/drift.dart' hide Column; 

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

  // --- NEU: Der Datenbank-Cache für den Heuhaufen-Algorithmus ---
  List<Card>? _allCardsCache;

  @override
  void initState() {
    super.initState();
    _loadDatabaseIntoMemory();
    _initializeCamera();
  }

  // Lädt einmalig alle Karten in den RAM für blitzschnelle Checks
  Future<void> _loadDatabaseIntoMemory() async {
    final db = ref.read(databaseProvider);
    final cards = await db.select(db.cards).get();
    
    // Sortieren nach Namenslänge (längste zuerst), 
    // damit z.B. "Bisasam" gefunden wird, bevor "Bis" triggert.
    cards.sort((a, b) => b.name.length.compareTo(a.name.length));
    
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
      print("❌ Kamera Fehler: $e");
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

    // Auf Android müssen wir die YUV_420_888 Planes manuell in ein flaches NV21 ByteArray umbauen
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

        // Plane 0: Y (Luminance)
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

        // Plane 1 (U) & Plane 2 (V) zu NV21 (V, U interlaced)
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
          format: InputImageFormat.nv21, // Wir sagen ML Kit explizit, dass es jetzt NV21 ist!
          bytesPerRow: width, // Bei NV21 ist bytesPerRow immer gleich width
        );

        return InputImage.fromBytes(bytes: nv21Bytes, metadata: inputImageData);
    } 
    // iOS Handling (BGRA8888 funktioniert direkt)
    else {
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
      
      // Bereinigter Heuhaufen: Alles außer Buchstaben und Zahlen fliegt raus, alles klein.
      // So wird "AS Meditalis" zu "asmeditalis"
      String rawClean = rawText.toLowerCase().replaceAll(RegExp(r'[^a-z0-9äöüß]'), '');

      // 1. HP & Nummer extrahieren (falls vorhanden)
      int? recognizedHP;
      String? recognizedNumber;
      
      RegExp hpRegEx = RegExp(r'\b(?:HP|KP)\s*(\d+)\b|\b(\d+)\s*(?:HP|KP)\b', caseSensitive: false);
      Match? hpMatch = hpRegEx.firstMatch(rawText);
      if (hpMatch != null) recognizedHP = int.tryParse(hpMatch.group(1) ?? hpMatch.group(2) ?? '');

      String noSpaceText = rawText.replaceAll(' ', '');
      RegExp slashPattern = RegExp(r'([A-Za-z]*\d+)/[A-Za-z]*\d+');
      Match? numMatch = slashPattern.firstMatch(noSpaceText);
      if (numMatch != null) recognizedNumber = numMatch.group(1)!.replaceAll(RegExp(r'^0+'), '').toLowerCase();

      // ==============================================================
      // 2. DER HEUHAUFEN-ALGORITHMUS (Name Search)
      // ==============================================================
      List<Card> nameMatches = [];
      
      for (final card in _allCardsCache!) {
          bool matchEn = _isNameInText(card.name, rawClean, rawText);
          bool matchDe = card.nameDe != null && _isNameInText(card.nameDe!, rawClean, rawText);

          if (matchEn || matchDe) {
              nameMatches.add(card);
          }
      }

      if (nameMatches.isEmpty) {
          _isProcessingImage = false;
          return; // Nichts gefunden -> Nächster Frame
      }

      // ==============================================================
      // 3. DAS SCORING-SYSTEM (Welcher Name ist der Richtige?)
      // ==============================================================
      Card? bestCard;
      int bestScore = -1;

      for (final card in nameMatches) {
          int score = 0;
          
          // Bonus-Punkte, wenn HP übereinstimmen
          if (recognizedHP != null && card.hp == recognizedHP) score += 10;
          
          // Bonus-Punkte, wenn die Kartennummer im Text gefunden wurde
          if (recognizedNumber != null && card.number.isNotEmpty) {
              String dbNum = card.number.replaceAll(RegExp(r'^0+'), '').toLowerCase();
              if (dbNum == recognizedNumber || dbNum.contains(recognizedNumber) || recognizedNumber.contains(dbNum)) {
                  score += 15; // Nummer ist ein sehr starker Indikator
              }
          }

          if (score > bestScore) {
              bestScore = score;
              bestCard = card;
          }
      }

      // Zeige dem Nutzer, was wir gefunden haben, auch wenn der Score niedrig ist
      setState(() => _scanStatus = "Analysiere: ${bestCard?.name}...");

      // ==============================================================
      // 4. TREFFER BESTÄTIGEN
      // ==============================================================
      // Wir akzeptieren die Karte nur, wenn entweder HP/Nummer den Score erhöht haben,
      // ODER wenn es die absolut einzige Karte mit diesem Namen in der ganzen Datenbank ist.
      if (bestCard != null && (bestScore > 0 || nameMatches.length == 1)) {
          HapticFeedback.vibrate(); 
          await _cameraController!.stopImageStream(); // Bild einfrieren
          
          if (!mounted) return;
          setState(() {
            _scanStatus = "✅ Gefunden!";
            _scannedCard = bestCard; 
          });
      }

    } catch (e) {
      print("OCR Fehler: $e");
    } finally {
      _isProcessingImage = false;
    }
  }

  // Prüft, ob der Datenbank-Name im verschmolzenen OCR-Heuhaufen steckt
  bool _isNameInText(String dbName, String rawClean, String rawFullText) {
      if (dbName.isEmpty) return false;
      
      String nameClean = dbName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9äöüß]'), '');
      
      // Ignoriere zu generische Kurz-Strings (z.B. "V", "EX"), die würden sonst überall matchen
      if (nameClean.length < 3) return false;

      if (nameClean.length <= 3) {
          // Bei kurzen Namen wie "Mew" verlangen wir ein echtes, alleinstehendes Wort im Original-Text
          return RegExp(r'\b' + RegExp.escape(dbName) + r'\b', caseSensitive: false).hasMatch(rawFullText);
      } else {
          // Bei langen Namen (Meditalis) prüfen wir den verschmolzenen Text. 
          // So ist "ASMeditalis" ein legaler Treffer für "meditalis"!
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

  Widget _buildResultArea(BuildContext context, ThemeData theme) {
    final card = _scannedCard!;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Erkannte Karte:", style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey)),
          const SizedBox(height: 8),
          
          Expanded(
            child: Row(
              children: [
                AspectRatio(
                  aspectRatio: 0.73, 
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        card.imageUrlDe ?? card.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 50),
                      ),
                  ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(card.nameDe ?? card.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text("Set ID: ${card.setId.toUpperCase()}", style: const TextStyle(fontSize: 14)),
                      Text("Nummer: ${card.number}", style: const TextStyle(fontSize: 14)),
                      if (card.hp != null) Text("HP: ${card.hp}", style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
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
                  label: const Text("Bestätigen & Hinzufügen"),
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