import 'package:drift/drift.dart';
import '../api/tcgdex_api_client.dart';
import '../../domain/logic/binder_service.dart';
import '../database/app_database.dart';

class _CardImportData {
  final CardsCompanion card;
  final CardMarketPricesCompanion? cmPrice;
  final TcgPlayerPricesCompanion? tcgPrice;

  _CardImportData(this.card, this.cmPrice, this.tcgPrice);
}

class SetImporter {
  final TcgDexApiClient dexClient;
  final AppDatabase database;

  SetImporter(this.dexClient, this.database);

  Future<void> syncAllData({Function(String status)? onProgress}) async {
    onProgress?.call('Lade Set-Liste von TCGdex...');
    
    final dexSetsEn = await dexClient.fetchAllSets(lang: 'en');
    final dexSetsDe = await dexClient.fetchAllSets(lang: 'de');
    final deMap = { for (var s in dexSetsDe) s['id']: s };

    // --- NEU: WIR LADEN DIE LETZTEN PREISE VORAB IN DEN SPEICHER ---
    // Das ist das Geheimnis für den ultimativen Speed-Boost!
    onProgress?.call('Lade Preis-Cache für smarten Sync...');
    final allLatestCmQuery = await database.customSelect(
      'SELECT card_id, trend, trend_holo, trend_reverse FROM card_market_prices GROUP BY card_id HAVING MAX(fetched_at)'
    ).get();
    final Map<String, Map<String, dynamic>> latestCmPrices = {
      for (var row in allLatestCmQuery) row.read<String>('card_id'): {
        'trend': row.read<double?>('trend'),
        'trendHolo': row.read<double?>('trend_holo'),
        'trendReverse': row.read<double?>('trend_reverse'),
      }
    };

    final allLatestTcgQuery = await database.customSelect(
      'SELECT card_id, normal_market, holo_market, reverse_market FROM tcg_player_prices GROUP BY card_id HAVING MAX(fetched_at)'
    ).get();
    final Map<String, Map<String, dynamic>> latestTcgPrices = {
      for (var row in allLatestTcgQuery) row.read<String>('card_id'): {
        'normalMarket': row.read<double?>('normal_market'),
        'holoMarket': row.read<double?>('holo_market'),
        'reverseMarket': row.read<double?>('reverse_market'),
      }
    };
    // -------------------------------------------------------------

    int current = 0;
    int skipped = 0;

    for (var listSet in dexSetsEn) {
      await Future.delayed(const Duration(milliseconds: 10)); 

      final setId = listSet['id'] as String;
      
      final serieData = listSet['serie'];
      final String serieId = (serieData is Map) ? serieData['id'] ?? '' : '';

      if (serieId == 'jumbo' || setId == 'xya' || setId == 'sp') {
        skipped++;
        print('⏩ Überspringe Pocket-Set: ${listSet['name']} ($setId)');
        continue; 
      }

      current++;
      final setName = listSet['name'] as String;
      
      onProgress?.call('Set $current/${dexSetsEn.length - skipped}: $setName...');
      
      final fullSetData = await dexClient.fetchSet(setId);
      
      if (fullSetData != null) {
        final detailSerie = fullSetData['serie'];
        final detailSerieId = (detailSerie is Map) ? detailSerie['id'] ?? '' : '';
        if (detailSerieId == 'tcgp') {
           skipped++; current--; continue;
        }

        final setDe = deMap[setId];
        await _saveSetMetadata(fullSetData, setDe);

        try {
          await importCardsForSet(setId, latestCmPrices, latestTcgPrices);
        } catch (e) {
          print('⚠️ Fehler bei Karten für $setId: $e');
        }
      }
    }
    
    onProgress?.call('✅ Sync fertig! $current Sets geladen.');
    onProgress?.call('Aktualisiere Binder-Werte...');
    await BinderService(database).recalculateAllBinders();
  }

