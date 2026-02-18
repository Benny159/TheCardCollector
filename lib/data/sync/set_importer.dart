import 'package:drift/drift.dart';
import '../api/tcgdex_api_client.dart';
import '../database/app_database.dart';

// Helper Klasse um Daten zwischenzuspeichern
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

  // --- HAUPT-LOGIK: ALLE SETS + ALLE KARTEN LADEN ---
  Future<void> syncAllData({Function(String status)? onProgress}) async {
    onProgress?.call('Lade Set-Liste von TCGdex...');
    
    // 1. Alle Sets laden
    final dexSetsEn = await dexClient.fetchAllSets(lang: 'en');
    final dexSetsDe = await dexClient.fetchAllSets(lang: 'de');
    final deMap = { for (var s in dexSetsDe) s['id']: s };

    int current = 0;
    int skipped = 0;

    for (var listSet in dexSetsEn) {
      await Future.delayed(const Duration(milliseconds: 10)); // UI atmen lassen

      final setId = listSet['id'] as String;
      
      // --- POCKET FILTER (Vorab-Check) ---
      final serieData = listSet['serie'];
      final String serieId = (serieData is Map) ? serieData['id'] ?? '' : '';

      if (serieId == 'jumbo' || setId == 'xya' || setId == 'sp') {
        skipped++;
        print('⏩ Überspringe Pocket-Set: ${listSet['name']} ($setId)');
        continue; 
      }
      // ---------------------

      current++;
      final setName = listSet['name'] as String;
      
      onProgress?.call('Set $current/${dexSetsEn.length - skipped}: $setName...');
      
      // 2. Details laden (für Release Date & korrekten Serie-Check)
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
          await importCardsForSet(setId);
        } catch (e) {
          print('⚠️ Fehler bei Karten für $setId: $e');
        }
      }
    }
    
    onProgress?.call('✅ Sync fertig! $current Sets geladen.');
  }

  Future<void> _saveSetMetadata(dynamic en, dynamic de) async {
    final setId = en['id'];
    
    final logoEn = en['logo'] != null ? '${en["logo"]}.png' : null;
    final logoDe = de?['logo'] != null ? '${de["logo"]}.png' : null;
    final symbol = en['symbol'] != null ? '${en["symbol"]}.png' : null;
    final String? rDate = en['releaseDate'];

    // LOGIC: Value.absent() schützt manuelle DB-Einträge, falls API null liefert
    await database.into(database.cardSets).insertOnConflictUpdate(
      CardSetsCompanion(
        id: Value(setId),
        name: Value(en['name']),
        nameDe: Value(de?['name']), // Name DE wird meist aus API Liste genommen
        series: Value(en['serie'] is Map ? en['serie']['name'] : 'Series'),
        printedTotal: Value(en['cardCount']?['official'] ?? 0),
        total: Value(en['cardCount']?['total'] ?? 0),
        releaseDate: rDate != null ? Value(rDate) : const Value.absent(),
        updatedAt: Value(DateTime.now().toIso8601String()),
        
        // Bilder schützen: Nur überschreiben wenn API was liefert
        logoUrl: logoEn != null ? Value(logoEn) : const Value.absent(),
        logoUrlDe: logoDe != null ? Value(logoDe) : const Value.absent(),
        symbolUrl: symbol != null ? Value(symbol) : const Value.absent(),
      )
    );
  }

  // --- KARTEN IMPORT (BATCHING) ---
  Future<void> importCardsForSet(String setId) async {
    final enList = await dexClient.fetchCardsOfSet(setId, lang: 'en');
    final deList = await dexClient.fetchCardsOfSet(setId, lang: 'de');
    final deMap = { for (var c in deList) c['id']: c };

    int chunkSize = 100;
    
    for (var i = 0; i < enList.length; i += chunkSize) {
      await Future.delayed(Duration.zero);

      final end = (i + chunkSize < enList.length) ? i + chunkSize : enList.length;
      final chunk = enList.sublist(i, end);
      
      final List<_CardImportData?> results = await Future.wait(
        chunk.map((c) => _prepareCardData(c, deMap[c['id']]))
      );

      final validData = results.whereType<_CardImportData>().toList();
      if (validData.isEmpty) continue;

      await database.batch((batch) {
        batch.insertAllOnConflictUpdate(
          database.cards, 
          validData.map((d) => d.card).toList()
        );

        final cmList = validData.map((d) => d.cmPrice).whereType<CardMarketPricesCompanion>().toList();
        if (cmList.isNotEmpty) {
          batch.insertAll(database.cardMarketPrices, cmList);
        }

        final tcgList = validData.map((d) => d.tcgPrice).whereType<TcgPlayerPricesCompanion>().toList();
        if (tcgList.isNotEmpty) {
          batch.insertAll(database.tcgPlayerPrices, tcgList);
        }
      });
    }
  }

