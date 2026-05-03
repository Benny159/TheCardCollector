import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart' show rootBundle;

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

  // Wir springen auf Version 44 für das Übersetzungs-Wörterbuch
  @override
  int get schemaVersion => 44; 

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

        // --- Version 43 (Schutzschilde, HP & Mapper) ---
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

        // --- NEU: Version 44 (Deutscher Pokedex) ---
        if (from < 44) {
          await m.addColumn(pokedex, pokedex.nameDe);
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
    // Wo soll die Datenbank auf dem Handy gespeichert werden?
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'tcg_collector.sqlite'));

    // --- DER WICHTIGE TEIL: PRE-FILLED DB KOPIEREN ---
    if (!await file.exists()) {
      print('📦 Keine lokale Datenbank gefunden. Kopiere Pre-filled DB aus Assets...');
      try {
        // Lade die Datei aus den Assets in den Zwischenspeicher
        final blob = await rootBundle.load('assets/db/tcg_collector.sqlite');
        final buffer = blob.buffer;
        
        // Schreibe die Datei auf den Handy-Speicher
        await file.writeAsBytes(buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes));
        print('✅ Pre-filled Datenbank erfolgreich auf das Gerät kopiert!');
      } catch (e) {
        print('❌ Fehler beim Kopieren der Asset-Datenbank: $e');
        // Falls die Datei im Asset-Ordner fehlt, baut Drift einfach eine leere auf.
      }
    } else {
      print('✅ Lokale Datenbank gefunden. Nutze bestehende Daten.');
    }
    // -------------------------------------------------

    // Öffne die Datenbank
    return NativeDatabase.createInBackground(file);
  });
}