  Future<void> _saveSetMetadata(dynamic en, dynamic de) async {
    final setId = en['id'];
    
    final logoEn = en['logo'] != null ? '${en["logo"]}.png' : null;
    final logoDe = de?['logo'] != null ? '${de["logo"]}.png' : null;
    final symbol = en['symbol'] != null ? '${en["symbol"]}.png' : null;
    final String? rDate = en['releaseDate'];

    final existingSet = await (database.select(database.cardSets)..where((t) => t.id.equals(setId))).getSingleOrNull();

    Value<String?> dbNameDe = de?['name'] != null ? Value(de!['name']) : const Value.absent();
    Value<String?> dbLogoEn = logoEn != null ? Value(logoEn) : const Value.absent();
    Value<String?> dbLogoDe = logoDe != null ? Value(logoDe) : const Value.absent();
    Value<String?> dbSymbol = symbol != null ? Value(symbol) : const Value.absent();

    if (existingSet != null) {
      if (existingSet.hasManualTranslations) dbNameDe = const Value.absent(); 
      if (existingSet.hasManualImages) {
         dbLogoEn = const Value.absent();
         dbLogoDe = const Value.absent();
         dbSymbol = const Value.absent();
      }
    }

    await database.into(database.cardSets).insertOnConflictUpdate(
      CardSetsCompanion(
        id: Value(setId),
        name: Value(en['name']),
        nameDe: dbNameDe,
        series: Value(en['serie'] is Map ? en['serie']['name'] : 'Series'),
        printedTotal: Value(en['cardCount']?['official'] ?? 0),
        total: Value(en['cardCount']?['total'] ?? 0),
        releaseDate: rDate != null ? Value(rDate) : const Value.absent(),
        updatedAt: Value(DateTime.now().toIso8601String()),
        logoUrl: dbLogoEn,
        logoUrlDe: dbLogoDe,
        symbolUrl: dbSymbol,
      )
    );
  }

  // --- KARTEN IMPORT ---
  Future<void> importCardsForSet(String setId, Map<String, Map<String, dynamic>> latestCmPrices, Map<String, Map<String, dynamic>> latestTcgPrices) async {
    final enList = await dexClient.fetchCardsOfSet(setId, lang: 'en');
    final deList = await dexClient.fetchCardsOfSet(setId, lang: 'de');
    final deMap = { for (var c in deList) c['id']: c };

    final existingCardsList = await (database.select(database.cards)..where((t) => t.setId.equals(setId))).get();
    final Map<String, Card> existingCardsMap = { for (var c in existingCardsList) c.id: c };

    int chunkSize = 200;
    
    for (var i = 0; i < enList.length; i += chunkSize) {
      await Future.delayed(Duration.zero);

      final end = (i + chunkSize < enList.length) ? i + chunkSize : enList.length;
      final chunk = enList.sublist(i, end);
      
      final List<_CardImportData?> results = await Future.wait(
        chunk.map((c) => _prepareCardData(c, deMap[c['id']], existingCardsMap[c['id']], latestCmPrices, latestTcgPrices))
      );

      final validData = results.whereType<_CardImportData>().toList();
      if (validData.isEmpty) continue;

      await database.batch((batch) {
        batch.insertAllOnConflictUpdate(
          database.cards, 
          validData.map((d) => d.card).toList()
        );

        final cmList = validData.map((d) => d.cmPrice).whereType<CardMarketPricesCompanion>().toList();
        if (cmList.isNotEmpty) batch.insertAll(database.cardMarketPrices, cmList);

        final tcgList = validData.map((d) => d.tcgPrice).whereType<TcgPlayerPricesCompanion>().toList();
        if (tcgList.isNotEmpty) batch.insertAll(database.tcgPlayerPrices, tcgList);
      });
    }
  }

