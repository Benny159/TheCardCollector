import 'package:drift/drift.dart';

// --- TABELLE 1: SETS (Stammdaten) ---
class CardSets extends Table {
  // ID ist z.B. "swsh4"
  TextColumn get id => text()(); 
  TextColumn get name => text()(); 
  TextColumn get series => text()(); 
  IntColumn get printedTotal => integer()();
  IntColumn get total => integer()();
  TextColumn get releaseDate => text()();
  TextColumn get updatedAt => text()(); // Wann hat die API das Set zuletzt aktualisiert?
  TextColumn get logoUrl => text()();
  TextColumn get symbolUrl => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- TABELLE 2: KARTEN (Stammdaten - ohne Preise!) ---
class Cards extends Table {
  // ID ist z.B. "swsh4-25"
  TextColumn get id => text()(); 
  
  // Verknüpfung zum Set (Foreign Key)
  TextColumn get setId => text().references(CardSets, #id)(); 
  
  TextColumn get name => text()(); 
  TextColumn get number => text()(); 
  
  // Bilder
  TextColumn get imageUrlSmall => text()(); 
  TextColumn get imageUrlLarge => text()(); 
  
  // Metadaten
  TextColumn get supertype => text().nullable()(); // "Pokémon"
  TextColumn get subtypes => text().nullable()(); // JSON-String: ["Stage 2"]
  TextColumn get types => text().nullable()();    // JSON-String: ["Fire"]
  TextColumn get artist => text().nullable()();
  TextColumn get rarity => text().nullable()();
  TextColumn get flavorText => text().nullable()();

  // WICHTIG: Keine Preise mehr hier! Die sind jetzt ausgelagert.

  @override
  Set<Column> get primaryKey => {id};
}

// --- TABELLE 3: CARDMARKET PREISE (Historie - Europa) ---
class CardMarketPrices extends Table {
  IntColumn get id => integer().autoIncrement()(); // Laufende Nummer
  
  // Welche Karte?
  TextColumn get cardId => text().references(Cards, #id)(); 
  
  // Wann haben WIR den Preis gespeichert? (Für den Graphen x-Achse)
  DateTimeColumn get fetchedAt => dateTime()(); 
  
  // Wann wurde der Preis bei Cardmarket aktualisiert? (Aus API)
  // Wir nutzen das, um zu prüfen, ob wir eine neue Zeile brauchen.
  TextColumn get updatedAt => text()(); 

  // Die Preise (in Euro)
  RealColumn get trendPrice => real().nullable()();
  RealColumn get avg1 => real().nullable()();     // Durchschnitt 1 Tag
  RealColumn get avg30 => real().nullable()();    // Durchschnitt 30 Tage
  RealColumn get lowPrice => real().nullable()();
  RealColumn get reverseHoloTrend => real().nullable()(); // Für Reverse Holo Graphen

  // URL zum Shop (falls man kaufen will)
  TextColumn get url => text().nullable()();
}

// --- TABELLE 4: TCGPLAYER PREISE (Historie - USA) ---
class TcgPlayerPrices extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  TextColumn get cardId => text().references(Cards, #id)(); 
  DateTimeColumn get fetchedAt => dateTime()(); 
  TextColumn get updatedAt => text()(); 

  // Preise (in Dollar) - Wir trennen Normal und Holo
  RealColumn get normalMarket => real().nullable()();
  RealColumn get normalLow => real().nullable()();
  
  RealColumn get reverseHoloMarket => real().nullable()();
  RealColumn get reverseHoloLow => real().nullable()();

  TextColumn get url => text().nullable()();
}

// ... Hier drunter bleiben deine UserCards, Binders etc. Tabellen wie vorher ...
// (Lass UserCards, Binders, BinderEntries einfach stehen)