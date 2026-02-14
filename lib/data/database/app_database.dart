import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables.dart'; 

part 'app_database.g.dart';

@DriftDatabase(tables: [Cards, CardSets, CardMarketPrices, TcgPlayerPrices, UserCards, PortfolioHistory])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Wir springen auf Version 20 für den "Hard Reset"
  @override
  int get schemaVersion => 23; 

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
       print('--- HARD RESET: Datenbank wird neu aufgebaut (v$from -> v$to) ---');
       
       // RADIKALE METHODE: Alles löschen!
       // Das garantiert, dass wir keine Konflikte mit alten Spalten haben.
       for (final table in allTables) {
         await m.deleteTable(table.actualTableName);
       }
       
       // Alles neu erstellen
       await m.createAll();
       print('--- HARD RESET ERFOLGREICH ---');
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