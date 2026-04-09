import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../database/app_database.dart';
import '../../domain/logic/binder_service.dart';

class PtcgImporter {
  final AppDatabase db;
  final String apiKey = '5941f408-9f09-4b60-9000-6726e7156816';

  PtcgImporter(this.db);

  Future<void> syncMissingData({Function(String status)? onProgress}) async {
    onProgress?.call('Lade Mappings aus der Datenbank...');
    final mappings = await (db.select(db.setMappings)..where((t) => t.ptcgId.isNotNull())).get();

    onProgress?.call('Lade Preis-Cache für smarten Sync...');
    final allLatestCmQuery = await db.customSelect(
      'SELECT card_id, trend, trend_holo, trend_reverse FROM card_market_prices GROUP BY card_id HAVING MAX(fetched_at)'
    ).get();
    final Map<String, Map<String, dynamic>> latestCmPrices = {
      for (var row in allLatestCmQuery) row.read<String>('card_id'): {
        'trend': row.read<double?>('trend'),
        'trendHolo': row.read<double?>('trend_holo'),
        'trendReverse': row.read<double?>('trend_reverse'),
      }
    };

    final allLatestTcgQuery = await db.customSelect(
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
    for (var mapping in mappings) {
      current++;
      final tcgdexId = mapping.tcgdexId;
      final ptcgId = mapping.ptcgId!;
      final cmCode = mapping.cardmarketCode; // <--- NEU: Wir holen den Code!

      onProgress?.call('Lückenfüller Set $current/${mappings.length}: $tcgdexId...');

      try {
        await _importPtcgSet(tcgdexId, ptcgId, cmCode, latestCmPrices, latestTcgPrices);
      } catch (e) {
        print('⚠️ Fehler bei PTCG Set $ptcgId: $e');
      }
    }

    onProgress?.call('✅ Deep-Sync abgeschlossen!');
    await BinderService(db).recalculateAllBinders();
  }

  Future<void> _importPtcgSet(String tcgdexId, String ptcgId, String? cmCode, Map<String, Map<String, dynamic>> latestCmPrices, Map<String, Map<String, dynamic>> latestTcgPrices) async {
    
    final existingSet = await (db.select(db.cardSets)..where((t) => t.id.equals(tcgdexId))).getSingleOrNull();
    
    // Wir brauchen die PTCG API, wenn das Set fehlt ODER wenn das Logo fehlt!
    bool needsSetInsert = existingSet == null;
    bool needsLogoUpdate = existingSet != null && !existingSet.hasManualImages && (existingSet.logoUrl == null || existingSet.logoUrl!.isEmpty);

    if (needsSetInsert || needsLogoUpdate) {
       final setUrl = Uri.parse('https://api.pokemontcg.io/v2/sets/$ptcgId');
       final setRes = await http.get(setUrl, headers: {'X-Api-Key': apiKey});
       
       if (setRes.statusCode == 200) {
          final setData = jsonDecode(setRes.body)['data'];
          final fetchedLogo = setData['images']?['logo'];
          final fetchedSymbol = setData['images']?['symbol'];

          if (needsSetInsert) {
            // Set komplett neu anlegen
            await db.into(db.cardSets).insert(CardSetsCompanion.insert(
              id: tcgdexId,
              name: setData['name'] ?? ptcgId,
              series: setData['series'] ?? 'Unknown',
              printedTotal: Value(setData['printedTotal']),
              total: Value(setData['total']),
              releaseDate: Value(setData['releaseDate']),
              updatedAt: DateTime.now().toIso8601String(),
              logoUrl: Value(fetchedLogo),
              symbolUrl: Value(fetchedSymbol),
            ));
          } else if (needsLogoUpdate) {
            // Lückenfüller: Nur das fehlende Logo & Symbol updaten!
            await (db.update(db.cardSets)..where((t) => t.id.equals(tcgdexId))).write(
              CardSetsCompanion(
                logoUrl: Value(fetchedLogo),
                symbolUrl: (existingSet.symbolUrl == null || existingSet.symbolUrl!.isEmpty) ? Value(fetchedSymbol) : const Value.absent(),
              )
            );
          }
       } else if (needsSetInsert) {
         return; // Abbruch, wenn das Set komplett neu wäre, aber die API fehlschlägt
       }
    }

    List<dynamic> allPtcgCards = [];
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final url = Uri.parse('https://api.pokemontcg.io/v2/cards?q=set.id:$ptcgId&page=$page&pageSize=250');
      final response = await http.get(url, headers: {'X-Api-Key': apiKey});
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cards = data['data'] as List;
        allPtcgCards.addAll(cards);
        
        if (cards.length < 250) {
          hasMore = false;
        } else {
          page++;
        }
      } else {
        hasMore = false;
      }
    }

