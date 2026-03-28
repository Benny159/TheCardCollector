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

      onProgress?.call('Lückenfüller Set $current/${mappings.length}: $tcgdexId...');

      try {
        await _importPtcgSet(tcgdexId, ptcgId, latestCmPrices, latestTcgPrices);
      } catch (e) {
        print('⚠️ Fehler bei PTCG Set $ptcgId: $e');
      }
    }

    onProgress?.call('✅ Deep-Sync abgeschlossen!');
    await BinderService(db).recalculateAllBinders();
  }

  Future<void> _importPtcgSet(String tcgdexId, String ptcgId, Map<String, Map<String, dynamic>> latestCmPrices, Map<String, Map<String, dynamic>> latestTcgPrices) async {
    
    final existingSet = await (db.select(db.cardSets)..where((t) => t.id.equals(tcgdexId))).getSingleOrNull();
    if (existingSet == null) {
       final setUrl = Uri.parse('https://api.pokemontcg.io/v2/sets/$ptcgId');
       final setRes = await http.get(setUrl, headers: {'X-Api-Key': apiKey});
       if (setRes.statusCode == 200) {
          final setData = jsonDecode(setRes.body)['data'];
          await db.into(db.cardSets).insert(CardSetsCompanion.insert(
            id: tcgdexId,
            name: setData['name'] ?? ptcgId,
            series: setData['series'] ?? 'Unknown',
            printedTotal: Value(setData['printedTotal']),
            total: Value(setData['total']),
            releaseDate: Value(setData['releaseDate']),
            updatedAt: DateTime.now().toIso8601String(),
            logoUrl: Value(setData['images']?['logo']),
            symbolUrl: Value(setData['images']?['symbol']),
          ));
       } else {
         return; 
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

      // 1. Lokale Suche im aktuell zugewiesenen Set
      try {
        existingCard = existingCardsList.firstWhere((c) {
          final dbNumClean = c.number.replaceAll(RegExp(r'^0+'), '').toLowerCase();
          final ptClean = ptcgNumClean.toLowerCase();
          return dbNumClean == ptClean || c.number.toLowerCase() == ptcgNumberRaw.toLowerCase();
        });
      } catch (_) {}

      // --- NEU: 2. Globale Suche in der gesamten Datenbank! ---
      // Verhindert zu 100% Duplikate bei TG/GG Karten aus Hauptsets
      if (existingCard == null) {
         final fallbackCards = await (db.select(db.cards)
            ..where((t) => t.name.equals(ptcgName))
         ).get();

         try {
            existingCard = fallbackCards.firstWhere((c) {
               final dbNumClean = c.number.replaceAll(RegExp(r'^0+'), '').toLowerCase();
               final ptClean = ptcgNumClean.toLowerCase();
               return dbNumClean == ptClean || c.number.toLowerCase() == ptcgNumberRaw.toLowerCase();
            });
         } catch (_) {}
      }
      // ---------------------------------------------------------

      // Wenn wir die Karte global gefunden haben, nutzen wir IHRE ID.
      // Wenn nicht, wird sie als komplett neue Karte angelegt.
      final String finalCardId = existingCard?.id ?? "$tcgdexId-$ptcgNumberRaw";
      String img = ptcgCard['images']?['large'] ?? ptcgCard['images']?['small'] ?? '';

      if (existingCard != null) {
        // FALL 1: KARTE EXISTIERT BEREITS (Auch in anderen Sets gefunden!)
        if (!existingCard.hasManualImages && existingCard.imageUrl.isEmpty && img.isNotEmpty) {
           try {
             await db.customUpdate(
               'UPDATE cards SET image_url = ? WHERE id = ?',
               variables: [Variable.withString(img), Variable.withString(finalCardId)]
             );
           } catch (_) {} 
        }
      } else {
        // FALL 2: KARTE EXISTIERT NOCH NICHT (Z.B. Perfect Order oder reine Promos)
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

      // --- PREISE IMMER AN DIE RICHTIGE KARTE HÄNGEN ---
      if (ptcgCard['cardmarket'] != null) {
        final cm = ptcgCard['cardmarket']['prices'];
        if (cm != null) {
          double? newTrend = (cm['trendPrice'] as num?)?.toDouble();
          double? newRevTrend = (cm['reverseHoloTrend'] as num?)?.toDouble();

          final oldCm = latestCmPrices[finalCardId];
          if (oldCm == null || oldCm['trend'] != newTrend || oldCm['trendReverse'] != newRevTrend) {
            cmCompanions.add(CardMarketPricesCompanion.insert(
              cardId: finalCardId,
              fetchedAt: now,
              average: Value((cm['averageSellPrice'] as num?)?.toDouble()),
              low: Value((cm['lowPrice'] as num?)?.toDouble()),
              trend: Value(newTrend),
              avg1: Value((cm['avg1'] as num?)?.toDouble()),
              avg7: Value((cm['avg7'] as num?)?.toDouble()),
              avg30: Value((cm['avg30'] as num?)?.toDouble()),
              trendReverse: Value(newRevTrend),
              url: Value(ptcgCard['cardmarket']['url']), 
            ));
          }
        }
      }

      if (ptcgCard['tcgplayer'] != null) {
        final tcg = ptcgCard['tcgplayer']['prices'];
        if (tcg != null) {
          final norm = tcg['normal'];
          final holo = tcg['holofoil'];
          final rev = tcg['reverseHolofoil'];

          final double? newNormMarket = (norm?['market'] as num?)?.toDouble();
          final double? newHoloMarket = (holo?['market'] as num?)?.toDouble();
          final double? newRevMarket = (rev?['market'] as num?)?.toDouble();

          final oldTcg = latestTcgPrices[finalCardId];
          if (oldTcg == null || oldTcg['normalMarket'] != newNormMarket || oldTcg['holoMarket'] != newHoloMarket || oldTcg['reverseMarket'] != newRevMarket) {
            tcgCompanions.add(TcgPlayerPricesCompanion.insert(
              cardId: finalCardId,
              fetchedAt: now,
              normalMarket: Value(newNormMarket),
              normalLow: Value((norm?['low'] as num?)?.toDouble()),
              normalMid: Value((norm?['mid'] as num?)?.toDouble()),
              normalDirectLow: Value((norm?['directLow'] as num?)?.toDouble()),
              holoMarket: Value(newHoloMarket),
              holoLow: Value((holo?['low'] as num?)?.toDouble()),
              holoMid: Value((holo?['mid'] as num?)?.toDouble()),
              holoDirectLow: Value((holo?['directLow'] as num?)?.toDouble()),
              reverseMarket: Value(newRevMarket),
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