  Future<_CardImportData?> _prepareCardData(dynamic summaryEn, dynamic summaryDe, Card? existingCard, Map<String, Map<String, dynamic>> latestCmPrices, Map<String, Map<String, dynamic>> latestTcgPrices) async {
    final cardId = summaryEn['id'];
    
    final data = await dexClient.fetchCardDetails(cardId, lang: 'en');
    if (data == null) return null;

    final nameEn = data['name'] ?? 'Unknown';
    final String? nameDeApi = summaryDe?['name']; 

    String imageEn = data['image'] ?? summaryEn['image'] ?? '';
    if (imageEn.isNotEmpty && !imageEn.endsWith('.png')) imageEn += '/high.png';

    String imageDe = summaryDe?['image'] ?? '';
    if (imageDe.isNotEmpty && !imageDe.endsWith('.png')) imageDe += '/high.png';

    final bool hasEn = imageEn.isNotEmpty;
    final bool hasDe = imageDe.isNotEmpty;

    final String finalImageEn = hasEn ? imageEn : (hasDe ? imageDe : '');
    final String finalImageDe = hasDe ? imageDe : (hasEn ? imageEn : '');

    final String? artistApi = data['illustrator'];
    final v = data['variants'] ?? {};
    final number = data['localId'] ?? '0';
    int sortNum = int.tryParse(number) ?? 0;

    String? cardType;
    final cat = data['category']; 
    if (cat == "Trainer") cardType = "Trainer";
    else if (cat == "Energy") cardType = "Energy";
    else if (data['types'] != null && data['types'] is List && (data['types'] as List).isNotEmpty) {
      cardType = (data['types'] as List).first.toString(); 
    }

    int? cardHp;
    if (data['hp'] != null) cardHp = int.tryParse(data['hp'].toString()); 

    Value<String?> dbNameDe = (nameDeApi != null && nameDeApi.isNotEmpty) ? Value(nameDeApi) : const Value.absent();
    Value<String> dbImgEn = Value(finalImageEn);
    Value<String?> dbImgDe = Value(finalImageDe);
    Value<String?> dbArtist = (artistApi != null && artistApi.isNotEmpty) ? Value(artistApi) : const Value.absent();
    Value<String?> dbRarity = Value(data['rarity']);
    Value<int?> dbHp = cardHp != null ? Value(cardHp) : const Value.absent();
    Value<String?> dbCardType = cardType != null ? Value(cardType) : const Value.absent();
    Value<String> dbNumber = Value(number);

    Value<bool> dbHas1st = Value(v['firstEdition'] == true);
    Value<bool> dbHasNormal = Value(v['normal'] == true);
    Value<bool> dbHasHolo = Value(v['holo'] == true);
    Value<bool> dbHasRev = Value(v['reverse'] == true);
    Value<bool> dbHasPromo = Value(v['wPromo'] == true);

    if (existingCard != null) {
      if (existingCard.hasManualTranslations) dbNameDe = const Value.absent();
      if (existingCard.hasManualImages) {
        dbImgEn = const Value.absent();
        dbImgDe = const Value.absent();
      }
      if (existingCard.hasManualStats) {
        dbArtist = const Value.absent();
        dbRarity = const Value.absent();
        dbHp = const Value.absent();
        dbCardType = const Value.absent();
        dbNumber = const Value.absent();
      }
      if (existingCard.hasManualVariants) {
        dbHas1st = const Value.absent();
        dbHasNormal = const Value.absent();
        dbHasHolo = const Value.absent();
        dbHasRev = const Value.absent();
        dbHasPromo = const Value.absent();
      }
    }

    final cardCompanion = CardsCompanion(
        id: Value(cardId),
        setId: Value(data['set']['id']),
        name: Value(nameEn),
        sortNumber: Value(sortNum),
        nameDe: dbNameDe,
        number: dbNumber,
        cardType: dbCardType,
        hp: dbHp, 
        artist: dbArtist,
        rarity: dbRarity,
        imageUrl: dbImgEn,
        imageUrlDe: dbImgDe,
        hasFirstEdition: dbHas1st,
        hasNormal: dbHasNormal,
        hasHolo: dbHasHolo,
        hasReverse: dbHasRev,
        hasWPromo: dbHasPromo,
    );

    CardMarketPricesCompanion? cmCompanion;
    TcgPlayerPricesCompanion? tcgCompanion;
    
    if (data['pricing'] != null) {
      final now = DateTime.now();
      final pricing = data['pricing'];

      // --- DER SMARTE PREIS-CHECK: Nur speichern, wenn sich etwas geändert hat! ---
      if (pricing['cardmarket'] != null) {
        final cm = pricing['cardmarket'];
        final double? newTrend = (cm['trend'] as num?)?.toDouble();
        final double? newTrendHolo = (cm['trend-holo'] as num?)?.toDouble();
        final double? newTrendRev = null; // TCGdex liefert aktuell keinen Rev Trend

        final oldCm = latestCmPrices[cardId];
        // Schreibe einen neuen Preis, wenn es noch keinen gibt, ODER wenn einer der Trend-Preise abweicht
        if (oldCm == null || oldCm['trend'] != newTrend || oldCm['trendHolo'] != newTrendHolo) {
          cmCompanion = CardMarketPricesCompanion.insert(
            cardId: cardId,
            fetchedAt: now,
            average: Value((cm['avg'] as num?)?.toDouble()),
            low: Value((cm['low'] as num?)?.toDouble()),
            trend: Value(newTrend),
            avg1: Value((cm['avg1'] as num?)?.toDouble()),
            avg7: Value((cm['avg7'] as num?)?.toDouble()),
            avg30: Value((cm['avg30'] as num?)?.toDouble()),
            avgHolo: Value((cm['avg-holo'] as num?)?.toDouble()),
            lowHolo: Value((cm['low-holo'] as num?)?.toDouble()),
            trendHolo: Value(newTrendHolo),
            avg1Holo: Value((cm['avg1-holo'] as num?)?.toDouble()),
            avg7Holo: Value((cm['avg7-holo'] as num?)?.toDouble()),
            avg30Holo: Value((cm['avg30-holo'] as num?)?.toDouble()),
          );
        }
      }

      if (pricing['tcgplayer'] != null) {
        final tcg = pricing['tcgplayer'];
        final norm = tcg['normal'];
        final holo = tcg['holofoil'];
        final rev = tcg['reverse-holofoil'];

        final double? newNormMarket = (norm?['marketPrice'] as num?)?.toDouble();
        final double? newHoloMarket = (holo?['marketPrice'] as num?)?.toDouble();
        final double? newRevMarket = (rev?['marketPrice'] as num?)?.toDouble();

        final oldTcg = latestTcgPrices[cardId];
        
        if (oldTcg == null || oldTcg['normalMarket'] != newNormMarket || oldTcg['holoMarket'] != newHoloMarket || oldTcg['reverseMarket'] != newRevMarket) {
          tcgCompanion = TcgPlayerPricesCompanion.insert(
            cardId: cardId,
            fetchedAt: now,
            normalMarket: Value(newNormMarket),
            normalLow: Value((norm?['lowPrice'] as num?)?.toDouble()),
            normalMid: Value((norm?['midPrice'] as num?)?.toDouble()),
            normalDirectLow: Value((norm?['directLowPrice'] as num?)?.toDouble()),
            holoMarket: Value(newHoloMarket),
            holoLow: Value((holo?['lowPrice'] as num?)?.toDouble()),
            holoMid: Value((holo?['midPrice'] as num?)?.toDouble()),
            holoDirectLow: Value((holo?['directLowPrice'] as num?)?.toDouble()),
            reverseMarket: Value(newRevMarket),
            reverseLow: Value((rev?['lowPrice'] as num?)?.toDouble()),
            reverseMid: Value((rev?['midPrice'] as num?)?.toDouble()),
            reverseDirectLow: Value((rev?['directLowPrice'] as num?)?.toDouble()),
          );
        }
      }
    }

    return _CardImportData(cardCompanion, cmCompanion, tcgCompanion);
  }
}