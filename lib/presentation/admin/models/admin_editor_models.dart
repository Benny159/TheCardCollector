import 'package:flutter/material.dart';
import '../../../data/database/app_database.dart' as db;

/// UI presentation model for an editable translation candidate.
class TranslationProposal {
  /// The card being translated.
  final db.Card card;

  /// Text editing controller for modifying the proposed German name.
  final TextEditingController controller;

  /// Whether this proposal is checked for saving.
  bool isSelected;

  /// Whether this proposal is an exact Pokédex match.
  final bool isSafe;

  TranslationProposal({
    required this.card,
    required String proposedNameDe,
    this.isSelected = true,
    required this.isSafe,
  }) : controller = TextEditingController(text: proposedNameDe);

  /// Releases resources used by [controller].
  void dispose() => controller.dispose();
}

/// UI presentation model for editing image URL and artist metadata.
class CardEditorItem {
  /// The card being edited.
  final db.Card card;

  /// Text editing controller for the card's primary image URL.
  final TextEditingController imgEnCtrl;

  /// Text editing controller for the artist credit.
  final TextEditingController artistCtrl;

  /// Optional Cardmarket URL for deep-linking.
  String? cmUrl;

  CardEditorItem({required this.card, this.cmUrl})
      : imgEnCtrl = TextEditingController(text: card.imageUrl),
        artistCtrl = TextEditingController(text: card.artist);

  /// Releases resources used by input controllers.
  void dispose() {
    imgEnCtrl.dispose();
    artistCtrl.dispose();
  }
}
