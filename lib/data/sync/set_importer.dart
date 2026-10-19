import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;
import '../api/tcgdex_api_client.dart';
import '../../domain/logic/binder_service.dart';
import '../database/app_database.dart';

class _CardImportData {
  final CardsCompanion card;
  final CardMarketPricesCompanion? cmPrice;
  final TcgPlayerPricesCompanion? tcgPrice;

  _CardImportData(this.card, this.cmPrice, this.tcgPrice);
}

/// Primary data synchronization service for fetching card sets, prints, and prices from TCGdex.
class SetImporter {
  /// REST API client for TCGdex endpoints.
  final TcgDexApiClient dexClient;

  /// Local Drift database instance.
  final AppDatabase database;

  /// Creates a [SetImporter] with the required [dexClient] and [database].
  const SetImporter(this.dexClient, this.database);

  /// Synchronizes all official Pokémon TCG card sets and cards from TCGdex.
  ///
  /// Skips digital-only and jumbo sets, pre-caches latest market prices in memory,
  /// and triggers portfolio value recalculations upon completion.
  Future<void> syncAllData({Function(String status)? onProgress}) async {
    onProgress?.call('Lade Set-Liste von TCGdex...');
    
    final dexSetsEn = await dexClient.fetchAllSets(lang: 'en');
    final dexSetsDe = await dexClient.fetchAllSets(lang: 'de');
    final deMap = { for (var s in dexSetsDe) s['id']: s };

    // Preload latest known prices into memory for change-detection diffing
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

    int current = 0;
    int skipped = 0;

    for (final listSet in dexSetsEn) {
      await Future.delayed(const Duration(milliseconds: 150)); 

      final setId = listSet['id'] as String;
      
      final serieData = listSet['serie'];
      final String serieId = (serieData is Map) ? serieData['id'] ?? '' : '';

      // Skip digital Pokémon Pocket sets, jumbo, and promotional special series
      final bool isPocketSet = serieId == 'tcgp' || setId.startsWith('A') || setId.startsWith('B') || setId == 'P-A';
      if (isPocketSet || serieId == 'jumbo' || setId == 'xya' || setId == 'sp') {
        skipped++;
        debugPrint('⏩ Skipping Pocket/digital/promotional set: ${listSet['name']} ($setId)');
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
          skipped++; 
          current--; 
          continue;
        }

        final setDe = deMap[setId];
        await _saveSetMetadata(fullSetData, setDe);

        try {
          await importCardsForSet(setId, latestCmPrices, latestTcgPrices);
        } catch (e) {
          debugPrint('⚠️ Error importing cards for set $setId: $e');
        }
      }
    }
    
