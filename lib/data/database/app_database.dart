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
  CustomCardPrices,
  CardMarketPrices, 
  TcgPlayerPrices, 
  PortfolioHistory,
  Binders,
  BinderCards,
  BinderHistory,
  Pokedex
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Wir springen auf Version 41
  @override
  int get schemaVersion => 41; 

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // --- NEU: Version 41 ---
        if (from < 41) {
          await m.addColumn(cards, cards.preferredPriceSource);
          await m.createTable(customCardPrices);
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