import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/api_card.dart';
import '../../domain/models/api_set.dart';
import '../sync/set_importer.dart';
import '../database/database_provider.dart';
import 'tcg_api_client.dart';

// --- 1. NEU: Das Enum für den Suchmodus ---
enum SearchMode { name, artist }

// --- 2. NEU: Der Provider für den Modus (Standard: Name) ---
final searchModeProvider = StateProvider<SearchMode>((ref) => SearchMode.name);

// Der Provider für den Suchtext
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider für ALLE Sets
final allSetsProvider = FutureProvider<List<ApiSet>>((ref) async {
  final db = ref.read(databaseProvider);
  
  // 1. In der lokalen DB nachsehen
  final localSets = await db.select(db.cardSets).get();
  
  // 2. Wenn wir Sets in der DB haben, nehmen wir die!
  if (localSets.isNotEmpty) {
    localSets.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));

    return localSets.map((s) => ApiSet(
      id: s.id,
      name: s.name,
      series: s.series,
      printedTotal: s.printedTotal,
      total: s.total,
      releaseDate: s.releaseDate,
      updatedAt: s.updatedAt,
      logoUrl: s.logoUrl,
      symbolUrl: s.symbolUrl,
    )).toList();
  }

  // 3. Nur wenn die DB komplett leer ist
  final api = ref.read(apiClientProvider);
  final importer = SetImporter(api, db);
  
  final apiSets = await api.fetchAllSets();
  
  for (final set in apiSets) {
    await importer.importSetInfo(set);
  }

  return apiSets;
});

