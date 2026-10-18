import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart' show rootBundle;

import 'tables.dart'; 

part 'app_database.g.dart';

/// Central Drift SQLite database managing relational data across sets, cards, binders, and prices.
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
  SetMappings,
])
class AppDatabase extends _$AppDatabase {
  /// Opens the background isolate connection to the local database file.
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 44; 

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Schema migrations
        if (from < 42) {
          await m.addColumn(userCards, userCards.customPrice);
          await m.addColumn(userCards, userCards.gradingCompany);
          await m.addColumn(userCards, userCards.gradingScore);
          await m.addColumn(binderCards, binderCards.userCardId);
        }

        if (from < 43) {
          await m.createTable(setMappings);
          await m.addColumn(cards, cards.hp);
          await m.addColumn(cards, cards.hasManualVariants);
          await m.addColumn(cards, cards.hasManualImages);
          await m.addColumn(cards, cards.hasManualTranslations);
          await m.addColumn(cards, cards.hasManualStats);
          await m.addColumn(cardSets, cardSets.hasManualTranslations);
          await m.addColumn(cardSets, cardSets.hasManualImages);
          
          await m.createIndex(Index('idx_cards_setid', 'CREATE INDEX idx_cards_setid ON cards (set_id)'));
          await m.createIndex(Index('idx_cmprices_cardid', 'CREATE INDEX idx_cmprices_cardid ON card_market_prices (card_id)'));
          await m.createIndex(Index('idx_tcgprices_cardid', 'CREATE INDEX idx_tcgprices_cardid ON tcg_player_prices (card_id)'));
          await m.createIndex(Index('idx_usercards_cardid', 'CREATE INDEX idx_usercards_cardid ON user_cards (card_id)'));
        }

        if (from < 44) {
          await m.addColumn(pokedex, pokedex.nameDe);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON;');
        await customStatement('PRAGMA journal_mode = WAL;');
        await customStatement('PRAGMA synchronous = NORMAL;');
        await customStatement('PRAGMA cache_size = -64000;');
        await customStatement('PRAGMA temp_store = MEMORY;');
        await customStatement('PRAGMA mmap_size = 268435456;');

        // Critical performance indexes (applied safely if missing)
        await customStatement('CREATE INDEX IF NOT EXISTS idx_binder_cards_sort ON binder_cards(binder_id, page_index, slot_index);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_binder_cards_cardid ON binder_cards(card_id);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_binder_cards_usercardid ON binder_cards(user_card_id);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_cmprices_card_date ON card_market_prices(card_id, fetched_at DESC);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_tcgprices_card_date ON tcg_player_prices(card_id, fetched_at DESC);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_customprices_card_date ON custom_card_prices(card_id, fetched_at DESC);');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'tcg_collector.sqlite'));

    // Copy bundled asset database on initial clean launch if missing
    if (!await file.exists()) {
      debugPrint('📦 No local database file found. Copying pre-filled database from assets...');
      try {
        final blob = await rootBundle.load('assets/db/tcg_collector.sqlite');
        final buffer = blob.buffer;
        
        await file.writeAsBytes(buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes));
        debugPrint('✅ Pre-filled database copied to device storage successfully.');
      } catch (e) {
        debugPrint('❌ Error copying asset database: $e');
      }
    } else {
      debugPrint('✅ Existing local database found.');
    }

    return NativeDatabase.createInBackground(file);
  });
}