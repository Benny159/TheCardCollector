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
  Pokedex,
  SetMappings // <--- NEU HINZUGEFÜGT
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Wir springen auf Version 43 für die Schutzschilde und den Scanner
  @override
  int get schemaVersion => 43; 

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // ... (Deine bisherigen Migrationsschritte bleiben hier!) ...
        
        // --- Version 42 ---
        if (from < 42) {
          await m.addColumn(userCards, userCards.customPrice);
          await m.addColumn(userCards, userCards.gradingCompany);
          await m.addColumn(userCards, userCards.gradingScore);
          await m.addColumn(binderCards, binderCards.userCardId);
        }

        // --- NEU: Version 43 (Schutzschilde, HP & Mapper) ---
        // --- NEU: Version 43 (Schutzschilde, HP & Mapper) ---
        if (from < 43) {
          // 1. Die neue Tabelle für API-Mappings erstellen
          await m.createTable(setMappings);

          // 2. HP für den Scanner in die Karten-Tabelle
          await m.addColumn(cards, cards.hp);

          // 3. Die Schutzschilde für die Karten-Tabelle
          await m.addColumn(cards, cards.hasManualVariants);
          await m.addColumn(cards, cards.hasManualImages);
          await m.addColumn(cards, cards.hasManualTranslations);
          await m.addColumn(cards, cards.hasManualStats);

          // 4. Die Schutzschilde für die Set-Tabelle
          await m.addColumn(cardSets, cardSets.hasManualTranslations);
          await m.addColumn(cardSets, cardSets.hasManualImages);
          
          // --- HIER! Wir zwingen Drift, die fehlenden Indizes zu bauen! ---
          await m.createIndex(Index('idx_cards_setid', 'CREATE INDEX idx_cards_setid ON cards (set_id)'));
          await m.createIndex(Index('idx_cmprices_cardid', 'CREATE INDEX idx_cmprices_cardid ON card_market_prices (card_id)'));
          await m.createIndex(Index('idx_tcgprices_cardid', 'CREATE INDEX idx_tcgprices_cardid ON tcg_player_prices (card_id)'));
          await m.createIndex(Index('idx_usercards_cardid', 'CREATE INDEX idx_usercards_cardid ON user_cards (card_id)'));
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