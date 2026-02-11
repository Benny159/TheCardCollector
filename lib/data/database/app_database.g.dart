// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CardSetsTable extends CardSets with TableInfo<$CardSetsTable, CardSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _seriesMeta = const VerificationMeta('series');
  @override
  late final GeneratedColumn<String> series = GeneratedColumn<String>(
      'series', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _printedTotalMeta =
      const VerificationMeta('printedTotal');
  @override
  late final GeneratedColumn<int> printedTotal = GeneratedColumn<int>(
      'printed_total', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
      'total', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _releaseDateMeta =
      const VerificationMeta('releaseDate');
  @override
  late final GeneratedColumn<String> releaseDate = GeneratedColumn<String>(
      'release_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _logoUrlMeta =
      const VerificationMeta('logoUrl');
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
      'logo_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _symbolUrlMeta =
      const VerificationMeta('symbolUrl');
  @override
  late final GeneratedColumn<String> symbolUrl = GeneratedColumn<String>(
      'symbol_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        series,
        printedTotal,
        total,
        releaseDate,
        updatedAt,
        logoUrl,
        symbolUrl
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'card_sets';
  @override
  VerificationContext validateIntegrity(Insertable<CardSet> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('series')) {
      context.handle(_seriesMeta,
          series.isAcceptableOrUnknown(data['series']!, _seriesMeta));
    } else if (isInserting) {
      context.missing(_seriesMeta);
    }
    if (data.containsKey('printed_total')) {
      context.handle(
          _printedTotalMeta,
          printedTotal.isAcceptableOrUnknown(
              data['printed_total']!, _printedTotalMeta));
    } else if (isInserting) {
      context.missing(_printedTotalMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
          _totalMeta, total.isAcceptableOrUnknown(data['total']!, _totalMeta));
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('release_date')) {
      context.handle(
          _releaseDateMeta,
          releaseDate.isAcceptableOrUnknown(
              data['release_date']!, _releaseDateMeta));
    } else if (isInserting) {
      context.missing(_releaseDateMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('logo_url')) {
      context.handle(_logoUrlMeta,
          logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta));
    } else if (isInserting) {
      context.missing(_logoUrlMeta);
    }
    if (data.containsKey('symbol_url')) {
      context.handle(_symbolUrlMeta,
          symbolUrl.isAcceptableOrUnknown(data['symbol_url']!, _symbolUrlMeta));
    } else if (isInserting) {
      context.missing(_symbolUrlMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardSet(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      series: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}series'])!,
      printedTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}printed_total'])!,
      total: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total'])!,
      releaseDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}release_date'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      logoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}logo_url'])!,
      symbolUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}symbol_url'])!,
    );
  }

  @override
  $CardSetsTable createAlias(String alias) {
    return $CardSetsTable(attachedDatabase, alias);
  }
}

