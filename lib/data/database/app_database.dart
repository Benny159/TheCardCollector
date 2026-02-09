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
  //UserCards,         // Deine Sammlung
  //Binders,           // Deine Ordner
  //BinderEntries,     // Karten in Ordnern
  //CardLocalizations  // Falls du das noch nutzt
])
class AppDatabase extends _$AppDatabase {
  // Der Konstruktor öffnet die Verbindung
  AppDatabase() : super(_openConnection());

  // Version 3, weil wir die Struktur massiv geändert haben
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // 1. Das hier passiert beim ERSTEN Start (Tabellen anlegen)
    onCreate: (Migrator m) async {
      await m.createAll();
    },

    // 2. Das hier passiert bei UPDATES (Version erhöht)
    onUpgrade: (Migrator m, int from, int to) async {
       print('Mache Update von v$from auf v$to');
       
       // Beispiel für die Zukunft (wenn wir Version 4 machen):
       if (from < 4) {
         // Wenn wir später "Binders" hinzufügen, erstellen wir NUR diese Tabelle neu.
         // Die alten Tabellen (Cards, Sets) lassen wir in Ruhe!
         
         // await m.createTable(binders);      // <-- Kommt später
         // await m.createTable(binderEntries); // <-- Kommt später
       }
       
       // Falls du AKTUELL noch Probleme hast und wirklich alles platt machen willst,
       // kannst du diesen Block hier temporär einkommentieren. 
       // Aber standardmäßig lassen wir ihn jetzt weg!
       /*
       for (final table in allTables) {
         await m.deleteTable(table.actualTableName);
         await m.createTable(table);
       }
       */
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