// --- 3. UPDATE: Der Such-Provider (Reagiert jetzt auf Name ODER Künstler) ---
final searchResultsProvider = FutureProvider<List<ApiCard>>((ref) async {
  final queryText = ref.watch(searchQueryProvider);
  final mode = ref.watch(searchModeProvider); // <--- HIER holen wir den Modus

  if (queryText.isEmpty) return [];

  final db = ref.watch(databaseProvider);

  // JOIN: Karten mit Sets verknüpfen (für printedTotal)
  final query = db.select(db.cards).join([
    innerJoin(db.cardSets, db.cardSets.id.equalsExp(db.cards.setId))
  ]);
  
  // --- HIER IST DIE NEUE LOGIK ---
  if (mode == SearchMode.name) {
    // Wenn Modus "Name" -> Suche im Namen
    query.where(db.cards.name.like('%$queryText%'));
  } else {
    // Wenn Modus "Artist" -> Suche im Künstler-Feld
    query.where(db.cards.artist.like('%$queryText%'));
  }
  
  final rows = await query.get();
  List<ApiCard> results = [];

  for (final row in rows) {
    final card = row.readTable(db.cards);
    final set = row.readTable(db.cardSets);

    // Preise holen (Cardmarket)
    final cmPrice = await (db.select(db.cardMarketPrices)
          ..where((tbl) => tbl.cardId.equals(card.id))
          ..orderBy([(t) => OrderingTerm(expression: t.fetchedAt, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();

    // Preise holen (TCGPlayer)
    final tcgPrice = await (db.select(db.tcgPlayerPrices)
          ..where((tbl) => tbl.cardId.equals(card.id))
          ..orderBy([(t) => OrderingTerm(expression: t.fetchedAt, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();

    List<String> parseList(String? value) => (value ?? '').split(', ').where((e) => e.isNotEmpty).toList();

    results.add(ApiCard(
      id: card.id,
      name: card.name,
      supertype: card.supertype ?? '',
      subtypes: parseList(card.subtypes),
      types: parseList(card.types),
      setId: card.setId,
      number: card.number,
      setPrintedTotal: set.printedTotal.toString(),
      artist: card.artist ?? '',
      rarity: card.rarity ?? '',
      flavorText: card.flavorText,
      smallImageUrl: card.imageUrlSmall,
      largeImageUrl: card.imageUrlLarge,
      
      cardmarket: cmPrice != null 
          ? ApiCardMarket(
              url: cmPrice.url ?? '',
              updatedAt: cmPrice.updatedAt,
              trendPrice: cmPrice.trendPrice,
              avg30: cmPrice.avg30,
              lowPrice: cmPrice.lowPrice,
              reverseHoloTrend: cmPrice.reverseHoloTrend,
            )
          : null,
      
      tcgplayer: tcgPrice != null 
          ? ApiTcgPlayer(
              url: tcgPrice.url ?? '',
              updatedAt: tcgPrice.updatedAt,
              prices: ApiTcgPlayerPrices(
                normal: ApiPriceType(
                  market: tcgPrice.normalMarket, 
                  low: tcgPrice.normalLow
                ),
                reverseHolofoil: ApiPriceType(
                  market: tcgPrice.reverseHoloMarket, 
                  low: tcgPrice.reverseHoloLow
                ),
              ),
            )
          : null, 
    ));
  }

  return results;
});

// --- UPDATE: Cards For Set Provider (Damit hier auch alles stimmt) ---
final cardsForSetProvider = FutureProvider.family<List<ApiCard>, String>((ref, setId) async {
  final db = ref.read(databaseProvider);

  // Set Info für printedTotal holen
  final setInfo = await (db.select(db.cardSets)..where((tbl) => tbl.id.equals(setId))).getSingleOrNull();

  // Karten holen
  final dbCards = await (db.select(db.cards)..where((tbl) => tbl.setId.equals(setId))).get();

  List<ApiCard> results = [];

  for (final dbCard in dbCards) {
    // Preise
    final cmPrice = await (db.select(db.cardMarketPrices)
          ..where((tbl) => tbl.cardId.equals(dbCard.id))
          ..orderBy([(t) => OrderingTerm(expression: t.fetchedAt, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();

    final tcgPrice = await (db.select(db.tcgPlayerPrices)
          ..where((tbl) => tbl.cardId.equals(dbCard.id))
          ..orderBy([(t) => OrderingTerm(expression: t.fetchedAt, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();

    List<String> parseList(String? value) => (value ?? '').split(', ').where((e) => e.isNotEmpty).toList();

    results.add(ApiCard(
      id: dbCard.id,
      name: dbCard.name,
      supertype: dbCard.supertype ?? '',
      subtypes: parseList(dbCard.subtypes),
      types: parseList(dbCard.types),
      setId: dbCard.setId,
      number: dbCard.number,
      
      setPrintedTotal: setInfo?.printedTotal.toString() ?? '?',

      artist: dbCard.artist ?? '',
      rarity: dbCard.rarity ?? 'Unbekannt',
      flavorText: dbCard.flavorText,
      smallImageUrl: dbCard.imageUrlSmall,
      largeImageUrl: dbCard.imageUrlLarge,
      
      cardmarket: cmPrice != null 
          ? ApiCardMarket(
              url: cmPrice.url ?? '',
              updatedAt: cmPrice.updatedAt,
              trendPrice: cmPrice.trendPrice,
              avg30: cmPrice.avg30,
              lowPrice: cmPrice.lowPrice,
              reverseHoloTrend: cmPrice.reverseHoloTrend,
            )
          : null,
      
      tcgplayer: tcgPrice != null 
          ? ApiTcgPlayer(
              url: tcgPrice.url ?? '',
              updatedAt: tcgPrice.updatedAt,
              prices: ApiTcgPlayerPrices(
                normal: ApiPriceType(
                  market: tcgPrice.normalMarket, 
                  low: tcgPrice.normalLow
                ),
                reverseHolofoil: ApiPriceType(
                  market: tcgPrice.reverseHoloMarket, 
                  low: tcgPrice.reverseHoloLow
                ),
              ),
            )
          : null, 
    ));
  }

  return results;
});

final setByIdProvider = FutureProvider.family<ApiSet?, String>((ref, setId) async {
  final sets = await ref.watch(allSetsProvider.future);
  try {
    return sets.firstWhere((s) => s.id == setId);
  } catch (e) {
    return null;
  }
});