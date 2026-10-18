import '../../data/database/app_database.dart';

/// Represents the evaluated output of card recognition from OCR text.
class ScanMatchResult {
  /// The highest-scoring matched card from the database, or null if no confident match was found.
  final Card? bestCard;

  /// The confidence score achieved by the best card candidate.
  final int bestScore;

  /// All database card candidates that matched by name or number criteria.
  final List<Card> candidateMatches;

  const ScanMatchResult({
    required this.bestCard,
    required this.bestScore,
    required this.candidateMatches,
  });

  /// Whether a confident card match was identified.
  bool get hasConfidentMatch =>
      bestCard != null && (bestScore > 0 || candidateMatches.length == 1);
}

/// Extracted OCR tokens from camera frames.
class ExtractedCardTokens {
  /// Recognized Hit Points (e.g. 120 from "HP 120" or "120 KP").
  final int? hp;

  /// Extracted card local number without leading zeroes (e.g. "4" from "004/102").
  final String? cardNumber;

  /// Extracted printed total without leading zeroes (e.g. "102" from "004/102").
  final String? printedTotal;

  /// The cleaned lowercase alphanumeric text for fuzzy substring matching.
  final String cleanText;

  /// The raw recognized OCR text with original spacing and casing.
  final String rawText;

  const ExtractedCardTokens({
    required this.hp,
    required this.cardNumber,
    required this.printedTotal,
    required this.cleanText,
    required this.rawText,
  });
}

/// Pure domain service that implements text recognition heuristics and card candidate scoring.
///
/// Decouples computer-vision parsing and database matching algorithms from the UI presentation layer.
class CardScannerMatcher {
  const CardScannerMatcher();

  /// Regex pattern to extract HP or KP values between 30 and 350.
  static final RegExp _hpRegEx = RegExp(
    r'\b(?:HP|KP)\s*(\d{2,3})\b|\b(\d{2,3})\s*(?:HP|KP)\b',
    caseSensitive: false,
  );

  /// Regex pattern to extract card number / set printed total (e.g. "025/198" or "TG01/TG30").
  static final RegExp _slashNumberPattern = RegExp(
    r'\b([A-Za-z]*\d+)\s*/\s*([A-Za-z]*\d+)\b',
  );

  /// Extracts structured tokens (HP, card numbers, cleaned text) from OCR raw text.
  ExtractedCardTokens extractTokens(String rawText) {
    int? recognizedHp;
    for (final match in _hpRegEx.allMatches(rawText)) {
      final parsed = int.tryParse(match.group(1) ?? match.group(2) ?? '');
      if (parsed != null && parsed >= 30 && parsed <= 350 && parsed % 10 == 0) {
        recognizedHp = parsed;
        break;
      }
    }

    String? cardNumber;
    String? maxNumber;
    final numMatch = _slashNumberPattern.firstMatch(rawText);
    if (numMatch != null) {
      cardNumber = numMatch.group(1)!.replaceAll(RegExp(r'^0+'), '').toLowerCase();
      maxNumber = numMatch.group(2)!.replaceAll(RegExp(r'^0+'), '').toLowerCase();
    }

    final cleanText = rawText.toLowerCase().replaceAll(RegExp(r'[^a-z0-9äöüß]'), '');

    return ExtractedCardTokens(
      hp: recognizedHp,
      cardNumber: cardNumber,
      printedTotal: maxNumber,
      cleanText: cleanText,
      rawText: rawText,
    );
  }

  /// Determines whether a card name appears inside the OCR text.
  bool isNameInText(String dbName, String cleanText, String rawFullText) {
    if (dbName.isEmpty) {
      return false;
    }

    final nameClean = dbName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9äöüß]'), '');
    if (nameClean.length < 3) {
      return false;
    }

    // For short 3-letter names (e.g. "Mew"), demand word-boundary matching
    if (nameClean.length <= 3) {
      return RegExp(r'\b' + RegExp.escape(dbName) + r'\b', caseSensitive: false)
          .hasMatch(rawFullText);
    }

