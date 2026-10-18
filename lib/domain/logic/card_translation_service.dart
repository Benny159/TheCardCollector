import 'package:drift/drift.dart' as drift;
import '../../data/database/app_database.dart' as db;
import '../models/proposed_translation.dart';

/// Domain service responsible for card name translation heuristics and persistence.
class CardTranslationService {
  final db.AppDatabase _database;

  const CardTranslationService(this._database);

  static const Map<String, String> _trainerDict = {
    "Brock's": "Rockos",
    "Misty's": "Mistys",
    "Lt. Surge's": "Major Bobs",
    "Erika's": "Erikas",
    "Koga's": "Kogas",
    "Sabrina's": "Sabrinas",
    "Blaine's": "Pyros",
    "Giovanni's": "Giovannis",
    "Rocket's": "Rockets",
    "Lance's": "Siegfrieds",
    "Falkner's": "Falks",
    "Bugsy's": "Kais",
    "Whitney's": "Biankas",
    "Morty's": "Jens'",
    "Jasmine's": "Jasmins",
    "Chuck's": "Hartwigs",
    "Pryce's": "Norberts",
    "Clair's": "Sandras",
    "Professor Oak's": "Professor Eichs",
    "Team Aqua's": "Team Aquas",
    "Team Magma's": "Team Magmas",
    "Team Plasma's": "Team Plasmas",
  };

  /// Generates proposed German translations based on Pokédex entries and known naming patterns.
  Future<List<ProposedTranslation>> generateProposals() async {
    final dex = await (_database.select(_database.pokedex)
          ..where((t) => t.nameDe.isNotNull() & t.nameDe.isNotValue('')))
        .get();
    dex.sort((a, b) => b.name.length.compareTo(a.name.length));

    final cards = await (_database.select(_database.cards)
          ..where((t) =>
              t.nameDe.isNull() |
              t.nameDe.equals('') |
              t.nameDe.equalsExp(t.name)))
        .get();

    final List<ProposedTranslation> proposals = [];

    for (final card in cards) {
      final engName = card.name;
      String? foundGermanBase;
      bool isExactMatch = false;

      for (final p in dex) {
        if (engName.toLowerCase() == p.name.toLowerCase()) {
          foundGermanBase = p.nameDe;
          isExactMatch = true;
          break;
        }

        final searchPattern =
            RegExp.escape(p.name).replaceAll(r'\-', r'[\s-]+');
        final regExp =
            RegExp(r'\b' + searchPattern + r'\b', caseSensitive: false);

        if (regExp.hasMatch(engName)) {
          String translatedName =
              engName.replaceAllMapped(regExp, (match) => p.nameDe!);

          _trainerDict.forEach((engTrainer, gerTrainer) {
            translatedName = translatedName.replaceAll(
                RegExp(RegExp.escape(engTrainer), caseSensitive: false),
                gerTrainer);
          });

          translatedName = translatedName.replaceAll(
              RegExp(r'\bDark\b', caseSensitive: false), 'Dunkles');
          translatedName = translatedName.replaceAll(
              RegExp(r'\bLight\b', caseSensitive: false), 'Helles');
          translatedName = translatedName.replaceAll(
              RegExp(r'\bShining\b', caseSensitive: false), 'Schimmerndes');
          translatedName = translatedName.replaceAll(
              RegExp(r'\bRadiant\b', caseSensitive: false), 'Strahlendes');
          translatedName = translatedName.replaceAll(
              RegExp(r'\bShadow\b', caseSensitive: false), 'Crypto');

          translatedName = translatedName.replaceAllMapped(
              RegExp(r'[\s-]+Spirit Link\b', caseSensitive: false),
              (match) => '-Geisterbund');

          translatedName = translatedName.replaceAll(
              RegExp(r'\bAlolan\b', caseSensitive: false), 'Alola');
          translatedName = translatedName.replaceAll(
              RegExp(r'\bGalarian\b', caseSensitive: false), 'Galar');
          translatedName = translatedName.replaceAll(
              RegExp(r'\bHisuian\b', caseSensitive: false), 'Hisui');
          translatedName = translatedName.replaceAll(
              RegExp(r'\bPaldean\b', caseSensitive: false), 'Paldea');

          translatedName = translatedName.replaceAllMapped(
              RegExp(r"\b([A-Za-z]+)'s\b", caseSensitive: false), (match) {
            final base = match.group(1)!;
            return "${base[0].toUpperCase()}${base.substring(1).toLowerCase()}s";
          });

          translatedName = translatedName.replaceAllMapped(
              RegExp(r'\b(Mega)[\s-]+', caseSensitive: false),
              (match) => 'Mega-');

          translatedName = translatedName.replaceAllMapped(
              RegExp(r'[\s-]+(ex|gx|v|vmax|vstar|break)\b',
                  caseSensitive: false), (match) {
            String suffix = match.group(1)!.toUpperCase();
            if (suffix == 'BREAK') suffix = 'TURBO';
            return '-$suffix';
          });

          foundGermanBase = translatedName;
          break;
        }
      }

      if (foundGermanBase != null &&
          foundGermanBase.toLowerCase() != engName.toLowerCase()) {
        proposals.add(ProposedTranslation(
          card: card,
          proposedNameDe: foundGermanBase,
          isSafe: isExactMatch,
        ));
      }
    }

    return proposals;
  }

  /// Persists a batch of manual translations into the database.
  Future<void> saveTranslations(Map<String, String> cardIdToGermanName) async {
    if (cardIdToGermanName.isEmpty) return;

    await _database.batch((batch) {
      for (final entry in cardIdToGermanName.entries) {
        batch.update(
          _database.cards,
          db.CardsCompanion(
            nameDe: drift.Value(entry.value),
            hasManualTranslations: const drift.Value(true),
          ),
          where: (t) => t.id.equals(entry.key),
        );
      }
    });
  }

  /// Resets all manually translated card names back to null.
  Future<int> resetManualTranslations() async {
    return await (_database.update(_database.cards)
          ..where((t) => t.hasManualTranslations.equals(true)))
        .write(const db.CardsCompanion(
      nameDe: drift.Value(null),
      hasManualTranslations: drift.Value(false),
    ));
  }
}
