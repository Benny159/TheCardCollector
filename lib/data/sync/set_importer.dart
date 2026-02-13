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

  SetImporter(this.apiClient, this.dexClient, this.database);

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
            updatedAt: Value(DateTime.now().toIso8601String()),
            logoUrl: Value(set.logoUrl),
            symbolUrl: Value(set.symbolUrl),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  /// 2. Importiert ein Set mit gewünschter Sprache
  /// [language] ist der Sprachcode für TCGdex (z.B. 'de' oder 'en')
  Future<void> importSet(ApiSet set, {String language = 'en'}) async {
    await importSetInfo(set);
    
    print('Starte Karten-Import für Set ${set.id} (Zusatzsprache: $language)...');
    
    // Wir holen ALLE Karten von der Haupt-API (Preise & Bilder sind hier besser)
    await apiClient.fetchAllCardsForSet(
      set.id,
      onBatchLoaded: (batchCards) async {
        // Diesen Batch verarbeiten (und ggf. mit TCGdex anreichern)
        await _processAndSaveBatch(set.id, batchCards, language);
      },
    );
    
    // Update Zeitstempel des Sets am Ende
    await (database.update(database.cardSets)..where((t) => t.id.equals(set.id))).write(
      CardSetsCompanion(updatedAt: Value(DateTime.now().toIso8601String())),
    );
  }

  /// 3. Verarbeitet einen Stapel Karten (Anreicherung + Speichern)
  Future<void> _processAndSaveBatch(String setId, List<ApiCard> cards, String lang) async {
    for (final card in cards) {
      Map<String, dynamic>? dexData;
      
      // BEDINGUNG: Wann fragen wir die zweite API?
      // 1. Wenn Sprache nicht Englisch ist (wir wollen deutsche Daten laden)
      // 2. ODER wenn der Künstler fehlt (Datenlücke schließen)
      bool needsEnrichment = lang != 'en' || (card.artist.isEmpty);

      if (needsEnrichment) {
        // TCGdex abfragen (SetID + Nummer)
        dexData = await dexClient.fetchCardDetails(setId, card.number, lang: lang);
      }

      await _saveMergedCard(card, dexData, lang);
    }
  }

  /// 4. Speichert eine einzelne Karte (Zusammengeführt aus beiden Quellen)
  Future<void> _saveMergedCard(ApiCard apiCard, Map<String, dynamic>? dexData, String requestedLang) async {
    
    // Basis-Werte (Englisch) von der Haupt-API
    String nameEn = apiCard.name;
    String artist = apiCard.artist;
    String? flavorEn = apiCard.flavorText;

    // Zusatz-Werte (Deutsch) - Standardmäßig null/leer
    String? nameDe;
    String? flavorDe;

    if (dexData != null) {
      // A) Lücken schließen (Künstler) -> Das füllen wir immer, egal welche Sprache
      if (artist.isEmpty && dexData['illustrator'] != null) {
        artist = dexData['illustrator'];
        // print('Künstler gefüllt: $artist');
      }

      // B) Deutsche Texte extrahieren (nur wenn 'de' angefordert war)
      if (requestedLang == 'de') {
        if (dexData['name'] != null) {
          nameDe = dexData['name']; 
        }
        if (dexData['description'] != null) {
          flavorDe = dexData['description'];
        }
      }
    }

    await database.transaction(() async {
      // 1) KARTE SPEICHERN (Stammdaten)
      // Wir nutzen insertOnConflictUpdate mit Value(), damit wir existierende Felder nicht
      // versehentlich mit null überschreiben, wenn wir z.B. später nur Preise updaten wollen.
      
      await database.into(database.cards).insertOnConflictUpdate(
        CardsCompanion(
          id: Value(apiCard.id),
          setId: Value(apiCard.setId),
          
          // ENGLISCH (Immer da)
          name: Value(nameEn),
          flavorText: Value(flavorEn),
          
          // DEUTSCH (Nur setzen, wenn wir Daten haben)
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

      // 2) PREISE SPEICHERN (Cardmarket - Europa)
      if (apiCard.cardmarket != null) {
        // Prüfen, ob wir für dieses Update-Datum schon einen Eintrag haben
        final existingEntry = await (database.select(database.cardMarketPrices)
              ..where((tbl) => tbl.cardId.equals(apiCard.id))
              ..where((tbl) => tbl.updatedAt.equals(apiCard.cardmarket!.updatedAt))
              ..limit(1))
            .getSingleOrNull();
        if (existingEntry == null) {
            await database.into(database.cardMarketPrices).insert(
              CardMarketPricesCompanion(
                cardId: Value(apiCard.id),
                fetchedAt: Value(DateTime.now()), // Wann haben WIR es geladen?
                updatedAt: Value(apiCard.cardmarket!.updatedAt), // Wann hat die API es aktualisiert?
                url: Value(apiCard.cardmarket!.url),
                trendPrice: Value(apiCard.cardmarket!.trendPrice),
                avg30: Value(apiCard.cardmarket!.avg30),
                lowPrice: Value(apiCard.cardmarket!.lowPrice),
                reverseHoloTrend: Value(apiCard.cardmarket!.reverseHoloTrend),
              ),
            );
          }
      }

      // 3) PREISE SPEICHERN (TCGPlayer - USA)
      if (apiCard.tcgplayer != null) {
        final tcg = apiCard.tcgplayer!;
        
        final existingEntry = await (database.select(database.tcgPlayerPrices)
              ..where((tbl) => tbl.cardId.equals(apiCard.id))
              ..where((tbl) => tbl.updatedAt.equals(tcg.updatedAt ?? ''))
              ..limit(1))
            .getSingleOrNull();

        if (existingEntry == null) {
          final prices = tcg.prices;
          // Fallback Logik für Hauptpreis (Normal -> Holo)
          final mainMarket = prices?.normal?.market ?? prices?.holofoil?.market;
          final mainLow = prices?.normal?.low ?? prices?.holofoil?.low;

          await database.into(database.tcgPlayerPrices).insert(
                  TcgPlayerPricesCompanion(
                    cardId: Value(apiCard.id),
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
    });
  }

  // --- HILFSFUNKTION FÜR DEN "FULL SYNC" BUTTON ---
  Future<void> syncAllData({Function(String status)? onProgress}) async {
    onProgress?.call('Lade Set-Liste...');
    final allSets = await apiClient.fetchAllSets();
    
    int currentSet = 1;
    
    for (final set in allSets) {
      onProgress?.call('Set $currentSet/${allSets.length}: ${set.name} wird geladen...');
      
      // Standard: Englisch importieren (schneller). 
      // Wenn du von Anfang an alles Deutsch willst, ändere 'en' zu 'de'.
      // Bedenke: 'de' verdoppelt die API-Requests und dauert länger.
      await importSet(set, language: 'de'); 
      
      currentSet++;
    }
    
    onProgress?.call('Fertig! Datenbank aktualisiert.');
  }
}