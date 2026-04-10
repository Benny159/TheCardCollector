import 'package:drift/drift.dart';

// --- TABELLE 1: SETS ---
class CardSets extends Table {
  TextColumn get id => text()(); 
  TextColumn get name => text()(); 
  TextColumn get series => text()(); 
  IntColumn get printedTotal => integer().nullable()();
  IntColumn get total => integer().nullable()();
  TextColumn get releaseDate => text().nullable()(); 
  TextColumn get updatedAt => text()();
  
  TextColumn get logoUrl => text().nullable()();   
  TextColumn get symbolUrl => text().nullable()();
  TextColumn get logoUrlDe => text().nullable()(); 
  TextColumn get nameDe => text().nullable()();

  BoolColumn get hasManualTranslations => boolean().withDefault(const Constant(false))();
  BoolColumn get hasManualImages => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// --- TABELLE 2: KARTEN ---
@TableIndex(name: 'idx_cards_setid', columns: {#setId})
class Cards extends Table {
  TextColumn get id => text()(); 
  TextColumn get setId => text().references(CardSets, #id)(); 
  TextColumn get name => text()(); 
  TextColumn get nameDe => text().nullable()(); 
  TextColumn get number => text()(); 
  TextColumn get cardType => text().nullable()();

  IntColumn get hp => integer().nullable()(); 

  TextColumn get preferredPriceSource => text().withDefault(const Constant('cardmarket'))();
  
  TextColumn get imageUrl => text()();    
  TextColumn get imageUrlDe => text().nullable()(); 
  
  TextColumn get artist => text().nullable()();
  TextColumn get rarity => text().nullable()();
  TextColumn get flavorText => text().nullable()();
  TextColumn get flavorTextDe => text().nullable()();

  BoolColumn get hasFirstEdition => boolean().withDefault(const Constant(false))();
  BoolColumn get hasNormal => boolean().withDefault(const Constant(true))();
  BoolColumn get hasHolo => boolean().withDefault(const Constant(false))();
  BoolColumn get hasReverse => boolean().withDefault(const Constant(false))();
  BoolColumn get hasWPromo => boolean().withDefault(const Constant(false))();

  BoolColumn get hasManualVariants => boolean().withDefault(const Constant(false))();
  BoolColumn get hasManualImages => boolean().withDefault(const Constant(false))();
  BoolColumn get hasManualTranslations => boolean().withDefault(const Constant(false))();
  BoolColumn get hasManualStats => boolean().withDefault(const Constant(false))();

  IntColumn get sortNumber => integer().withDefault(const Constant(0))(); 

  @override
  Set<Column> get primaryKey => {id};
}

class SetMappings extends Table {
  TextColumn get tcgdexId => text()(); 
  TextColumn get ptcgId => text().nullable()(); 
  TextColumn get cardmarketCode => text().nullable()(); 
  
  @override
  Set<Column> get primaryKey => {tcgdexId};
}

class CustomCardPrices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cardId => text().references(Cards, #id)();
  DateTimeColumn get fetchedAt => dateTime()();
  RealColumn get price => real()();
}

// --- TABELLE 3: CARDMARKET PREISE ---
@TableIndex(name: 'idx_cmprices_cardid', columns: {#cardId})
class CardMarketPrices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cardId => text().references(Cards, #id)(); 
  DateTimeColumn get fetchedAt => dateTime()(); 
  
  RealColumn get average => real().nullable()();
  RealColumn get low => real().nullable()();
  RealColumn get trend => real().nullable()();
  RealColumn get avg1 => real().nullable()();
  RealColumn get avg7 => real().nullable()();
  RealColumn get avg30 => real().nullable()();
  
  RealColumn get avgHolo => real().nullable()();
  RealColumn get lowHolo => real().nullable()();
  RealColumn get trendHolo => real().nullable()();
  RealColumn get avg1Holo => real().nullable()();
  RealColumn get avg7Holo => real().nullable()();
  RealColumn get avg30Holo => real().nullable()();
  
  RealColumn get trendReverse => real().nullable()();

  TextColumn get url => text().nullable()();
}

// --- TABELLE 4: TCGPLAYER PREISE ---
@TableIndex(name: 'idx_tcgprices_cardid', columns: {#cardId})
class TcgPlayerPrices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cardId => text().references(Cards, #id)(); 
  DateTimeColumn get fetchedAt => dateTime()(); 
  
  RealColumn get normalMarket => real().nullable()();
  RealColumn get normalLow => real().nullable()();
  RealColumn get normalMid => real().nullable()();
  RealColumn get normalDirectLow => real().nullable()();
  
  RealColumn get holoMarket => real().nullable()();
  RealColumn get holoLow => real().nullable()();
  RealColumn get holoMid => real().nullable()();
  RealColumn get holoDirectLow => real().nullable()();
  
  RealColumn get reverseMarket => real().nullable()();
  RealColumn get reverseLow => real().nullable()();
  RealColumn get reverseMid => real().nullable()();
  RealColumn get reverseDirectLow => real().nullable()();
  
  TextColumn get url => text().nullable()();
}

// --- TABELLE 5: USER CARDS ---
@TableIndex(name: 'idx_usercards_cardid', columns: {#cardId})
class UserCards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cardId => text().references(Cards, #id)();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get condition => text().withDefault(const Constant('NM'))();
  TextColumn get language => text().withDefault(const Constant('Deutsch'))();
  TextColumn get variant => text().withDefault(const Constant('Normal'))(); 
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  RealColumn get customPrice => real().nullable()();
  TextColumn get gradingCompany => text().nullable()();
  TextColumn get gradingScore => text().nullable()();
}

class PortfolioHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get totalValue => real()();
}

class Binders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  
  IntColumn get color => integer()(); 
  TextColumn get icon => text().nullable()(); 
  
  IntColumn get rowsPerPage => integer().withDefault(const Constant(3))(); 
  IntColumn get columnsPerPage => integer().withDefault(const Constant(3))();
  
  TextColumn get type => text().withDefault(const Constant('custom'))(); 
  TextColumn get sortOrder => text().withDefault(const Constant('leftToRight'))();
  
  RealColumn get totalValue => real().withDefault(const Constant(0.0))();

  BoolColumn get isFull => boolean().withDefault(const Constant(false))();

  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

class BinderHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get binderId => integer().references(Binders, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  RealColumn get value => real()();
}

@DataClassName('BinderCard')
@TableIndex(name: 'binder_cards_binder_idx', columns: {#binderId})
class BinderCards extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get binderId => integer().references(Binders, #id, onDelete: KeyAction.cascade)();
  IntColumn get pageIndex => integer()();
  IntColumn get slotIndex => integer()();
  TextColumn get cardId => text().nullable().references(Cards, #id)();
  BoolColumn get isPlaceholder => boolean().withDefault(const Constant(false))();
  TextColumn get placeholderLabel => text().nullable()(); 
  TextColumn get variant => text().nullable()();
  IntColumn get userCardId => integer().nullable()(); 
}

class Pokedex extends Table {
  IntColumn get id => integer()(); 
  TextColumn get name => text()(); 
  TextColumn get nameDe => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}