    return cleanText.contains(nameClean);
  }

  /// Finds candidate cards from [allCards] matching OCR tokens.
  List<Card> findCandidates({
    required List<Card> allCards,
    required ExtractedCardTokens tokens,
    required Map<String, int> setPrintedTotalMap,
  }) {
    final List<Card> nameMatches = [];

    // 1. Try matching by German or English card name
    for (final card in allCards) {
      final bool matchEn = isNameInText(card.name, tokens.cleanText, tokens.rawText);
      final bool matchDe = card.nameDe != null &&
          isNameInText(card.nameDe!, tokens.cleanText, tokens.rawText);
      if (matchEn || matchDe) {
        nameMatches.add(card);
      }
    }

    // 2. If no name matched, fallback to matching card number + set printed total ratio
    if (nameMatches.isEmpty &&
        tokens.cardNumber != null &&
        tokens.printedTotal != null) {
      final ocrMax = int.tryParse(tokens.printedTotal!);
      if (ocrMax != null) {
        for (final card in allCards) {
          final dbNum = card.number.replaceAll(RegExp(r'^0+'), '').toLowerCase();
          final dbMax = setPrintedTotalMap[card.setId];
          final isNumMatch = dbNum == tokens.cardNumber ||
              (int.tryParse(dbNum) != null &&
                  int.tryParse(tokens.cardNumber!) != null &&
                  int.parse(dbNum) == int.parse(tokens.cardNumber!));

          if (isNumMatch && dbMax == ocrMax) {
            nameMatches.add(card);
          }
        }
      }
    }

    return nameMatches;
  }

  /// Scores a list of candidates against the extracted OCR tokens and finds the best match.
  ScanMatchResult scoreAndEvaluate({
    required List<Card> candidates,
    required ExtractedCardTokens tokens,
    required Map<String, int> setPrintedTotalMap,
  }) {
    if (candidates.isEmpty) {
      return const ScanMatchResult(
        bestCard: null,
        bestScore: -1,
        candidateMatches: [],
      );
    }

    Card? bestCard;
    int bestScore = -1;

    for (final card in candidates) {
      int score = 0;

      // HP match
      if (tokens.hp != null && card.hp == tokens.hp) {
        score += 20;
      }

      // Card local number match
      if (tokens.cardNumber != null && card.number.isNotEmpty) {
        final dbNum = card.number.replaceAll(RegExp(r'^0+'), '').toLowerCase();
        if (dbNum == tokens.cardNumber) {
          score += 50;
        } else if (int.tryParse(dbNum) != null &&
            int.tryParse(tokens.cardNumber!) != null &&
            int.parse(dbNum) == int.parse(tokens.cardNumber!)) {
          score += 50;
        }
      }

      // Set printed total match
      if (tokens.printedTotal != null) {
        final ocrMax = int.tryParse(tokens.printedTotal!);
        final dbMax = setPrintedTotalMap[card.setId];
        if (ocrMax != null && dbMax != null && ocrMax == dbMax) {
          score += 40;
        }
      }

      // Set ID occurrence in raw text (e.g. "sv04", "swsh12")
      final setIdLower = card.setId.toLowerCase();
      if (tokens.rawText.toLowerCase().contains(setIdLower)) {
        score += 30;
      }

      if (score > bestScore) {
        bestScore = score;
        bestCard = card;
      }
    }

    return ScanMatchResult(
      bestCard: bestCard,
      bestScore: bestScore,
      candidateMatches: candidates,
    );
  }

  /// Complete pipeline: extracts tokens, finds candidates, and selects the best matching card.
  ScanMatchResult evaluateRawText({
    required String rawText,
    required List<Card> allCards,
    required Map<String, int> setPrintedTotalMap,
  }) {
    final tokens = extractTokens(rawText);
    final candidates = findCandidates(
      allCards: allCards,
      tokens: tokens,
      setPrintedTotalMap: setPrintedTotalMap,
    );
    return scoreAndEvaluate(
      candidates: candidates,
      tokens: tokens,
      setPrintedTotalMap: setPrintedTotalMap,
    );
  }
}