Future<_CardImportData?> _prepareCardData(dynamic summaryEn, dynamic summaryDe) async {
    final cardId = summaryEn['id'];
    
    // Wir laden EN Details
    final data = await dexClient.fetchCardDetails(cardId, lang: 'en');
    if (data == null) return null;

    final nameEn = data['name'] ?? 'Unknown';
    final String? nameDeApi = summaryDe?['name']; 

    // --- BILD LOGIK (ROBUST) ---
    String imageEn = data['image'] ?? summaryEn['image'] ?? '';
    // API Fix: Manchmal fehlt die Endung
    if (imageEn.isNotEmpty && !imageEn.endsWith('.png')) imageEn += '/high.png';

    String imageDe = summaryDe?['image'] ?? '';
    if (imageDe.isNotEmpty && !imageDe.endsWith('.png')) imageDe += '/high.png';

    // Sicherstellen, dass wir gültige Strings haben
    final bool hasEn = imageEn.isNotEmpty;
    final bool hasDe = imageDe.isNotEmpty;

    // 1. Englisches Feld füllen (Prio: EN -> DE -> Leer)
    // Wir dürfen NIEMALS Value.absent() senden, da die DB "NOT NULL" ist.
    final String finalImageEn = hasEn ? imageEn : (hasDe ? imageDe : '');

    // 2. Deutsches Feld füllen (Prio: DE -> EN -> Leer)
    final String finalImageDe = hasDe ? imageDe : (hasEn ? imageEn : '');
    // ---------------------------

    final String? artistApi = data['illustrator'];
    final v = data['variants'] ?? {};
    final number = data['localId'] ?? '0';
    int sortNum = int.tryParse(number) ?? 0;

    final cardCompanion = CardsCompanion(
        id: Value(cardId),
        setId: Value(data['set']['id']),
        name: Value(nameEn),
        number: Value(number),
        sortNumber: Value(sortNum),
        
        nameDe: (nameDeApi != null && nameDeApi.isNotEmpty) ? Value(nameDeApi) : const Value.absent(),
        artist: (artistApi != null && artistApi.isNotEmpty) ? Value(artistApi) : const Value.absent(),
        
        // --- FIX: Immer Value() senden, niemals Value.absent() für Bilder ---
        imageUrl: Value(finalImageEn),
        imageUrlDe: Value(finalImageDe),
        // -------------------------------------------------------------------
        
        rarity: Value(data['rarity']),
        hasFirstEdition: Value(v['firstEdition'] == true),
        hasNormal: Value(v['normal'] == true),
        hasHolo: Value(v['holo'] == true),
        hasReverse: Value(v['reverse'] == true),
        hasWPromo: Value(v['wPromo'] == true),
    );
    CardMarketPricesCompanion? cmCompanion;
    TcgPlayerPricesCompanion? tcgCompanion;
    
    if (data['pricing'] != null) {
      final now = DateTime.now();
      final pricing = data['pricing'];

      if (pricing['cardmarket'] != null) {
        final cm = pricing['cardmarket'];
        cmCompanion = CardMarketPricesCompanion.insert(
          cardId: cardId,
          fetchedAt: now,
          average: Value((cm['avg'] as num?)?.toDouble()),
          low: Value((cm['low'] as num?)?.toDouble()),
          trend: Value((cm['trend'] as num?)?.toDouble()),
          avg1: Value((cm['avg1'] as num?)?.toDouble()),
          avg7: Value((cm['avg7'] as num?)?.toDouble()),
          avg30: Value((cm['avg30'] as num?)?.toDouble()),
          avgHolo: Value((cm['avg-holo'] as num?)?.toDouble()),
          lowHolo: Value((cm['low-holo'] as num?)?.toDouble()),
          trendHolo: Value((cm['trend-holo'] as num?)?.toDouble()),
          avg1Holo: Value((cm['avg1-holo'] as num?)?.toDouble()),
          avg7Holo: Value((cm['avg7-holo'] as num?)?.toDouble()),
          avg30Holo: Value((cm['avg30-holo'] as num?)?.toDouble()),
        );
      }

      if (pricing['tcgplayer'] != null) {
        final tcg = pricing['tcgplayer'];
        final norm = tcg['normal'];
        final holo = tcg['holofoil'];
        final rev = tcg['reverse-holofoil'];

        tcgCompanion = TcgPlayerPricesCompanion.insert(
          cardId: cardId,
          fetchedAt: now,
          normalMarket: Value((norm?['marketPrice'] as num?)?.toDouble()),
          normalLow: Value((norm?['lowPrice'] as num?)?.toDouble()),
          normalMid: Value((norm?['midPrice'] as num?)?.toDouble()),
          normalDirectLow: Value((norm?['directLowPrice'] as num?)?.toDouble()),
          holoMarket: Value((holo?['marketPrice'] as num?)?.toDouble()),
          holoLow: Value((holo?['lowPrice'] as num?)?.toDouble()),
          holoMid: Value((holo?['midPrice'] as num?)?.toDouble()),
          holoDirectLow: Value((holo?['directLowPrice'] as num?)?.toDouble()),
          reverseMarket: Value((rev?['marketPrice'] as num?)?.toDouble()),
          reverseLow: Value((rev?['lowPrice'] as num?)?.toDouble()),
          reverseMid: Value((rev?['midPrice'] as num?)?.toDouble()),
          reverseDirectLow: Value((rev?['directLowPrice'] as num?)?.toDouble()),
        );
      }
    }

    return _CardImportData(cardCompanion, cmCompanion, tcgCompanion);
  }
}