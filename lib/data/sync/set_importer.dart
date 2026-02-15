import 'package:drift/drift.dart';
import '../api/tcgdex_api_client.dart';
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

  // --- HAUPT-LOGIK: ALLE SETS + ALLE KARTEN LADEN ---
  Future<void> syncAllData({Function(String status)? onProgress}) async {
    onProgress?.call('Lade Set-Liste von TCGdex...');
    
    // 1. Alle Sets laden (Basis-Liste)
    final dexSetsEn = await dexClient.fetchAllSets(lang: 'en');
    final dexSetsDe = await dexClient.fetchAllSets(lang: 'de');
    final deMap = { for (var s in dexSetsDe) s['id']: s };

    int current = 0;
    int skipped = 0;

    for (var listSet in dexSetsEn) {
      await Future.delayed(const Duration(milliseconds: 10));
      final setId = listSet['id'] as String;

      current++;
      final setName = listSet['name'] as String;
      
      onProgress?.call('Set $current/${dexSetsEn.length - skipped}: $setName - Lade Details & Datum...');
      
      // --- NEU: DETAILS LADEN (FÜR RELEASE DATE) ---
      // Wir holen das volle Set-Objekt, da das Listen-Objekt oft kein Datum hat.
      final fullSetData = await dexClient.fetchSet(setId);
      
      if (fullSetData != null) {
        // --- POCKET FILTER ---
        final serieData = fullSetData['serie'];
        final String serieId = (serieData is Map) ? serieData['id'] ?? '' : '';

        if (serieId == 'tcgp') {
          skipped++;
          current--; // Zähler korrigieren, da wir es doch nicht nehmen
          print('⏩ Überspringe Pocket-Set (Serie-Check): $setName ($setId)');
          continue; // ABBRUCH FÜR DIESES SET!
        }
        // ---------------------------
        final setDe = deMap[setId];
        
        // Metadaten speichern (inklusive Datum!)
        await _saveSetMetadata(fullSetData, setDe);

        // Karten laden
        onProgress?.call('Set $current: $setName - Lade Karten & Preise...');
        try {
          await importCardsForSet(setId);
        } catch (e) {
          print('⚠️ Fehler bei Karten für $setId: $e');
        }
      }
    }
    
    onProgress?.call('✅ Sync fertig! $current Sets geladen ($skipped Pocket-Sets ignoriert).');
  }

  Future<void> _saveSetMetadata(dynamic en, dynamic de) async {
    final setId = en['id'];
    
    // BILDER
    final logoEn = en['logo'] != null ? '${en["logo"]}.png' : null;
    final logoDe = de?['logo'] != null ? '${de["logo"]}.png' : null;
    final symbol = en['symbol'] != null ? '${en["symbol"]}.png' : null;

    // DATUM (Hier ist es!)
    final String? rDate = en['releaseDate'];

    await database.into(database.cardSets).insertOnConflictUpdate(
      CardSetsCompanion(
        id: Value(setId),
        name: Value(en['name']),
        nameDe: Value(de?['name']),
        series: Value(en['serie'] is Map ? en['serie']['name'] : 'Series'),
        printedTotal: Value(en['cardCount']?['official'] ?? 0),
        total: Value(en['cardCount']?['total'] ?? 0),
        // JETZT MIT DATUM:
        releaseDate: rDate != null ? Value(rDate) : const Value.absent(),
        updatedAt: Value(DateTime.now().toIso8601String()),
        logoUrl: Value(logoEn),
        logoUrlDe: Value(logoDe),
        symbolUrl: Value(symbol),
      )
    );
  }

  // --- KARTEN IMPORTIEREN ---
  Future<void> importCardsForSet(String setId) async {
    // Hier nutzen wir fetchCardsOfSet, das (laut meiner Ergänzung im Client)
    // direkt die Kartenliste zurückgibt.
    final enList = await dexClient.fetchCardsOfSet(setId, lang: 'en');
    final deList = await dexClient.fetchCardsOfSet(setId, lang: 'de');
    final deMap = { for (var c in deList) c['id']: c };

    // Batch Processing
    int chunkSize = 20;
    for (var i = 0; i < enList.length; i += chunkSize) {
      await Future.delayed(Duration.zero);
      final end = (i + chunkSize < enList.length) ? i + chunkSize : enList.length;
      final chunk = enList.sublist(i, end);
      // 1. Parallel Daten laden (Netzwerk)
      final List<_CardImportData?> results = await Future.wait(
        chunk.map((c) => _prepareCardData(c, deMap[c['id']]))
      );

      // Null-Werte (Fehler) filtern
      final validData = results.whereType<_CardImportData>().toList();
      if (validData.isEmpty) continue;

      // 2. Alles in EINER Transaktion speichern (Datenbank)
      // Das ist der Performance-Boost! Statt 20x Insert machen wir 1x Batch.
      await database.batch((batch) {
        // Karten einfügen/updaten
        batch.insertAllOnConflictUpdate(
          database.cards, 
          validData.map((d) => d.card).toList()
        );

        // Preise einfügen (nur neue Zeilen)
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
    
    final data = await dexClient.fetchCardDetails(cardId, lang: 'en');
    if (data == null) return null;

    final nameEn = data['name'] ?? 'Unknown';
    final nameDe = summaryDe?['name']; 

    String imageEn = data['image'] ?? summaryEn['image'] ?? '';
    if (imageEn.isNotEmpty && !imageEn.endsWith('.png')) imageEn += '/high.png';

    // Bild-Logik Fix (damit Null auch Null bleibt)
    String? imageDe = summaryDe?['image'];
    if (imageDe != null && imageDe.isNotEmpty) {
       if (!imageDe.endsWith('.png')) imageDe += '/high.png';
    } else {
       imageDe = null; 
    }

    final v = data['variants'] ?? {};
    final number = data['localId'] ?? '0';
    int sortNum = int.tryParse(number) ?? 0;

    // Karte vorbereiten
    final cardCompanion = CardsCompanion(
        id: Value(cardId),
        setId: Value(data['set']['id']),
        name: Value(nameEn),
        nameDe: Value(nameDe),
        number: Value(number),
        sortNumber: Value(sortNum),
        imageUrl: Value(imageEn),
        imageUrlDe: Value(imageDe),
        artist: Value(data['illustrator']),
        rarity: Value(data['rarity']),
        hasFirstEdition: Value(v['firstEdition'] == true),
        hasNormal: Value(v['normal'] == true),
        hasHolo: Value(v['holo'] == true),
        hasReverse: Value(v['reverse'] == true),
        hasWPromo: Value(v['wPromo'] == true),
    );

    // Preise vorbereiten
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

  Future<void> _fetchAndSaveCard(dynamic summaryEn, dynamic summaryDe) async {
    final cardId = summaryEn['id'];
    final data = await dexClient.fetchCardDetails(cardId, lang: 'en');
    if (data == null) return;

    final nameEn = data['name'] ?? 'Unknown';
    final nameDe = summaryDe?['name']; 

    String imageEn = data['image'] ?? summaryEn['image'] ?? '';
    if (imageEn.isNotEmpty && !imageEn.endsWith('.png')) imageEn += '/high.png';

    String imageDe = summaryDe?['image'] ?? '';
    if (imageDe.isNotEmpty && !imageDe.endsWith('.png')) imageDe += '/high.png';

    final v = data['variants'] ?? {};
    final number = data['localId'] ?? '0';
    int sortNum = int.tryParse(number) ?? 0;

    await database.into(database.cards).insertOnConflictUpdate(
      CardsCompanion(
        id: Value(cardId),
        setId: Value(data['set']['id']),
        name: Value(nameEn),
        nameDe: Value(nameDe),
        number: Value(number),
        sortNumber: Value(sortNum),
        imageUrl: Value(imageEn),
        imageUrlDe: Value(imageDe),
        artist: Value(data['illustrator']),
        rarity: Value(data['rarity']),
        hasFirstEdition: Value(v['firstEdition'] == true),
        hasNormal: Value(v['normal'] == true),
        hasHolo: Value(v['holo'] == true),
        hasReverse: Value(v['reverse'] == true),
        hasWPromo: Value(v['wPromo'] == true),
      )
    );

    if (data['pricing'] != null) {
      await _savePrices(cardId, data['pricing']);
    }
  }

  Future<void> _savePrices(String cardId, dynamic pricing) async {
    final now = DateTime.now();

    // 1. Cardmarket (EUR)
    if (pricing['cardmarket'] != null) {
      final cm = pricing['cardmarket'];
      await database.into(database.cardMarketPrices).insert(
        CardMarketPricesCompanion.insert(
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
        )
      );
    }

    // 2. TCGPlayer (USD)
    if (pricing['tcgplayer'] != null) {
      final tcg = pricing['tcgplayer'];
      final norm = tcg['normal'];
      final holo = tcg['holofoil'];
      final rev = tcg['reverse-holofoil'];

      await database.into(database.tcgPlayerPrices).insert(
        TcgPlayerPricesCompanion.insert(
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
        )
      );
    }
  }
}