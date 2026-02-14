import 'package:drift/drift.dart';
import '../../domain/models/api_card.dart';
import '../../domain/models/api_set.dart';
import '../api/tcg_api_client.dart';
import '../api/tcgdex_api_client.dart';
import '../database/app_database.dart';

class SetImporter {
  final TcgApiClient apiClient;
  final TcgDexApiClient dexClient;
  final AppDatabase database;

  List<dynamic>? _cachedDexSets;

  SetImporter(this.apiClient, this.dexClient, this.database);

  Future<void> importSetInfo(ApiSet set) async {
    await database.into(database.cardSets).insert(
          CardSetsCompanion(
            id: Value(set.id),
            name: Value(set.name),
            series: Value(set.series),
            printedTotal: Value(set.printedTotal),
            total: Value(set.total),
            releaseDate: Value(set.releaseDate),
            updatedAt: Value(DateTime.now().toIso8601String()),
            logoUrl: Value(set.logoUrl),
            symbolUrl: Value(set.symbolUrl),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> importSet(ApiSet set, {String language = 'de'}) async {
    await importSetInfo(set);
    print('🔄 IMPORT START: Set ${set.id} ("${set.name}") | Sprache: $language');

    String? tcgDexSetId;
    try {
      if (_cachedDexSets == null) {
          print('📥 Lade TCGdex Set-Liste...');
          _cachedDexSets = await dexClient.fetchAllSets(lang: language);
      }
      
      tcgDexSetId = _resolveTcgDexSetId(set, _cachedDexSets!);
      
      if (tcgDexSetId != null) {
        print('✅ ID Mapping: API "${set.id}" -> TCGdex "$tcgDexSetId"');
      } else {
        print('⚠️ KEIN MAPPING für "${set.id}". Nutze Fallback.');
        tcgDexSetId = set.id;
      }
    } catch (e) {
      print('❌ Fehler beim Mapping: $e');
      tcgDexSetId = set.id;
    }

    await apiClient.fetchAllCardsForSet(
      set.id,
      onBatchLoaded: (batchCards) async {
        await _processAndSaveBatch(set.id, tcgDexSetId!, batchCards, language);
      },
    );
    
    await (database.update(database.cardSets)..where((t) => t.id.equals(set.id))).write(
      CardSetsCompanion(updatedAt: Value(DateTime.now().toIso8601String())),
    );
    print('✅ IMPORT ENDE: Set ${set.id} fertig.');
  }

  // --- DIE KORRIGIERTE MAPPING LOGIK ---
  String? _resolveTcgDexSetId(ApiSet apiSet, List<dynamic> dexSets) {
    final apiId = apiSet.id.toLowerCase();
    final apiName = apiSet.name.toLowerCase();

    // 1. MANUELLE LISTE (Deine Beispiele + Bekannte Probleme)
    final manualMap = <String, String>{
      'zsv1': 'sv01',
      'rsv1': 'sv01',
      'swsh45sv': 'swsh04.5',
      // Füge hier weitere hinzu, die automatisch nicht gehen
    };

    if (manualMap.containsKey(apiId)) {
      var match = dexSets.firstWhere((d) => d['id'].toString().toLowerCase() == manualMap[apiId], orElse: () => null);
      if (match != null) return match['id'];
    }

    // 2. NAMENS-MATCH (Prio 2)
    var match = dexSets.firstWhere(
      (d) => d['name'].toString().toLowerCase() == apiName, 
      orElse: () => null
    );
    if (match != null) return match['id'];

    // 3. INTELLIGENTES MAPPING
    // API-ID Normalisieren: "me2pt5" -> "me2.5"
    String normalizedApi = apiId.replaceAll('pt', '.');

    // HIER IST DER FIX: Wir bauen eine "sv01" Variante aus "sv1"
    // Regex sucht: Buchstaben + EINE Ziffer + (keine weitere Ziffer)
    // Beispiel: "sv1" -> Matcht "v1" -> Wird zu "v01" -> "sv01"
    // Beispiel: "sv10" -> Matcht NICHT (weil 1 gefolgt von 0 ist) -> Bleibt "sv10"
    // Beispiel: "me2.5" -> Matcht "e2" -> Wird zu "e02" -> "me02.5"
    String paddedApi = normalizedApi.replaceAllMapped(
      RegExp(r'([a-z]+)([0-9])(?![0-9])'), 
      (m) => '${m[1]}0${m[2]}'
    );

    // Fallback: Wir entfernen Nullen zum Vergleichen (sv01 -> sv1)
    String stripZeros(String s) => s.replaceAllMapped(RegExp(r'([a-z]+)0+([1-9])'), (m) => '${m[1]}${m[2]}');

    for (var d in dexSets) {
      String dexId = d['id'].toString().toLowerCase();

      // Check A: Exakter Match nach 'pt' Bereinigung
      if (dexId == normalizedApi) return d['id'];

      // Check B (DEIN WUNSCH): API mit Nullen aufgefüllt (sv1 -> sv01) == DexID (sv01)
      if (dexId == paddedApi) return d['id'];

      // Check C: Beide ohne Nullen (Fallback, falls Dex mal sv1 heißt und API sv01)
      if (stripZeros(dexId) == stripZeros(normalizedApi)) return d['id'];
    }

    return null;
  }

  Future<void> _processAndSaveBatch(String apiSetId, String dexSetId, List<ApiCard> cards, String lang) async {
    for (final card in cards) {
      Map<String, dynamic>? dexData;
      bool needsEnrichment = lang != 'en' || (card.artist.isEmpty);

      if (needsEnrichment) {
        String queryNumber = card.number;
        
        // Versuch 1: Normal
        dexData = await dexClient.fetchCardDetails(dexSetId, queryNumber, lang: lang);
        
        // Versuch 2: Padding (API "1" -> Dex "001")
        if (dexData == null && int.tryParse(queryNumber) != null) {
             String padded3 = queryNumber.padLeft(3, '0');
             if (padded3 != queryNumber) dexData = await dexClient.fetchCardDetails(dexSetId, padded3, lang: lang);
             
             if (dexData == null) {
               String padded2 = queryNumber.padLeft(2, '0');
               if (padded2 != queryNumber) dexData = await dexClient.fetchCardDetails(dexSetId, padded2, lang: lang);
             }
        }
      }
      await _saveMergedCard(card, dexData, lang);
    }
  }

  Future<void> _saveMergedCard(ApiCard apiCard, Map<String, dynamic>? dexData, String requestedLang) async {
    String nameEn = apiCard.name;
    String artist = apiCard.artist;
    String? flavorEn = apiCard.flavorText;
    String? nameDe;
    String? flavorDe;

    if (dexData != null) {
      if (artist.isEmpty && dexData['illustrator'] != null) {
        artist = dexData['illustrator'];
      }
      if (requestedLang == 'de') {
        if (dexData['name'] != null) nameDe = dexData['name']; 
        if (dexData['description'] != null) flavorDe = dexData['description'];
        else if (dexData['effect'] != null) flavorDe = dexData['effect'];
      }
    }

    await database.transaction(() async {
      await database.into(database.cards).insertOnConflictUpdate(
        CardsCompanion(
          id: Value(apiCard.id),
          setId: Value(apiCard.setId),
          name: Value(nameEn),
          flavorText: Value(flavorEn),
          nameDe: nameDe != null ? Value(nameDe) : const Value.absent(),
          flavorTextDe: flavorDe != null ? Value(flavorDe) : const Value.absent(),
          number: Value(apiCard.number),
          imageUrlSmall: Value(apiCard.smallImageUrl),
          imageUrlLarge: Value(apiCard.largeImageUrl ?? apiCard.smallImageUrl),
          artist: Value(artist),
          rarity: Value(apiCard.rarity),
          supertype: Value(apiCard.supertype),
          subtypes: Value(apiCard.subtypes.join(', ')),
          types: Value(apiCard.types.join(', ')),
        ),
      );

      if (apiCard.cardmarket != null) {
        final existingEntry = await (database.select(database.cardMarketPrices)
              ..where((tbl) => tbl.cardId.equals(apiCard.id))
              ..where((tbl) => tbl.updatedAt.equals(apiCard.cardmarket!.updatedAt))
              ..limit(1)).getSingleOrNull();
        if (existingEntry == null) {
          await database.into(database.cardMarketPrices).insert(
            CardMarketPricesCompanion.insert(
              cardId: apiCard.id,
              fetchedAt: DateTime.now(),
              updatedAt: apiCard.cardmarket!.updatedAt,
              trendPrice: Value(apiCard.cardmarket!.trendPrice),
              avg30: Value(apiCard.cardmarket!.avg30),
              reverseHoloTrend: Value(apiCard.cardmarket!.reverseHoloTrend),
              lowPrice: Value(apiCard.cardmarket!.lowPrice),
              url: Value(apiCard.cardmarket!.url),
            ),
          );
        }
      }

      if (apiCard.tcgplayer != null) {
        final tcg = apiCard.tcgplayer!;
        final existingEntry = await (database.select(database.tcgPlayerPrices)
              ..where((tbl) => tbl.cardId.equals(apiCard.id))
              ..where((tbl) => tbl.updatedAt.equals(tcg.updatedAt ?? ''))
              ..limit(1)).getSingleOrNull();
        if (existingEntry == null) {
          final prices = tcg.prices;
          final mainMarket = prices?.normal?.market ?? prices?.holofoil?.market;
          final mainLow = prices?.normal?.low ?? prices?.holofoil?.low;
          await database.into(database.tcgPlayerPrices).insert(
            TcgPlayerPricesCompanion.insert(
              cardId: apiCard.id,
              fetchedAt: DateTime.now(),
              updatedAt: tcg.updatedAt ?? '',
              url: Value(tcg.url),
              normalMarket: Value(mainMarket),
              normalLow: Value(mainLow),
              reverseHoloMarket: Value(prices?.reverseHolofoil?.market),
              reverseHoloLow: Value(prices?.reverseHolofoil?.low),
            ),
          );
        }
      }
    });
  }

  Future<void> updateSingleCard(String cardId) async {
    final parts = cardId.split('-');
    if (parts.length < 2) return;
    
    final setId = parts[0];
    final allSetCards = await apiClient.fetchCardsForSet(setId);
    final mainCard = allSetCards.firstWhere((c) => c.id == cardId, orElse: () => allSetCards.first);

    if (_cachedDexSets == null) {
        _cachedDexSets = await dexClient.fetchAllSets(lang: 'de');
    }
    
    final dbSet = await (database.select(database.cardSets)..where((t) => t.id.equals(setId))).getSingleOrNull();
    String dexSetId = setId;
    if (dbSet != null) {
        final dummyApiSet = ApiSet(
            id: dbSet.id, name: dbSet.name, nameDe: dbSet.nameDe, series: dbSet.series, printedTotal: dbSet.printedTotal, 
            total: dbSet.total, releaseDate: dbSet.releaseDate, updatedAt: dbSet.updatedAt, 
            logoUrl: dbSet.logoUrl, symbolUrl: dbSet.symbolUrl
        );
        dexSetId = _resolveTcgDexSetId(dummyApiSet, _cachedDexSets!) ?? setId;
    }

    String queryNumber = mainCard.number;
    var dexData = await dexClient.fetchCardDetails(dexSetId, queryNumber, lang: 'de');
    if (dexData == null && int.tryParse(queryNumber) != null) {
       dexData = await dexClient.fetchCardDetails(dexSetId, queryNumber.padLeft(3, '0'), lang: 'de');
    }

    await _saveMergedCard(mainCard, dexData, 'de');
  }

  Future<void> syncAllData({Function(String status)? onProgress}) async {
    onProgress?.call('Lade Set-Liste...');
    final allSets = await apiClient.fetchAllSets();
    
    int currentSet = 1;
    for (final set in allSets) {
      onProgress?.call('Set $currentSet/${allSets.length}: ${set.name} wird geladen...');
      await importSet(set, language: 'de'); 
      currentSet++;
    }
    onProgress?.call('Fertig! Datenbank aktualisiert.');
  }
}