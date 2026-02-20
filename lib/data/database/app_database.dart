import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables.dart'; 

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Cards, 
  CardSets, 
  UserCards, 
  CardMarketPrices, 
  TcgPlayerPrices, 
  PortfolioHistory,
  // NEU:
  Binders,
  BinderCards,
  BinderHistory,
  Pokedex
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Wir springen auf Version 20 für den "Hard Reset"
  @override
  int get schemaVersion => 37; 

@override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 35) {
          await m.addColumn(binderCards, binderCards.variant);
          await m.addColumn(binders, binders.totalValue);
          await m.createTable(binderHistory);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
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