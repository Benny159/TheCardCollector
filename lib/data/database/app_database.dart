import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables.dart'; 

part 'app_database.g.dart';

@DriftDatabase(tables: [Cards, CardSets, CardMarketPrices, TcgPlayerPrices, UserCards, PortfolioHistory])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // WICHTIG: Wir gehen auf 12, damit das Update auf jeden Fall ausgeführt wird!
  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    
    onUpgrade: (Migrator m, int from, int to) async {
       print('--- MIGRATION START: v$from -> v$to ---');
       
       // Dieser Block läuft, weil dein Handy < 12 ist.
       if (from < 12) {
         
         // 1. FEHLENDE SPALTE IN CARD_SETS (Das ist dein aktueller Fehler)
         try {
           await m.addColumn(cardSets, cardSets.nameDe);
           print("ERFOLG: Spalte cardSets.nameDe wurde erstellt.");
         } catch (e) {
           print("Info: cardSets.nameDe existierte vielleicht schon? Fehler: $e");
         }

         // 2. FEHLENDE SPALTEN IN CARDS (Sicherheitshalber auch prüfen)
         try {
           await m.addColumn(cards, cards.nameDe);
           print("ERFOLG: Spalte cards.nameDe wurde erstellt.");
         } catch (e) {
           print("Info: cards.nameDe existierte schon.");
         }

         try {
           await m.addColumn(cards, cards.flavorTextDe);
           print("ERFOLG: Spalte cards.flavorTextDe wurde erstellt.");
         } catch (e) {
           print("Info: cards.flavorTextDe existierte schon.");
         }

         // 3. UserCards created_at / addedAt Check
         // Falls die Spalte fehlt, legen wir sie an.
         try {
           // Prüfen wie sie in tables.dart heißt. Ich gehe von createdAt aus
           // basierend auf deinem Fehlerprotokoll.
           await m.addColumn(userCards, userCards.createdAt);
           print("ERFOLG: Spalte userCards.createdAt erstellt.");
         } catch (e) {
           print("Info: userCards.createdAt existierte schon.");
         }
         
         // 4. PortfolioHistory Tabelle
         try {
            await m.createTable(portfolioHistory);
         } catch (e) {
            print("Info: Tabelle portfolioHistory existierte schon.");
         }
       }
       
       print('--- MIGRATION ENDE ---');
    },
    
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'tcg_collector.sqlite'));
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    return NativeDatabase.createInBackground(file);
  });
}