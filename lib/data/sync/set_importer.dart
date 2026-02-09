import 'package:drift/drift.dart';
import '../../domain/models/api_card.dart';
import '../../domain/models/api_set.dart';
import '../api/tcg_api_client.dart';
import '../database/app_database.dart';

class SetImporter {
  final TcgApiClient apiClient;
  final AppDatabase database;

  SetImporter(this.apiClient, this.database);

  /// 1. Importiert die Basis-Infos des Sets (Name, Logo, ReleaseDate)
  Future<void> importSetInfo(ApiSet set) async {
    print('Speichere Set-Infos für ${set.name}...');
    await database.into(database.cardSets).insert(
          CardSetsCompanion(
            id: Value(set.id),
            name: Value(set.name),
            series: Value(set.series),
            printedTotal: Value(set.printedTotal),
            total: Value(set.total),
            releaseDate: Value(set.releaseDate),
            // Wir speichern einfach das aktuelle Datum als "zuletzt aktualisiert"
            updatedAt: Value(DateTime.now().toString()),
            logoUrl: Value(set.logoUrl),
            symbolUrl: Value(set.symbolUrl),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  /// 2. Startet den Download aller Karten für dieses Set
  Future<void> importCardsForSet(String setId) async {
    print('Starte Karten-Import für Set $setId...');
    
    // Wir nutzen unsere "unendliche" API-Methode mit Callback
    await apiClient.fetchAllCardsForSet(
      setId,
      onBatchLoaded: (batchCards) async {
        // Sobald 10 Karten da sind, speichern wir sie sofort
        await _saveBatch(batchCards);
      },
    );
  }

  /// 3. Speichert einen Stapel Karten und prüft die Preise
  Future<void> _saveBatch(List<ApiCard> cards) async {
    await database.transaction(() async {
      for (final card in cards) {
        // A) KARTE SPEICHERN (Nur Stammdaten)
        await database.into(database.cards).insert(
              CardsCompanion(
                id: Value(card.id),
                setId: Value(card.setId),
                name: Value(card.name),
                number: Value(card.number),
                imageUrlSmall: Value(card.smallImageUrl),
                imageUrlLarge: Value(card.largeImageUrl),
                artist: Value(card.artist),
                rarity: Value(card.rarity),
                flavorText: Value(card.flavorText),
                // Listen als String speichern (z.B. "Fire, Water")
                supertype: Value(card.supertype),
                subtypes: Value(card.subtypes.join(', ')),
                types: Value(card.types.join(', ')),
              ),
              mode: InsertMode.insertOrReplace,
            );

        // B) PREIS-CHECK: CARDMARKET (Europa)
        if (card.cardmarket != null) {
          // Wir prüfen: Haben wir für DIESE Karte und DIESES Update-Datum schon einen Eintrag?
          final existingEntry = await (database.select(database.cardMarketPrices)
                ..where((tbl) => tbl.cardId.equals(card.id))
                ..where((tbl) => tbl.updatedAt.equals(card.cardmarket!.updatedAt))
                ..limit(1))
              .getSingleOrNull();

          // Wenn nein: Neue Zeile anlegen (Historie wächst)
          if (existingEntry == null) {
            await database.into(database.cardMarketPrices).insert(
                  CardMarketPricesCompanion(
                    cardId: Value(card.id),
                    fetchedAt: Value(DateTime.now()), // Wann haben WIR es geladen?
                    updatedAt: Value(card.cardmarket!.updatedAt), // Wann hat die API es aktualisiert?
                    url: Value(card.cardmarket!.url),
                    trendPrice: Value(card.cardmarket!.trendPrice),
                    avg30: Value(card.cardmarket!.avg30),
                    lowPrice: Value(card.cardmarket!.lowPrice),
                    reverseHoloTrend: Value(card.cardmarket!.reverseHoloTrend),
                  ),
                );
          }
        }

        // C) PREIS-CHECK: TCGPLAYER (USA)
        // Wir arbeiten hier mit dem OBJEKT 'card.tcgplayer', nicht mit JSON!
        if (card.tcgplayer != null) {
          final tcg = card.tcgplayer!;
          
          final existingEntry = await (database.select(database.tcgPlayerPrices)
                ..where((tbl) => tbl.cardId.equals(card.id))
                ..where((tbl) => tbl.updatedAt.equals(tcg.updatedAt ?? ''))
                ..limit(1))
              .getSingleOrNull();

          if (existingEntry == null) {
            // HIER IST DEINE LOGIK (Normal vs Holofoil Fallback):
            final prices = tcg.prices;
            
            // Wenn "normal" null ist, versuchen wir "holofoil" zu nehmen
            final mainMarket = prices?.normal?.market ?? prices?.holofoil?.market;
            final mainLow = prices?.normal?.low ?? prices?.holofoil?.low;

            await database.into(database.tcgPlayerPrices).insert(
                  TcgPlayerPricesCompanion(
                    cardId: Value(card.id),
                    fetchedAt: Value(DateTime.now()),
                    updatedAt: Value(tcg.updatedAt ?? ''),
                    url: Value(tcg.url),
                    
                    // Normale Preise (oder Holo Fallback)
                    normalMarket: Value(mainMarket),
                    normalLow: Value(mainLow),
                    
                    // Reverse Holo Preise
                    reverseHoloMarket: Value(prices?.reverseHolofoil?.market),
                    reverseHoloLow: Value(prices?.reverseHolofoil?.low),
                  ),
                );
          }
        }
      }
    });
  }

  Future<void> importSet(ApiSet set) async {
    await importSetInfo(set);
    await importCardsForSet(set.id);
  }

  Future<void> syncAllData({Function(String status)? onProgress}) async {
    // 1. Alle Sets holen
    onProgress?.call('Lade Set-Liste...');
    final allSets = await apiClient.fetchAllSets();
    
    int currentSet = 1;
    
    // 2. Jedes Set durchgehen
    for (final set in allSets) {
      onProgress?.call('Set ${currentSet}/${allSets.length}: ${set.name} wird geladen...');
      
      // A) Set Infos speichern
      await importSetInfo(set);

      // B) Karten speichern (Die Endlos-Schleife regelt Fehler automatisch!)
      await importCardsForSet(set.id);
      
      currentSet++;
    }
    
    onProgress?.call('Fertig! Die komplette Datenbank ist jetzt lokal.');
  }
}