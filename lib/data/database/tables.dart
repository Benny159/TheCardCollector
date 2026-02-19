import 'package:drift/drift.dart';

// --- TABELLE 1: SETS ---
class CardSets extends Table {
  TextColumn get id => text()(); // Wir nutzen jetzt TCGdex IDs (z.B. "me02.5")
  TextColumn get name => text()(); 
  TextColumn get series => text()(); 
  IntColumn get printedTotal => integer().nullable()();
  IntColumn get total => integer().nullable()();
  TextColumn get releaseDate => text().nullable()(); // Kommt von der ALTEN API
  TextColumn get updatedAt => text()();
  
  // BILDER: Auch für Sets speichern wir beide!
  TextColumn get logoUrl => text().nullable()();   // Englisch
  TextColumn get symbolUrl => text().nullable()();
  TextColumn get logoUrlDe => text().nullable()(); // <--- NEU: Deutsch
  TextColumn get nameDe => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- TABELLE 2: KARTEN ---
class Cards extends Table {
  TextColumn get id => text()(); 
  TextColumn get setId => text().references(CardSets, #id)(); 
  TextColumn get name => text()(); 
  TextColumn get nameDe => text().nullable()(); 
  TextColumn get number => text()(); 
  
  // BILDER: Beide Sprachen
  TextColumn get imageUrl => text()();    // Englisch
  TextColumn get imageUrlDe => text().nullable()(); // <--- NEU: Deutsch
  
  TextColumn get artist => text().nullable()();
  TextColumn get rarity => text().nullable()();
  TextColumn get flavorText => text().nullable()();
  TextColumn get flavorTextDe => text().nullable()();

  // VARIANTEN FLAGS
  BoolColumn get hasFirstEdition => boolean().withDefault(const Constant(false))();
  BoolColumn get hasNormal => boolean().withDefault(const Constant(true))();
  BoolColumn get hasHolo => boolean().withDefault(const Constant(false))();
  BoolColumn get hasReverse => boolean().withDefault(const Constant(false))();
  BoolColumn get hasWPromo => boolean().withDefault(const Constant(false))();

  // Sortier-Hilfe
  IntColumn get sortNumber => integer().withDefault(const Constant(0))(); 

  @override
  Set<Column> get primaryKey => {id};
}

// --- TABELLE 3: CARDMARKET PREISE (EUR) ---
class CardMarketPrices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cardId => text().references(Cards, #id)(); 
  DateTimeColumn get fetchedAt => dateTime()(); 
  
  // Normal
  RealColumn get average => real().nullable()();
  RealColumn get low => real().nullable()();
  RealColumn get trend => real().nullable()();
  RealColumn get avg1 => real().nullable()();
  RealColumn get avg7 => real().nullable()();
  RealColumn get avg30 => real().nullable()();
  
  // Holo
  RealColumn get avgHolo => real().nullable()();
  RealColumn get lowHolo => real().nullable()();
  RealColumn get trendHolo => real().nullable()();
  RealColumn get avg1Holo => real().nullable()();
  RealColumn get avg7Holo => real().nullable()();
  RealColumn get avg30Holo => real().nullable()();
  
  // Reverse Holo
  RealColumn get trendReverse => real().nullable()();

  TextColumn get url => text().nullable()();
}

// --- TABELLE 4: TCGPLAYER PREISE (USD) ---
class TcgPlayerPrices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cardId => text().references(Cards, #id)(); 
  DateTimeColumn get fetchedAt => dateTime()(); 
  
  // --- Normal ---
  RealColumn get normalMarket => real().nullable()();
  RealColumn get normalLow => real().nullable()();
  RealColumn get normalMid => real().nullable()();
  RealColumn get normalDirectLow => real().nullable()();
  
  // --- Holo ---
  RealColumn get holoMarket => real().nullable()();
  RealColumn get holoLow => real().nullable()();
  RealColumn get holoMid => real().nullable()();
  RealColumn get holoDirectLow => real().nullable()();
  
  // --- Reverse Holo ---
  RealColumn get reverseMarket => real().nullable()();
  RealColumn get reverseLow => real().nullable()();
  RealColumn get reverseMid => real().nullable()();
  RealColumn get reverseDirectLow => real().nullable()();
  
  TextColumn get url => text().nullable()();
}

// --- TABELLE 5: USER CARDS ---
class UserCards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cardId => text().references(Cards, #id)();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get condition => text().withDefault(const Constant('NM'))();
  TextColumn get language => text().withDefault(const Constant('Deutsch'))();
  TextColumn get variant => text().withDefault(const Constant('Normal'))(); 
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// --- TABELLE 6: PORTFOLIO HISTORIE ---
class PortfolioHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get totalValue => real()();
}

// --- NEUE TABELLE: BINDER (Mappen) ---
class Binders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  
  // Design
  IntColumn get color => integer()(); // Speichert Color.value (ARGB)
  TextColumn get icon => text().nullable()(); // z.B. Icon Name oder Pfad
  
  // Layout Konfiguration
  IntColumn get rowsPerPage => integer().withDefault(const Constant(3))(); // Standard 3x3
  IntColumn get columnsPerPage => integer().withDefault(const Constant(3))();
  
  // Typ / Thema
  // 'custom', 'nationalDex', 'set:sv1', 'pokemon:pikachu'
  TextColumn get type => text().withDefault(const Constant('custom'))(); 
  // Wir speichern es als Text ('leftToRight' oder 'topToBottom')
  TextColumn get sortOrder => text().withDefault(const Constant('leftToRight'))();
  
  RealColumn get totalValue => real().withDefault(const Constant(0.0))();

  // Metadaten
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

class BinderHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get binderId => integer().references(Binders, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  RealColumn get value => real()();
}

// --- NEUE TABELLE: KARTEN IM BINDER ---
@DataClassName('BinderCard')
class BinderCards extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  // Verknüpfung zum Binder
  IntColumn get binderId => integer().references(Binders, #id, onDelete: KeyAction.cascade)();
  
  // Position
  IntColumn get pageIndex => integer()(); // Seite 0, 1, 2...
  IntColumn get slotIndex => integer()(); // Slot 0 bis (rows*cols)-1
  
  // Inhalt (Kann eine echte Karte sein ODER ein Platzhalter)
  TextColumn get cardId => text().nullable().references(Cards, #id)();
  
  // Falls es ein Platzhalter ist (z.B. für National Dex Planung, aber Karte fehlt noch)
  BoolColumn get isPlaceholder => boolean().withDefault(const Constant(false))();
  TextColumn get placeholderLabel => text().nullable()(); // z.B. "Glurak #006"
  TextColumn get variant => text().nullable()();
}

class Pokedex extends Table {
  // Wir nutzen keine auto-increment ID, sondern die echte Pokedex Nummer als ID
  IntColumn get id => integer()(); 
  TextColumn get name => text()(); // "Bulbasaur" (oder Deutsch, wenn wir ne Quelle finden)
  
  @override
  Set<Column> get primaryKey => {id};
}