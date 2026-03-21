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

  // Wir springen auf Version 42
  @override
  int get schemaVersion => 42; 

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // ... (Deine bisherigen Migrationsschritte bis 41 bleiben hier stehen!) ...
        
        // --- NEU: Version 42 ---
        if (from < 42) {
          await m.addColumn(userCards, userCards.customPrice);
          await m.addColumn(userCards, userCards.gradingCompany);
          await m.addColumn(userCards, userCards.gradingScore);
          await m.addColumn(binderCards, binderCards.userCardId);
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