class CardSet extends DataClass implements Insertable<CardSet> {
  final String id;
  final String name;
  final String series;
  final int printedTotal;
  final int total;
  final String releaseDate;
  final String updatedAt;
  final String logoUrl;
  final String symbolUrl;
  const CardSet(
      {required this.id,
      required this.name,
      required this.series,
      required this.printedTotal,
      required this.total,
      required this.releaseDate,
      required this.updatedAt,
      required this.logoUrl,
      required this.symbolUrl});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['series'] = Variable<String>(series);
    map['printed_total'] = Variable<int>(printedTotal);
    map['total'] = Variable<int>(total);
    map['release_date'] = Variable<String>(releaseDate);
    map['updated_at'] = Variable<String>(updatedAt);
    map['logo_url'] = Variable<String>(logoUrl);
    map['symbol_url'] = Variable<String>(symbolUrl);
    return map;
  }

  CardSetsCompanion toCompanion(bool nullToAbsent) {
    return CardSetsCompanion(
      id: Value(id),
      name: Value(name),
      series: Value(series),
      printedTotal: Value(printedTotal),
      total: Value(total),
      releaseDate: Value(releaseDate),
      updatedAt: Value(updatedAt),
      logoUrl: Value(logoUrl),
      symbolUrl: Value(symbolUrl),
    );
  }

  factory CardSet.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardSet(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      series: serializer.fromJson<String>(json['series']),
      printedTotal: serializer.fromJson<int>(json['printedTotal']),
      total: serializer.fromJson<int>(json['total']),
      releaseDate: serializer.fromJson<String>(json['releaseDate']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      logoUrl: serializer.fromJson<String>(json['logoUrl']),
      symbolUrl: serializer.fromJson<String>(json['symbolUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'series': serializer.toJson<String>(series),
      'printedTotal': serializer.toJson<int>(printedTotal),
      'total': serializer.toJson<int>(total),
      'releaseDate': serializer.toJson<String>(releaseDate),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'logoUrl': serializer.toJson<String>(logoUrl),
      'symbolUrl': serializer.toJson<String>(symbolUrl),
    };
  }

  CardSet copyWith(
          {String? id,
          String? name,
          String? series,
          int? printedTotal,
          int? total,
          String? releaseDate,
          String? updatedAt,
          String? logoUrl,
          String? symbolUrl}) =>
      CardSet(
        id: id ?? this.id,
        name: name ?? this.name,
        series: series ?? this.series,
        printedTotal: printedTotal ?? this.printedTotal,
        total: total ?? this.total,
        releaseDate: releaseDate ?? this.releaseDate,
        updatedAt: updatedAt ?? this.updatedAt,
        logoUrl: logoUrl ?? this.logoUrl,
        symbolUrl: symbolUrl ?? this.symbolUrl,
      );
  CardSet copyWithCompanion(CardSetsCompanion data) {
    return CardSet(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      series: data.series.present ? data.series.value : this.series,
      printedTotal: data.printedTotal.present
          ? data.printedTotal.value
          : this.printedTotal,
      total: data.total.present ? data.total.value : this.total,
      releaseDate:
          data.releaseDate.present ? data.releaseDate.value : this.releaseDate,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      logoUrl: data.logoUrl.present ? data.logoUrl.value : this.logoUrl,
      symbolUrl: data.symbolUrl.present ? data.symbolUrl.value : this.symbolUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardSet(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('series: $series, ')
          ..write('printedTotal: $printedTotal, ')
          ..write('total: $total, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('symbolUrl: $symbolUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, series, printedTotal, total,
      releaseDate, updatedAt, logoUrl, symbolUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardSet &&
          other.id == this.id &&
          other.name == this.name &&
          other.series == this.series &&
          other.printedTotal == this.printedTotal &&
          other.total == this.total &&
          other.releaseDate == this.releaseDate &&
          other.updatedAt == this.updatedAt &&
          other.logoUrl == this.logoUrl &&
          other.symbolUrl == this.symbolUrl);
}

class CardSetsCompanion extends UpdateCompanion<CardSet> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> series;
  final Value<int> printedTotal;
  final Value<int> total;
  final Value<String> releaseDate;
  final Value<String> updatedAt;
  final Value<String> logoUrl;
  final Value<String> symbolUrl;
  final Value<int> rowid;
  const CardSetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.series = const Value.absent(),
    this.printedTotal = const Value.absent(),
    this.total = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.symbolUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardSetsCompanion.insert({
    required String id,
    required String name,
    required String series,
    required int printedTotal,
    required int total,
    required String releaseDate,
    required String updatedAt,
    required String logoUrl,
    required String symbolUrl,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        series = Value(series),
        printedTotal = Value(printedTotal),
        total = Value(total),
        releaseDate = Value(releaseDate),
        updatedAt = Value(updatedAt),
        logoUrl = Value(logoUrl),
        symbolUrl = Value(symbolUrl);
  static Insertable<CardSet> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? series,
    Expression<int>? printedTotal,
    Expression<int>? total,
    Expression<String>? releaseDate,
    Expression<String>? updatedAt,
    Expression<String>? logoUrl,
    Expression<String>? symbolUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (series != null) 'series': series,
      if (printedTotal != null) 'printed_total': printedTotal,
      if (total != null) 'total': total,
      if (releaseDate != null) 'release_date': releaseDate,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (symbolUrl != null) 'symbol_url': symbolUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardSetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? series,
      Value<int>? printedTotal,
      Value<int>? total,
      Value<String>? releaseDate,
      Value<String>? updatedAt,
      Value<String>? logoUrl,
      Value<String>? symbolUrl,
      Value<int>? rowid}) {
    return CardSetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      series: series ?? this.series,
      printedTotal: printedTotal ?? this.printedTotal,
      total: total ?? this.total,
      releaseDate: releaseDate ?? this.releaseDate,
      updatedAt: updatedAt ?? this.updatedAt,
      logoUrl: logoUrl ?? this.logoUrl,
      symbolUrl: symbolUrl ?? this.symbolUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (series.present) {
      map['series'] = Variable<String>(series.value);
    }
    if (printedTotal.present) {
      map['printed_total'] = Variable<int>(printedTotal.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<String>(releaseDate.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    if (symbolUrl.present) {
      map['symbol_url'] = Variable<String>(symbolUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardSetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('series: $series, ')
          ..write('printedTotal: $printedTotal, ')
          ..write('total: $total, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('symbolUrl: $symbolUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CardsTable extends Cards with TableInfo<$CardsTable, Card> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _setIdMeta = const VerificationMeta('setId');
  @override
  late final GeneratedColumn<String> setId = GeneratedColumn<String>(
      'set_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES card_sets (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
      'number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _imageUrlSmallMeta =
      const VerificationMeta('imageUrlSmall');
  @override
  late final GeneratedColumn<String> imageUrlSmall = GeneratedColumn<String>(
      'image_url_small', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _imageUrlLargeMeta =
      const VerificationMeta('imageUrlLarge');
  @override
  late final GeneratedColumn<String> imageUrlLarge = GeneratedColumn<String>(
      'image_url_large', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _supertypeMeta =
      const VerificationMeta('supertype');
  @override
  late final GeneratedColumn<String> supertype = GeneratedColumn<String>(
      'supertype', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _subtypesMeta =
      const VerificationMeta('subtypes');
  @override
  late final GeneratedColumn<String> subtypes = GeneratedColumn<String>(
      'subtypes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typesMeta = const VerificationMeta('types');
  @override
  late final GeneratedColumn<String> types = GeneratedColumn<String>(
      'types', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
      'artist', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rarityMeta = const VerificationMeta('rarity');
  @override
  late final GeneratedColumn<String> rarity = GeneratedColumn<String>(
      'rarity', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _flavorTextMeta =
      const VerificationMeta('flavorText');
  @override
  late final GeneratedColumn<String> flavorText = GeneratedColumn<String>(
      'flavor_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        setId,
        name,
        number,
        imageUrlSmall,
        imageUrlLarge,
        supertype,
        subtypes,
        types,
        artist,
        rarity,
        flavorText
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  VerificationContext validateIntegrity(Insertable<Card> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('set_id')) {
      context.handle(
          _setIdMeta, setId.isAcceptableOrUnknown(data['set_id']!, _setIdMeta));
    } else if (isInserting) {
      context.missing(_setIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('number')) {
      context.handle(_numberMeta,
          number.isAcceptableOrUnknown(data['number']!, _numberMeta));
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('image_url_small')) {
      context.handle(
          _imageUrlSmallMeta,
          imageUrlSmall.isAcceptableOrUnknown(
              data['image_url_small']!, _imageUrlSmallMeta));
    } else if (isInserting) {
      context.missing(_imageUrlSmallMeta);
    }
    if (data.containsKey('image_url_large')) {
      context.handle(
          _imageUrlLargeMeta,
          imageUrlLarge.isAcceptableOrUnknown(
              data['image_url_large']!, _imageUrlLargeMeta));
    } else if (isInserting) {
      context.missing(_imageUrlLargeMeta);
    }
    if (data.containsKey('supertype')) {
      context.handle(_supertypeMeta,
          supertype.isAcceptableOrUnknown(data['supertype']!, _supertypeMeta));
    }
    if (data.containsKey('subtypes')) {
      context.handle(_subtypesMeta,
          subtypes.isAcceptableOrUnknown(data['subtypes']!, _subtypesMeta));
    }
    if (data.containsKey('types')) {
      context.handle(
          _typesMeta, types.isAcceptableOrUnknown(data['types']!, _typesMeta));
    }
    if (data.containsKey('artist')) {
      context.handle(_artistMeta,
          artist.isAcceptableOrUnknown(data['artist']!, _artistMeta));
    }
    if (data.containsKey('rarity')) {
      context.handle(_rarityMeta,
          rarity.isAcceptableOrUnknown(data['rarity']!, _rarityMeta));
    }
    if (data.containsKey('flavor_text')) {
      context.handle(
          _flavorTextMeta,
          flavorText.isAcceptableOrUnknown(
              data['flavor_text']!, _flavorTextMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Card map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Card(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      setId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}set_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      number: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}number'])!,
      imageUrlSmall: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}image_url_small'])!,
      imageUrlLarge: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}image_url_large'])!,
      supertype: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}supertype']),
      subtypes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subtypes']),
      types: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}types']),
      artist: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist']),
      rarity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rarity']),
      flavorText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}flavor_text']),
    );
  }

  @override
  $CardsTable createAlias(String alias) {
    return $CardsTable(attachedDatabase, alias);
  }
}

class Card extends DataClass implements Insertable<Card> {
  final String id;
  final String setId;
  final String name;
  final String number;
  final String imageUrlSmall;
  final String imageUrlLarge;
  final String? supertype;
  final String? subtypes;
  final String? types;
  final String? artist;
  final String? rarity;
  final String? flavorText;
  const Card(
      {required this.id,
      required this.setId,
      required this.name,
      required this.number,
      required this.imageUrlSmall,
      required this.imageUrlLarge,
      this.supertype,
      this.subtypes,
      this.types,
      this.artist,
      this.rarity,
      this.flavorText});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['set_id'] = Variable<String>(setId);
    map['name'] = Variable<String>(name);
    map['number'] = Variable<String>(number);
    map['image_url_small'] = Variable<String>(imageUrlSmall);
    map['image_url_large'] = Variable<String>(imageUrlLarge);
    if (!nullToAbsent || supertype != null) {
      map['supertype'] = Variable<String>(supertype);
    }
    if (!nullToAbsent || subtypes != null) {
      map['subtypes'] = Variable<String>(subtypes);
    }
    if (!nullToAbsent || types != null) {
      map['types'] = Variable<String>(types);
    }
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    if (!nullToAbsent || rarity != null) {
      map['rarity'] = Variable<String>(rarity);
    }
    if (!nullToAbsent || flavorText != null) {
      map['flavor_text'] = Variable<String>(flavorText);
    }
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      id: Value(id),
      setId: Value(setId),
      name: Value(name),
      number: Value(number),
      imageUrlSmall: Value(imageUrlSmall),
      imageUrlLarge: Value(imageUrlLarge),
      supertype: supertype == null && nullToAbsent
          ? const Value.absent()
          : Value(supertype),
      subtypes: subtypes == null && nullToAbsent
          ? const Value.absent()
          : Value(subtypes),
      types:
          types == null && nullToAbsent ? const Value.absent() : Value(types),
      artist:
          artist == null && nullToAbsent ? const Value.absent() : Value(artist),
      rarity:
          rarity == null && nullToAbsent ? const Value.absent() : Value(rarity),
      flavorText: flavorText == null && nullToAbsent
          ? const Value.absent()
          : Value(flavorText),
    );
  }

  factory Card.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Card(
      id: serializer.fromJson<String>(json['id']),
      setId: serializer.fromJson<String>(json['setId']),
      name: serializer.fromJson<String>(json['name']),
      number: serializer.fromJson<String>(json['number']),
      imageUrlSmall: serializer.fromJson<String>(json['imageUrlSmall']),
      imageUrlLarge: serializer.fromJson<String>(json['imageUrlLarge']),
      supertype: serializer.fromJson<String?>(json['supertype']),
      subtypes: serializer.fromJson<String?>(json['subtypes']),
      types: serializer.fromJson<String?>(json['types']),
      artist: serializer.fromJson<String?>(json['artist']),
      rarity: serializer.fromJson<String?>(json['rarity']),
      flavorText: serializer.fromJson<String?>(json['flavorText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'setId': serializer.toJson<String>(setId),
      'name': serializer.toJson<String>(name),
      'number': serializer.toJson<String>(number),
      'imageUrlSmall': serializer.toJson<String>(imageUrlSmall),
      'imageUrlLarge': serializer.toJson<String>(imageUrlLarge),
      'supertype': serializer.toJson<String?>(supertype),
      'subtypes': serializer.toJson<String?>(subtypes),
      'types': serializer.toJson<String?>(types),
      'artist': serializer.toJson<String?>(artist),
      'rarity': serializer.toJson<String?>(rarity),
      'flavorText': serializer.toJson<String?>(flavorText),
    };
  }

  Card copyWith(
          {String? id,
          String? setId,
          String? name,
          String? number,
          String? imageUrlSmall,
          String? imageUrlLarge,
          Value<String?> supertype = const Value.absent(),
          Value<String?> subtypes = const Value.absent(),
          Value<String?> types = const Value.absent(),
          Value<String?> artist = const Value.absent(),
          Value<String?> rarity = const Value.absent(),
          Value<String?> flavorText = const Value.absent()}) =>
      Card(
        id: id ?? this.id,
        setId: setId ?? this.setId,
        name: name ?? this.name,
        number: number ?? this.number,
        imageUrlSmall: imageUrlSmall ?? this.imageUrlSmall,
        imageUrlLarge: imageUrlLarge ?? this.imageUrlLarge,
        supertype: supertype.present ? supertype.value : this.supertype,
        subtypes: subtypes.present ? subtypes.value : this.subtypes,
        types: types.present ? types.value : this.types,
        artist: artist.present ? artist.value : this.artist,
        rarity: rarity.present ? rarity.value : this.rarity,
        flavorText: flavorText.present ? flavorText.value : this.flavorText,
      );
  Card copyWithCompanion(CardsCompanion data) {
    return Card(
      id: data.id.present ? data.id.value : this.id,
      setId: data.setId.present ? data.setId.value : this.setId,
      name: data.name.present ? data.name.value : this.name,
      number: data.number.present ? data.number.value : this.number,
      imageUrlSmall: data.imageUrlSmall.present
          ? data.imageUrlSmall.value
          : this.imageUrlSmall,
      imageUrlLarge: data.imageUrlLarge.present
          ? data.imageUrlLarge.value
          : this.imageUrlLarge,
      supertype: data.supertype.present ? data.supertype.value : this.supertype,
      subtypes: data.subtypes.present ? data.subtypes.value : this.subtypes,
      types: data.types.present ? data.types.value : this.types,
      artist: data.artist.present ? data.artist.value : this.artist,
      rarity: data.rarity.present ? data.rarity.value : this.rarity,
      flavorText:
          data.flavorText.present ? data.flavorText.value : this.flavorText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Card(')
          ..write('id: $id, ')
          ..write('setId: $setId, ')
          ..write('name: $name, ')
          ..write('number: $number, ')
          ..write('imageUrlSmall: $imageUrlSmall, ')
          ..write('imageUrlLarge: $imageUrlLarge, ')
          ..write('supertype: $supertype, ')
          ..write('subtypes: $subtypes, ')
          ..write('types: $types, ')
          ..write('artist: $artist, ')
          ..write('rarity: $rarity, ')
          ..write('flavorText: $flavorText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, setId, name, number, imageUrlSmall,
      imageUrlLarge, supertype, subtypes, types, artist, rarity, flavorText);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Card &&
          other.id == this.id &&
          other.setId == this.setId &&
          other.name == this.name &&
          other.number == this.number &&
          other.imageUrlSmall == this.imageUrlSmall &&
          other.imageUrlLarge == this.imageUrlLarge &&
          other.supertype == this.supertype &&
          other.subtypes == this.subtypes &&
          other.types == this.types &&
          other.artist == this.artist &&
          other.rarity == this.rarity &&
          other.flavorText == this.flavorText);
}

class CardsCompanion extends UpdateCompanion<Card> {
  final Value<String> id;
  final Value<String> setId;
  final Value<String> name;
  final Value<String> number;
  final Value<String> imageUrlSmall;
  final Value<String> imageUrlLarge;
  final Value<String?> supertype;
  final Value<String?> subtypes;
  final Value<String?> types;
  final Value<String?> artist;
  final Value<String?> rarity;
  final Value<String?> flavorText;
  final Value<int> rowid;
  const CardsCompanion({
    this.id = const Value.absent(),
    this.setId = const Value.absent(),
    this.name = const Value.absent(),
    this.number = const Value.absent(),
    this.imageUrlSmall = const Value.absent(),
    this.imageUrlLarge = const Value.absent(),
    this.supertype = const Value.absent(),
    this.subtypes = const Value.absent(),
    this.types = const Value.absent(),
    this.artist = const Value.absent(),
    this.rarity = const Value.absent(),
    this.flavorText = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardsCompanion.insert({
    required String id,
    required String setId,
    required String name,
    required String number,
    required String imageUrlSmall,
    required String imageUrlLarge,
    this.supertype = const Value.absent(),
    this.subtypes = const Value.absent(),
    this.types = const Value.absent(),
    this.artist = const Value.absent(),
    this.rarity = const Value.absent(),
    this.flavorText = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        setId = Value(setId),
        name = Value(name),
        number = Value(number),
        imageUrlSmall = Value(imageUrlSmall),
        imageUrlLarge = Value(imageUrlLarge);
  static Insertable<Card> custom({
    Expression<String>? id,
    Expression<String>? setId,
    Expression<String>? name,
    Expression<String>? number,
    Expression<String>? imageUrlSmall,
    Expression<String>? imageUrlLarge,
    Expression<String>? supertype,
    Expression<String>? subtypes,
    Expression<String>? types,
    Expression<String>? artist,
    Expression<String>? rarity,
    Expression<String>? flavorText,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (setId != null) 'set_id': setId,
      if (name != null) 'name': name,
      if (number != null) 'number': number,
      if (imageUrlSmall != null) 'image_url_small': imageUrlSmall,
      if (imageUrlLarge != null) 'image_url_large': imageUrlLarge,
      if (supertype != null) 'supertype': supertype,
      if (subtypes != null) 'subtypes': subtypes,
      if (types != null) 'types': types,
      if (artist != null) 'artist': artist,
      if (rarity != null) 'rarity': rarity,
      if (flavorText != null) 'flavor_text': flavorText,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardsCompanion copyWith(
      {Value<String>? id,
      Value<String>? setId,
      Value<String>? name,
      Value<String>? number,
      Value<String>? imageUrlSmall,
      Value<String>? imageUrlLarge,
      Value<String?>? supertype,
      Value<String?>? subtypes,
      Value<String?>? types,
      Value<String?>? artist,
      Value<String?>? rarity,
      Value<String?>? flavorText,
      Value<int>? rowid}) {
    return CardsCompanion(
      id: id ?? this.id,
      setId: setId ?? this.setId,
      name: name ?? this.name,
      number: number ?? this.number,
      imageUrlSmall: imageUrlSmall ?? this.imageUrlSmall,
      imageUrlLarge: imageUrlLarge ?? this.imageUrlLarge,
      supertype: supertype ?? this.supertype,
      subtypes: subtypes ?? this.subtypes,
      types: types ?? this.types,
      artist: artist ?? this.artist,
      rarity: rarity ?? this.rarity,
      flavorText: flavorText ?? this.flavorText,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (setId.present) {
      map['set_id'] = Variable<String>(setId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (imageUrlSmall.present) {
      map['image_url_small'] = Variable<String>(imageUrlSmall.value);
    }
    if (imageUrlLarge.present) {
      map['image_url_large'] = Variable<String>(imageUrlLarge.value);
    }
    if (supertype.present) {
      map['supertype'] = Variable<String>(supertype.value);
    }
    if (subtypes.present) {
      map['subtypes'] = Variable<String>(subtypes.value);
    }
    if (types.present) {
      map['types'] = Variable<String>(types.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (rarity.present) {
      map['rarity'] = Variable<String>(rarity.value);
    }
    if (flavorText.present) {
      map['flavor_text'] = Variable<String>(flavorText.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsCompanion(')
          ..write('id: $id, ')
          ..write('setId: $setId, ')
          ..write('name: $name, ')
          ..write('number: $number, ')
          ..write('imageUrlSmall: $imageUrlSmall, ')
          ..write('imageUrlLarge: $imageUrlLarge, ')
          ..write('supertype: $supertype, ')
          ..write('subtypes: $subtypes, ')
          ..write('types: $types, ')
          ..write('artist: $artist, ')
          ..write('rarity: $rarity, ')
          ..write('flavorText: $flavorText, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CardMarketPricesTable extends CardMarketPrices
    with TableInfo<$CardMarketPricesTable, CardMarketPrice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardMarketPricesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
      'card_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES cards (id)'));
  static const VerificationMeta _fetchedAtMeta =
      const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
      'fetched_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _trendPriceMeta =
      const VerificationMeta('trendPrice');
  @override
  late final GeneratedColumn<double> trendPrice = GeneratedColumn<double>(
      'trend_price', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avg1Meta = const VerificationMeta('avg1');
  @override
  late final GeneratedColumn<double> avg1 = GeneratedColumn<double>(
      'avg1', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avg30Meta = const VerificationMeta('avg30');
  @override
  late final GeneratedColumn<double> avg30 = GeneratedColumn<double>(
      'avg30', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _lowPriceMeta =
      const VerificationMeta('lowPrice');
  @override
  late final GeneratedColumn<double> lowPrice = GeneratedColumn<double>(
      'low_price', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _reverseHoloTrendMeta =
      const VerificationMeta('reverseHoloTrend');
  @override
  late final GeneratedColumn<double> reverseHoloTrend = GeneratedColumn<double>(
      'reverse_holo_trend', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        cardId,
        fetchedAt,
        updatedAt,
        trendPrice,
        avg1,
        avg30,
        lowPrice,
        reverseHoloTrend,
        url
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'card_market_prices';
  @override
  VerificationContext validateIntegrity(Insertable<CardMarketPrice> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('card_id')) {
      context.handle(_cardIdMeta,
          cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta));
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(_fetchedAtMeta,
          fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta));
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('trend_price')) {
      context.handle(
          _trendPriceMeta,
          trendPrice.isAcceptableOrUnknown(
              data['trend_price']!, _trendPriceMeta));
    }
    if (data.containsKey('avg1')) {
      context.handle(
          _avg1Meta, avg1.isAcceptableOrUnknown(data['avg1']!, _avg1Meta));
    }
    if (data.containsKey('avg30')) {
      context.handle(
          _avg30Meta, avg30.isAcceptableOrUnknown(data['avg30']!, _avg30Meta));
    }
    if (data.containsKey('low_price')) {
      context.handle(_lowPriceMeta,
          lowPrice.isAcceptableOrUnknown(data['low_price']!, _lowPriceMeta));
    }
    if (data.containsKey('reverse_holo_trend')) {
      context.handle(
          _reverseHoloTrendMeta,
          reverseHoloTrend.isAcceptableOrUnknown(
              data['reverse_holo_trend']!, _reverseHoloTrendMeta));
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardMarketPrice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardMarketPrice(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      cardId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}card_id'])!,
      fetchedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}fetched_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      trendPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}trend_price']),
      avg1: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg1']),
      avg30: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg30']),
      lowPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}low_price']),
      reverseHoloTrend: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}reverse_holo_trend']),
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url']),
    );
  }

  @override
  $CardMarketPricesTable createAlias(String alias) {
    return $CardMarketPricesTable(attachedDatabase, alias);
  }
}

class CardMarketPrice extends DataClass implements Insertable<CardMarketPrice> {
  final int id;
  final String cardId;
  final DateTime fetchedAt;
  final String updatedAt;
  final double? trendPrice;
  final double? avg1;
  final double? avg30;
  final double? lowPrice;
  final double? reverseHoloTrend;
  final String? url;
  const CardMarketPrice(
      {required this.id,
      required this.cardId,
      required this.fetchedAt,
      required this.updatedAt,
      this.trendPrice,
      this.avg1,
      this.avg30,
      this.lowPrice,
      this.reverseHoloTrend,
      this.url});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['card_id'] = Variable<String>(cardId);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || trendPrice != null) {
      map['trend_price'] = Variable<double>(trendPrice);
    }
    if (!nullToAbsent || avg1 != null) {
      map['avg1'] = Variable<double>(avg1);
    }
    if (!nullToAbsent || avg30 != null) {
      map['avg30'] = Variable<double>(avg30);
    }
    if (!nullToAbsent || lowPrice != null) {
      map['low_price'] = Variable<double>(lowPrice);
    }
    if (!nullToAbsent || reverseHoloTrend != null) {
      map['reverse_holo_trend'] = Variable<double>(reverseHoloTrend);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    return map;
  }

  CardMarketPricesCompanion toCompanion(bool nullToAbsent) {
    return CardMarketPricesCompanion(
      id: Value(id),
      cardId: Value(cardId),
      fetchedAt: Value(fetchedAt),
      updatedAt: Value(updatedAt),
      trendPrice: trendPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(trendPrice),
      avg1: avg1 == null && nullToAbsent ? const Value.absent() : Value(avg1),
      avg30:
          avg30 == null && nullToAbsent ? const Value.absent() : Value(avg30),
      lowPrice: lowPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(lowPrice),
      reverseHoloTrend: reverseHoloTrend == null && nullToAbsent
          ? const Value.absent()
          : Value(reverseHoloTrend),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
    );
  }

  factory CardMarketPrice.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardMarketPrice(
      id: serializer.fromJson<int>(json['id']),
      cardId: serializer.fromJson<String>(json['cardId']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      trendPrice: serializer.fromJson<double?>(json['trendPrice']),
      avg1: serializer.fromJson<double?>(json['avg1']),
      avg30: serializer.fromJson<double?>(json['avg30']),
      lowPrice: serializer.fromJson<double?>(json['lowPrice']),
      reverseHoloTrend: serializer.fromJson<double?>(json['reverseHoloTrend']),
      url: serializer.fromJson<String?>(json['url']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cardId': serializer.toJson<String>(cardId),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'trendPrice': serializer.toJson<double?>(trendPrice),
      'avg1': serializer.toJson<double?>(avg1),
      'avg30': serializer.toJson<double?>(avg30),
      'lowPrice': serializer.toJson<double?>(lowPrice),
      'reverseHoloTrend': serializer.toJson<double?>(reverseHoloTrend),
      'url': serializer.toJson<String?>(url),
    };
  }

  CardMarketPrice copyWith(
          {int? id,
          String? cardId,
          DateTime? fetchedAt,
          String? updatedAt,
          Value<double?> trendPrice = const Value.absent(),
          Value<double?> avg1 = const Value.absent(),
          Value<double?> avg30 = const Value.absent(),
          Value<double?> lowPrice = const Value.absent(),
          Value<double?> reverseHoloTrend = const Value.absent(),
          Value<String?> url = const Value.absent()}) =>
      CardMarketPrice(
        id: id ?? this.id,
        cardId: cardId ?? this.cardId,
        fetchedAt: fetchedAt ?? this.fetchedAt,
        updatedAt: updatedAt ?? this.updatedAt,
        trendPrice: trendPrice.present ? trendPrice.value : this.trendPrice,
        avg1: avg1.present ? avg1.value : this.avg1,
        avg30: avg30.present ? avg30.value : this.avg30,
        lowPrice: lowPrice.present ? lowPrice.value : this.lowPrice,
        reverseHoloTrend: reverseHoloTrend.present
            ? reverseHoloTrend.value
            : this.reverseHoloTrend,
        url: url.present ? url.value : this.url,
      );
  CardMarketPrice copyWithCompanion(CardMarketPricesCompanion data) {
    return CardMarketPrice(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      trendPrice:
          data.trendPrice.present ? data.trendPrice.value : this.trendPrice,
      avg1: data.avg1.present ? data.avg1.value : this.avg1,
      avg30: data.avg30.present ? data.avg30.value : this.avg30,
      lowPrice: data.lowPrice.present ? data.lowPrice.value : this.lowPrice,
      reverseHoloTrend: data.reverseHoloTrend.present
          ? data.reverseHoloTrend.value
          : this.reverseHoloTrend,
      url: data.url.present ? data.url.value : this.url,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardMarketPrice(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('trendPrice: $trendPrice, ')
          ..write('avg1: $avg1, ')
          ..write('avg30: $avg30, ')
          ..write('lowPrice: $lowPrice, ')
          ..write('reverseHoloTrend: $reverseHoloTrend, ')
          ..write('url: $url')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, cardId, fetchedAt, updatedAt, trendPrice,
      avg1, avg30, lowPrice, reverseHoloTrend, url);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardMarketPrice &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.fetchedAt == this.fetchedAt &&
          other.updatedAt == this.updatedAt &&
          other.trendPrice == this.trendPrice &&
          other.avg1 == this.avg1 &&
          other.avg30 == this.avg30 &&
          other.lowPrice == this.lowPrice &&
          other.reverseHoloTrend == this.reverseHoloTrend &&
          other.url == this.url);
}

class CardMarketPricesCompanion extends UpdateCompanion<CardMarketPrice> {
  final Value<int> id;
  final Value<String> cardId;
  final Value<DateTime> fetchedAt;
  final Value<String> updatedAt;
  final Value<double?> trendPrice;
  final Value<double?> avg1;
  final Value<double?> avg30;
  final Value<double?> lowPrice;
  final Value<double?> reverseHoloTrend;
  final Value<String?> url;
  const CardMarketPricesCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.trendPrice = const Value.absent(),
    this.avg1 = const Value.absent(),
    this.avg30 = const Value.absent(),
    this.lowPrice = const Value.absent(),
    this.reverseHoloTrend = const Value.absent(),
    this.url = const Value.absent(),
  });
  CardMarketPricesCompanion.insert({
    this.id = const Value.absent(),
    required String cardId,
    required DateTime fetchedAt,
    required String updatedAt,
    this.trendPrice = const Value.absent(),
    this.avg1 = const Value.absent(),
    this.avg30 = const Value.absent(),
    this.lowPrice = const Value.absent(),
    this.reverseHoloTrend = const Value.absent(),
    this.url = const Value.absent(),
  })  : cardId = Value(cardId),
        fetchedAt = Value(fetchedAt),
        updatedAt = Value(updatedAt);
  static Insertable<CardMarketPrice> custom({
    Expression<int>? id,
    Expression<String>? cardId,
    Expression<DateTime>? fetchedAt,
    Expression<String>? updatedAt,
    Expression<double>? trendPrice,
    Expression<double>? avg1,
    Expression<double>? avg30,
    Expression<double>? lowPrice,
    Expression<double>? reverseHoloTrend,
    Expression<String>? url,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (trendPrice != null) 'trend_price': trendPrice,
      if (avg1 != null) 'avg1': avg1,
      if (avg30 != null) 'avg30': avg30,
      if (lowPrice != null) 'low_price': lowPrice,
      if (reverseHoloTrend != null) 'reverse_holo_trend': reverseHoloTrend,
      if (url != null) 'url': url,
    });
  }

  CardMarketPricesCompanion copyWith(
      {Value<int>? id,
      Value<String>? cardId,
      Value<DateTime>? fetchedAt,
      Value<String>? updatedAt,
      Value<double?>? trendPrice,
      Value<double?>? avg1,
      Value<double?>? avg30,
      Value<double?>? lowPrice,
      Value<double?>? reverseHoloTrend,
      Value<String?>? url}) {
    return CardMarketPricesCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      trendPrice: trendPrice ?? this.trendPrice,
      avg1: avg1 ?? this.avg1,
      avg30: avg30 ?? this.avg30,
      lowPrice: lowPrice ?? this.lowPrice,
      reverseHoloTrend: reverseHoloTrend ?? this.reverseHoloTrend,
      url: url ?? this.url,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (trendPrice.present) {
      map['trend_price'] = Variable<double>(trendPrice.value);
    }
    if (avg1.present) {
      map['avg1'] = Variable<double>(avg1.value);
    }
    if (avg30.present) {
      map['avg30'] = Variable<double>(avg30.value);
    }
    if (lowPrice.present) {
      map['low_price'] = Variable<double>(lowPrice.value);
    }
    if (reverseHoloTrend.present) {
      map['reverse_holo_trend'] = Variable<double>(reverseHoloTrend.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardMarketPricesCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('trendPrice: $trendPrice, ')
          ..write('avg1: $avg1, ')
          ..write('avg30: $avg30, ')
          ..write('lowPrice: $lowPrice, ')
          ..write('reverseHoloTrend: $reverseHoloTrend, ')
          ..write('url: $url')
          ..write(')'))
        .toString();
  }
}

class $TcgPlayerPricesTable extends TcgPlayerPrices
    with TableInfo<$TcgPlayerPricesTable, TcgPlayerPrice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TcgPlayerPricesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
      'card_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES cards (id)'));
  static const VerificationMeta _fetchedAtMeta =
      const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
      'fetched_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _normalMarketMeta =
      const VerificationMeta('normalMarket');
  @override
  late final GeneratedColumn<double> normalMarket = GeneratedColumn<double>(
      'normal_market', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _normalLowMeta =
      const VerificationMeta('normalLow');
  @override
  late final GeneratedColumn<double> normalLow = GeneratedColumn<double>(
      'normal_low', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _reverseHoloMarketMeta =
      const VerificationMeta('reverseHoloMarket');
  @override
  late final GeneratedColumn<double> reverseHoloMarket =
      GeneratedColumn<double>('reverse_holo_market', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _reverseHoloLowMeta =
      const VerificationMeta('reverseHoloLow');
  @override
  late final GeneratedColumn<double> reverseHoloLow = GeneratedColumn<double>(
      'reverse_holo_low', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        cardId,
        fetchedAt,
        updatedAt,
        normalMarket,
        normalLow,
        reverseHoloMarket,
        reverseHoloLow,
        url
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tcg_player_prices';
  @override
  VerificationContext validateIntegrity(Insertable<TcgPlayerPrice> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('card_id')) {
      context.handle(_cardIdMeta,
          cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta));
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(_fetchedAtMeta,
          fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta));
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('normal_market')) {
      context.handle(
          _normalMarketMeta,
          normalMarket.isAcceptableOrUnknown(
              data['normal_market']!, _normalMarketMeta));
    }
    if (data.containsKey('normal_low')) {
      context.handle(_normalLowMeta,
          normalLow.isAcceptableOrUnknown(data['normal_low']!, _normalLowMeta));
    }
    if (data.containsKey('reverse_holo_market')) {
      context.handle(
          _reverseHoloMarketMeta,
          reverseHoloMarket.isAcceptableOrUnknown(
              data['reverse_holo_market']!, _reverseHoloMarketMeta));
    }
    if (data.containsKey('reverse_holo_low')) {
      context.handle(
          _reverseHoloLowMeta,
          reverseHoloLow.isAcceptableOrUnknown(
              data['reverse_holo_low']!, _reverseHoloLowMeta));
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TcgPlayerPrice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TcgPlayerPrice(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      cardId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}card_id'])!,
      fetchedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}fetched_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      normalMarket: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}normal_market']),
      normalLow: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}normal_low']),
      reverseHoloMarket: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}reverse_holo_market']),
      reverseHoloLow: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}reverse_holo_low']),
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url']),
    );
  }

  @override
  $TcgPlayerPricesTable createAlias(String alias) {
    return $TcgPlayerPricesTable(attachedDatabase, alias);
  }
}

class TcgPlayerPrice extends DataClass implements Insertable<TcgPlayerPrice> {
  final int id;
  final String cardId;
  final DateTime fetchedAt;
  final String updatedAt;
  final double? normalMarket;
  final double? normalLow;
  final double? reverseHoloMarket;
  final double? reverseHoloLow;
  final String? url;
  const TcgPlayerPrice(
      {required this.id,
      required this.cardId,
      required this.fetchedAt,
      required this.updatedAt,
      this.normalMarket,
      this.normalLow,
      this.reverseHoloMarket,
      this.reverseHoloLow,
      this.url});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['card_id'] = Variable<String>(cardId);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || normalMarket != null) {
      map['normal_market'] = Variable<double>(normalMarket);
    }
    if (!nullToAbsent || normalLow != null) {
      map['normal_low'] = Variable<double>(normalLow);
    }
    if (!nullToAbsent || reverseHoloMarket != null) {
      map['reverse_holo_market'] = Variable<double>(reverseHoloMarket);
    }
    if (!nullToAbsent || reverseHoloLow != null) {
      map['reverse_holo_low'] = Variable<double>(reverseHoloLow);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    return map;
  }

  TcgPlayerPricesCompanion toCompanion(bool nullToAbsent) {
    return TcgPlayerPricesCompanion(
      id: Value(id),
      cardId: Value(cardId),
      fetchedAt: Value(fetchedAt),
      updatedAt: Value(updatedAt),
      normalMarket: normalMarket == null && nullToAbsent
          ? const Value.absent()
          : Value(normalMarket),
      normalLow: normalLow == null && nullToAbsent
          ? const Value.absent()
          : Value(normalLow),
      reverseHoloMarket: reverseHoloMarket == null && nullToAbsent
          ? const Value.absent()
          : Value(reverseHoloMarket),
      reverseHoloLow: reverseHoloLow == null && nullToAbsent
          ? const Value.absent()
          : Value(reverseHoloLow),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
    );
  }

  factory TcgPlayerPrice.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TcgPlayerPrice(
      id: serializer.fromJson<int>(json['id']),
      cardId: serializer.fromJson<String>(json['cardId']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      normalMarket: serializer.fromJson<double?>(json['normalMarket']),
      normalLow: serializer.fromJson<double?>(json['normalLow']),
      reverseHoloMarket:
          serializer.fromJson<double?>(json['reverseHoloMarket']),
      reverseHoloLow: serializer.fromJson<double?>(json['reverseHoloLow']),
      url: serializer.fromJson<String?>(json['url']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cardId': serializer.toJson<String>(cardId),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'normalMarket': serializer.toJson<double?>(normalMarket),
      'normalLow': serializer.toJson<double?>(normalLow),
      'reverseHoloMarket': serializer.toJson<double?>(reverseHoloMarket),
      'reverseHoloLow': serializer.toJson<double?>(reverseHoloLow),
      'url': serializer.toJson<String?>(url),
    };
  }

  TcgPlayerPrice copyWith(
          {int? id,
          String? cardId,
          DateTime? fetchedAt,
          String? updatedAt,
          Value<double?> normalMarket = const Value.absent(),
          Value<double?> normalLow = const Value.absent(),
          Value<double?> reverseHoloMarket = const Value.absent(),
          Value<double?> reverseHoloLow = const Value.absent(),
          Value<String?> url = const Value.absent()}) =>
      TcgPlayerPrice(
        id: id ?? this.id,
        cardId: cardId ?? this.cardId,
        fetchedAt: fetchedAt ?? this.fetchedAt,
        updatedAt: updatedAt ?? this.updatedAt,
        normalMarket:
            normalMarket.present ? normalMarket.value : this.normalMarket,
        normalLow: normalLow.present ? normalLow.value : this.normalLow,
        reverseHoloMarket: reverseHoloMarket.present
            ? reverseHoloMarket.value
            : this.reverseHoloMarket,
        reverseHoloLow:
            reverseHoloLow.present ? reverseHoloLow.value : this.reverseHoloLow,
        url: url.present ? url.value : this.url,
      );
  TcgPlayerPrice copyWithCompanion(TcgPlayerPricesCompanion data) {
    return TcgPlayerPrice(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      normalMarket: data.normalMarket.present
          ? data.normalMarket.value
          : this.normalMarket,
      normalLow: data.normalLow.present ? data.normalLow.value : this.normalLow,
      reverseHoloMarket: data.reverseHoloMarket.present
          ? data.reverseHoloMarket.value
          : this.reverseHoloMarket,
      reverseHoloLow: data.reverseHoloLow.present
          ? data.reverseHoloLow.value
          : this.reverseHoloLow,
      url: data.url.present ? data.url.value : this.url,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TcgPlayerPrice(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('normalMarket: $normalMarket, ')
          ..write('normalLow: $normalLow, ')
          ..write('reverseHoloMarket: $reverseHoloMarket, ')
          ..write('reverseHoloLow: $reverseHoloLow, ')
          ..write('url: $url')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, cardId, fetchedAt, updatedAt,
      normalMarket, normalLow, reverseHoloMarket, reverseHoloLow, url);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TcgPlayerPrice &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.fetchedAt == this.fetchedAt &&
          other.updatedAt == this.updatedAt &&
          other.normalMarket == this.normalMarket &&
          other.normalLow == this.normalLow &&
          other.reverseHoloMarket == this.reverseHoloMarket &&
          other.reverseHoloLow == this.reverseHoloLow &&
          other.url == this.url);
}

class TcgPlayerPricesCompanion extends UpdateCompanion<TcgPlayerPrice> {
  final Value<int> id;
  final Value<String> cardId;
  final Value<DateTime> fetchedAt;
  final Value<String> updatedAt;
  final Value<double?> normalMarket;
  final Value<double?> normalLow;
  final Value<double?> reverseHoloMarket;
  final Value<double?> reverseHoloLow;
  final Value<String?> url;
  const TcgPlayerPricesCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.normalMarket = const Value.absent(),
    this.normalLow = const Value.absent(),
    this.reverseHoloMarket = const Value.absent(),
    this.reverseHoloLow = const Value.absent(),
    this.url = const Value.absent(),
  });
  TcgPlayerPricesCompanion.insert({
    this.id = const Value.absent(),
    required String cardId,
    required DateTime fetchedAt,
    required String updatedAt,
    this.normalMarket = const Value.absent(),
    this.normalLow = const Value.absent(),
    this.reverseHoloMarket = const Value.absent(),
    this.reverseHoloLow = const Value.absent(),
    this.url = const Value.absent(),
  })  : cardId = Value(cardId),
        fetchedAt = Value(fetchedAt),
        updatedAt = Value(updatedAt);
  static Insertable<TcgPlayerPrice> custom({
    Expression<int>? id,
    Expression<String>? cardId,
    Expression<DateTime>? fetchedAt,
    Expression<String>? updatedAt,
    Expression<double>? normalMarket,
    Expression<double>? normalLow,
    Expression<double>? reverseHoloMarket,
    Expression<double>? reverseHoloLow,
    Expression<String>? url,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (normalMarket != null) 'normal_market': normalMarket,
      if (normalLow != null) 'normal_low': normalLow,
      if (reverseHoloMarket != null) 'reverse_holo_market': reverseHoloMarket,
      if (reverseHoloLow != null) 'reverse_holo_low': reverseHoloLow,
      if (url != null) 'url': url,
    });
  }

  TcgPlayerPricesCompanion copyWith(
      {Value<int>? id,
      Value<String>? cardId,
      Value<DateTime>? fetchedAt,
      Value<String>? updatedAt,
      Value<double?>? normalMarket,
      Value<double?>? normalLow,
      Value<double?>? reverseHoloMarket,
      Value<double?>? reverseHoloLow,
      Value<String?>? url}) {
    return TcgPlayerPricesCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      normalMarket: normalMarket ?? this.normalMarket,
      normalLow: normalLow ?? this.normalLow,
      reverseHoloMarket: reverseHoloMarket ?? this.reverseHoloMarket,
      reverseHoloLow: reverseHoloLow ?? this.reverseHoloLow,
      url: url ?? this.url,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (normalMarket.present) {
      map['normal_market'] = Variable<double>(normalMarket.value);
    }
    if (normalLow.present) {
      map['normal_low'] = Variable<double>(normalLow.value);
    }
    if (reverseHoloMarket.present) {
      map['reverse_holo_market'] = Variable<double>(reverseHoloMarket.value);
    }
    if (reverseHoloLow.present) {
      map['reverse_holo_low'] = Variable<double>(reverseHoloLow.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TcgPlayerPricesCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('normalMarket: $normalMarket, ')
          ..write('normalLow: $normalLow, ')
          ..write('reverseHoloMarket: $reverseHoloMarket, ')
          ..write('reverseHoloLow: $reverseHoloLow, ')
          ..write('url: $url')
          ..write(')'))
        .toString();
  }
}

class $UserCardsTable extends UserCards
    with TableInfo<$UserCardsTable, UserCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
      'card_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES cards (id)'));
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _conditionMeta =
      const VerificationMeta('condition');
  @override
  late final GeneratedColumn<String> condition = GeneratedColumn<String>(
      'condition', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('NM'));
  static const VerificationMeta _languageMeta =
      const VerificationMeta('language');
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
      'language', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Deutsch'));
  static const VerificationMeta _variantMeta =
      const VerificationMeta('variant');
  @override
  late final GeneratedColumn<String> variant = GeneratedColumn<String>(
      'variant', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Normal'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, cardId, quantity, condition, language, variant, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_cards';
  @override
  VerificationContext validateIntegrity(Insertable<UserCard> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('card_id')) {
      context.handle(_cardIdMeta,
          cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta));
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('condition')) {
      context.handle(_conditionMeta,
          condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta));
    }
    if (data.containsKey('language')) {
      context.handle(_languageMeta,
          language.isAcceptableOrUnknown(data['language']!, _languageMeta));
    }
    if (data.containsKey('variant')) {
      context.handle(_variantMeta,
          variant.isAcceptableOrUnknown(data['variant']!, _variantMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserCard(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      cardId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}card_id'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
      condition: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}condition'])!,
      language: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}language'])!,
      variant: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}variant'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $UserCardsTable createAlias(String alias) {
    return $UserCardsTable(attachedDatabase, alias);
  }
}

class UserCard extends DataClass implements Insertable<UserCard> {
  final int id;
  final String cardId;
  final int quantity;
  final String condition;
  final String language;
  final String variant;
  final DateTime createdAt;
  const UserCard(
      {required this.id,
      required this.cardId,
      required this.quantity,
      required this.condition,
      required this.language,
      required this.variant,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['card_id'] = Variable<String>(cardId);
    map['quantity'] = Variable<int>(quantity);
    map['condition'] = Variable<String>(condition);
    map['language'] = Variable<String>(language);
    map['variant'] = Variable<String>(variant);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UserCardsCompanion toCompanion(bool nullToAbsent) {
    return UserCardsCompanion(
      id: Value(id),
      cardId: Value(cardId),
      quantity: Value(quantity),
      condition: Value(condition),
      language: Value(language),
      variant: Value(variant),
      createdAt: Value(createdAt),
    );
  }

  factory UserCard.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserCard(
      id: serializer.fromJson<int>(json['id']),
      cardId: serializer.fromJson<String>(json['cardId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      condition: serializer.fromJson<String>(json['condition']),
      language: serializer.fromJson<String>(json['language']),
      variant: serializer.fromJson<String>(json['variant']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cardId': serializer.toJson<String>(cardId),
      'quantity': serializer.toJson<int>(quantity),
      'condition': serializer.toJson<String>(condition),
      'language': serializer.toJson<String>(language),
      'variant': serializer.toJson<String>(variant),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserCard copyWith(
          {int? id,
          String? cardId,
          int? quantity,
          String? condition,
          String? language,
          String? variant,
          DateTime? createdAt}) =>
      UserCard(
        id: id ?? this.id,
        cardId: cardId ?? this.cardId,
        quantity: quantity ?? this.quantity,
        condition: condition ?? this.condition,
        language: language ?? this.language,
        variant: variant ?? this.variant,
        createdAt: createdAt ?? this.createdAt,
      );
  UserCard copyWithCompanion(UserCardsCompanion data) {
    return UserCard(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      condition: data.condition.present ? data.condition.value : this.condition,
      language: data.language.present ? data.language.value : this.language,
      variant: data.variant.present ? data.variant.value : this.variant,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserCard(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('quantity: $quantity, ')
          ..write('condition: $condition, ')
          ..write('language: $language, ')
          ..write('variant: $variant, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, cardId, quantity, condition, language, variant, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserCard &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.quantity == this.quantity &&
          other.condition == this.condition &&
          other.language == this.language &&
          other.variant == this.variant &&
          other.createdAt == this.createdAt);
}

class UserCardsCompanion extends UpdateCompanion<UserCard> {
  final Value<int> id;
  final Value<String> cardId;
  final Value<int> quantity;
  final Value<String> condition;
  final Value<String> language;
  final Value<String> variant;
  final Value<DateTime> createdAt;
  const UserCardsCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.condition = const Value.absent(),
    this.language = const Value.absent(),
    this.variant = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UserCardsCompanion.insert({
    this.id = const Value.absent(),
    required String cardId,
    this.quantity = const Value.absent(),
    this.condition = const Value.absent(),
    this.language = const Value.absent(),
    this.variant = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : cardId = Value(cardId);
  static Insertable<UserCard> custom({
    Expression<int>? id,
    Expression<String>? cardId,
    Expression<int>? quantity,
    Expression<String>? condition,
    Expression<String>? language,
    Expression<String>? variant,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (quantity != null) 'quantity': quantity,
      if (condition != null) 'condition': condition,
      if (language != null) 'language': language,
      if (variant != null) 'variant': variant,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UserCardsCompanion copyWith(
      {Value<int>? id,
      Value<String>? cardId,
      Value<int>? quantity,
      Value<String>? condition,
      Value<String>? language,
      Value<String>? variant,
      Value<DateTime>? createdAt}) {
    return UserCardsCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      quantity: quantity ?? this.quantity,
      condition: condition ?? this.condition,
      language: language ?? this.language,
      variant: variant ?? this.variant,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (condition.present) {
      map['condition'] = Variable<String>(condition.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (variant.present) {
      map['variant'] = Variable<String>(variant.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserCardsCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('quantity: $quantity, ')
          ..write('condition: $condition, ')
          ..write('language: $language, ')
          ..write('variant: $variant, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PortfolioHistoryTable extends PortfolioHistory
    with TableInfo<$PortfolioHistoryTable, PortfolioHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PortfolioHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _totalValueMeta =
      const VerificationMeta('totalValue');
  @override
  late final GeneratedColumn<double> totalValue = GeneratedColumn<double>(
      'total_value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, date, totalValue];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'portfolio_history';
  @override
  VerificationContext validateIntegrity(
      Insertable<PortfolioHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('total_value')) {
      context.handle(
          _totalValueMeta,
          totalValue.isAcceptableOrUnknown(
              data['total_value']!, _totalValueMeta));
    } else if (isInserting) {
      context.missing(_totalValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PortfolioHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PortfolioHistoryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      totalValue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_value'])!,
    );
  }

  @override
  $PortfolioHistoryTable createAlias(String alias) {
    return $PortfolioHistoryTable(attachedDatabase, alias);
  }
}

class PortfolioHistoryData extends DataClass
    implements Insertable<PortfolioHistoryData> {
  final int id;
  final DateTime date;
  final double totalValue;
  const PortfolioHistoryData(
      {required this.id, required this.date, required this.totalValue});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['total_value'] = Variable<double>(totalValue);
    return map;
  }

  PortfolioHistoryCompanion toCompanion(bool nullToAbsent) {
    return PortfolioHistoryCompanion(
      id: Value(id),
      date: Value(date),
      totalValue: Value(totalValue),
    );
  }

  factory PortfolioHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PortfolioHistoryData(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      totalValue: serializer.fromJson<double>(json['totalValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'totalValue': serializer.toJson<double>(totalValue),
    };
  }

  PortfolioHistoryData copyWith(
          {int? id, DateTime? date, double? totalValue}) =>
      PortfolioHistoryData(
        id: id ?? this.id,
        date: date ?? this.date,
        totalValue: totalValue ?? this.totalValue,
      );
  PortfolioHistoryData copyWithCompanion(PortfolioHistoryCompanion data) {
    return PortfolioHistoryData(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      totalValue:
          data.totalValue.present ? data.totalValue.value : this.totalValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PortfolioHistoryData(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('totalValue: $totalValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, totalValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PortfolioHistoryData &&
          other.id == this.id &&
          other.date == this.date &&
          other.totalValue == this.totalValue);
}

class PortfolioHistoryCompanion extends UpdateCompanion<PortfolioHistoryData> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<double> totalValue;
  const PortfolioHistoryCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.totalValue = const Value.absent(),
  });
  PortfolioHistoryCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required double totalValue,
  })  : date = Value(date),
        totalValue = Value(totalValue);
  static Insertable<PortfolioHistoryData> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<double>? totalValue,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (totalValue != null) 'total_value': totalValue,
    });
  }

  PortfolioHistoryCompanion copyWith(
      {Value<int>? id, Value<DateTime>? date, Value<double>? totalValue}) {
    return PortfolioHistoryCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      totalValue: totalValue ?? this.totalValue,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (totalValue.present) {
      map['total_value'] = Variable<double>(totalValue.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PortfolioHistoryCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('totalValue: $totalValue')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CardSetsTable cardSets = $CardSetsTable(this);
  late final $CardsTable cards = $CardsTable(this);
  late final $CardMarketPricesTable cardMarketPrices =
      $CardMarketPricesTable(this);
  late final $TcgPlayerPricesTable tcgPlayerPrices =
      $TcgPlayerPricesTable(this);
  late final $UserCardsTable userCards = $UserCardsTable(this);
  late final $PortfolioHistoryTable portfolioHistory =
      $PortfolioHistoryTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        cardSets,
        cards,
        cardMarketPrices,
        tcgPlayerPrices,
        userCards,
        portfolioHistory
      ];
}

typedef $$CardSetsTableCreateCompanionBuilder = CardSetsCompanion Function({
  required String id,
  required String name,
  required String series,
  required int printedTotal,
  required int total,
  required String releaseDate,
  required String updatedAt,
  required String logoUrl,
  required String symbolUrl,
  Value<int> rowid,
});
typedef $$CardSetsTableUpdateCompanionBuilder = CardSetsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> series,
  Value<int> printedTotal,
  Value<int> total,
  Value<String> releaseDate,
  Value<String> updatedAt,
  Value<String> logoUrl,
  Value<String> symbolUrl,
  Value<int> rowid,
});

class $$CardSetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CardSetsTable,
    CardSet,
    $$CardSetsTableFilterComposer,
    $$CardSetsTableOrderingComposer,
    $$CardSetsTableCreateCompanionBuilder,
    $$CardSetsTableUpdateCompanionBuilder> {
  $$CardSetsTableTableManager(_$AppDatabase db, $CardSetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$CardSetsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$CardSetsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> series = const Value.absent(),
            Value<int> printedTotal = const Value.absent(),
            Value<int> total = const Value.absent(),
            Value<String> releaseDate = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<String> logoUrl = const Value.absent(),
            Value<String> symbolUrl = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CardSetsCompanion(
            id: id,
            name: name,
            series: series,
            printedTotal: printedTotal,
            total: total,
            releaseDate: releaseDate,
            updatedAt: updatedAt,
            logoUrl: logoUrl,
            symbolUrl: symbolUrl,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String series,
            required int printedTotal,
            required int total,
            required String releaseDate,
            required String updatedAt,
            required String logoUrl,
            required String symbolUrl,
            Value<int> rowid = const Value.absent(),
          }) =>
              CardSetsCompanion.insert(
            id: id,
            name: name,
            series: series,
            printedTotal: printedTotal,
            total: total,
            releaseDate: releaseDate,
            updatedAt: updatedAt,
            logoUrl: logoUrl,
            symbolUrl: symbolUrl,
            rowid: rowid,
          ),
        ));
}

class $$CardSetsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $CardSetsTable> {
  $$CardSetsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get series => $state.composableBuilder(
      column: $state.table.series,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get printedTotal => $state.composableBuilder(
      column: $state.table.printedTotal,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get total => $state.composableBuilder(
      column: $state.table.total,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get releaseDate => $state.composableBuilder(
      column: $state.table.releaseDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get logoUrl => $state.composableBuilder(
      column: $state.table.logoUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get symbolUrl => $state.composableBuilder(
      column: $state.table.symbolUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter cardsRefs(
      ComposableFilter Function($$CardsTableFilterComposer f) f) {
    final $$CardsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.cards,
        getReferencedColumn: (t) => t.setId,
        builder: (joinBuilder, parentComposers) => $$CardsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.cards, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$CardSetsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $CardSetsTable> {
  $$CardSetsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get series => $state.composableBuilder(
      column: $state.table.series,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get printedTotal => $state.composableBuilder(
      column: $state.table.printedTotal,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get total => $state.composableBuilder(
      column: $state.table.total,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get releaseDate => $state.composableBuilder(
      column: $state.table.releaseDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get logoUrl => $state.composableBuilder(
      column: $state.table.logoUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get symbolUrl => $state.composableBuilder(
      column: $state.table.symbolUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$CardsTableCreateCompanionBuilder = CardsCompanion Function({
  required String id,
  required String setId,
  required String name,
  required String number,
  required String imageUrlSmall,
  required String imageUrlLarge,
  Value<String?> supertype,
  Value<String?> subtypes,
  Value<String?> types,
  Value<String?> artist,
  Value<String?> rarity,
  Value<String?> flavorText,
  Value<int> rowid,
});
typedef $$CardsTableUpdateCompanionBuilder = CardsCompanion Function({
  Value<String> id,
  Value<String> setId,
  Value<String> name,
  Value<String> number,
  Value<String> imageUrlSmall,
  Value<String> imageUrlLarge,
  Value<String?> supertype,
  Value<String?> subtypes,
  Value<String?> types,
  Value<String?> artist,
  Value<String?> rarity,
  Value<String?> flavorText,
  Value<int> rowid,
});

class $$CardsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CardsTable,
    Card,
    $$CardsTableFilterComposer,
    $$CardsTableOrderingComposer,
    $$CardsTableCreateCompanionBuilder,
    $$CardsTableUpdateCompanionBuilder> {
  $$CardsTableTableManager(_$AppDatabase db, $CardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$CardsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$CardsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> setId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> number = const Value.absent(),
            Value<String> imageUrlSmall = const Value.absent(),
            Value<String> imageUrlLarge = const Value.absent(),
            Value<String?> supertype = const Value.absent(),
            Value<String?> subtypes = const Value.absent(),
            Value<String?> types = const Value.absent(),
            Value<String?> artist = const Value.absent(),
            Value<String?> rarity = const Value.absent(),
            Value<String?> flavorText = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CardsCompanion(
            id: id,
            setId: setId,
            name: name,
            number: number,
            imageUrlSmall: imageUrlSmall,
            imageUrlLarge: imageUrlLarge,
            supertype: supertype,
            subtypes: subtypes,
            types: types,
            artist: artist,
            rarity: rarity,
            flavorText: flavorText,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String setId,
            required String name,
            required String number,
            required String imageUrlSmall,
            required String imageUrlLarge,
            Value<String?> supertype = const Value.absent(),
            Value<String?> subtypes = const Value.absent(),
            Value<String?> types = const Value.absent(),
            Value<String?> artist = const Value.absent(),
            Value<String?> rarity = const Value.absent(),
            Value<String?> flavorText = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CardsCompanion.insert(
            id: id,
            setId: setId,
            name: name,
            number: number,
            imageUrlSmall: imageUrlSmall,
            imageUrlLarge: imageUrlLarge,
            supertype: supertype,
            subtypes: subtypes,
            types: types,
            artist: artist,
            rarity: rarity,
            flavorText: flavorText,
            rowid: rowid,
          ),
        ));
}

class $$CardsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $CardsTable> {
  $$CardsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get number => $state.composableBuilder(
      column: $state.table.number,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get imageUrlSmall => $state.composableBuilder(
      column: $state.table.imageUrlSmall,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get imageUrlLarge => $state.composableBuilder(
      column: $state.table.imageUrlLarge,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get supertype => $state.composableBuilder(
      column: $state.table.supertype,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get subtypes => $state.composableBuilder(
      column: $state.table.subtypes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get types => $state.composableBuilder(
      column: $state.table.types,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get artist => $state.composableBuilder(
      column: $state.table.artist,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get rarity => $state.composableBuilder(
      column: $state.table.rarity,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get flavorText => $state.composableBuilder(
      column: $state.table.flavorText,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$CardSetsTableFilterComposer get setId {
    final $$CardSetsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.setId,
        referencedTable: $state.db.cardSets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$CardSetsTableFilterComposer(ComposerState(
                $state.db, $state.db.cardSets, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter cardMarketPricesRefs(
      ComposableFilter Function($$CardMarketPricesTableFilterComposer f) f) {
    final $$CardMarketPricesTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.cardMarketPrices,
            getReferencedColumn: (t) => t.cardId,
            builder: (joinBuilder, parentComposers) =>
                $$CardMarketPricesTableFilterComposer(ComposerState($state.db,
                    $state.db.cardMarketPrices, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter tcgPlayerPricesRefs(
      ComposableFilter Function($$TcgPlayerPricesTableFilterComposer f) f) {
    final $$TcgPlayerPricesTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.tcgPlayerPrices,
            getReferencedColumn: (t) => t.cardId,
            builder: (joinBuilder, parentComposers) =>
                $$TcgPlayerPricesTableFilterComposer(ComposerState($state.db,
                    $state.db.tcgPlayerPrices, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter userCardsRefs(
      ComposableFilter Function($$UserCardsTableFilterComposer f) f) {
    final $$UserCardsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.userCards,
        getReferencedColumn: (t) => t.cardId,
        builder: (joinBuilder, parentComposers) =>
            $$UserCardsTableFilterComposer(ComposerState(
                $state.db, $state.db.userCards, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$CardsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $CardsTable> {
  $$CardsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get number => $state.composableBuilder(
      column: $state.table.number,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get imageUrlSmall => $state.composableBuilder(
      column: $state.table.imageUrlSmall,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get imageUrlLarge => $state.composableBuilder(
      column: $state.table.imageUrlLarge,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get supertype => $state.composableBuilder(
      column: $state.table.supertype,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get subtypes => $state.composableBuilder(
      column: $state.table.subtypes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get types => $state.composableBuilder(
      column: $state.table.types,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get artist => $state.composableBuilder(
      column: $state.table.artist,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get rarity => $state.composableBuilder(
      column: $state.table.rarity,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get flavorText => $state.composableBuilder(
      column: $state.table.flavorText,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$CardSetsTableOrderingComposer get setId {
    final $$CardSetsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.setId,
        referencedTable: $state.db.cardSets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$CardSetsTableOrderingComposer(ComposerState(
                $state.db, $state.db.cardSets, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$CardMarketPricesTableCreateCompanionBuilder
    = CardMarketPricesCompanion Function({
  Value<int> id,
  required String cardId,
  required DateTime fetchedAt,
  required String updatedAt,
  Value<double?> trendPrice,
  Value<double?> avg1,
  Value<double?> avg30,
  Value<double?> lowPrice,
  Value<double?> reverseHoloTrend,
  Value<String?> url,
});
typedef $$CardMarketPricesTableUpdateCompanionBuilder
    = CardMarketPricesCompanion Function({
  Value<int> id,
  Value<String> cardId,
  Value<DateTime> fetchedAt,
  Value<String> updatedAt,
  Value<double?> trendPrice,
  Value<double?> avg1,
  Value<double?> avg30,
  Value<double?> lowPrice,
  Value<double?> reverseHoloTrend,
  Value<String?> url,
});

class $$CardMarketPricesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CardMarketPricesTable,
    CardMarketPrice,
    $$CardMarketPricesTableFilterComposer,
    $$CardMarketPricesTableOrderingComposer,
    $$CardMarketPricesTableCreateCompanionBuilder,
    $$CardMarketPricesTableUpdateCompanionBuilder> {
  $$CardMarketPricesTableTableManager(
      _$AppDatabase db, $CardMarketPricesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$CardMarketPricesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$CardMarketPricesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> cardId = const Value.absent(),
            Value<DateTime> fetchedAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<double?> trendPrice = const Value.absent(),
            Value<double?> avg1 = const Value.absent(),
            Value<double?> avg30 = const Value.absent(),
            Value<double?> lowPrice = const Value.absent(),
            Value<double?> reverseHoloTrend = const Value.absent(),
            Value<String?> url = const Value.absent(),
          }) =>
              CardMarketPricesCompanion(
            id: id,
            cardId: cardId,
            fetchedAt: fetchedAt,
            updatedAt: updatedAt,
            trendPrice: trendPrice,
            avg1: avg1,
            avg30: avg30,
            lowPrice: lowPrice,
            reverseHoloTrend: reverseHoloTrend,
            url: url,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String cardId,
            required DateTime fetchedAt,
            required String updatedAt,
            Value<double?> trendPrice = const Value.absent(),
            Value<double?> avg1 = const Value.absent(),
            Value<double?> avg30 = const Value.absent(),
            Value<double?> lowPrice = const Value.absent(),
            Value<double?> reverseHoloTrend = const Value.absent(),
            Value<String?> url = const Value.absent(),
          }) =>
              CardMarketPricesCompanion.insert(
            id: id,
            cardId: cardId,
            fetchedAt: fetchedAt,
            updatedAt: updatedAt,
            trendPrice: trendPrice,
            avg1: avg1,
            avg30: avg30,
            lowPrice: lowPrice,
            reverseHoloTrend: reverseHoloTrend,
            url: url,
          ),
        ));
}

class $$CardMarketPricesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $CardMarketPricesTable> {
  $$CardMarketPricesTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get fetchedAt => $state.composableBuilder(
      column: $state.table.fetchedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get trendPrice => $state.composableBuilder(
      column: $state.table.trendPrice,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get avg1 => $state.composableBuilder(
      column: $state.table.avg1,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get avg30 => $state.composableBuilder(
      column: $state.table.avg30,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get lowPrice => $state.composableBuilder(
      column: $state.table.lowPrice,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get reverseHoloTrend => $state.composableBuilder(
      column: $state.table.reverseHoloTrend,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get url => $state.composableBuilder(
      column: $state.table.url,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$CardsTableFilterComposer get cardId {
    final $$CardsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $state.db.cards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$CardsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.cards, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$CardMarketPricesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $CardMarketPricesTable> {
  $$CardMarketPricesTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get fetchedAt => $state.composableBuilder(
      column: $state.table.fetchedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get trendPrice => $state.composableBuilder(
      column: $state.table.trendPrice,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get avg1 => $state.composableBuilder(
      column: $state.table.avg1,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get avg30 => $state.composableBuilder(
      column: $state.table.avg30,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get lowPrice => $state.composableBuilder(
      column: $state.table.lowPrice,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get reverseHoloTrend => $state.composableBuilder(
      column: $state.table.reverseHoloTrend,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get url => $state.composableBuilder(
      column: $state.table.url,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$CardsTableOrderingComposer get cardId {
    final $$CardsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $state.db.cards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$CardsTableOrderingComposer(
            ComposerState(
                $state.db, $state.db.cards, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$TcgPlayerPricesTableCreateCompanionBuilder = TcgPlayerPricesCompanion
    Function({
  Value<int> id,
  required String cardId,
  required DateTime fetchedAt,
  required String updatedAt,
  Value<double?> normalMarket,
  Value<double?> normalLow,
  Value<double?> reverseHoloMarket,
  Value<double?> reverseHoloLow,
  Value<String?> url,
});
typedef $$TcgPlayerPricesTableUpdateCompanionBuilder = TcgPlayerPricesCompanion
    Function({
  Value<int> id,
  Value<String> cardId,
  Value<DateTime> fetchedAt,
  Value<String> updatedAt,
  Value<double?> normalMarket,
  Value<double?> normalLow,
  Value<double?> reverseHoloMarket,
  Value<double?> reverseHoloLow,
  Value<String?> url,
});

class $$TcgPlayerPricesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TcgPlayerPricesTable,
    TcgPlayerPrice,
    $$TcgPlayerPricesTableFilterComposer,
    $$TcgPlayerPricesTableOrderingComposer,
    $$TcgPlayerPricesTableCreateCompanionBuilder,
    $$TcgPlayerPricesTableUpdateCompanionBuilder> {
  $$TcgPlayerPricesTableTableManager(
      _$AppDatabase db, $TcgPlayerPricesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$TcgPlayerPricesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$TcgPlayerPricesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> cardId = const Value.absent(),
            Value<DateTime> fetchedAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<double?> normalMarket = const Value.absent(),
            Value<double?> normalLow = const Value.absent(),
            Value<double?> reverseHoloMarket = const Value.absent(),
            Value<double?> reverseHoloLow = const Value.absent(),
            Value<String?> url = const Value.absent(),
          }) =>
              TcgPlayerPricesCompanion(
            id: id,
            cardId: cardId,
            fetchedAt: fetchedAt,
            updatedAt: updatedAt,
            normalMarket: normalMarket,
            normalLow: normalLow,
            reverseHoloMarket: reverseHoloMarket,
            reverseHoloLow: reverseHoloLow,
            url: url,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String cardId,
            required DateTime fetchedAt,
            required String updatedAt,
            Value<double?> normalMarket = const Value.absent(),
            Value<double?> normalLow = const Value.absent(),
            Value<double?> reverseHoloMarket = const Value.absent(),
            Value<double?> reverseHoloLow = const Value.absent(),
            Value<String?> url = const Value.absent(),
          }) =>
              TcgPlayerPricesCompanion.insert(
            id: id,
            cardId: cardId,
            fetchedAt: fetchedAt,
            updatedAt: updatedAt,
            normalMarket: normalMarket,
            normalLow: normalLow,
            reverseHoloMarket: reverseHoloMarket,
            reverseHoloLow: reverseHoloLow,
            url: url,
          ),
        ));
}

class $$TcgPlayerPricesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $TcgPlayerPricesTable> {
  $$TcgPlayerPricesTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get fetchedAt => $state.composableBuilder(
      column: $state.table.fetchedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get normalMarket => $state.composableBuilder(
      column: $state.table.normalMarket,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get normalLow => $state.composableBuilder(
      column: $state.table.normalLow,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get reverseHoloMarket => $state.composableBuilder(
      column: $state.table.reverseHoloMarket,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get reverseHoloLow => $state.composableBuilder(
      column: $state.table.reverseHoloLow,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get url => $state.composableBuilder(
      column: $state.table.url,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$CardsTableFilterComposer get cardId {
    final $$CardsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $state.db.cards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$CardsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.cards, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$TcgPlayerPricesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $TcgPlayerPricesTable> {
  $$TcgPlayerPricesTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get fetchedAt => $state.composableBuilder(
      column: $state.table.fetchedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get normalMarket => $state.composableBuilder(
      column: $state.table.normalMarket,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get normalLow => $state.composableBuilder(
      column: $state.table.normalLow,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get reverseHoloMarket => $state.composableBuilder(
      column: $state.table.reverseHoloMarket,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get reverseHoloLow => $state.composableBuilder(
      column: $state.table.reverseHoloLow,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get url => $state.composableBuilder(
      column: $state.table.url,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$CardsTableOrderingComposer get cardId {
    final $$CardsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $state.db.cards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$CardsTableOrderingComposer(
            ComposerState(
                $state.db, $state.db.cards, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$UserCardsTableCreateCompanionBuilder = UserCardsCompanion Function({
  Value<int> id,
  required String cardId,
  Value<int> quantity,
  Value<String> condition,
  Value<String> language,
  Value<String> variant,
  Value<DateTime> createdAt,
});
typedef $$UserCardsTableUpdateCompanionBuilder = UserCardsCompanion Function({
  Value<int> id,
  Value<String> cardId,
  Value<int> quantity,
  Value<String> condition,
  Value<String> language,
  Value<String> variant,
  Value<DateTime> createdAt,
});

class $$UserCardsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserCardsTable,
    UserCard,
    $$UserCardsTableFilterComposer,
    $$UserCardsTableOrderingComposer,
    $$UserCardsTableCreateCompanionBuilder,
    $$UserCardsTableUpdateCompanionBuilder> {
  $$UserCardsTableTableManager(_$AppDatabase db, $UserCardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$UserCardsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$UserCardsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> cardId = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<String> condition = const Value.absent(),
            Value<String> language = const Value.absent(),
            Value<String> variant = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              UserCardsCompanion(
            id: id,
            cardId: cardId,
            quantity: quantity,
            condition: condition,
            language: language,
            variant: variant,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String cardId,
            Value<int> quantity = const Value.absent(),
            Value<String> condition = const Value.absent(),
            Value<String> language = const Value.absent(),
            Value<String> variant = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              UserCardsCompanion.insert(
            id: id,
            cardId: cardId,
            quantity: quantity,
            condition: condition,
            language: language,
            variant: variant,
            createdAt: createdAt,
          ),
        ));
}

class $$UserCardsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $UserCardsTable> {
  $$UserCardsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get quantity => $state.composableBuilder(
      column: $state.table.quantity,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get condition => $state.composableBuilder(
      column: $state.table.condition,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get language => $state.composableBuilder(
      column: $state.table.language,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get variant => $state.composableBuilder(
      column: $state.table.variant,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$CardsTableFilterComposer get cardId {
    final $$CardsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $state.db.cards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$CardsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.cards, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$UserCardsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $UserCardsTable> {
  $$UserCardsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get quantity => $state.composableBuilder(
      column: $state.table.quantity,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get condition => $state.composableBuilder(
      column: $state.table.condition,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get language => $state.composableBuilder(
      column: $state.table.language,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get variant => $state.composableBuilder(
      column: $state.table.variant,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$CardsTableOrderingComposer get cardId {
    final $$CardsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $state.db.cards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$CardsTableOrderingComposer(
            ComposerState(
                $state.db, $state.db.cards, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$PortfolioHistoryTableCreateCompanionBuilder
    = PortfolioHistoryCompanion Function({
  Value<int> id,
  required DateTime date,
  required double totalValue,
});
typedef $$PortfolioHistoryTableUpdateCompanionBuilder
    = PortfolioHistoryCompanion Function({
  Value<int> id,
  Value<DateTime> date,
  Value<double> totalValue,
});

class $$PortfolioHistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PortfolioHistoryTable,
    PortfolioHistoryData,
    $$PortfolioHistoryTableFilterComposer,
    $$PortfolioHistoryTableOrderingComposer,
    $$PortfolioHistoryTableCreateCompanionBuilder,
    $$PortfolioHistoryTableUpdateCompanionBuilder> {
  $$PortfolioHistoryTableTableManager(
      _$AppDatabase db, $PortfolioHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PortfolioHistoryTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PortfolioHistoryTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<double> totalValue = const Value.absent(),
          }) =>
              PortfolioHistoryCompanion(
            id: id,
            date: date,
            totalValue: totalValue,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime date,
            required double totalValue,
          }) =>
              PortfolioHistoryCompanion.insert(
            id: id,
            date: date,
            totalValue: totalValue,
          ),
        ));
}

class $$PortfolioHistoryTableFilterComposer
    extends FilterComposer<_$AppDatabase, $PortfolioHistoryTable> {
  $$PortfolioHistoryTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get totalValue => $state.composableBuilder(
      column: $state.table.totalValue,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$PortfolioHistoryTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $PortfolioHistoryTable> {
  $$PortfolioHistoryTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get totalValue => $state.composableBuilder(
      column: $state.table.totalValue,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CardSetsTableTableManager get cardSets =>
      $$CardSetsTableTableManager(_db, _db.cardSets);
  $$CardsTableTableManager get cards =>
      $$CardsTableTableManager(_db, _db.cards);
  $$CardMarketPricesTableTableManager get cardMarketPrices =>
      $$CardMarketPricesTableTableManager(_db, _db.cardMarketPrices);
  $$TcgPlayerPricesTableTableManager get tcgPlayerPrices =>
      $$TcgPlayerPricesTableTableManager(_db, _db.tcgPlayerPrices);
  $$UserCardsTableTableManager get userCards =>
      $$UserCardsTableTableManager(_db, _db.userCards);
  $$PortfolioHistoryTableTableManager get portfolioHistory =>
      $$PortfolioHistoryTableTableManager(_db, _db.portfolioHistory);
}