    onProgress?.call('✅ Sync fertig! $current Sets geladen.');
    onProgress?.call('Aktualisiere Binder-Werte...');
    await BinderService(database).recalculateAllBinders();
  }

  /// Saves or updates set metadata respecting manual override locks.
  Future<void> _saveSetMetadata(dynamic en, dynamic de) async {
    final setId = en['id'];
    
    final logoEn = en['logo'] != null ? '${en["logo"]}.png' : null;
    final logoDe = de?['logo'] != null ? '${de["logo"]}.png' : null;
    final symbol = en['symbol'] != null ? '${en["symbol"]}.png' : null;
    final String? rDate = en['releaseDate'];

    final existingSet = await (database.select(database.cardSets)..where((t) => t.id.equals(setId))).getSingleOrNull();

    drift.Value<String?> dbNameDe = de?['name'] != null ? drift.Value(de!['name']) : const drift.Value.absent();
    drift.Value<String?> dbLogoEn = logoEn != null ? drift.Value(logoEn) : const drift.Value.absent();
    drift.Value<String?> dbLogoDe = logoDe != null ? drift.Value(logoDe) : const drift.Value.absent();
    drift.Value<String?> dbSymbol = symbol != null ? drift.Value(symbol) : const drift.Value.absent();

    drift.Value<bool> dbHasManualTranslationsSet = const drift.Value.absent();
    drift.Value<bool> dbHasManualImagesSet = const drift.Value.absent();

    if (existingSet != null) {
      // 1. Translations override check
      if (existingSet.hasManualTranslations) {
        final bool apiHasRealTranslation = de?['name'] != null && de!['name'].toString().isNotEmpty && de!['name'].toString().toLowerCase() != en['name'].toString().toLowerCase();
        if (apiHasRealTranslation) {
          dbNameDe = drift.Value(de!['name']);
          dbHasManualTranslationsSet = const drift.Value(false);
        } else {
          dbNameDe = const drift.Value.absent();
        }
      } 
      // 2. Logo images override check
      if (existingSet.hasManualImages) {
        final bool apiHasRealLogo = logoEn != null && logoEn.isNotEmpty;
        if (apiHasRealLogo) {
          dbLogoEn = drift.Value(logoEn);
          dbLogoDe = logoDe != null ? drift.Value(logoDe) : const drift.Value.absent();
          dbSymbol = symbol != null ? drift.Value(symbol) : const drift.Value.absent();
          dbHasManualImagesSet = const drift.Value(false);
        } else {
          dbLogoEn = const drift.Value.absent();
          dbLogoDe = const drift.Value.absent();
          dbSymbol = const drift.Value.absent();
        }
      }
    }

    await database.into(database.cardSets).insertOnConflictUpdate(
      CardSetsCompanion(
        id: drift.Value(setId),
        name: drift.Value(en['name']),
        nameDe: dbNameDe,
        series: drift.Value(en['serie'] is Map ? en['serie']['name'] : 'Series'),
        printedTotal: drift.Value(en['cardCount']?['official'] ?? 0),
        total: drift.Value(en['cardCount']?['total'] ?? 0),
        releaseDate: rDate != null ? drift.Value(rDate) : const drift.Value.absent(),
        updatedAt: drift.Value(DateTime.now().toIso8601String()),
        logoUrl: dbLogoEn,
        logoUrlDe: dbLogoDe,
        symbolUrl: dbSymbol,
        hasManualTranslations: dbHasManualTranslationsSet,
        hasManualImages: dbHasManualImagesSet,
      )
    );
  }

  /// Reconciles duplicate placeholder card records that share the same normalized card number.
  ///
  /// Merges user collection inventory and binder slots onto official canonical card prints.
  Future<void> mergeDuplicatePlaceholderCards(String setId) async {
    // 1. Fetch all cards for this set
    final cards = await (database.select(database.cards)..where((t) => t.setId.equals(setId))).get();

    // 2. Group cards by normalized Prefix + Number + Suffix
    final Map<String, List<dynamic>> groupedCards = {};
    
    for (final card in cards) {
      final String cleanNum = card.number.split('/').first.trim();
      final match = RegExp(r'^([A-Za-z_\-]*)\s*0*(\d+)\s*([A-Za-z_\-]*)$').firstMatch(cleanNum);
      
      if (match != null) {
        final prefix = match.group(1)?.toLowerCase() ?? "";
        final numberValue = match.group(2) ?? "";
        final suffix = match.group(3)?.toLowerCase() ?? "";
        
        final key = "${prefix}_${numberValue}_$suffix";
        groupedCards.putIfAbsent(key, () => []).add(card);
      }
    }

    // 3. Consolidate duplicates onto the official card record
    for (final entry in groupedCards.entries) {
      final duplicates = entry.value;

      if (duplicates.length > 1) {
        // Official prints generally have formatted leading zeros or longer ID codes
        duplicates.sort((a, b) => (b.id as String).length.compareTo((a.id as String).length));
        
        final officialCard = duplicates.first;
        final fakeCards = duplicates.skip(1).toList();

        for (final fake in fakeCards) {
          debugPrint("Consolidating card duplicates: ${fake.id} (${fake.number}) -> ${officialCard.id} (${officialCard.number})");

          // A: Remap user inventory cards
          await (database.update(database.userCards)..where((t) => t.cardId.equals(fake.id)))
              .write(UserCardsCompanion(cardId: drift.Value(officialCard.id)));

          // B: Remap binder slots
          await (database.update(database.binderCards)..where((t) => t.cardId.equals(fake.id)))
              .write(BinderCardsCompanion(cardId: drift.Value(officialCard.id)));

          // C: Remap custom prices
          await (database.update(database.customCardPrices)..where((t) => t.cardId.equals(fake.id)))
              .write(CustomCardPricesCompanion(cardId: drift.Value(officialCard.id)));

          // D: Clean foreign key dependent prices before deleting fake card record
          await (database.delete(database.cardMarketPrices)..where((t) => t.cardId.equals(fake.id))).go();
          await (database.delete(database.tcgPlayerPrices)..where((t) => t.cardId.equals(fake.id))).go();

          // E: Delete orphaned duplicate card record
          await (database.delete(database.cards)..where((t) => t.id.equals(fake.id))).go();
        }
      }
    }
  }

  /// Imports all cards belonging to [setId] with prices in batch chunks of 200.
  Future<void> importCardsForSet(
    String setId,
    Map<String, Map<String, dynamic>> latestCmPrices,
    Map<String, Map<String, dynamic>> latestTcgPrices,
  ) async {
    final enList = await dexClient.fetchCardsOfSet(setId, lang: 'en');
    final deList = await dexClient.fetchCardsOfSet(setId, lang: 'de');
    final deMap = { for (var c in deList) c['id']: c };

    final existingCardsList = await (database.select(database.cards)..where((t) => t.setId.equals(setId))).get();
    final Map<String, Card> existingCardsMap = { for (var c in existingCardsList) c.id: c };

    const int chunkSize = 200;
    
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

    // Clean up duplicate placeholders that may have been generated by partial syncs
    await mergeDuplicatePlaceholderCards(setId);
  }

  /// Fetches card details and constructs companions for cards and price records.
  Future<_CardImportData?> _prepareCardData(
    dynamic summaryEn,
    dynamic summaryDe,
    Card? existingCard,
    Map<String, Map<String, dynamic>> latestCmPrices,
    Map<String, Map<String, dynamic>> latestTcgPrices,
  ) async {
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
    final int sortNum = int.tryParse(number) ?? 0;

    String? cardType;
    final cat = data['category']; 
    if (cat == "Trainer") {
      cardType = "Trainer";
    } else if (cat == "Energy") {
      cardType = "Energy";
    } else if (data['types'] != null && data['types'] is List && (data['types'] as List).isNotEmpty) {
      cardType = (data['types'] as List).first.toString(); 
    }

    int? cardHp;
    if (data['hp'] != null) {
      cardHp = int.tryParse(data['hp'].toString()); 
    } 

    drift.Value<String?> dbNameDe = (nameDeApi != null && nameDeApi.isNotEmpty) ? drift.Value(nameDeApi) : const drift.Value.absent();
    drift.Value<String> dbImgEn = drift.Value(finalImageEn);
    drift.Value<String?> dbImgDe = drift.Value(finalImageDe);
    drift.Value<String?> dbArtist = (artistApi != null && artistApi.isNotEmpty) ? drift.Value(artistApi) : const drift.Value.absent();
    drift.Value<String?> dbRarity = drift.Value(data['rarity']);
    drift.Value<int?> dbHp = cardHp != null ? drift.Value(cardHp) : const drift.Value.absent();
    drift.Value<String?> dbCardType = cardType != null ? drift.Value(cardType) : const drift.Value.absent();
    drift.Value<String> dbNumber = drift.Value(number);

    drift.Value<bool> dbHas1st = drift.Value(v['firstEdition'] == true);
    drift.Value<bool> dbHasNormal = drift.Value(v['normal'] == true);
    drift.Value<bool> dbHasHolo = drift.Value(v['holo'] == true);
    drift.Value<bool> dbHasRev = drift.Value(v['reverse'] == true);
    drift.Value<bool> dbHasPromo = drift.Value(v['wPromo'] == true);

    // Flags for smart update locks
    drift.Value<bool> dbHasManualTranslationsCard = const drift.Value.absent();
    drift.Value<bool> dbHasManualImagesCard = const drift.Value.absent();
    drift.Value<bool> dbHasManualStatsCard = const drift.Value.absent();

    if (existingCard != null) {
      // 1. Translations lock
      if (existingCard.hasManualTranslations) {
        final bool apiHasRealTranslation = nameDeApi != null && nameDeApi.isNotEmpty && nameDeApi.toLowerCase() != nameEn.toLowerCase();
        if (apiHasRealTranslation) {
          dbNameDe = drift.Value(nameDeApi);
          dbHasManualTranslationsCard = const drift.Value(false);
        } else {
          dbNameDe = drift.Value(existingCard.nameDe);
        }
      }
      
      // 2. Card image assets lock
      if (existingCard.hasManualImages) {
        final bool apiHasRealImage = finalImageEn.isNotEmpty;
        if (apiHasRealImage) {
          dbImgEn = drift.Value(finalImageEn);
          dbImgDe = drift.Value(finalImageDe);
          dbHasManualImagesCard = const drift.Value(false);
        } else {
          dbImgEn = drift.Value(existingCard.imageUrl);
          dbImgDe = drift.Value(existingCard.imageUrlDe);
        }
      }
      
      // 3. Metadata stats lock (artist, rarity, hp)
      if (existingCard.hasManualStats) {
        final bool apiHasRealArtist = artistApi != null && artistApi.isNotEmpty && artistApi.toLowerCase() != 'unknown' && artistApi.toLowerCase() != 'illustrator';
        if (apiHasRealArtist) {
          dbArtist = drift.Value(artistApi);
          dbHasManualStatsCard = const drift.Value(false);
        } else {
          dbArtist = drift.Value(existingCard.artist);
          dbRarity = drift.Value(existingCard.rarity);
          dbHp = drift.Value(existingCard.hp);
          dbCardType = drift.Value(existingCard.cardType);
          dbNumber = drift.Value(existingCard.number);
        }
      }
      
      // 4. Variant flags lock
      if (existingCard.hasManualVariants) {
        dbHas1st = drift.Value(existingCard.hasFirstEdition);
        dbHasNormal = drift.Value(existingCard.hasNormal);
        dbHasHolo = drift.Value(existingCard.hasHolo);
        dbHasRev = drift.Value(existingCard.hasReverse);
        dbHasPromo = drift.Value(existingCard.hasWPromo);
      }
    }

    final cardCompanion = CardsCompanion(
      id: drift.Value(cardId),
      setId: drift.Value(data['set']['id']),
      name: drift.Value(nameEn),
      sortNumber: drift.Value(sortNum),
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
      hasManualTranslations: dbHasManualTranslationsCard,
      hasManualImages: dbHasManualImagesCard,
      hasManualStats: dbHasManualStatsCard,
    );

    CardMarketPricesCompanion? cmCompanion;
    TcgPlayerPricesCompanion? tcgCompanion;
    
    if (data['pricing'] != null) {
      final now = DateTime.now();
      final pricing = data['pricing'];

      if (pricing['cardmarket'] != null) {
        final cm = pricing['cardmarket'];
        final double? newTrend = (cm['trend'] as num?)?.toDouble();
        final double? newTrendHolo = (cm['trend-holo'] as num?)?.toDouble();

        final oldCm = latestCmPrices[cardId];
        if (oldCm == null || oldCm['trend'] != newTrend || oldCm['trendHolo'] != newTrendHolo) {
          cmCompanion = CardMarketPricesCompanion.insert(
            cardId: cardId,
            fetchedAt: now,
            average: drift.Value((cm['avg'] as num?)?.toDouble()),
            low: drift.Value((cm['low'] as num?)?.toDouble()),
            trend: drift.Value(newTrend),
            avg1: drift.Value((cm['avg1'] as num?)?.toDouble()),
            avg7: drift.Value((cm['avg7'] as num?)?.toDouble()),
            avg30: drift.Value((cm['avg30'] as num?)?.toDouble()),
            avgHolo: drift.Value((cm['avg-holo'] as num?)?.toDouble()),
            lowHolo: drift.Value((cm['low-holo'] as num?)?.toDouble()),
            trendHolo: drift.Value(newTrendHolo),
            avg1Holo: drift.Value((cm['avg1-holo'] as num?)?.toDouble()),
            avg7Holo: drift.Value((cm['avg7-holo'] as num?)?.toDouble()),
            avg30Holo: drift.Value((cm['avg30-holo'] as num?)?.toDouble()),
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
            normalMarket: drift.Value(newNormMarket),
            normalLow: drift.Value((norm?['lowPrice'] as num?)?.toDouble()),
            normalMid: drift.Value((norm?['midPrice'] as num?)?.toDouble()),
            normalDirectLow: drift.Value((norm?['directLowPrice'] as num?)?.toDouble()),
            holoMarket: drift.Value(newHoloMarket),
            holoLow: drift.Value((holo?['lowPrice'] as num?)?.toDouble()),
            holoMid: drift.Value((holo?['midPrice'] as num?)?.toDouble()),
            holoDirectLow: drift.Value((holo?['directLowPrice'] as num?)?.toDouble()),
            reverseMarket: drift.Value(newRevMarket),
            reverseLow: drift.Value((rev?['lowPrice'] as num?)?.toDouble()),
            reverseMid: drift.Value((rev?['midPrice'] as num?)?.toDouble()),
            reverseDirectLow: drift.Value((rev?['directLowPrice'] as num?)?.toDouble()),
          );
        }
      }
    }

    return _CardImportData(cardCompanion, cmCompanion, tcgCompanion);
  }
}