    if (allPtcgCards.isEmpty) return;

    final existingCardsList = await (db.select(db.cards)..where((t) => t.setId.equals(tcgdexId))).get();

    final List<CardsCompanion> cardsToInsert = [];
    final List<CardMarketPricesCompanion> cmCompanions = [];
    final List<TcgPlayerPricesCompanion> tcgCompanions = [];
    
    final now = DateTime.now();

    for (var ptcgCard in allPtcgCards) {
      final ptcgNumberRaw = ptcgCard['number'].toString();
      final ptcgNumClean = ptcgNumberRaw.replaceAll(RegExp(r'^0+'), ''); 
      final ptcgName = ptcgCard['name'].toString().trim();

      Card? existingCard;

      // 1. Lokale Suche im zugewiesenen Set
      try {
        existingCard = existingCardsList.firstWhere((c) {
          final dbNumClean = c.number.replaceAll(RegExp(r'^0+'), '').toLowerCase();
          final ptClean = ptcgNumClean.toLowerCase();
          return dbNumClean == ptClean || c.number.toLowerCase() == ptcgNumberRaw.toLowerCase();
        });
      } catch (_) {}

      // --- DER SUPER-FILTER: Globale Suche, aber NUR innerhalb der gleichen Set-Familie! ---
      if (existingCard == null && cmCode != null && cmCode.isNotEmpty) {
         // Wir finden alle Set-IDs (z.B. swsh12.5), die ebenfalls den Code 'CRZ' haben
         final relatedMappings = await (db.select(db.setMappings)..where((t) => t.cardmarketCode.equals(cmCode))).get();
         final relatedSetIds = relatedMappings.map((m) => m.tcgdexId).toList();
         
         if (relatedSetIds.isNotEmpty) {
             final fallbackCards = await (db.select(db.cards)
                // Die Karte MUSS denselben Namen haben UND das Set muss in der Familie sein
                ..where((t) => t.name.equals(ptcgName) & t.setId.isIn(relatedSetIds))
             ).get();

             try {
                existingCard = fallbackCards.firstWhere((c) {
                   final dbNumClean = c.number.replaceAll(RegExp(r'^0+'), '').toLowerCase();
                   final ptClean = ptcgNumClean.toLowerCase();
                   return dbNumClean == ptClean || c.number.toLowerCase() == ptcgNumberRaw.toLowerCase();
                });
             } catch (_) {}
         }
      }
      // --------------------------------------------------------------------------------------

      final String finalCardId = existingCard?.id ?? "$tcgdexId-$ptcgNumberRaw";
      String img = ptcgCard['images']?['large'] ?? ptcgCard['images']?['small'] ?? '';

      if (existingCard != null) {
        // FALL 1: KARTE WURDE GEFUNDEN (Lokal oder im Schwester-Set)
        if (!existingCard.hasManualImages && existingCard.imageUrl.isEmpty && img.isNotEmpty) {
           try {
             await db.customUpdate(
               'UPDATE cards SET image_url = ? WHERE id = ?',
               variables: [Variable.withString(img), Variable.withString(finalCardId)]
             );
           } catch (_) {} 
        }
      } else {
        // FALL 2: KARTE EXISTIERT NIRGENDWO -> WIRD NEU ANGELEGT
        int sortNum = int.tryParse(ptcgNumberRaw) ?? 0;
        int? hp = ptcgCard['hp'] != null ? int.tryParse(ptcgCard['hp'].toString()) : null;
        String? cType = (ptcgCard['types'] as List?)?.first?.toString();
        
        final tcgPrices = ptcgCard['tcgplayer']?['prices'];
        bool hasRev = tcgPrices?['reverseHolofoil'] != null;
        bool hasHolo = tcgPrices?['holofoil'] != null || (ptcgCard['rarity']?.toString().contains('Holo') ?? false);
        bool hasNormal = tcgPrices?['normal'] != null || (!hasRev && !hasHolo);
        bool has1st = tcgPrices?['1stEditionHolofoil'] != null || tcgPrices?['1stEditionNormal'] != null;

        cardsToInsert.add(CardsCompanion.insert(
            id: finalCardId,
            setId: tcgdexId,
            name: ptcgName,
            number: ptcgNumberRaw,
            imageUrl: img,
            sortNumber: Value(sortNum),
            hp: Value(hp),
            cardType: Value(cType),
            artist: Value(ptcgCard['artist']),
            rarity: Value(ptcgCard['rarity']),
            hasNormal: Value(hasNormal),
            hasReverse: Value(hasRev),
            hasHolo: Value(hasHolo),
            hasFirstEdition: Value(has1st),
        ));
      }

      // --- PREISE (STRENGER LÜCKENFÜLLER) ---
      if (ptcgCard['cardmarket'] != null) {
        final cm = ptcgCard['cardmarket']['prices'];
        if (cm != null) {
          final oldCm = latestCmPrices[finalCardId];
          
          // FIX: Er greift NUR ein, wenn es noch absolut gar keinen Preis (oldCm == null) gibt!
          if (oldCm == null) {
            cmCompanions.add(CardMarketPricesCompanion.insert(
              cardId: finalCardId,
              fetchedAt: now,
              average: Value((cm['averageSellPrice'] as num?)?.toDouble()),
              low: Value((cm['lowPrice'] as num?)?.toDouble()),
              trend: Value((cm['trendPrice'] as num?)?.toDouble()),
              avg1: Value((cm['avg1'] as num?)?.toDouble()),
              avg7: Value((cm['avg7'] as num?)?.toDouble()),
              avg30: Value((cm['avg30'] as num?)?.toDouble()),
              trendReverse: Value((cm['reverseHoloTrend'] as num?)?.toDouble()),
              url: Value(ptcgCard['cardmarket']['url']), 
            ));
          }
        }
      }

      if (ptcgCard['tcgplayer'] != null) {
        final tcg = ptcgCard['tcgplayer']['prices'];
        if (tcg != null) {
          final oldTcg = latestTcgPrices[finalCardId];
          
          // FIX: Auch hier: TCGPlayer Preise von PTCG nur nehmen, wenn TCGdex versagt hat!
          if (oldTcg == null) {
            final norm = tcg['normal'];
            final holo = tcg['holofoil'];
            final rev = tcg['reverseHolofoil'];

            tcgCompanions.add(TcgPlayerPricesCompanion.insert(
              cardId: finalCardId,
              fetchedAt: now,
              normalMarket: Value((norm?['market'] as num?)?.toDouble()),
              normalLow: Value((norm?['low'] as num?)?.toDouble()),
              normalMid: Value((norm?['mid'] as num?)?.toDouble()),
              normalDirectLow: Value((norm?['directLow'] as num?)?.toDouble()),
              holoMarket: Value((holo?['market'] as num?)?.toDouble()),
              holoLow: Value((holo?['low'] as num?)?.toDouble()),
              holoMid: Value((holo?['mid'] as num?)?.toDouble()),
              holoDirectLow: Value((holo?['directLow'] as num?)?.toDouble()),
              reverseMarket: Value((rev?['market'] as num?)?.toDouble()),
              reverseLow: Value((rev?['low'] as num?)?.toDouble()),
              reverseMid: Value((rev?['mid'] as num?)?.toDouble()),
              reverseDirectLow: Value((rev?['directLow'] as num?)?.toDouble()),
              url: Value(ptcgCard['tcgplayer']['url']),
            ));
          }
        }
      }
    }

    await db.batch((batch) {
      if (cardsToInsert.isNotEmpty) batch.insertAll(db.cards, cardsToInsert, mode: InsertMode.insertOrIgnore);
      if (cmCompanions.isNotEmpty) batch.insertAll(db.cardMarketPrices, cmCompanions);
      if (tcgCompanions.isNotEmpty) batch.insertAll(db.tcgPlayerPrices, tcgCompanions);
    });
  }
}