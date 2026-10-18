import '../../data/database/app_database.dart' as db;

/// Represents a proposed German translation candidate for a card.
class ProposedTranslation {
  /// The card needing translation.
  final db.Card card;

  /// The generated German name candidate.
  final String proposedNameDe;

  /// True if the name matched the German Pokédex dictionary with 100% confidence.
  final bool isSafe;

  const ProposedTranslation({
    required this.card,
    required this.proposedNameDe,
    required this.isSafe,
  });
}
