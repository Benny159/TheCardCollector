import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

// Importiere deine Tabellen-Definitionen
import 'tables.dart';

// WICHTIG: Das hier verknüpft den generierten Code
part 'app_database.g.dart';

// HIER IST DIE ÄNDERUNG: Wir müssen ALLE Tabellen anmelden!
@DriftDatabase(tables: [
  Cards, 
  CardSets,          // Neu: Für die Sets
  CardMarketPrices,  // Neu: Für Cardmarket Preise
  TcgPlayerPrices,   // Neu: Für TCGPlayer Preise
  UserCards,         // Deine Sammlung
  PortfolioHistory   // Historie des Portfolios (für den Graphen)
  //Binders,           // Deine Ordner
  //BinderEntries,     // Karten in Ordnern
  //CardLocalizations  // Falls du das noch nutzt
])
class AppDatabase extends _$AppDatabase {
  // Der Konstruktor öffnet die Verbindung
  AppDatabase() : super(_openConnection());

  // Version 3, weil wir die Struktur massiv geändert haben
  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // 1. Das hier passiert beim ERSTEN Start (Tabellen anlegen)
    onCreate: (Migrator m) async {
      await m.createAll();
    },

    // 2. Das hier passiert bei UPDATES (Version erhöht)
    onUpgrade: (Migrator m, int from, int to) async {
       print('--- MIGRATION START: v$from -> v$to ---');
       
       // Wenn die App Version kleiner als 7 ist (was sie ist, da sie 6 ist),
       // wird dieser Block ausgeführt.
       if (from < 7) {
         try {
           // 1. Versuchen, die neue Tabelle zu erstellen
           await m.createTable(portfolioHistory);
           print("Tabelle 'portfolioHistory' erfolgreich erstellt.");
         } catch (e) {
           print("Warnung: Tabelle 'portfolioHistory' existierte vielleicht schon? Fehler: $e");
         }
         print('--- MIGRATION ENDE ---');
       }
    },
    
    // 3. Wichtig: Fremdschlüssel aktivieren (für Verknüpfungen)
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

// Diese Funktion kümmert sich darum, wo die Datei auf dem Handy/PC liegt
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // 1. Ordner finden (Dokumente-Ordner der App)
    final dbFolder = await getApplicationDocumentsDirectory();
    
    // 2. Dateinamen festlegen
    final file = File(p.join(dbFolder.path, 'tcg_collector.sqlite'));

    // 3. Fix für ältere Android-Versionen
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    // 4. Datenbank im Hintergrund öffnen
    return NativeDatabase.createInBackground(file);
  });
}