import 'package:drift/drift.dart';

/// Database table representing Pokémon TCG expansion sets.
///
/// Stores metadata including release dates, card totals, logo and symbol URLs,
/// and localization attributes for English and German releases.
class CardSets extends Table {
  /// Unique identifier of the expansion set (e.g. 'swsh1', 'sv01').
  TextColumn get id => text()(); 

  /// English name of the expansion set.
  TextColumn get name => text()(); 

  /// Super-series the set belongs to (e.g. 'Sword & Shield', 'Scarlet & Violet').
  TextColumn get series => text()(); 

  /// Number of cards officially printed in the main numbered set list.
  IntColumn get printedTotal => integer().nullable()();

  /// Total number of cards including secret rares.
  IntColumn get total => integer().nullable()();

  /// Official release date string formatted as YYYY-MM-DD.
  TextColumn get releaseDate => text().nullable()(); 

  /// Timestamp string when this set's metadata was last synchronized.
  TextColumn get updatedAt => text()();
  
  /// Remote URL for the English set logo.
  TextColumn get logoUrl => text().nullable()();   

  /// Remote URL for the expansion symbol vector/PNG.
  TextColumn get symbolUrl => text().nullable()();

  /// Remote URL for the localized German set logo.
  TextColumn get logoUrlDe => text().nullable()(); 

  /// Localized German set name.
  TextColumn get nameDe => text().nullable()();

  /// Flag indicating whether custom manual translations were provided.
  BoolColumn get hasManualTranslations => boolean().withDefault(const Constant(false))();

  /// Flag indicating whether custom manual image URLs were provided.
  BoolColumn get hasManualImages => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Database table representing individual Pokémon card prints.
///
/// Stores core statistics, print variants, illustrator, rarity, and image assets.
@TableIndex(name: 'idx_cards_setid', columns: {#setId})
class Cards extends Table {
  /// Unique card identifier across the database (e.g. 'swsh1-1').
  TextColumn get id => text()(); 

  /// Foreign key referencing the parent [CardSets.id].
  TextColumn get setId => text().references(CardSets, #id)(); 

  /// English card name.
  TextColumn get name => text()(); 

  /// Localized German card name.
  TextColumn get nameDe => text().nullable()(); 

  /// Printed card number within the set (e.g. '001/202' or '1').
  TextColumn get number => text()(); 

  /// Supertype classification (e.g. 'Pokémon', 'Trainer', 'Energy').
  TextColumn get cardType => text().nullable()();

  /// Base hit points of the Pokémon card print.
  IntColumn get hp => integer().nullable()(); 

  /// Preferred valuation source: 'cardmarket', 'tcgplayer', or 'custom'.
  TextColumn get preferredPriceSource => text().withDefault(const Constant('cardmarket'))();
  
  /// High-resolution remote image URL.
  TextColumn get imageUrl => text()();    

  /// Localized German card print image URL, if available.
  TextColumn get imageUrlDe => text().nullable()(); 
  
  /// Card illustrator name.
  TextColumn get artist => text().nullable()();

  /// Rarity tier (e.g. 'Common', 'Rare Holo', 'Ultra Rare', 'Illustration Rare').
  TextColumn get rarity => text().nullable()();

  /// English flavor text / Pokédex entry snippet.
  TextColumn get flavorText => text().nullable()();

  /// German flavor text snippet.
  TextColumn get flavorTextDe => text().nullable()();

  /// Whether this card was published with a 1st Edition stamp.
  BoolColumn get hasFirstEdition => boolean().withDefault(const Constant(false))();

  /// Whether this card print exists as a standard non-foil variant.
  BoolColumn get hasNormal => boolean().withDefault(const Constant(true))();

  /// Whether this card print exists as a regular holographic foil.
  BoolColumn get hasHolo => boolean().withDefault(const Constant(false))();

  /// Whether this card print exists as a reverse holographic foil.
  BoolColumn get hasReverse => boolean().withDefault(const Constant(false))();

  /// Whether this card print exists with a W Promo stamp.
  BoolColumn get hasWPromo => boolean().withDefault(const Constant(false))();

  /// Flags indicating user customizations and manual overrides.
  BoolColumn get hasManualVariants => boolean().withDefault(const Constant(false))();
  BoolColumn get hasManualImages => boolean().withDefault(const Constant(false))();
  BoolColumn get hasManualTranslations => boolean().withDefault(const Constant(false))();
  BoolColumn get hasManualStats => boolean().withDefault(const Constant(false))();

  /// Numeric sorting index for proper sequential ordering within sets.
  IntColumn get sortNumber => integer().withDefault(const Constant(0))(); 

  @override
  Set<Column> get primaryKey => {id};
}

/// External API mapping table for cross-platform set identifiers.
class SetMappings extends Table {
  /// Canonical TCGdex set identifier.
  TextColumn get tcgdexId => text()(); 

  /// Corresponding Pokémon TCG Developer API set code.
  TextColumn get ptcgId => text().nullable()(); 

  /// Corresponding CardMarket expansion code for web links.
  TextColumn get cardmarketCode => text().nullable()(); 
  
  @override
  Set<Column> get primaryKey => {tcgdexId};
}

/// Table storing user-assigned custom price overrides for specific cards.
class CustomCardPrices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cardId => text().references(Cards, #id)();
  DateTimeColumn get fetchedAt => dateTime()();
  RealColumn get price => real()();
}

/// Historical CardMarket market price tracking table.
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

/// Historical TCGPlayer market price tracking table.
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

/// Physical collection inventory entries owned by the user.
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

/// Daily portfolio valuation snapshots for the entire collection.
class PortfolioHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get totalValue => real()();
}

/// Physical binder and bulk storage box container configurations.
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

/// Daily valuation history points per physical binder.
class BinderHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get binderId => integer().references(Binders, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  RealColumn get value => real()();
}

/// Slot placements within a binder or bulk storage box.
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

/// National Pokédex registry linking species IDs with English and German names.
class Pokedex extends Table {
  IntColumn get id => integer()(); 
  TextColumn get name => text()(); 
  TextColumn get nameDe => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}