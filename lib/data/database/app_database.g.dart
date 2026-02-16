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
      'printed_total', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
      'total', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _releaseDateMeta =
      const VerificationMeta('releaseDate');
  @override
  late final GeneratedColumn<String> releaseDate = GeneratedColumn<String>(
      'release_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
      'logo_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _symbolUrlMeta =
      const VerificationMeta('symbolUrl');
  @override
  late final GeneratedColumn<String> symbolUrl = GeneratedColumn<String>(
      'symbol_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _logoUrlDeMeta =
      const VerificationMeta('logoUrlDe');
  @override
  late final GeneratedColumn<String> logoUrlDe = GeneratedColumn<String>(
      'logo_url_de', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameDeMeta = const VerificationMeta('nameDe');
  @override
  late final GeneratedColumn<String> nameDe = GeneratedColumn<String>(
      'name_de', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
        symbolUrl,
        logoUrlDe,
        nameDe
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
    }
    if (data.containsKey('total')) {
      context.handle(
          _totalMeta, total.isAcceptableOrUnknown(data['total']!, _totalMeta));
    }
    if (data.containsKey('release_date')) {
      context.handle(
          _releaseDateMeta,
          releaseDate.isAcceptableOrUnknown(
              data['release_date']!, _releaseDateMeta));
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
    }
    if (data.containsKey('symbol_url')) {
      context.handle(_symbolUrlMeta,
          symbolUrl.isAcceptableOrUnknown(data['symbol_url']!, _symbolUrlMeta));
    }
    if (data.containsKey('logo_url_de')) {
      context.handle(
          _logoUrlDeMeta,
          logoUrlDe.isAcceptableOrUnknown(
              data['logo_url_de']!, _logoUrlDeMeta));
    }
    if (data.containsKey('name_de')) {
      context.handle(_nameDeMeta,
          nameDe.isAcceptableOrUnknown(data['name_de']!, _nameDeMeta));
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
          .read(DriftSqlType.int, data['${effectivePrefix}printed_total']),
      total: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total']),
      releaseDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}release_date']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      logoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}logo_url']),
      symbolUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}symbol_url']),
      logoUrlDe: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}logo_url_de']),
      nameDe: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_de']),
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
  final int? printedTotal;
  final int? total;
  final String? releaseDate;
  final String updatedAt;
  final String? logoUrl;
  final String? symbolUrl;
  final String? logoUrlDe;
  final String? nameDe;
  const CardSet(
      {required this.id,
      required this.name,
      required this.series,
      this.printedTotal,
      this.total,
      this.releaseDate,
      required this.updatedAt,
      this.logoUrl,
      this.symbolUrl,
      this.logoUrlDe,
      this.nameDe});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['series'] = Variable<String>(series);
    if (!nullToAbsent || printedTotal != null) {
      map['printed_total'] = Variable<int>(printedTotal);
    }
    if (!nullToAbsent || total != null) {
      map['total'] = Variable<int>(total);
    }
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<String>(releaseDate);
    }
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || logoUrl != null) {
      map['logo_url'] = Variable<String>(logoUrl);
    }
    if (!nullToAbsent || symbolUrl != null) {
      map['symbol_url'] = Variable<String>(symbolUrl);
    }
    if (!nullToAbsent || logoUrlDe != null) {
      map['logo_url_de'] = Variable<String>(logoUrlDe);
    }
    if (!nullToAbsent || nameDe != null) {
      map['name_de'] = Variable<String>(nameDe);
    }
    return map;
  }

  CardSetsCompanion toCompanion(bool nullToAbsent) {
    return CardSetsCompanion(
      id: Value(id),
      name: Value(name),
      series: Value(series),
      printedTotal: printedTotal == null && nullToAbsent
          ? const Value.absent()
          : Value(printedTotal),
      total:
          total == null && nullToAbsent ? const Value.absent() : Value(total),
      releaseDate: releaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseDate),
      updatedAt: Value(updatedAt),
      logoUrl: logoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(logoUrl),
      symbolUrl: symbolUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(symbolUrl),
      logoUrlDe: logoUrlDe == null && nullToAbsent
          ? const Value.absent()
          : Value(logoUrlDe),
      nameDe:
          nameDe == null && nullToAbsent ? const Value.absent() : Value(nameDe),
    );
  }

  factory CardSet.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardSet(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      series: serializer.fromJson<String>(json['series']),
      printedTotal: serializer.fromJson<int?>(json['printedTotal']),
      total: serializer.fromJson<int?>(json['total']),
      releaseDate: serializer.fromJson<String?>(json['releaseDate']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      logoUrl: serializer.fromJson<String?>(json['logoUrl']),
      symbolUrl: serializer.fromJson<String?>(json['symbolUrl']),
      logoUrlDe: serializer.fromJson<String?>(json['logoUrlDe']),
      nameDe: serializer.fromJson<String?>(json['nameDe']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'series': serializer.toJson<String>(series),
      'printedTotal': serializer.toJson<int?>(printedTotal),
      'total': serializer.toJson<int?>(total),
      'releaseDate': serializer.toJson<String?>(releaseDate),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'logoUrl': serializer.toJson<String?>(logoUrl),
      'symbolUrl': serializer.toJson<String?>(symbolUrl),
      'logoUrlDe': serializer.toJson<String?>(logoUrlDe),
      'nameDe': serializer.toJson<String?>(nameDe),
    };
  }

  CardSet copyWith(
          {String? id,
          String? name,
          String? series,
          Value<int?> printedTotal = const Value.absent(),
          Value<int?> total = const Value.absent(),
          Value<String?> releaseDate = const Value.absent(),
          String? updatedAt,
          Value<String?> logoUrl = const Value.absent(),
          Value<String?> symbolUrl = const Value.absent(),
          Value<String?> logoUrlDe = const Value.absent(),
          Value<String?> nameDe = const Value.absent()}) =>
      CardSet(
        id: id ?? this.id,
        name: name ?? this.name,
        series: series ?? this.series,
        printedTotal:
            printedTotal.present ? printedTotal.value : this.printedTotal,
        total: total.present ? total.value : this.total,
        releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
        updatedAt: updatedAt ?? this.updatedAt,
        logoUrl: logoUrl.present ? logoUrl.value : this.logoUrl,
        symbolUrl: symbolUrl.present ? symbolUrl.value : this.symbolUrl,
        logoUrlDe: logoUrlDe.present ? logoUrlDe.value : this.logoUrlDe,
        nameDe: nameDe.present ? nameDe.value : this.nameDe,
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
      logoUrlDe: data.logoUrlDe.present ? data.logoUrlDe.value : this.logoUrlDe,
      nameDe: data.nameDe.present ? data.nameDe.value : this.nameDe,
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
          ..write('symbolUrl: $symbolUrl, ')
          ..write('logoUrlDe: $logoUrlDe, ')
          ..write('nameDe: $nameDe')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, series, printedTotal, total,
      releaseDate, updatedAt, logoUrl, symbolUrl, logoUrlDe, nameDe);
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
          other.symbolUrl == this.symbolUrl &&
          other.logoUrlDe == this.logoUrlDe &&
          other.nameDe == this.nameDe);
}

class CardSetsCompanion extends UpdateCompanion<CardSet> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> series;
  final Value<int?> printedTotal;
  final Value<int?> total;
  final Value<String?> releaseDate;
  final Value<String> updatedAt;
  final Value<String?> logoUrl;
  final Value<String?> symbolUrl;
  final Value<String?> logoUrlDe;
  final Value<String?> nameDe;
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
    this.logoUrlDe = const Value.absent(),
    this.nameDe = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardSetsCompanion.insert({
    required String id,
    required String name,
    required String series,
    this.printedTotal = const Value.absent(),
    this.total = const Value.absent(),
    this.releaseDate = const Value.absent(),
    required String updatedAt,
    this.logoUrl = const Value.absent(),
    this.symbolUrl = const Value.absent(),
    this.logoUrlDe = const Value.absent(),
    this.nameDe = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        series = Value(series),
        updatedAt = Value(updatedAt);
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
    Expression<String>? logoUrlDe,
    Expression<String>? nameDe,
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
      if (logoUrlDe != null) 'logo_url_de': logoUrlDe,
      if (nameDe != null) 'name_de': nameDe,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardSetsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? series,
      Value<int?>? printedTotal,
      Value<int?>? total,
      Value<String?>? releaseDate,
      Value<String>? updatedAt,
      Value<String?>? logoUrl,
      Value<String?>? symbolUrl,
      Value<String?>? logoUrlDe,
      Value<String?>? nameDe,
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
      logoUrlDe: logoUrlDe ?? this.logoUrlDe,
      nameDe: nameDe ?? this.nameDe,
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
    if (logoUrlDe.present) {
      map['logo_url_de'] = Variable<String>(logoUrlDe.value);
    }
    if (nameDe.present) {
      map['name_de'] = Variable<String>(nameDe.value);
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
          ..write('logoUrlDe: $logoUrlDe, ')
          ..write('nameDe: $nameDe, ')
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
  static const VerificationMeta _nameDeMeta = const VerificationMeta('nameDe');
  @override
  late final GeneratedColumn<String> nameDe = GeneratedColumn<String>(
      'name_de', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
      'number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _imageUrlDeMeta =
      const VerificationMeta('imageUrlDe');
  @override
  late final GeneratedColumn<String> imageUrlDe = GeneratedColumn<String>(
      'image_url_de', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
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
  static const VerificationMeta _flavorTextDeMeta =
      const VerificationMeta('flavorTextDe');
  @override
  late final GeneratedColumn<String> flavorTextDe = GeneratedColumn<String>(
      'flavor_text_de', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _hasFirstEditionMeta =
      const VerificationMeta('hasFirstEdition');
  @override
  late final GeneratedColumn<bool> hasFirstEdition = GeneratedColumn<bool>(
      'has_first_edition', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_first_edition" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _hasNormalMeta =
      const VerificationMeta('hasNormal');
  @override
  late final GeneratedColumn<bool> hasNormal = GeneratedColumn<bool>(
      'has_normal', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("has_normal" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _hasHoloMeta =
      const VerificationMeta('hasHolo');
  @override
  late final GeneratedColumn<bool> hasHolo = GeneratedColumn<bool>(
      'has_holo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("has_holo" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _hasReverseMeta =
      const VerificationMeta('hasReverse');
  @override
  late final GeneratedColumn<bool> hasReverse = GeneratedColumn<bool>(
      'has_reverse', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("has_reverse" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _hasWPromoMeta =
      const VerificationMeta('hasWPromo');
  @override
  late final GeneratedColumn<bool> hasWPromo = GeneratedColumn<bool>(
      'has_w_promo', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("has_w_promo" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortNumberMeta =
      const VerificationMeta('sortNumber');
  @override
  late final GeneratedColumn<int> sortNumber = GeneratedColumn<int>(
      'sort_number', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        setId,
        name,
        nameDe,
        number,
        imageUrl,
        imageUrlDe,
        artist,
        rarity,
        flavorText,
        flavorTextDe,
        hasFirstEdition,
        hasNormal,
        hasHolo,
        hasReverse,
        hasWPromo,
        sortNumber
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
    if (data.containsKey('name_de')) {
      context.handle(_nameDeMeta,
          nameDe.isAcceptableOrUnknown(data['name_de']!, _nameDeMeta));
    }
    if (data.containsKey('number')) {
      context.handle(_numberMeta,
          number.isAcceptableOrUnknown(data['number']!, _numberMeta));
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    } else if (isInserting) {
      context.missing(_imageUrlMeta);
    }
    if (data.containsKey('image_url_de')) {
      context.handle(
          _imageUrlDeMeta,
          imageUrlDe.isAcceptableOrUnknown(
              data['image_url_de']!, _imageUrlDeMeta));
    } else if (isInserting) {
      context.missing(_imageUrlDeMeta);
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
    if (data.containsKey('flavor_text_de')) {
      context.handle(
          _flavorTextDeMeta,
          flavorTextDe.isAcceptableOrUnknown(
              data['flavor_text_de']!, _flavorTextDeMeta));
    }
    if (data.containsKey('has_first_edition')) {
      context.handle(
          _hasFirstEditionMeta,
          hasFirstEdition.isAcceptableOrUnknown(
              data['has_first_edition']!, _hasFirstEditionMeta));
    }
    if (data.containsKey('has_normal')) {
      context.handle(_hasNormalMeta,
          hasNormal.isAcceptableOrUnknown(data['has_normal']!, _hasNormalMeta));
    }
    if (data.containsKey('has_holo')) {
      context.handle(_hasHoloMeta,
          hasHolo.isAcceptableOrUnknown(data['has_holo']!, _hasHoloMeta));
    }
    if (data.containsKey('has_reverse')) {
      context.handle(
          _hasReverseMeta,
          hasReverse.isAcceptableOrUnknown(
              data['has_reverse']!, _hasReverseMeta));
    }
    if (data.containsKey('has_w_promo')) {
      context.handle(
          _hasWPromoMeta,
          hasWPromo.isAcceptableOrUnknown(
              data['has_w_promo']!, _hasWPromoMeta));
    }
    if (data.containsKey('sort_number')) {
      context.handle(
          _sortNumberMeta,
          sortNumber.isAcceptableOrUnknown(
              data['sort_number']!, _sortNumberMeta));
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
      nameDe: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_de']),
      number: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}number'])!,
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url'])!,
      imageUrlDe: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url_de'])!,
      artist: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artist']),
      rarity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rarity']),
      flavorText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}flavor_text']),
      flavorTextDe: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}flavor_text_de']),
      hasFirstEdition: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}has_first_edition'])!,
      hasNormal: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_normal'])!,
      hasHolo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_holo'])!,
      hasReverse: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_reverse'])!,
      hasWPromo: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_w_promo'])!,
      sortNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_number'])!,
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
  final String? nameDe;
  final String number;
  final String imageUrl;
  final String imageUrlDe;
  final String? artist;
  final String? rarity;
  final String? flavorText;
  final String? flavorTextDe;
  final bool hasFirstEdition;
  final bool hasNormal;
  final bool hasHolo;
  final bool hasReverse;
  final bool hasWPromo;
  final int sortNumber;
  const Card(
      {required this.id,
      required this.setId,
      required this.name,
      this.nameDe,
      required this.number,
      required this.imageUrl,
      required this.imageUrlDe,
      this.artist,
      this.rarity,
      this.flavorText,
      this.flavorTextDe,
      required this.hasFirstEdition,
      required this.hasNormal,
      required this.hasHolo,
      required this.hasReverse,
      required this.hasWPromo,
      required this.sortNumber});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['set_id'] = Variable<String>(setId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || nameDe != null) {
      map['name_de'] = Variable<String>(nameDe);
    }
    map['number'] = Variable<String>(number);
    map['image_url'] = Variable<String>(imageUrl);
    map['image_url_de'] = Variable<String>(imageUrlDe);
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    if (!nullToAbsent || rarity != null) {
      map['rarity'] = Variable<String>(rarity);
    }
    if (!nullToAbsent || flavorText != null) {
      map['flavor_text'] = Variable<String>(flavorText);
    }
    if (!nullToAbsent || flavorTextDe != null) {
      map['flavor_text_de'] = Variable<String>(flavorTextDe);
    }
    map['has_first_edition'] = Variable<bool>(hasFirstEdition);
    map['has_normal'] = Variable<bool>(hasNormal);
    map['has_holo'] = Variable<bool>(hasHolo);
    map['has_reverse'] = Variable<bool>(hasReverse);
    map['has_w_promo'] = Variable<bool>(hasWPromo);
    map['sort_number'] = Variable<int>(sortNumber);
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      id: Value(id),
      setId: Value(setId),
      name: Value(name),
      nameDe:
          nameDe == null && nullToAbsent ? const Value.absent() : Value(nameDe),
      number: Value(number),
      imageUrl: Value(imageUrl),
      imageUrlDe: Value(imageUrlDe),
      artist:
          artist == null && nullToAbsent ? const Value.absent() : Value(artist),
      rarity:
          rarity == null && nullToAbsent ? const Value.absent() : Value(rarity),
      flavorText: flavorText == null && nullToAbsent
          ? const Value.absent()
          : Value(flavorText),
      flavorTextDe: flavorTextDe == null && nullToAbsent
          ? const Value.absent()
          : Value(flavorTextDe),
      hasFirstEdition: Value(hasFirstEdition),
      hasNormal: Value(hasNormal),
      hasHolo: Value(hasHolo),
      hasReverse: Value(hasReverse),
      hasWPromo: Value(hasWPromo),
      sortNumber: Value(sortNumber),
    );
  }

  factory Card.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Card(
      id: serializer.fromJson<String>(json['id']),
      setId: serializer.fromJson<String>(json['setId']),
      name: serializer.fromJson<String>(json['name']),
      nameDe: serializer.fromJson<String?>(json['nameDe']),
      number: serializer.fromJson<String>(json['number']),
      imageUrl: serializer.fromJson<String>(json['imageUrl']),
      imageUrlDe: serializer.fromJson<String>(json['imageUrlDe']),
      artist: serializer.fromJson<String?>(json['artist']),
      rarity: serializer.fromJson<String?>(json['rarity']),
      flavorText: serializer.fromJson<String?>(json['flavorText']),
      flavorTextDe: serializer.fromJson<String?>(json['flavorTextDe']),
      hasFirstEdition: serializer.fromJson<bool>(json['hasFirstEdition']),
      hasNormal: serializer.fromJson<bool>(json['hasNormal']),
      hasHolo: serializer.fromJson<bool>(json['hasHolo']),
      hasReverse: serializer.fromJson<bool>(json['hasReverse']),
      hasWPromo: serializer.fromJson<bool>(json['hasWPromo']),
      sortNumber: serializer.fromJson<int>(json['sortNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'setId': serializer.toJson<String>(setId),
      'name': serializer.toJson<String>(name),
      'nameDe': serializer.toJson<String?>(nameDe),
      'number': serializer.toJson<String>(number),
      'imageUrl': serializer.toJson<String>(imageUrl),
      'imageUrlDe': serializer.toJson<String>(imageUrlDe),
      'artist': serializer.toJson<String?>(artist),
      'rarity': serializer.toJson<String?>(rarity),
      'flavorText': serializer.toJson<String?>(flavorText),
      'flavorTextDe': serializer.toJson<String?>(flavorTextDe),
      'hasFirstEdition': serializer.toJson<bool>(hasFirstEdition),
      'hasNormal': serializer.toJson<bool>(hasNormal),
      'hasHolo': serializer.toJson<bool>(hasHolo),
      'hasReverse': serializer.toJson<bool>(hasReverse),
      'hasWPromo': serializer.toJson<bool>(hasWPromo),
      'sortNumber': serializer.toJson<int>(sortNumber),
    };
  }

  Card copyWith(
          {String? id,
          String? setId,
          String? name,
          Value<String?> nameDe = const Value.absent(),
          String? number,
          String? imageUrl,
          String? imageUrlDe,
          Value<String?> artist = const Value.absent(),
          Value<String?> rarity = const Value.absent(),
          Value<String?> flavorText = const Value.absent(),
          Value<String?> flavorTextDe = const Value.absent(),
          bool? hasFirstEdition,
          bool? hasNormal,
          bool? hasHolo,
          bool? hasReverse,
          bool? hasWPromo,
          int? sortNumber}) =>
      Card(
        id: id ?? this.id,
        setId: setId ?? this.setId,
        name: name ?? this.name,
        nameDe: nameDe.present ? nameDe.value : this.nameDe,
        number: number ?? this.number,
        imageUrl: imageUrl ?? this.imageUrl,
        imageUrlDe: imageUrlDe ?? this.imageUrlDe,
        artist: artist.present ? artist.value : this.artist,
        rarity: rarity.present ? rarity.value : this.rarity,
        flavorText: flavorText.present ? flavorText.value : this.flavorText,
        flavorTextDe:
            flavorTextDe.present ? flavorTextDe.value : this.flavorTextDe,
        hasFirstEdition: hasFirstEdition ?? this.hasFirstEdition,
        hasNormal: hasNormal ?? this.hasNormal,
        hasHolo: hasHolo ?? this.hasHolo,
        hasReverse: hasReverse ?? this.hasReverse,
        hasWPromo: hasWPromo ?? this.hasWPromo,
        sortNumber: sortNumber ?? this.sortNumber,
      );
  Card copyWithCompanion(CardsCompanion data) {
    return Card(
      id: data.id.present ? data.id.value : this.id,
      setId: data.setId.present ? data.setId.value : this.setId,
      name: data.name.present ? data.name.value : this.name,
      nameDe: data.nameDe.present ? data.nameDe.value : this.nameDe,
      number: data.number.present ? data.number.value : this.number,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      imageUrlDe:
          data.imageUrlDe.present ? data.imageUrlDe.value : this.imageUrlDe,
      artist: data.artist.present ? data.artist.value : this.artist,
      rarity: data.rarity.present ? data.rarity.value : this.rarity,
      flavorText:
          data.flavorText.present ? data.flavorText.value : this.flavorText,
      flavorTextDe: data.flavorTextDe.present
          ? data.flavorTextDe.value
          : this.flavorTextDe,
      hasFirstEdition: data.hasFirstEdition.present
          ? data.hasFirstEdition.value
          : this.hasFirstEdition,
      hasNormal: data.hasNormal.present ? data.hasNormal.value : this.hasNormal,
      hasHolo: data.hasHolo.present ? data.hasHolo.value : this.hasHolo,
      hasReverse:
          data.hasReverse.present ? data.hasReverse.value : this.hasReverse,
      hasWPromo: data.hasWPromo.present ? data.hasWPromo.value : this.hasWPromo,
      sortNumber:
          data.sortNumber.present ? data.sortNumber.value : this.sortNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Card(')
          ..write('id: $id, ')
          ..write('setId: $setId, ')
          ..write('name: $name, ')
          ..write('nameDe: $nameDe, ')
          ..write('number: $number, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('imageUrlDe: $imageUrlDe, ')
          ..write('artist: $artist, ')
          ..write('rarity: $rarity, ')
          ..write('flavorText: $flavorText, ')
          ..write('flavorTextDe: $flavorTextDe, ')
          ..write('hasFirstEdition: $hasFirstEdition, ')
          ..write('hasNormal: $hasNormal, ')
          ..write('hasHolo: $hasHolo, ')
          ..write('hasReverse: $hasReverse, ')
          ..write('hasWPromo: $hasWPromo, ')
          ..write('sortNumber: $sortNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      setId,
      name,
      nameDe,
      number,
      imageUrl,
      imageUrlDe,
      artist,
      rarity,
      flavorText,
      flavorTextDe,
      hasFirstEdition,
      hasNormal,
      hasHolo,
      hasReverse,
      hasWPromo,
      sortNumber);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Card &&
          other.id == this.id &&
          other.setId == this.setId &&
          other.name == this.name &&
          other.nameDe == this.nameDe &&
          other.number == this.number &&
          other.imageUrl == this.imageUrl &&
          other.imageUrlDe == this.imageUrlDe &&
          other.artist == this.artist &&
          other.rarity == this.rarity &&
          other.flavorText == this.flavorText &&
          other.flavorTextDe == this.flavorTextDe &&
          other.hasFirstEdition == this.hasFirstEdition &&
          other.hasNormal == this.hasNormal &&
          other.hasHolo == this.hasHolo &&
          other.hasReverse == this.hasReverse &&
          other.hasWPromo == this.hasWPromo &&
          other.sortNumber == this.sortNumber);
}

class CardsCompanion extends UpdateCompanion<Card> {
  final Value<String> id;
  final Value<String> setId;
  final Value<String> name;
  final Value<String?> nameDe;
  final Value<String> number;
  final Value<String> imageUrl;
  final Value<String> imageUrlDe;
  final Value<String?> artist;
  final Value<String?> rarity;
  final Value<String?> flavorText;
  final Value<String?> flavorTextDe;
  final Value<bool> hasFirstEdition;
  final Value<bool> hasNormal;
  final Value<bool> hasHolo;
  final Value<bool> hasReverse;
  final Value<bool> hasWPromo;
  final Value<int> sortNumber;
  final Value<int> rowid;
  const CardsCompanion({
    this.id = const Value.absent(),
    this.setId = const Value.absent(),
    this.name = const Value.absent(),
    this.nameDe = const Value.absent(),
    this.number = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.imageUrlDe = const Value.absent(),
    this.artist = const Value.absent(),
    this.rarity = const Value.absent(),
    this.flavorText = const Value.absent(),
    this.flavorTextDe = const Value.absent(),
    this.hasFirstEdition = const Value.absent(),
    this.hasNormal = const Value.absent(),
    this.hasHolo = const Value.absent(),
    this.hasReverse = const Value.absent(),
    this.hasWPromo = const Value.absent(),
    this.sortNumber = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardsCompanion.insert({
    required String id,
    required String setId,
    required String name,
    this.nameDe = const Value.absent(),
    required String number,
    required String imageUrl,
    required String imageUrlDe,
    this.artist = const Value.absent(),
    this.rarity = const Value.absent(),
    this.flavorText = const Value.absent(),
    this.flavorTextDe = const Value.absent(),
    this.hasFirstEdition = const Value.absent(),
    this.hasNormal = const Value.absent(),
    this.hasHolo = const Value.absent(),
    this.hasReverse = const Value.absent(),
    this.hasWPromo = const Value.absent(),
    this.sortNumber = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        setId = Value(setId),
        name = Value(name),
        number = Value(number),
        imageUrl = Value(imageUrl),
        imageUrlDe = Value(imageUrlDe);
  static Insertable<Card> custom({
    Expression<String>? id,
    Expression<String>? setId,
    Expression<String>? name,
    Expression<String>? nameDe,
    Expression<String>? number,
    Expression<String>? imageUrl,
    Expression<String>? imageUrlDe,
    Expression<String>? artist,
    Expression<String>? rarity,
    Expression<String>? flavorText,
    Expression<String>? flavorTextDe,
    Expression<bool>? hasFirstEdition,
    Expression<bool>? hasNormal,
    Expression<bool>? hasHolo,
    Expression<bool>? hasReverse,
    Expression<bool>? hasWPromo,
    Expression<int>? sortNumber,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (setId != null) 'set_id': setId,
      if (name != null) 'name': name,
      if (nameDe != null) 'name_de': nameDe,
      if (number != null) 'number': number,
      if (imageUrl != null) 'image_url': imageUrl,
      if (imageUrlDe != null) 'image_url_de': imageUrlDe,
      if (artist != null) 'artist': artist,
      if (rarity != null) 'rarity': rarity,
      if (flavorText != null) 'flavor_text': flavorText,
      if (flavorTextDe != null) 'flavor_text_de': flavorTextDe,
      if (hasFirstEdition != null) 'has_first_edition': hasFirstEdition,
      if (hasNormal != null) 'has_normal': hasNormal,
      if (hasHolo != null) 'has_holo': hasHolo,
      if (hasReverse != null) 'has_reverse': hasReverse,
      if (hasWPromo != null) 'has_w_promo': hasWPromo,
      if (sortNumber != null) 'sort_number': sortNumber,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardsCompanion copyWith(
      {Value<String>? id,
      Value<String>? setId,
      Value<String>? name,
      Value<String?>? nameDe,
      Value<String>? number,
      Value<String>? imageUrl,
      Value<String>? imageUrlDe,
      Value<String?>? artist,
      Value<String?>? rarity,
      Value<String?>? flavorText,
      Value<String?>? flavorTextDe,
      Value<bool>? hasFirstEdition,
      Value<bool>? hasNormal,
      Value<bool>? hasHolo,
      Value<bool>? hasReverse,
      Value<bool>? hasWPromo,
      Value<int>? sortNumber,
      Value<int>? rowid}) {
    return CardsCompanion(
      id: id ?? this.id,
      setId: setId ?? this.setId,
      name: name ?? this.name,
      nameDe: nameDe ?? this.nameDe,
      number: number ?? this.number,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrlDe: imageUrlDe ?? this.imageUrlDe,
      artist: artist ?? this.artist,
      rarity: rarity ?? this.rarity,
      flavorText: flavorText ?? this.flavorText,
      flavorTextDe: flavorTextDe ?? this.flavorTextDe,
      hasFirstEdition: hasFirstEdition ?? this.hasFirstEdition,
      hasNormal: hasNormal ?? this.hasNormal,
      hasHolo: hasHolo ?? this.hasHolo,
      hasReverse: hasReverse ?? this.hasReverse,
      hasWPromo: hasWPromo ?? this.hasWPromo,
      sortNumber: sortNumber ?? this.sortNumber,
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
    if (nameDe.present) {
      map['name_de'] = Variable<String>(nameDe.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (imageUrlDe.present) {
      map['image_url_de'] = Variable<String>(imageUrlDe.value);
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
    if (flavorTextDe.present) {
      map['flavor_text_de'] = Variable<String>(flavorTextDe.value);
    }
    if (hasFirstEdition.present) {
      map['has_first_edition'] = Variable<bool>(hasFirstEdition.value);
    }
    if (hasNormal.present) {
      map['has_normal'] = Variable<bool>(hasNormal.value);
    }
    if (hasHolo.present) {
      map['has_holo'] = Variable<bool>(hasHolo.value);
    }
    if (hasReverse.present) {
      map['has_reverse'] = Variable<bool>(hasReverse.value);
    }
    if (hasWPromo.present) {
      map['has_w_promo'] = Variable<bool>(hasWPromo.value);
    }
    if (sortNumber.present) {
      map['sort_number'] = Variable<int>(sortNumber.value);
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
          ..write('nameDe: $nameDe, ')
          ..write('number: $number, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('imageUrlDe: $imageUrlDe, ')
          ..write('artist: $artist, ')
          ..write('rarity: $rarity, ')
          ..write('flavorText: $flavorText, ')
          ..write('flavorTextDe: $flavorTextDe, ')
          ..write('hasFirstEdition: $hasFirstEdition, ')
          ..write('hasNormal: $hasNormal, ')
          ..write('hasHolo: $hasHolo, ')
          ..write('hasReverse: $hasReverse, ')
          ..write('hasWPromo: $hasWPromo, ')
          ..write('sortNumber: $sortNumber, ')
          ..write('rowid: $rowid')
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
  static const VerificationMeta _averageMeta =
      const VerificationMeta('average');
  @override
  late final GeneratedColumn<double> average = GeneratedColumn<double>(
      'average', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _lowMeta = const VerificationMeta('low');
  @override
  late final GeneratedColumn<double> low = GeneratedColumn<double>(
      'low', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _trendMeta = const VerificationMeta('trend');
  @override
  late final GeneratedColumn<double> trend = GeneratedColumn<double>(
      'trend', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avg1Meta = const VerificationMeta('avg1');
  @override
  late final GeneratedColumn<double> avg1 = GeneratedColumn<double>(
      'avg1', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avg7Meta = const VerificationMeta('avg7');
  @override
  late final GeneratedColumn<double> avg7 = GeneratedColumn<double>(
      'avg7', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avg30Meta = const VerificationMeta('avg30');
  @override
  late final GeneratedColumn<double> avg30 = GeneratedColumn<double>(
      'avg30', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avgHoloMeta =
      const VerificationMeta('avgHolo');
  @override
  late final GeneratedColumn<double> avgHolo = GeneratedColumn<double>(
      'avg_holo', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _lowHoloMeta =
      const VerificationMeta('lowHolo');
  @override
  late final GeneratedColumn<double> lowHolo = GeneratedColumn<double>(
      'low_holo', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _trendHoloMeta =
      const VerificationMeta('trendHolo');
  @override
  late final GeneratedColumn<double> trendHolo = GeneratedColumn<double>(
      'trend_holo', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avg1HoloMeta =
      const VerificationMeta('avg1Holo');
  @override
  late final GeneratedColumn<double> avg1Holo = GeneratedColumn<double>(
      'avg1_holo', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avg7HoloMeta =
      const VerificationMeta('avg7Holo');
  @override
  late final GeneratedColumn<double> avg7Holo = GeneratedColumn<double>(
      'avg7_holo', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avg30HoloMeta =
      const VerificationMeta('avg30Holo');
  @override
  late final GeneratedColumn<double> avg30Holo = GeneratedColumn<double>(
      'avg30_holo', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _trendReverseMeta =
      const VerificationMeta('trendReverse');
  @override
  late final GeneratedColumn<double> trendReverse = GeneratedColumn<double>(
      'trend_reverse', aliasedName, true,
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
        average,
        low,
        trend,
        avg1,
        avg7,
        avg30,
        avgHolo,
        lowHolo,
        trendHolo,
        avg1Holo,
        avg7Holo,
        avg30Holo,
        trendReverse,
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
    if (data.containsKey('average')) {
      context.handle(_averageMeta,
          average.isAcceptableOrUnknown(data['average']!, _averageMeta));
    }
    if (data.containsKey('low')) {
      context.handle(
          _lowMeta, low.isAcceptableOrUnknown(data['low']!, _lowMeta));
    }
    if (data.containsKey('trend')) {
      context.handle(
          _trendMeta, trend.isAcceptableOrUnknown(data['trend']!, _trendMeta));
    }
    if (data.containsKey('avg1')) {
      context.handle(
          _avg1Meta, avg1.isAcceptableOrUnknown(data['avg1']!, _avg1Meta));
    }
    if (data.containsKey('avg7')) {
      context.handle(
          _avg7Meta, avg7.isAcceptableOrUnknown(data['avg7']!, _avg7Meta));
    }
    if (data.containsKey('avg30')) {
      context.handle(
          _avg30Meta, avg30.isAcceptableOrUnknown(data['avg30']!, _avg30Meta));
    }
    if (data.containsKey('avg_holo')) {
      context.handle(_avgHoloMeta,
          avgHolo.isAcceptableOrUnknown(data['avg_holo']!, _avgHoloMeta));
    }
    if (data.containsKey('low_holo')) {
      context.handle(_lowHoloMeta,
          lowHolo.isAcceptableOrUnknown(data['low_holo']!, _lowHoloMeta));
    }
    if (data.containsKey('trend_holo')) {
      context.handle(_trendHoloMeta,
          trendHolo.isAcceptableOrUnknown(data['trend_holo']!, _trendHoloMeta));
    }
    if (data.containsKey('avg1_holo')) {
      context.handle(_avg1HoloMeta,
          avg1Holo.isAcceptableOrUnknown(data['avg1_holo']!, _avg1HoloMeta));
    }
    if (data.containsKey('avg7_holo')) {
      context.handle(_avg7HoloMeta,
          avg7Holo.isAcceptableOrUnknown(data['avg7_holo']!, _avg7HoloMeta));
    }
    if (data.containsKey('avg30_holo')) {
      context.handle(_avg30HoloMeta,
          avg30Holo.isAcceptableOrUnknown(data['avg30_holo']!, _avg30HoloMeta));
    }
    if (data.containsKey('trend_reverse')) {
      context.handle(
          _trendReverseMeta,
          trendReverse.isAcceptableOrUnknown(
              data['trend_reverse']!, _trendReverseMeta));
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
      average: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}average']),
      low: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}low']),
      trend: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}trend']),
      avg1: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg1']),
      avg7: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg7']),
      avg30: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg30']),
      avgHolo: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_holo']),
      lowHolo: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}low_holo']),
      trendHolo: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}trend_holo']),
      avg1Holo: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg1_holo']),
      avg7Holo: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg7_holo']),
      avg30Holo: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg30_holo']),
      trendReverse: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}trend_reverse']),
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
  final double? average;
  final double? low;
  final double? trend;
  final double? avg1;
  final double? avg7;
  final double? avg30;
  final double? avgHolo;
  final double? lowHolo;
  final double? trendHolo;
  final double? avg1Holo;
  final double? avg7Holo;
  final double? avg30Holo;
  final double? trendReverse;
  final String? url;
  const CardMarketPrice(
      {required this.id,
      required this.cardId,
      required this.fetchedAt,
      this.average,
      this.low,
      this.trend,
      this.avg1,
      this.avg7,
      this.avg30,
      this.avgHolo,
      this.lowHolo,
      this.trendHolo,
      this.avg1Holo,
      this.avg7Holo,
      this.avg30Holo,
      this.trendReverse,
      this.url});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['card_id'] = Variable<String>(cardId);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    if (!nullToAbsent || average != null) {
      map['average'] = Variable<double>(average);
    }
    if (!nullToAbsent || low != null) {
      map['low'] = Variable<double>(low);
    }
    if (!nullToAbsent || trend != null) {
      map['trend'] = Variable<double>(trend);
    }
    if (!nullToAbsent || avg1 != null) {
      map['avg1'] = Variable<double>(avg1);
    }
    if (!nullToAbsent || avg7 != null) {
      map['avg7'] = Variable<double>(avg7);
    }
    if (!nullToAbsent || avg30 != null) {
      map['avg30'] = Variable<double>(avg30);
    }
    if (!nullToAbsent || avgHolo != null) {
      map['avg_holo'] = Variable<double>(avgHolo);
    }
    if (!nullToAbsent || lowHolo != null) {
      map['low_holo'] = Variable<double>(lowHolo);
    }
    if (!nullToAbsent || trendHolo != null) {
      map['trend_holo'] = Variable<double>(trendHolo);
    }
    if (!nullToAbsent || avg1Holo != null) {
      map['avg1_holo'] = Variable<double>(avg1Holo);
    }
    if (!nullToAbsent || avg7Holo != null) {
      map['avg7_holo'] = Variable<double>(avg7Holo);
    }
    if (!nullToAbsent || avg30Holo != null) {
      map['avg30_holo'] = Variable<double>(avg30Holo);
    }
    if (!nullToAbsent || trendReverse != null) {
      map['trend_reverse'] = Variable<double>(trendReverse);
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
      average: average == null && nullToAbsent
          ? const Value.absent()
          : Value(average),
      low: low == null && nullToAbsent ? const Value.absent() : Value(low),
      trend:
          trend == null && nullToAbsent ? const Value.absent() : Value(trend),
      avg1: avg1 == null && nullToAbsent ? const Value.absent() : Value(avg1),
      avg7: avg7 == null && nullToAbsent ? const Value.absent() : Value(avg7),
      avg30:
          avg30 == null && nullToAbsent ? const Value.absent() : Value(avg30),
      avgHolo: avgHolo == null && nullToAbsent
          ? const Value.absent()
          : Value(avgHolo),
      lowHolo: lowHolo == null && nullToAbsent
          ? const Value.absent()
          : Value(lowHolo),
      trendHolo: trendHolo == null && nullToAbsent
          ? const Value.absent()
          : Value(trendHolo),
      avg1Holo: avg1Holo == null && nullToAbsent
          ? const Value.absent()
          : Value(avg1Holo),
      avg7Holo: avg7Holo == null && nullToAbsent
          ? const Value.absent()
          : Value(avg7Holo),
      avg30Holo: avg30Holo == null && nullToAbsent
          ? const Value.absent()
          : Value(avg30Holo),
      trendReverse: trendReverse == null && nullToAbsent
          ? const Value.absent()
          : Value(trendReverse),
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
      average: serializer.fromJson<double?>(json['average']),
      low: serializer.fromJson<double?>(json['low']),
      trend: serializer.fromJson<double?>(json['trend']),
      avg1: serializer.fromJson<double?>(json['avg1']),
      avg7: serializer.fromJson<double?>(json['avg7']),
      avg30: serializer.fromJson<double?>(json['avg30']),
      avgHolo: serializer.fromJson<double?>(json['avgHolo']),
      lowHolo: serializer.fromJson<double?>(json['lowHolo']),
      trendHolo: serializer.fromJson<double?>(json['trendHolo']),
      avg1Holo: serializer.fromJson<double?>(json['avg1Holo']),
      avg7Holo: serializer.fromJson<double?>(json['avg7Holo']),
      avg30Holo: serializer.fromJson<double?>(json['avg30Holo']),
      trendReverse: serializer.fromJson<double?>(json['trendReverse']),
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
      'average': serializer.toJson<double?>(average),
      'low': serializer.toJson<double?>(low),
      'trend': serializer.toJson<double?>(trend),
      'avg1': serializer.toJson<double?>(avg1),
      'avg7': serializer.toJson<double?>(avg7),
      'avg30': serializer.toJson<double?>(avg30),
      'avgHolo': serializer.toJson<double?>(avgHolo),
      'lowHolo': serializer.toJson<double?>(lowHolo),
      'trendHolo': serializer.toJson<double?>(trendHolo),
      'avg1Holo': serializer.toJson<double?>(avg1Holo),
      'avg7Holo': serializer.toJson<double?>(avg7Holo),
      'avg30Holo': serializer.toJson<double?>(avg30Holo),
      'trendReverse': serializer.toJson<double?>(trendReverse),
      'url': serializer.toJson<String?>(url),
    };
  }

  CardMarketPrice copyWith(
          {int? id,
          String? cardId,
          DateTime? fetchedAt,
          Value<double?> average = const Value.absent(),
          Value<double?> low = const Value.absent(),
          Value<double?> trend = const Value.absent(),
          Value<double?> avg1 = const Value.absent(),
          Value<double?> avg7 = const Value.absent(),
          Value<double?> avg30 = const Value.absent(),
          Value<double?> avgHolo = const Value.absent(),
          Value<double?> lowHolo = const Value.absent(),
          Value<double?> trendHolo = const Value.absent(),
          Value<double?> avg1Holo = const Value.absent(),
          Value<double?> avg7Holo = const Value.absent(),
          Value<double?> avg30Holo = const Value.absent(),
          Value<double?> trendReverse = const Value.absent(),
          Value<String?> url = const Value.absent()}) =>
      CardMarketPrice(
        id: id ?? this.id,
        cardId: cardId ?? this.cardId,
        fetchedAt: fetchedAt ?? this.fetchedAt,
        average: average.present ? average.value : this.average,
        low: low.present ? low.value : this.low,
        trend: trend.present ? trend.value : this.trend,
        avg1: avg1.present ? avg1.value : this.avg1,
        avg7: avg7.present ? avg7.value : this.avg7,
        avg30: avg30.present ? avg30.value : this.avg30,
        avgHolo: avgHolo.present ? avgHolo.value : this.avgHolo,
        lowHolo: lowHolo.present ? lowHolo.value : this.lowHolo,
        trendHolo: trendHolo.present ? trendHolo.value : this.trendHolo,
        avg1Holo: avg1Holo.present ? avg1Holo.value : this.avg1Holo,
        avg7Holo: avg7Holo.present ? avg7Holo.value : this.avg7Holo,
        avg30Holo: avg30Holo.present ? avg30Holo.value : this.avg30Holo,
        trendReverse:
            trendReverse.present ? trendReverse.value : this.trendReverse,
        url: url.present ? url.value : this.url,
      );
  CardMarketPrice copyWithCompanion(CardMarketPricesCompanion data) {
    return CardMarketPrice(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      average: data.average.present ? data.average.value : this.average,
      low: data.low.present ? data.low.value : this.low,
      trend: data.trend.present ? data.trend.value : this.trend,
      avg1: data.avg1.present ? data.avg1.value : this.avg1,
      avg7: data.avg7.present ? data.avg7.value : this.avg7,
      avg30: data.avg30.present ? data.avg30.value : this.avg30,
      avgHolo: data.avgHolo.present ? data.avgHolo.value : this.avgHolo,
      lowHolo: data.lowHolo.present ? data.lowHolo.value : this.lowHolo,
      trendHolo: data.trendHolo.present ? data.trendHolo.value : this.trendHolo,
      avg1Holo: data.avg1Holo.present ? data.avg1Holo.value : this.avg1Holo,
      avg7Holo: data.avg7Holo.present ? data.avg7Holo.value : this.avg7Holo,
      avg30Holo: data.avg30Holo.present ? data.avg30Holo.value : this.avg30Holo,
      trendReverse: data.trendReverse.present
          ? data.trendReverse.value
          : this.trendReverse,
      url: data.url.present ? data.url.value : this.url,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardMarketPrice(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('average: $average, ')
          ..write('low: $low, ')
          ..write('trend: $trend, ')
          ..write('avg1: $avg1, ')
          ..write('avg7: $avg7, ')
          ..write('avg30: $avg30, ')
          ..write('avgHolo: $avgHolo, ')
          ..write('lowHolo: $lowHolo, ')
          ..write('trendHolo: $trendHolo, ')
          ..write('avg1Holo: $avg1Holo, ')
          ..write('avg7Holo: $avg7Holo, ')
          ..write('avg30Holo: $avg30Holo, ')
          ..write('trendReverse: $trendReverse, ')
          ..write('url: $url')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      cardId,
      fetchedAt,
      average,
      low,
      trend,
      avg1,
      avg7,
      avg30,
      avgHolo,
      lowHolo,
      trendHolo,
      avg1Holo,
      avg7Holo,
      avg30Holo,
      trendReverse,
      url);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardMarketPrice &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.fetchedAt == this.fetchedAt &&
          other.average == this.average &&
          other.low == this.low &&
          other.trend == this.trend &&
          other.avg1 == this.avg1 &&
          other.avg7 == this.avg7 &&
          other.avg30 == this.avg30 &&
          other.avgHolo == this.avgHolo &&
          other.lowHolo == this.lowHolo &&
          other.trendHolo == this.trendHolo &&
          other.avg1Holo == this.avg1Holo &&
          other.avg7Holo == this.avg7Holo &&
          other.avg30Holo == this.avg30Holo &&
          other.trendReverse == this.trendReverse &&
          other.url == this.url);
}

class CardMarketPricesCompanion extends UpdateCompanion<CardMarketPrice> {
  final Value<int> id;
  final Value<String> cardId;
  final Value<DateTime> fetchedAt;
  final Value<double?> average;
  final Value<double?> low;
  final Value<double?> trend;
  final Value<double?> avg1;
  final Value<double?> avg7;
  final Value<double?> avg30;
  final Value<double?> avgHolo;
  final Value<double?> lowHolo;
  final Value<double?> trendHolo;
  final Value<double?> avg1Holo;
  final Value<double?> avg7Holo;
  final Value<double?> avg30Holo;
  final Value<double?> trendReverse;
  final Value<String?> url;
  const CardMarketPricesCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.average = const Value.absent(),
    this.low = const Value.absent(),
    this.trend = const Value.absent(),
    this.avg1 = const Value.absent(),
    this.avg7 = const Value.absent(),
    this.avg30 = const Value.absent(),
    this.avgHolo = const Value.absent(),
    this.lowHolo = const Value.absent(),
    this.trendHolo = const Value.absent(),
    this.avg1Holo = const Value.absent(),
    this.avg7Holo = const Value.absent(),
    this.avg30Holo = const Value.absent(),
    this.trendReverse = const Value.absent(),
    this.url = const Value.absent(),
  });
  CardMarketPricesCompanion.insert({
    this.id = const Value.absent(),
    required String cardId,
    required DateTime fetchedAt,
    this.average = const Value.absent(),
    this.low = const Value.absent(),
    this.trend = const Value.absent(),
    this.avg1 = const Value.absent(),
    this.avg7 = const Value.absent(),
    this.avg30 = const Value.absent(),
    this.avgHolo = const Value.absent(),
    this.lowHolo = const Value.absent(),
    this.trendHolo = const Value.absent(),
    this.avg1Holo = const Value.absent(),
    this.avg7Holo = const Value.absent(),
    this.avg30Holo = const Value.absent(),
    this.trendReverse = const Value.absent(),
    this.url = const Value.absent(),
  })  : cardId = Value(cardId),
        fetchedAt = Value(fetchedAt);
  static Insertable<CardMarketPrice> custom({
    Expression<int>? id,
    Expression<String>? cardId,
    Expression<DateTime>? fetchedAt,
    Expression<double>? average,
    Expression<double>? low,
    Expression<double>? trend,
    Expression<double>? avg1,
    Expression<double>? avg7,
    Expression<double>? avg30,
    Expression<double>? avgHolo,
    Expression<double>? lowHolo,
    Expression<double>? trendHolo,
    Expression<double>? avg1Holo,
    Expression<double>? avg7Holo,
    Expression<double>? avg30Holo,
    Expression<double>? trendReverse,
    Expression<String>? url,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (average != null) 'average': average,
      if (low != null) 'low': low,
      if (trend != null) 'trend': trend,
      if (avg1 != null) 'avg1': avg1,
      if (avg7 != null) 'avg7': avg7,
      if (avg30 != null) 'avg30': avg30,
      if (avgHolo != null) 'avg_holo': avgHolo,
      if (lowHolo != null) 'low_holo': lowHolo,
      if (trendHolo != null) 'trend_holo': trendHolo,
      if (avg1Holo != null) 'avg1_holo': avg1Holo,
      if (avg7Holo != null) 'avg7_holo': avg7Holo,
      if (avg30Holo != null) 'avg30_holo': avg30Holo,
      if (trendReverse != null) 'trend_reverse': trendReverse,
      if (url != null) 'url': url,
    });
  }

  CardMarketPricesCompanion copyWith(
      {Value<int>? id,
      Value<String>? cardId,
      Value<DateTime>? fetchedAt,
      Value<double?>? average,
      Value<double?>? low,
      Value<double?>? trend,
      Value<double?>? avg1,
      Value<double?>? avg7,
      Value<double?>? avg30,
      Value<double?>? avgHolo,
      Value<double?>? lowHolo,
      Value<double?>? trendHolo,
      Value<double?>? avg1Holo,
      Value<double?>? avg7Holo,
      Value<double?>? avg30Holo,
      Value<double?>? trendReverse,
      Value<String?>? url}) {
    return CardMarketPricesCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      average: average ?? this.average,
      low: low ?? this.low,
      trend: trend ?? this.trend,
      avg1: avg1 ?? this.avg1,
      avg7: avg7 ?? this.avg7,
      avg30: avg30 ?? this.avg30,
      avgHolo: avgHolo ?? this.avgHolo,
      lowHolo: lowHolo ?? this.lowHolo,
      trendHolo: trendHolo ?? this.trendHolo,
      avg1Holo: avg1Holo ?? this.avg1Holo,
      avg7Holo: avg7Holo ?? this.avg7Holo,
      avg30Holo: avg30Holo ?? this.avg30Holo,
      trendReverse: trendReverse ?? this.trendReverse,
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
    if (average.present) {
      map['average'] = Variable<double>(average.value);
    }
    if (low.present) {
      map['low'] = Variable<double>(low.value);
    }
    if (trend.present) {
      map['trend'] = Variable<double>(trend.value);
    }
    if (avg1.present) {
      map['avg1'] = Variable<double>(avg1.value);
    }
    if (avg7.present) {
      map['avg7'] = Variable<double>(avg7.value);
    }
    if (avg30.present) {
      map['avg30'] = Variable<double>(avg30.value);
    }
    if (avgHolo.present) {
      map['avg_holo'] = Variable<double>(avgHolo.value);
    }
    if (lowHolo.present) {
      map['low_holo'] = Variable<double>(lowHolo.value);
    }
    if (trendHolo.present) {
      map['trend_holo'] = Variable<double>(trendHolo.value);
    }
    if (avg1Holo.present) {
      map['avg1_holo'] = Variable<double>(avg1Holo.value);
    }
    if (avg7Holo.present) {
      map['avg7_holo'] = Variable<double>(avg7Holo.value);
    }
    if (avg30Holo.present) {
      map['avg30_holo'] = Variable<double>(avg30Holo.value);
    }
    if (trendReverse.present) {
      map['trend_reverse'] = Variable<double>(trendReverse.value);
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
          ..write('average: $average, ')
          ..write('low: $low, ')
          ..write('trend: $trend, ')
          ..write('avg1: $avg1, ')
          ..write('avg7: $avg7, ')
          ..write('avg30: $avg30, ')
          ..write('avgHolo: $avgHolo, ')
          ..write('lowHolo: $lowHolo, ')
          ..write('trendHolo: $trendHolo, ')
          ..write('avg1Holo: $avg1Holo, ')
          ..write('avg7Holo: $avg7Holo, ')
          ..write('avg30Holo: $avg30Holo, ')
          ..write('trendReverse: $trendReverse, ')
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
  static const VerificationMeta _normalMidMeta =
      const VerificationMeta('normalMid');
  @override
  late final GeneratedColumn<double> normalMid = GeneratedColumn<double>(
      'normal_mid', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _normalDirectLowMeta =
      const VerificationMeta('normalDirectLow');
  @override
  late final GeneratedColumn<double> normalDirectLow = GeneratedColumn<double>(
      'normal_direct_low', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _holoMarketMeta =
      const VerificationMeta('holoMarket');
  @override
  late final GeneratedColumn<double> holoMarket = GeneratedColumn<double>(
      'holo_market', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _holoLowMeta =
      const VerificationMeta('holoLow');
  @override
  late final GeneratedColumn<double> holoLow = GeneratedColumn<double>(
      'holo_low', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _holoMidMeta =
      const VerificationMeta('holoMid');
  @override
  late final GeneratedColumn<double> holoMid = GeneratedColumn<double>(
      'holo_mid', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _holoDirectLowMeta =
      const VerificationMeta('holoDirectLow');
  @override
  late final GeneratedColumn<double> holoDirectLow = GeneratedColumn<double>(
      'holo_direct_low', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _reverseMarketMeta =
      const VerificationMeta('reverseMarket');
  @override
  late final GeneratedColumn<double> reverseMarket = GeneratedColumn<double>(
      'reverse_market', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _reverseLowMeta =
      const VerificationMeta('reverseLow');
  @override
  late final GeneratedColumn<double> reverseLow = GeneratedColumn<double>(
      'reverse_low', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _reverseMidMeta =
      const VerificationMeta('reverseMid');
  @override
  late final GeneratedColumn<double> reverseMid = GeneratedColumn<double>(
      'reverse_mid', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _reverseDirectLowMeta =
      const VerificationMeta('reverseDirectLow');
  @override
  late final GeneratedColumn<double> reverseDirectLow = GeneratedColumn<double>(
      'reverse_direct_low', aliasedName, true,
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
        normalMarket,
        normalLow,
        normalMid,
        normalDirectLow,
        holoMarket,
        holoLow,
        holoMid,
        holoDirectLow,
        reverseMarket,
        reverseLow,
        reverseMid,
        reverseDirectLow,
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
    if (data.containsKey('normal_mid')) {
      context.handle(_normalMidMeta,
          normalMid.isAcceptableOrUnknown(data['normal_mid']!, _normalMidMeta));
    }
    if (data.containsKey('normal_direct_low')) {
      context.handle(
          _normalDirectLowMeta,
          normalDirectLow.isAcceptableOrUnknown(
              data['normal_direct_low']!, _normalDirectLowMeta));
    }
    if (data.containsKey('holo_market')) {
      context.handle(
          _holoMarketMeta,
          holoMarket.isAcceptableOrUnknown(
              data['holo_market']!, _holoMarketMeta));
    }
    if (data.containsKey('holo_low')) {
      context.handle(_holoLowMeta,
          holoLow.isAcceptableOrUnknown(data['holo_low']!, _holoLowMeta));
    }
    if (data.containsKey('holo_mid')) {
      context.handle(_holoMidMeta,
          holoMid.isAcceptableOrUnknown(data['holo_mid']!, _holoMidMeta));
    }
    if (data.containsKey('holo_direct_low')) {
      context.handle(
          _holoDirectLowMeta,
          holoDirectLow.isAcceptableOrUnknown(
              data['holo_direct_low']!, _holoDirectLowMeta));
    }
    if (data.containsKey('reverse_market')) {
      context.handle(
          _reverseMarketMeta,
          reverseMarket.isAcceptableOrUnknown(
              data['reverse_market']!, _reverseMarketMeta));
    }
    if (data.containsKey('reverse_low')) {
      context.handle(
          _reverseLowMeta,
          reverseLow.isAcceptableOrUnknown(
              data['reverse_low']!, _reverseLowMeta));
    }
    if (data.containsKey('reverse_mid')) {
      context.handle(
          _reverseMidMeta,
          reverseMid.isAcceptableOrUnknown(
              data['reverse_mid']!, _reverseMidMeta));
    }
    if (data.containsKey('reverse_direct_low')) {
      context.handle(
          _reverseDirectLowMeta,
          reverseDirectLow.isAcceptableOrUnknown(
              data['reverse_direct_low']!, _reverseDirectLowMeta));
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
      normalMarket: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}normal_market']),
      normalLow: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}normal_low']),
      normalMid: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}normal_mid']),
      normalDirectLow: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}normal_direct_low']),
      holoMarket: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}holo_market']),
      holoLow: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}holo_low']),
      holoMid: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}holo_mid']),
      holoDirectLow: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}holo_direct_low']),
      reverseMarket: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}reverse_market']),
      reverseLow: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}reverse_low']),
      reverseMid: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}reverse_mid']),
      reverseDirectLow: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}reverse_direct_low']),
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
  final double? normalMarket;
  final double? normalLow;
  final double? normalMid;
  final double? normalDirectLow;
  final double? holoMarket;
  final double? holoLow;
  final double? holoMid;
  final double? holoDirectLow;
  final double? reverseMarket;
  final double? reverseLow;
  final double? reverseMid;
  final double? reverseDirectLow;
  final String? url;
  const TcgPlayerPrice(
      {required this.id,
      required this.cardId,
      required this.fetchedAt,
      this.normalMarket,
      this.normalLow,
      this.normalMid,
      this.normalDirectLow,
      this.holoMarket,
      this.holoLow,
      this.holoMid,
      this.holoDirectLow,
      this.reverseMarket,
      this.reverseLow,
      this.reverseMid,
      this.reverseDirectLow,
      this.url});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['card_id'] = Variable<String>(cardId);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    if (!nullToAbsent || normalMarket != null) {
      map['normal_market'] = Variable<double>(normalMarket);
    }
    if (!nullToAbsent || normalLow != null) {
      map['normal_low'] = Variable<double>(normalLow);
    }
    if (!nullToAbsent || normalMid != null) {
      map['normal_mid'] = Variable<double>(normalMid);
    }
    if (!nullToAbsent || normalDirectLow != null) {
      map['normal_direct_low'] = Variable<double>(normalDirectLow);
    }
    if (!nullToAbsent || holoMarket != null) {
      map['holo_market'] = Variable<double>(holoMarket);
    }
    if (!nullToAbsent || holoLow != null) {
      map['holo_low'] = Variable<double>(holoLow);
    }
    if (!nullToAbsent || holoMid != null) {
      map['holo_mid'] = Variable<double>(holoMid);
    }
    if (!nullToAbsent || holoDirectLow != null) {
      map['holo_direct_low'] = Variable<double>(holoDirectLow);
    }
    if (!nullToAbsent || reverseMarket != null) {
      map['reverse_market'] = Variable<double>(reverseMarket);
    }
    if (!nullToAbsent || reverseLow != null) {
      map['reverse_low'] = Variable<double>(reverseLow);
    }
    if (!nullToAbsent || reverseMid != null) {
      map['reverse_mid'] = Variable<double>(reverseMid);
    }
    if (!nullToAbsent || reverseDirectLow != null) {
      map['reverse_direct_low'] = Variable<double>(reverseDirectLow);
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
      normalMarket: normalMarket == null && nullToAbsent
          ? const Value.absent()
          : Value(normalMarket),
      normalLow: normalLow == null && nullToAbsent
          ? const Value.absent()
          : Value(normalLow),
      normalMid: normalMid == null && nullToAbsent
          ? const Value.absent()
          : Value(normalMid),
      normalDirectLow: normalDirectLow == null && nullToAbsent
          ? const Value.absent()
          : Value(normalDirectLow),
      holoMarket: holoMarket == null && nullToAbsent
          ? const Value.absent()
          : Value(holoMarket),
      holoLow: holoLow == null && nullToAbsent
          ? const Value.absent()
          : Value(holoLow),
      holoMid: holoMid == null && nullToAbsent
          ? const Value.absent()
          : Value(holoMid),
      holoDirectLow: holoDirectLow == null && nullToAbsent
          ? const Value.absent()
          : Value(holoDirectLow),
      reverseMarket: reverseMarket == null && nullToAbsent
          ? const Value.absent()
          : Value(reverseMarket),
      reverseLow: reverseLow == null && nullToAbsent
          ? const Value.absent()
          : Value(reverseLow),
      reverseMid: reverseMid == null && nullToAbsent
          ? const Value.absent()
          : Value(reverseMid),
      reverseDirectLow: reverseDirectLow == null && nullToAbsent
          ? const Value.absent()
          : Value(reverseDirectLow),
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
      normalMarket: serializer.fromJson<double?>(json['normalMarket']),
      normalLow: serializer.fromJson<double?>(json['normalLow']),
      normalMid: serializer.fromJson<double?>(json['normalMid']),
      normalDirectLow: serializer.fromJson<double?>(json['normalDirectLow']),
      holoMarket: serializer.fromJson<double?>(json['holoMarket']),
      holoLow: serializer.fromJson<double?>(json['holoLow']),
      holoMid: serializer.fromJson<double?>(json['holoMid']),
      holoDirectLow: serializer.fromJson<double?>(json['holoDirectLow']),
      reverseMarket: serializer.fromJson<double?>(json['reverseMarket']),
      reverseLow: serializer.fromJson<double?>(json['reverseLow']),
      reverseMid: serializer.fromJson<double?>(json['reverseMid']),
      reverseDirectLow: serializer.fromJson<double?>(json['reverseDirectLow']),
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
      'normalMarket': serializer.toJson<double?>(normalMarket),
      'normalLow': serializer.toJson<double?>(normalLow),
      'normalMid': serializer.toJson<double?>(normalMid),
      'normalDirectLow': serializer.toJson<double?>(normalDirectLow),
      'holoMarket': serializer.toJson<double?>(holoMarket),
      'holoLow': serializer.toJson<double?>(holoLow),
      'holoMid': serializer.toJson<double?>(holoMid),
      'holoDirectLow': serializer.toJson<double?>(holoDirectLow),
      'reverseMarket': serializer.toJson<double?>(reverseMarket),
      'reverseLow': serializer.toJson<double?>(reverseLow),
      'reverseMid': serializer.toJson<double?>(reverseMid),
      'reverseDirectLow': serializer.toJson<double?>(reverseDirectLow),
      'url': serializer.toJson<String?>(url),
    };
  }

  TcgPlayerPrice copyWith(
          {int? id,
          String? cardId,
          DateTime? fetchedAt,
          Value<double?> normalMarket = const Value.absent(),
          Value<double?> normalLow = const Value.absent(),
          Value<double?> normalMid = const Value.absent(),
          Value<double?> normalDirectLow = const Value.absent(),
          Value<double?> holoMarket = const Value.absent(),
          Value<double?> holoLow = const Value.absent(),
          Value<double?> holoMid = const Value.absent(),
          Value<double?> holoDirectLow = const Value.absent(),
          Value<double?> reverseMarket = const Value.absent(),
          Value<double?> reverseLow = const Value.absent(),
          Value<double?> reverseMid = const Value.absent(),
          Value<double?> reverseDirectLow = const Value.absent(),
          Value<String?> url = const Value.absent()}) =>
      TcgPlayerPrice(
        id: id ?? this.id,
        cardId: cardId ?? this.cardId,
        fetchedAt: fetchedAt ?? this.fetchedAt,
        normalMarket:
            normalMarket.present ? normalMarket.value : this.normalMarket,
        normalLow: normalLow.present ? normalLow.value : this.normalLow,
        normalMid: normalMid.present ? normalMid.value : this.normalMid,
        normalDirectLow: normalDirectLow.present
            ? normalDirectLow.value
            : this.normalDirectLow,
        holoMarket: holoMarket.present ? holoMarket.value : this.holoMarket,
        holoLow: holoLow.present ? holoLow.value : this.holoLow,
        holoMid: holoMid.present ? holoMid.value : this.holoMid,
        holoDirectLow:
            holoDirectLow.present ? holoDirectLow.value : this.holoDirectLow,
        reverseMarket:
            reverseMarket.present ? reverseMarket.value : this.reverseMarket,
        reverseLow: reverseLow.present ? reverseLow.value : this.reverseLow,
        reverseMid: reverseMid.present ? reverseMid.value : this.reverseMid,
        reverseDirectLow: reverseDirectLow.present
            ? reverseDirectLow.value
            : this.reverseDirectLow,
        url: url.present ? url.value : this.url,
      );
  TcgPlayerPrice copyWithCompanion(TcgPlayerPricesCompanion data) {
    return TcgPlayerPrice(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      normalMarket: data.normalMarket.present
          ? data.normalMarket.value
          : this.normalMarket,
      normalLow: data.normalLow.present ? data.normalLow.value : this.normalLow,
      normalMid: data.normalMid.present ? data.normalMid.value : this.normalMid,
      normalDirectLow: data.normalDirectLow.present
          ? data.normalDirectLow.value
          : this.normalDirectLow,
      holoMarket:
          data.holoMarket.present ? data.holoMarket.value : this.holoMarket,
      holoLow: data.holoLow.present ? data.holoLow.value : this.holoLow,
      holoMid: data.holoMid.present ? data.holoMid.value : this.holoMid,
      holoDirectLow: data.holoDirectLow.present
          ? data.holoDirectLow.value
          : this.holoDirectLow,
      reverseMarket: data.reverseMarket.present
          ? data.reverseMarket.value
          : this.reverseMarket,
      reverseLow:
          data.reverseLow.present ? data.reverseLow.value : this.reverseLow,
      reverseMid:
          data.reverseMid.present ? data.reverseMid.value : this.reverseMid,
      reverseDirectLow: data.reverseDirectLow.present
          ? data.reverseDirectLow.value
          : this.reverseDirectLow,
      url: data.url.present ? data.url.value : this.url,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TcgPlayerPrice(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('normalMarket: $normalMarket, ')
          ..write('normalLow: $normalLow, ')
          ..write('normalMid: $normalMid, ')
          ..write('normalDirectLow: $normalDirectLow, ')
          ..write('holoMarket: $holoMarket, ')
          ..write('holoLow: $holoLow, ')
          ..write('holoMid: $holoMid, ')
          ..write('holoDirectLow: $holoDirectLow, ')
          ..write('reverseMarket: $reverseMarket, ')
          ..write('reverseLow: $reverseLow, ')
          ..write('reverseMid: $reverseMid, ')
          ..write('reverseDirectLow: $reverseDirectLow, ')
          ..write('url: $url')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      cardId,
      fetchedAt,
      normalMarket,
      normalLow,
      normalMid,
      normalDirectLow,
      holoMarket,
      holoLow,
      holoMid,
      holoDirectLow,
      reverseMarket,
      reverseLow,
      reverseMid,
      reverseDirectLow,
      url);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TcgPlayerPrice &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.fetchedAt == this.fetchedAt &&
          other.normalMarket == this.normalMarket &&
          other.normalLow == this.normalLow &&
          other.normalMid == this.normalMid &&
          other.normalDirectLow == this.normalDirectLow &&
          other.holoMarket == this.holoMarket &&
          other.holoLow == this.holoLow &&
          other.holoMid == this.holoMid &&
          other.holoDirectLow == this.holoDirectLow &&
          other.reverseMarket == this.reverseMarket &&
          other.reverseLow == this.reverseLow &&
          other.reverseMid == this.reverseMid &&
          other.reverseDirectLow == this.reverseDirectLow &&
          other.url == this.url);
}

class TcgPlayerPricesCompanion extends UpdateCompanion<TcgPlayerPrice> {
  final Value<int> id;
  final Value<String> cardId;
  final Value<DateTime> fetchedAt;
  final Value<double?> normalMarket;
  final Value<double?> normalLow;
  final Value<double?> normalMid;
  final Value<double?> normalDirectLow;
  final Value<double?> holoMarket;
  final Value<double?> holoLow;
  final Value<double?> holoMid;
  final Value<double?> holoDirectLow;
  final Value<double?> reverseMarket;
  final Value<double?> reverseLow;
  final Value<double?> reverseMid;
  final Value<double?> reverseDirectLow;
  final Value<String?> url;
  const TcgPlayerPricesCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.normalMarket = const Value.absent(),
    this.normalLow = const Value.absent(),
    this.normalMid = const Value.absent(),
    this.normalDirectLow = const Value.absent(),
    this.holoMarket = const Value.absent(),
    this.holoLow = const Value.absent(),
    this.holoMid = const Value.absent(),
    this.holoDirectLow = const Value.absent(),
    this.reverseMarket = const Value.absent(),
    this.reverseLow = const Value.absent(),
    this.reverseMid = const Value.absent(),
    this.reverseDirectLow = const Value.absent(),
    this.url = const Value.absent(),
  });
  TcgPlayerPricesCompanion.insert({
    this.id = const Value.absent(),
    required String cardId,
    required DateTime fetchedAt,
    this.normalMarket = const Value.absent(),
    this.normalLow = const Value.absent(),
    this.normalMid = const Value.absent(),
    this.normalDirectLow = const Value.absent(),
    this.holoMarket = const Value.absent(),
    this.holoLow = const Value.absent(),
    this.holoMid = const Value.absent(),
    this.holoDirectLow = const Value.absent(),
    this.reverseMarket = const Value.absent(),
    this.reverseLow = const Value.absent(),
    this.reverseMid = const Value.absent(),
    this.reverseDirectLow = const Value.absent(),
    this.url = const Value.absent(),
  })  : cardId = Value(cardId),
        fetchedAt = Value(fetchedAt);
  static Insertable<TcgPlayerPrice> custom({
    Expression<int>? id,
    Expression<String>? cardId,
    Expression<DateTime>? fetchedAt,
    Expression<double>? normalMarket,
    Expression<double>? normalLow,
    Expression<double>? normalMid,
    Expression<double>? normalDirectLow,
    Expression<double>? holoMarket,
    Expression<double>? holoLow,
    Expression<double>? holoMid,
    Expression<double>? holoDirectLow,
    Expression<double>? reverseMarket,
    Expression<double>? reverseLow,
    Expression<double>? reverseMid,
    Expression<double>? reverseDirectLow,
    Expression<String>? url,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (normalMarket != null) 'normal_market': normalMarket,
      if (normalLow != null) 'normal_low': normalLow,
      if (normalMid != null) 'normal_mid': normalMid,
      if (normalDirectLow != null) 'normal_direct_low': normalDirectLow,
      if (holoMarket != null) 'holo_market': holoMarket,
      if (holoLow != null) 'holo_low': holoLow,
      if (holoMid != null) 'holo_mid': holoMid,
      if (holoDirectLow != null) 'holo_direct_low': holoDirectLow,
      if (reverseMarket != null) 'reverse_market': reverseMarket,
      if (reverseLow != null) 'reverse_low': reverseLow,
      if (reverseMid != null) 'reverse_mid': reverseMid,
      if (reverseDirectLow != null) 'reverse_direct_low': reverseDirectLow,
      if (url != null) 'url': url,
    });
  }

  TcgPlayerPricesCompanion copyWith(
      {Value<int>? id,
      Value<String>? cardId,
      Value<DateTime>? fetchedAt,
      Value<double?>? normalMarket,
      Value<double?>? normalLow,
      Value<double?>? normalMid,
      Value<double?>? normalDirectLow,
      Value<double?>? holoMarket,
      Value<double?>? holoLow,
      Value<double?>? holoMid,
      Value<double?>? holoDirectLow,
      Value<double?>? reverseMarket,
      Value<double?>? reverseLow,
      Value<double?>? reverseMid,
      Value<double?>? reverseDirectLow,
      Value<String?>? url}) {
    return TcgPlayerPricesCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      normalMarket: normalMarket ?? this.normalMarket,
      normalLow: normalLow ?? this.normalLow,
      normalMid: normalMid ?? this.normalMid,
      normalDirectLow: normalDirectLow ?? this.normalDirectLow,
      holoMarket: holoMarket ?? this.holoMarket,
      holoLow: holoLow ?? this.holoLow,
      holoMid: holoMid ?? this.holoMid,
      holoDirectLow: holoDirectLow ?? this.holoDirectLow,
      reverseMarket: reverseMarket ?? this.reverseMarket,
      reverseLow: reverseLow ?? this.reverseLow,
      reverseMid: reverseMid ?? this.reverseMid,
      reverseDirectLow: reverseDirectLow ?? this.reverseDirectLow,
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
    if (normalMarket.present) {
      map['normal_market'] = Variable<double>(normalMarket.value);
    }
    if (normalLow.present) {
      map['normal_low'] = Variable<double>(normalLow.value);
    }
    if (normalMid.present) {
      map['normal_mid'] = Variable<double>(normalMid.value);
    }
    if (normalDirectLow.present) {
      map['normal_direct_low'] = Variable<double>(normalDirectLow.value);
    }
    if (holoMarket.present) {
      map['holo_market'] = Variable<double>(holoMarket.value);
    }
    if (holoLow.present) {
      map['holo_low'] = Variable<double>(holoLow.value);
    }
    if (holoMid.present) {
      map['holo_mid'] = Variable<double>(holoMid.value);
    }
    if (holoDirectLow.present) {
      map['holo_direct_low'] = Variable<double>(holoDirectLow.value);
    }
    if (reverseMarket.present) {
      map['reverse_market'] = Variable<double>(reverseMarket.value);
    }
    if (reverseLow.present) {
      map['reverse_low'] = Variable<double>(reverseLow.value);
    }
    if (reverseMid.present) {
      map['reverse_mid'] = Variable<double>(reverseMid.value);
    }
    if (reverseDirectLow.present) {
      map['reverse_direct_low'] = Variable<double>(reverseDirectLow.value);
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
          ..write('normalMarket: $normalMarket, ')
          ..write('normalLow: $normalLow, ')
          ..write('normalMid: $normalMid, ')
          ..write('normalDirectLow: $normalDirectLow, ')
          ..write('holoMarket: $holoMarket, ')
          ..write('holoLow: $holoLow, ')
          ..write('holoMid: $holoMid, ')
          ..write('holoDirectLow: $holoDirectLow, ')
          ..write('reverseMarket: $reverseMarket, ')
          ..write('reverseLow: $reverseLow, ')
          ..write('reverseMid: $reverseMid, ')
          ..write('reverseDirectLow: $reverseDirectLow, ')
          ..write('url: $url')
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

class $BindersTable extends Binders with TableInfo<$BindersTable, Binder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rowsPerPageMeta =
      const VerificationMeta('rowsPerPage');
  @override
  late final GeneratedColumn<int> rowsPerPage = GeneratedColumn<int>(
      'rows_per_page', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _columnsPerPageMeta =
      const VerificationMeta('columnsPerPage');
  @override
  late final GeneratedColumn<int> columnsPerPage = GeneratedColumn<int>(
      'columns_per_page', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('custom'));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<String> sortOrder = GeneratedColumn<String>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('leftToRight'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        color,
        icon,
        rowsPerPage,
        columnsPerPage,
        type,
        sortOrder,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'binders';
  @override
  VerificationContext validateIntegrity(Insertable<Binder> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('rows_per_page')) {
      context.handle(
          _rowsPerPageMeta,
          rowsPerPage.isAcceptableOrUnknown(
              data['rows_per_page']!, _rowsPerPageMeta));
    }
    if (data.containsKey('columns_per_page')) {
      context.handle(
          _columnsPerPageMeta,
          columnsPerPage.isAcceptableOrUnknown(
              data['columns_per_page']!, _columnsPerPageMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Binder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Binder(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
      rowsPerPage: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rows_per_page'])!,
      columnsPerPage: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}columns_per_page'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $BindersTable createAlias(String alias) {
    return $BindersTable(attachedDatabase, alias);
  }
}

class Binder extends DataClass implements Insertable<Binder> {
  final int id;
  final String name;
  final int color;
  final String? icon;
  final int rowsPerPage;
  final int columnsPerPage;
  final String type;
  final String sortOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const Binder(
      {required this.id,
      required this.name,
      required this.color,
      this.icon,
      required this.rowsPerPage,
      required this.columnsPerPage,
      required this.type,
      required this.sortOrder,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<int>(color);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['rows_per_page'] = Variable<int>(rowsPerPage);
    map['columns_per_page'] = Variable<int>(columnsPerPage);
    map['type'] = Variable<String>(type);
    map['sort_order'] = Variable<String>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  BindersCompanion toCompanion(bool nullToAbsent) {
    return BindersCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      rowsPerPage: Value(rowsPerPage),
      columnsPerPage: Value(columnsPerPage),
      type: Value(type),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Binder.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Binder(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
      rowsPerPage: serializer.fromJson<int>(json['rowsPerPage']),
      columnsPerPage: serializer.fromJson<int>(json['columnsPerPage']),
      type: serializer.fromJson<String>(json['type']),
      sortOrder: serializer.fromJson<String>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int>(color),
      'icon': serializer.toJson<String?>(icon),
      'rowsPerPage': serializer.toJson<int>(rowsPerPage),
      'columnsPerPage': serializer.toJson<int>(columnsPerPage),
      'type': serializer.toJson<String>(type),
      'sortOrder': serializer.toJson<String>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  Binder copyWith(
          {int? id,
          String? name,
          int? color,
          Value<String?> icon = const Value.absent(),
          int? rowsPerPage,
          int? columnsPerPage,
          String? type,
          String? sortOrder,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      Binder(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        icon: icon.present ? icon.value : this.icon,
        rowsPerPage: rowsPerPage ?? this.rowsPerPage,
        columnsPerPage: columnsPerPage ?? this.columnsPerPage,
        type: type ?? this.type,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  Binder copyWithCompanion(BindersCompanion data) {
    return Binder(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      rowsPerPage:
          data.rowsPerPage.present ? data.rowsPerPage.value : this.rowsPerPage,
      columnsPerPage: data.columnsPerPage.present
          ? data.columnsPerPage.value
          : this.columnsPerPage,
      type: data.type.present ? data.type.value : this.type,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Binder(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('rowsPerPage: $rowsPerPage, ')
          ..write('columnsPerPage: $columnsPerPage, ')
          ..write('type: $type, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, icon, rowsPerPage,
      columnsPerPage, type, sortOrder, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Binder &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.rowsPerPage == this.rowsPerPage &&
          other.columnsPerPage == this.columnsPerPage &&
          other.type == this.type &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BindersCompanion extends UpdateCompanion<Binder> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> color;
  final Value<String?> icon;
  final Value<int> rowsPerPage;
  final Value<int> columnsPerPage;
  final Value<String> type;
  final Value<String> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  const BindersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.rowsPerPage = const Value.absent(),
    this.columnsPerPage = const Value.absent(),
    this.type = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BindersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int color,
    this.icon = const Value.absent(),
    this.rowsPerPage = const Value.absent(),
    this.columnsPerPage = const Value.absent(),
    this.type = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : name = Value(name),
        color = Value(color);
  static Insertable<Binder> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<String>? icon,
    Expression<int>? rowsPerPage,
    Expression<int>? columnsPerPage,
    Expression<String>? type,
    Expression<String>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (rowsPerPage != null) 'rows_per_page': rowsPerPage,
      if (columnsPerPage != null) 'columns_per_page': columnsPerPage,
      if (type != null) 'type': type,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BindersCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? color,
      Value<String?>? icon,
      Value<int>? rowsPerPage,
      Value<int>? columnsPerPage,
      Value<String>? type,
      Value<String>? sortOrder,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt}) {
    return BindersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      rowsPerPage: rowsPerPage ?? this.rowsPerPage,
      columnsPerPage: columnsPerPage ?? this.columnsPerPage,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (rowsPerPage.present) {
      map['rows_per_page'] = Variable<int>(rowsPerPage.value);
    }
    if (columnsPerPage.present) {
      map['columns_per_page'] = Variable<int>(columnsPerPage.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<String>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BindersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('rowsPerPage: $rowsPerPage, ')
          ..write('columnsPerPage: $columnsPerPage, ')
          ..write('type: $type, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $BinderCardsTable extends BinderCards
    with TableInfo<$BinderCardsTable, BinderCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BinderCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _binderIdMeta =
      const VerificationMeta('binderId');
  @override
  late final GeneratedColumn<int> binderId = GeneratedColumn<int>(
      'binder_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES binders (id) ON DELETE CASCADE'));
  static const VerificationMeta _pageIndexMeta =
      const VerificationMeta('pageIndex');
  @override
  late final GeneratedColumn<int> pageIndex = GeneratedColumn<int>(
      'page_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _slotIndexMeta =
      const VerificationMeta('slotIndex');
  @override
  late final GeneratedColumn<int> slotIndex = GeneratedColumn<int>(
      'slot_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
      'card_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES cards (id)'));
  static const VerificationMeta _isPlaceholderMeta =
      const VerificationMeta('isPlaceholder');
  @override
  late final GeneratedColumn<bool> isPlaceholder = GeneratedColumn<bool>(
      'is_placeholder', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_placeholder" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _placeholderLabelMeta =
      const VerificationMeta('placeholderLabel');
  @override
  late final GeneratedColumn<String> placeholderLabel = GeneratedColumn<String>(
      'placeholder_label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        binderId,
        pageIndex,
        slotIndex,
        cardId,
        isPlaceholder,
        placeholderLabel
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'binder_cards';
  @override
  VerificationContext validateIntegrity(Insertable<BinderCard> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('binder_id')) {
      context.handle(_binderIdMeta,
          binderId.isAcceptableOrUnknown(data['binder_id']!, _binderIdMeta));
    } else if (isInserting) {
      context.missing(_binderIdMeta);
    }
    if (data.containsKey('page_index')) {
      context.handle(_pageIndexMeta,
          pageIndex.isAcceptableOrUnknown(data['page_index']!, _pageIndexMeta));
    } else if (isInserting) {
      context.missing(_pageIndexMeta);
    }
    if (data.containsKey('slot_index')) {
      context.handle(_slotIndexMeta,
          slotIndex.isAcceptableOrUnknown(data['slot_index']!, _slotIndexMeta));
    } else if (isInserting) {
      context.missing(_slotIndexMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(_cardIdMeta,
          cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta));
    }
    if (data.containsKey('is_placeholder')) {
      context.handle(
          _isPlaceholderMeta,
          isPlaceholder.isAcceptableOrUnknown(
              data['is_placeholder']!, _isPlaceholderMeta));
    }
    if (data.containsKey('placeholder_label')) {
      context.handle(
          _placeholderLabelMeta,
          placeholderLabel.isAcceptableOrUnknown(
              data['placeholder_label']!, _placeholderLabelMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BinderCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BinderCard(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      binderId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}binder_id'])!,
      pageIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_index'])!,
      slotIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}slot_index'])!,
      cardId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}card_id']),
      isPlaceholder: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_placeholder'])!,
      placeholderLabel: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}placeholder_label']),
    );
  }

  @override
  $BinderCardsTable createAlias(String alias) {
    return $BinderCardsTable(attachedDatabase, alias);
  }
}

class BinderCard extends DataClass implements Insertable<BinderCard> {
  final int id;
  final int binderId;
  final int pageIndex;
  final int slotIndex;
  final String? cardId;
  final bool isPlaceholder;
  final String? placeholderLabel;
  const BinderCard(
      {required this.id,
      required this.binderId,
      required this.pageIndex,
      required this.slotIndex,
      this.cardId,
      required this.isPlaceholder,
      this.placeholderLabel});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['binder_id'] = Variable<int>(binderId);
    map['page_index'] = Variable<int>(pageIndex);
    map['slot_index'] = Variable<int>(slotIndex);
    if (!nullToAbsent || cardId != null) {
      map['card_id'] = Variable<String>(cardId);
    }
    map['is_placeholder'] = Variable<bool>(isPlaceholder);
    if (!nullToAbsent || placeholderLabel != null) {
      map['placeholder_label'] = Variable<String>(placeholderLabel);
    }
    return map;
  }

  BinderCardsCompanion toCompanion(bool nullToAbsent) {
    return BinderCardsCompanion(
      id: Value(id),
      binderId: Value(binderId),
      pageIndex: Value(pageIndex),
      slotIndex: Value(slotIndex),
      cardId:
          cardId == null && nullToAbsent ? const Value.absent() : Value(cardId),
      isPlaceholder: Value(isPlaceholder),
      placeholderLabel: placeholderLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(placeholderLabel),
    );
  }

  factory BinderCard.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BinderCard(
      id: serializer.fromJson<int>(json['id']),
      binderId: serializer.fromJson<int>(json['binderId']),
      pageIndex: serializer.fromJson<int>(json['pageIndex']),
      slotIndex: serializer.fromJson<int>(json['slotIndex']),
      cardId: serializer.fromJson<String?>(json['cardId']),
      isPlaceholder: serializer.fromJson<bool>(json['isPlaceholder']),
      placeholderLabel: serializer.fromJson<String?>(json['placeholderLabel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'binderId': serializer.toJson<int>(binderId),
      'pageIndex': serializer.toJson<int>(pageIndex),
      'slotIndex': serializer.toJson<int>(slotIndex),
      'cardId': serializer.toJson<String?>(cardId),
      'isPlaceholder': serializer.toJson<bool>(isPlaceholder),
      'placeholderLabel': serializer.toJson<String?>(placeholderLabel),
    };
  }

  BinderCard copyWith(
          {int? id,
          int? binderId,
          int? pageIndex,
          int? slotIndex,
          Value<String?> cardId = const Value.absent(),
          bool? isPlaceholder,
          Value<String?> placeholderLabel = const Value.absent()}) =>
      BinderCard(
        id: id ?? this.id,
        binderId: binderId ?? this.binderId,
        pageIndex: pageIndex ?? this.pageIndex,
        slotIndex: slotIndex ?? this.slotIndex,
        cardId: cardId.present ? cardId.value : this.cardId,
        isPlaceholder: isPlaceholder ?? this.isPlaceholder,
        placeholderLabel: placeholderLabel.present
            ? placeholderLabel.value
            : this.placeholderLabel,
      );
  BinderCard copyWithCompanion(BinderCardsCompanion data) {
    return BinderCard(
      id: data.id.present ? data.id.value : this.id,
      binderId: data.binderId.present ? data.binderId.value : this.binderId,
      pageIndex: data.pageIndex.present ? data.pageIndex.value : this.pageIndex,
      slotIndex: data.slotIndex.present ? data.slotIndex.value : this.slotIndex,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      isPlaceholder: data.isPlaceholder.present
          ? data.isPlaceholder.value
          : this.isPlaceholder,
      placeholderLabel: data.placeholderLabel.present
          ? data.placeholderLabel.value
          : this.placeholderLabel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BinderCard(')
          ..write('id: $id, ')
          ..write('binderId: $binderId, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('slotIndex: $slotIndex, ')
          ..write('cardId: $cardId, ')
          ..write('isPlaceholder: $isPlaceholder, ')
          ..write('placeholderLabel: $placeholderLabel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, binderId, pageIndex, slotIndex, cardId,
      isPlaceholder, placeholderLabel);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BinderCard &&
          other.id == this.id &&
          other.binderId == this.binderId &&
          other.pageIndex == this.pageIndex &&
          other.slotIndex == this.slotIndex &&
          other.cardId == this.cardId &&
          other.isPlaceholder == this.isPlaceholder &&
          other.placeholderLabel == this.placeholderLabel);
}

class BinderCardsCompanion extends UpdateCompanion<BinderCard> {
  final Value<int> id;
  final Value<int> binderId;
  final Value<int> pageIndex;
  final Value<int> slotIndex;
  final Value<String?> cardId;
  final Value<bool> isPlaceholder;
  final Value<String?> placeholderLabel;
  const BinderCardsCompanion({
    this.id = const Value.absent(),
    this.binderId = const Value.absent(),
    this.pageIndex = const Value.absent(),
    this.slotIndex = const Value.absent(),
    this.cardId = const Value.absent(),
    this.isPlaceholder = const Value.absent(),
    this.placeholderLabel = const Value.absent(),
  });
  BinderCardsCompanion.insert({
    this.id = const Value.absent(),
    required int binderId,
    required int pageIndex,
    required int slotIndex,
    this.cardId = const Value.absent(),
    this.isPlaceholder = const Value.absent(),
    this.placeholderLabel = const Value.absent(),
  })  : binderId = Value(binderId),
        pageIndex = Value(pageIndex),
        slotIndex = Value(slotIndex);
  static Insertable<BinderCard> custom({
    Expression<int>? id,
    Expression<int>? binderId,
    Expression<int>? pageIndex,
    Expression<int>? slotIndex,
    Expression<String>? cardId,
    Expression<bool>? isPlaceholder,
    Expression<String>? placeholderLabel,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (binderId != null) 'binder_id': binderId,
      if (pageIndex != null) 'page_index': pageIndex,
      if (slotIndex != null) 'slot_index': slotIndex,
      if (cardId != null) 'card_id': cardId,
      if (isPlaceholder != null) 'is_placeholder': isPlaceholder,
      if (placeholderLabel != null) 'placeholder_label': placeholderLabel,
    });
  }

  BinderCardsCompanion copyWith(
      {Value<int>? id,
      Value<int>? binderId,
      Value<int>? pageIndex,
      Value<int>? slotIndex,
      Value<String?>? cardId,
      Value<bool>? isPlaceholder,
      Value<String?>? placeholderLabel}) {
    return BinderCardsCompanion(
      id: id ?? this.id,
      binderId: binderId ?? this.binderId,
      pageIndex: pageIndex ?? this.pageIndex,
      slotIndex: slotIndex ?? this.slotIndex,
      cardId: cardId ?? this.cardId,
      isPlaceholder: isPlaceholder ?? this.isPlaceholder,
      placeholderLabel: placeholderLabel ?? this.placeholderLabel,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (binderId.present) {
      map['binder_id'] = Variable<int>(binderId.value);
    }
    if (pageIndex.present) {
      map['page_index'] = Variable<int>(pageIndex.value);
    }
    if (slotIndex.present) {
      map['slot_index'] = Variable<int>(slotIndex.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (isPlaceholder.present) {
      map['is_placeholder'] = Variable<bool>(isPlaceholder.value);
    }
    if (placeholderLabel.present) {
      map['placeholder_label'] = Variable<String>(placeholderLabel.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BinderCardsCompanion(')
          ..write('id: $id, ')
          ..write('binderId: $binderId, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('slotIndex: $slotIndex, ')
          ..write('cardId: $cardId, ')
          ..write('isPlaceholder: $isPlaceholder, ')
          ..write('placeholderLabel: $placeholderLabel')
          ..write(')'))
        .toString();
  }
}

class $PokedexTable extends Pokedex with TableInfo<$PokedexTable, PokedexData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PokedexTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pokedex';
  @override
  VerificationContext validateIntegrity(Insertable<PokedexData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PokedexData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PokedexData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $PokedexTable createAlias(String alias) {
    return $PokedexTable(attachedDatabase, alias);
  }
}

class PokedexData extends DataClass implements Insertable<PokedexData> {
  final int id;
  final String name;
  const PokedexData({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  PokedexCompanion toCompanion(bool nullToAbsent) {
    return PokedexCompanion(
      id: Value(id),
      name: Value(name),
    );
  }

  factory PokedexData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PokedexData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  PokedexData copyWith({int? id, String? name}) => PokedexData(
        id: id ?? this.id,
        name: name ?? this.name,
      );
  PokedexData copyWithCompanion(PokedexCompanion data) {
    return PokedexData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PokedexData(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PokedexData && other.id == this.id && other.name == this.name);
}

class PokedexCompanion extends UpdateCompanion<PokedexData> {
  final Value<int> id;
  final Value<String> name;
  const PokedexCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  PokedexCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<PokedexData> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  PokedexCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return PokedexCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PokedexCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CardSetsTable cardSets = $CardSetsTable(this);
  late final $CardsTable cards = $CardsTable(this);
  late final $UserCardsTable userCards = $UserCardsTable(this);
  late final $CardMarketPricesTable cardMarketPrices =
      $CardMarketPricesTable(this);
  late final $TcgPlayerPricesTable tcgPlayerPrices =
      $TcgPlayerPricesTable(this);
  late final $PortfolioHistoryTable portfolioHistory =
      $PortfolioHistoryTable(this);
  late final $BindersTable binders = $BindersTable(this);
  late final $BinderCardsTable binderCards = $BinderCardsTable(this);
  late final $PokedexTable pokedex = $PokedexTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        cardSets,
        cards,
        userCards,
        cardMarketPrices,
        tcgPlayerPrices,
        portfolioHistory,
        binders,
        binderCards,
        pokedex
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('binders',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('binder_cards', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$CardSetsTableCreateCompanionBuilder = CardSetsCompanion Function({
  required String id,
  required String name,
  required String series,
  Value<int?> printedTotal,
  Value<int?> total,
  Value<String?> releaseDate,
  required String updatedAt,
  Value<String?> logoUrl,
  Value<String?> symbolUrl,
  Value<String?> logoUrlDe,
  Value<String?> nameDe,
  Value<int> rowid,
});
typedef $$CardSetsTableUpdateCompanionBuilder = CardSetsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> series,
  Value<int?> printedTotal,
  Value<int?> total,
  Value<String?> releaseDate,
  Value<String> updatedAt,
  Value<String?> logoUrl,
  Value<String?> symbolUrl,
  Value<String?> logoUrlDe,
  Value<String?> nameDe,
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
            Value<int?> printedTotal = const Value.absent(),
            Value<int?> total = const Value.absent(),
            Value<String?> releaseDate = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<String?> logoUrl = const Value.absent(),
            Value<String?> symbolUrl = const Value.absent(),
            Value<String?> logoUrlDe = const Value.absent(),
            Value<String?> nameDe = const Value.absent(),
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
            logoUrlDe: logoUrlDe,
            nameDe: nameDe,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String series,
            Value<int?> printedTotal = const Value.absent(),
            Value<int?> total = const Value.absent(),
            Value<String?> releaseDate = const Value.absent(),
            required String updatedAt,
            Value<String?> logoUrl = const Value.absent(),
            Value<String?> symbolUrl = const Value.absent(),
            Value<String?> logoUrlDe = const Value.absent(),
            Value<String?> nameDe = const Value.absent(),
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
            logoUrlDe: logoUrlDe,
            nameDe: nameDe,
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

  ColumnFilters<String> get logoUrlDe => $state.composableBuilder(
      column: $state.table.logoUrlDe,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get nameDe => $state.composableBuilder(
      column: $state.table.nameDe,
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

  ColumnOrderings<String> get logoUrlDe => $state.composableBuilder(
      column: $state.table.logoUrlDe,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get nameDe => $state.composableBuilder(
      column: $state.table.nameDe,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$CardsTableCreateCompanionBuilder = CardsCompanion Function({
  required String id,
  required String setId,
  required String name,
  Value<String?> nameDe,
  required String number,
  required String imageUrl,
  required String imageUrlDe,
  Value<String?> artist,
  Value<String?> rarity,
  Value<String?> flavorText,
  Value<String?> flavorTextDe,
  Value<bool> hasFirstEdition,
  Value<bool> hasNormal,
  Value<bool> hasHolo,
  Value<bool> hasReverse,
  Value<bool> hasWPromo,
  Value<int> sortNumber,
  Value<int> rowid,
});
typedef $$CardsTableUpdateCompanionBuilder = CardsCompanion Function({
  Value<String> id,
  Value<String> setId,
  Value<String> name,
  Value<String?> nameDe,
  Value<String> number,
  Value<String> imageUrl,
  Value<String> imageUrlDe,
  Value<String?> artist,
  Value<String?> rarity,
  Value<String?> flavorText,
  Value<String?> flavorTextDe,
  Value<bool> hasFirstEdition,
  Value<bool> hasNormal,
  Value<bool> hasHolo,
  Value<bool> hasReverse,
  Value<bool> hasWPromo,
  Value<int> sortNumber,
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
            Value<String?> nameDe = const Value.absent(),
            Value<String> number = const Value.absent(),
            Value<String> imageUrl = const Value.absent(),
            Value<String> imageUrlDe = const Value.absent(),
            Value<String?> artist = const Value.absent(),
            Value<String?> rarity = const Value.absent(),
            Value<String?> flavorText = const Value.absent(),
            Value<String?> flavorTextDe = const Value.absent(),
            Value<bool> hasFirstEdition = const Value.absent(),
            Value<bool> hasNormal = const Value.absent(),
            Value<bool> hasHolo = const Value.absent(),
            Value<bool> hasReverse = const Value.absent(),
            Value<bool> hasWPromo = const Value.absent(),
            Value<int> sortNumber = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CardsCompanion(
            id: id,
            setId: setId,
            name: name,
            nameDe: nameDe,
            number: number,
            imageUrl: imageUrl,
            imageUrlDe: imageUrlDe,
            artist: artist,
            rarity: rarity,
            flavorText: flavorText,
            flavorTextDe: flavorTextDe,
            hasFirstEdition: hasFirstEdition,
            hasNormal: hasNormal,
            hasHolo: hasHolo,
            hasReverse: hasReverse,
            hasWPromo: hasWPromo,
            sortNumber: sortNumber,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String setId,
            required String name,
            Value<String?> nameDe = const Value.absent(),
            required String number,
            required String imageUrl,
            required String imageUrlDe,
            Value<String?> artist = const Value.absent(),
            Value<String?> rarity = const Value.absent(),
            Value<String?> flavorText = const Value.absent(),
            Value<String?> flavorTextDe = const Value.absent(),
            Value<bool> hasFirstEdition = const Value.absent(),
            Value<bool> hasNormal = const Value.absent(),
            Value<bool> hasHolo = const Value.absent(),
            Value<bool> hasReverse = const Value.absent(),
            Value<bool> hasWPromo = const Value.absent(),
            Value<int> sortNumber = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CardsCompanion.insert(
            id: id,
            setId: setId,
            name: name,
            nameDe: nameDe,
            number: number,
            imageUrl: imageUrl,
            imageUrlDe: imageUrlDe,
            artist: artist,
            rarity: rarity,
            flavorText: flavorText,
            flavorTextDe: flavorTextDe,
            hasFirstEdition: hasFirstEdition,
            hasNormal: hasNormal,
            hasHolo: hasHolo,
            hasReverse: hasReverse,
            hasWPromo: hasWPromo,
            sortNumber: sortNumber,
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

  ColumnFilters<String> get nameDe => $state.composableBuilder(
      column: $state.table.nameDe,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get number => $state.composableBuilder(
      column: $state.table.number,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get imageUrl => $state.composableBuilder(
      column: $state.table.imageUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get imageUrlDe => $state.composableBuilder(
      column: $state.table.imageUrlDe,
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

  ColumnFilters<String> get flavorTextDe => $state.composableBuilder(
      column: $state.table.flavorTextDe,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get hasFirstEdition => $state.composableBuilder(
      column: $state.table.hasFirstEdition,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get hasNormal => $state.composableBuilder(
      column: $state.table.hasNormal,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get hasHolo => $state.composableBuilder(
      column: $state.table.hasHolo,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get hasReverse => $state.composableBuilder(
      column: $state.table.hasReverse,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get hasWPromo => $state.composableBuilder(
      column: $state.table.hasWPromo,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get sortNumber => $state.composableBuilder(
      column: $state.table.sortNumber,
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

  ComposableFilter binderCardsRefs(
      ComposableFilter Function($$BinderCardsTableFilterComposer f) f) {
    final $$BinderCardsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.binderCards,
        getReferencedColumn: (t) => t.cardId,
        builder: (joinBuilder, parentComposers) =>
            $$BinderCardsTableFilterComposer(ComposerState($state.db,
                $state.db.binderCards, joinBuilder, parentComposers)));
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

  ColumnOrderings<String> get nameDe => $state.composableBuilder(
      column: $state.table.nameDe,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get number => $state.composableBuilder(
      column: $state.table.number,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get imageUrl => $state.composableBuilder(
      column: $state.table.imageUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get imageUrlDe => $state.composableBuilder(
      column: $state.table.imageUrlDe,
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

  ColumnOrderings<String> get flavorTextDe => $state.composableBuilder(
      column: $state.table.flavorTextDe,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get hasFirstEdition => $state.composableBuilder(
      column: $state.table.hasFirstEdition,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get hasNormal => $state.composableBuilder(
      column: $state.table.hasNormal,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get hasHolo => $state.composableBuilder(
      column: $state.table.hasHolo,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get hasReverse => $state.composableBuilder(
      column: $state.table.hasReverse,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get hasWPromo => $state.composableBuilder(
      column: $state.table.hasWPromo,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get sortNumber => $state.composableBuilder(
      column: $state.table.sortNumber,
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

typedef $$CardMarketPricesTableCreateCompanionBuilder
    = CardMarketPricesCompanion Function({
  Value<int> id,
  required String cardId,
  required DateTime fetchedAt,
  Value<double?> average,
  Value<double?> low,
  Value<double?> trend,
  Value<double?> avg1,
  Value<double?> avg7,
  Value<double?> avg30,
  Value<double?> avgHolo,
  Value<double?> lowHolo,
  Value<double?> trendHolo,
  Value<double?> avg1Holo,
  Value<double?> avg7Holo,
  Value<double?> avg30Holo,
  Value<double?> trendReverse,
  Value<String?> url,
});
typedef $$CardMarketPricesTableUpdateCompanionBuilder
    = CardMarketPricesCompanion Function({
  Value<int> id,
  Value<String> cardId,
  Value<DateTime> fetchedAt,
  Value<double?> average,
  Value<double?> low,
  Value<double?> trend,
  Value<double?> avg1,
  Value<double?> avg7,
  Value<double?> avg30,
  Value<double?> avgHolo,
  Value<double?> lowHolo,
  Value<double?> trendHolo,
  Value<double?> avg1Holo,
  Value<double?> avg7Holo,
  Value<double?> avg30Holo,
  Value<double?> trendReverse,
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
            Value<double?> average = const Value.absent(),
            Value<double?> low = const Value.absent(),
            Value<double?> trend = const Value.absent(),
            Value<double?> avg1 = const Value.absent(),
            Value<double?> avg7 = const Value.absent(),
            Value<double?> avg30 = const Value.absent(),
            Value<double?> avgHolo = const Value.absent(),
            Value<double?> lowHolo = const Value.absent(),
            Value<double?> trendHolo = const Value.absent(),
            Value<double?> avg1Holo = const Value.absent(),
            Value<double?> avg7Holo = const Value.absent(),
            Value<double?> avg30Holo = const Value.absent(),
            Value<double?> trendReverse = const Value.absent(),
            Value<String?> url = const Value.absent(),
          }) =>
              CardMarketPricesCompanion(
            id: id,
            cardId: cardId,
            fetchedAt: fetchedAt,
            average: average,
            low: low,
            trend: trend,
            avg1: avg1,
            avg7: avg7,
            avg30: avg30,
            avgHolo: avgHolo,
            lowHolo: lowHolo,
            trendHolo: trendHolo,
            avg1Holo: avg1Holo,
            avg7Holo: avg7Holo,
            avg30Holo: avg30Holo,
            trendReverse: trendReverse,
            url: url,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String cardId,
            required DateTime fetchedAt,
            Value<double?> average = const Value.absent(),
            Value<double?> low = const Value.absent(),
            Value<double?> trend = const Value.absent(),
            Value<double?> avg1 = const Value.absent(),
            Value<double?> avg7 = const Value.absent(),
            Value<double?> avg30 = const Value.absent(),
            Value<double?> avgHolo = const Value.absent(),
            Value<double?> lowHolo = const Value.absent(),
            Value<double?> trendHolo = const Value.absent(),
            Value<double?> avg1Holo = const Value.absent(),
            Value<double?> avg7Holo = const Value.absent(),
            Value<double?> avg30Holo = const Value.absent(),
            Value<double?> trendReverse = const Value.absent(),
            Value<String?> url = const Value.absent(),
          }) =>
              CardMarketPricesCompanion.insert(
            id: id,
            cardId: cardId,
            fetchedAt: fetchedAt,
            average: average,
            low: low,
            trend: trend,
            avg1: avg1,
            avg7: avg7,
            avg30: avg30,
            avgHolo: avgHolo,
            lowHolo: lowHolo,
            trendHolo: trendHolo,
            avg1Holo: avg1Holo,
            avg7Holo: avg7Holo,
            avg30Holo: avg30Holo,
            trendReverse: trendReverse,
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

  ColumnFilters<double> get average => $state.composableBuilder(
      column: $state.table.average,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get low => $state.composableBuilder(
      column: $state.table.low,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get trend => $state.composableBuilder(
      column: $state.table.trend,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get avg1 => $state.composableBuilder(
      column: $state.table.avg1,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get avg7 => $state.composableBuilder(
      column: $state.table.avg7,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get avg30 => $state.composableBuilder(
      column: $state.table.avg30,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get avgHolo => $state.composableBuilder(
      column: $state.table.avgHolo,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get lowHolo => $state.composableBuilder(
      column: $state.table.lowHolo,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get trendHolo => $state.composableBuilder(
      column: $state.table.trendHolo,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get avg1Holo => $state.composableBuilder(
      column: $state.table.avg1Holo,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get avg7Holo => $state.composableBuilder(
      column: $state.table.avg7Holo,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get avg30Holo => $state.composableBuilder(
      column: $state.table.avg30Holo,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get trendReverse => $state.composableBuilder(
      column: $state.table.trendReverse,
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

  ColumnOrderings<double> get average => $state.composableBuilder(
      column: $state.table.average,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get low => $state.composableBuilder(
      column: $state.table.low,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get trend => $state.composableBuilder(
      column: $state.table.trend,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get avg1 => $state.composableBuilder(
      column: $state.table.avg1,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get avg7 => $state.composableBuilder(
      column: $state.table.avg7,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get avg30 => $state.composableBuilder(
      column: $state.table.avg30,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get avgHolo => $state.composableBuilder(
      column: $state.table.avgHolo,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get lowHolo => $state.composableBuilder(
      column: $state.table.lowHolo,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get trendHolo => $state.composableBuilder(
      column: $state.table.trendHolo,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get avg1Holo => $state.composableBuilder(
      column: $state.table.avg1Holo,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get avg7Holo => $state.composableBuilder(
      column: $state.table.avg7Holo,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get avg30Holo => $state.composableBuilder(
      column: $state.table.avg30Holo,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get trendReverse => $state.composableBuilder(
      column: $state.table.trendReverse,
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
  Value<double?> normalMarket,
  Value<double?> normalLow,
  Value<double?> normalMid,
  Value<double?> normalDirectLow,
  Value<double?> holoMarket,
  Value<double?> holoLow,
  Value<double?> holoMid,
  Value<double?> holoDirectLow,
  Value<double?> reverseMarket,
  Value<double?> reverseLow,
  Value<double?> reverseMid,
  Value<double?> reverseDirectLow,
  Value<String?> url,
});
typedef $$TcgPlayerPricesTableUpdateCompanionBuilder = TcgPlayerPricesCompanion
    Function({
  Value<int> id,
  Value<String> cardId,
  Value<DateTime> fetchedAt,
  Value<double?> normalMarket,
  Value<double?> normalLow,
  Value<double?> normalMid,
  Value<double?> normalDirectLow,
  Value<double?> holoMarket,
  Value<double?> holoLow,
  Value<double?> holoMid,
  Value<double?> holoDirectLow,
  Value<double?> reverseMarket,
  Value<double?> reverseLow,
  Value<double?> reverseMid,
  Value<double?> reverseDirectLow,
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
            Value<double?> normalMarket = const Value.absent(),
            Value<double?> normalLow = const Value.absent(),
            Value<double?> normalMid = const Value.absent(),
            Value<double?> normalDirectLow = const Value.absent(),
            Value<double?> holoMarket = const Value.absent(),
            Value<double?> holoLow = const Value.absent(),
            Value<double?> holoMid = const Value.absent(),
            Value<double?> holoDirectLow = const Value.absent(),
            Value<double?> reverseMarket = const Value.absent(),
            Value<double?> reverseLow = const Value.absent(),
            Value<double?> reverseMid = const Value.absent(),
            Value<double?> reverseDirectLow = const Value.absent(),
            Value<String?> url = const Value.absent(),
          }) =>
              TcgPlayerPricesCompanion(
            id: id,
            cardId: cardId,
            fetchedAt: fetchedAt,
            normalMarket: normalMarket,
            normalLow: normalLow,
            normalMid: normalMid,
            normalDirectLow: normalDirectLow,
            holoMarket: holoMarket,
            holoLow: holoLow,
            holoMid: holoMid,
            holoDirectLow: holoDirectLow,
            reverseMarket: reverseMarket,
            reverseLow: reverseLow,
            reverseMid: reverseMid,
            reverseDirectLow: reverseDirectLow,
            url: url,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String cardId,
            required DateTime fetchedAt,
            Value<double?> normalMarket = const Value.absent(),
            Value<double?> normalLow = const Value.absent(),
            Value<double?> normalMid = const Value.absent(),
            Value<double?> normalDirectLow = const Value.absent(),
            Value<double?> holoMarket = const Value.absent(),
            Value<double?> holoLow = const Value.absent(),
            Value<double?> holoMid = const Value.absent(),
            Value<double?> holoDirectLow = const Value.absent(),
            Value<double?> reverseMarket = const Value.absent(),
            Value<double?> reverseLow = const Value.absent(),
            Value<double?> reverseMid = const Value.absent(),
            Value<double?> reverseDirectLow = const Value.absent(),
            Value<String?> url = const Value.absent(),
          }) =>
              TcgPlayerPricesCompanion.insert(
            id: id,
            cardId: cardId,
            fetchedAt: fetchedAt,
            normalMarket: normalMarket,
            normalLow: normalLow,
            normalMid: normalMid,
            normalDirectLow: normalDirectLow,
            holoMarket: holoMarket,
            holoLow: holoLow,
            holoMid: holoMid,
            holoDirectLow: holoDirectLow,
            reverseMarket: reverseMarket,
            reverseLow: reverseLow,
            reverseMid: reverseMid,
            reverseDirectLow: reverseDirectLow,
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

  ColumnFilters<double> get normalMarket => $state.composableBuilder(
      column: $state.table.normalMarket,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get normalLow => $state.composableBuilder(
      column: $state.table.normalLow,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get normalMid => $state.composableBuilder(
      column: $state.table.normalMid,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get normalDirectLow => $state.composableBuilder(
      column: $state.table.normalDirectLow,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get holoMarket => $state.composableBuilder(
      column: $state.table.holoMarket,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get holoLow => $state.composableBuilder(
      column: $state.table.holoLow,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get holoMid => $state.composableBuilder(
      column: $state.table.holoMid,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get holoDirectLow => $state.composableBuilder(
      column: $state.table.holoDirectLow,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get reverseMarket => $state.composableBuilder(
      column: $state.table.reverseMarket,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get reverseLow => $state.composableBuilder(
      column: $state.table.reverseLow,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get reverseMid => $state.composableBuilder(
      column: $state.table.reverseMid,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get reverseDirectLow => $state.composableBuilder(
      column: $state.table.reverseDirectLow,
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

  ColumnOrderings<double> get normalMarket => $state.composableBuilder(
      column: $state.table.normalMarket,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get normalLow => $state.composableBuilder(
      column: $state.table.normalLow,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get normalMid => $state.composableBuilder(
      column: $state.table.normalMid,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get normalDirectLow => $state.composableBuilder(
      column: $state.table.normalDirectLow,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get holoMarket => $state.composableBuilder(
      column: $state.table.holoMarket,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get holoLow => $state.composableBuilder(
      column: $state.table.holoLow,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get holoMid => $state.composableBuilder(
      column: $state.table.holoMid,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get holoDirectLow => $state.composableBuilder(
      column: $state.table.holoDirectLow,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get reverseMarket => $state.composableBuilder(
      column: $state.table.reverseMarket,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get reverseLow => $state.composableBuilder(
      column: $state.table.reverseLow,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get reverseMid => $state.composableBuilder(
      column: $state.table.reverseMid,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get reverseDirectLow => $state.composableBuilder(
      column: $state.table.reverseDirectLow,
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

typedef $$BindersTableCreateCompanionBuilder = BindersCompanion Function({
  Value<int> id,
  required String name,
  required int color,
  Value<String?> icon,
  Value<int> rowsPerPage,
  Value<int> columnsPerPage,
  Value<String> type,
  Value<String> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
});
typedef $$BindersTableUpdateCompanionBuilder = BindersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> color,
  Value<String?> icon,
  Value<int> rowsPerPage,
  Value<int> columnsPerPage,
  Value<String> type,
  Value<String> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
});

class $$BindersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BindersTable,
    Binder,
    $$BindersTableFilterComposer,
    $$BindersTableOrderingComposer,
    $$BindersTableCreateCompanionBuilder,
    $$BindersTableUpdateCompanionBuilder> {
  $$BindersTableTableManager(_$AppDatabase db, $BindersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$BindersTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$BindersTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> color = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<int> rowsPerPage = const Value.absent(),
            Value<int> columnsPerPage = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              BindersCompanion(
            id: id,
            name: name,
            color: color,
            icon: icon,
            rowsPerPage: rowsPerPage,
            columnsPerPage: columnsPerPage,
            type: type,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required int color,
            Value<String?> icon = const Value.absent(),
            Value<int> rowsPerPage = const Value.absent(),
            Value<int> columnsPerPage = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
          }) =>
              BindersCompanion.insert(
            id: id,
            name: name,
            color: color,
            icon: icon,
            rowsPerPage: rowsPerPage,
            columnsPerPage: columnsPerPage,
            type: type,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$BindersTableFilterComposer
    extends FilterComposer<_$AppDatabase, $BindersTable> {
  $$BindersTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get color => $state.composableBuilder(
      column: $state.table.color,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get icon => $state.composableBuilder(
      column: $state.table.icon,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get rowsPerPage => $state.composableBuilder(
      column: $state.table.rowsPerPage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get columnsPerPage => $state.composableBuilder(
      column: $state.table.columnsPerPage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sortOrder => $state.composableBuilder(
      column: $state.table.sortOrder,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter binderCardsRefs(
      ComposableFilter Function($$BinderCardsTableFilterComposer f) f) {
    final $$BinderCardsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.binderCards,
        getReferencedColumn: (t) => t.binderId,
        builder: (joinBuilder, parentComposers) =>
            $$BinderCardsTableFilterComposer(ComposerState($state.db,
                $state.db.binderCards, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$BindersTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $BindersTable> {
  $$BindersTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get color => $state.composableBuilder(
      column: $state.table.color,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get icon => $state.composableBuilder(
      column: $state.table.icon,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get rowsPerPage => $state.composableBuilder(
      column: $state.table.rowsPerPage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get columnsPerPage => $state.composableBuilder(
      column: $state.table.columnsPerPage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sortOrder => $state.composableBuilder(
      column: $state.table.sortOrder,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$BinderCardsTableCreateCompanionBuilder = BinderCardsCompanion
    Function({
  Value<int> id,
  required int binderId,
  required int pageIndex,
  required int slotIndex,
  Value<String?> cardId,
  Value<bool> isPlaceholder,
  Value<String?> placeholderLabel,
});
typedef $$BinderCardsTableUpdateCompanionBuilder = BinderCardsCompanion
    Function({
  Value<int> id,
  Value<int> binderId,
  Value<int> pageIndex,
  Value<int> slotIndex,
  Value<String?> cardId,
  Value<bool> isPlaceholder,
  Value<String?> placeholderLabel,
});

class $$BinderCardsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BinderCardsTable,
    BinderCard,
    $$BinderCardsTableFilterComposer,
    $$BinderCardsTableOrderingComposer,
    $$BinderCardsTableCreateCompanionBuilder,
    $$BinderCardsTableUpdateCompanionBuilder> {
  $$BinderCardsTableTableManager(_$AppDatabase db, $BinderCardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$BinderCardsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$BinderCardsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> binderId = const Value.absent(),
            Value<int> pageIndex = const Value.absent(),
            Value<int> slotIndex = const Value.absent(),
            Value<String?> cardId = const Value.absent(),
            Value<bool> isPlaceholder = const Value.absent(),
            Value<String?> placeholderLabel = const Value.absent(),
          }) =>
              BinderCardsCompanion(
            id: id,
            binderId: binderId,
            pageIndex: pageIndex,
            slotIndex: slotIndex,
            cardId: cardId,
            isPlaceholder: isPlaceholder,
            placeholderLabel: placeholderLabel,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int binderId,
            required int pageIndex,
            required int slotIndex,
            Value<String?> cardId = const Value.absent(),
            Value<bool> isPlaceholder = const Value.absent(),
            Value<String?> placeholderLabel = const Value.absent(),
          }) =>
              BinderCardsCompanion.insert(
            id: id,
            binderId: binderId,
            pageIndex: pageIndex,
            slotIndex: slotIndex,
            cardId: cardId,
            isPlaceholder: isPlaceholder,
            placeholderLabel: placeholderLabel,
          ),
        ));
}

class $$BinderCardsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $BinderCardsTable> {
  $$BinderCardsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get pageIndex => $state.composableBuilder(
      column: $state.table.pageIndex,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get slotIndex => $state.composableBuilder(
      column: $state.table.slotIndex,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isPlaceholder => $state.composableBuilder(
      column: $state.table.isPlaceholder,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get placeholderLabel => $state.composableBuilder(
      column: $state.table.placeholderLabel,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$BindersTableFilterComposer get binderId {
    final $$BindersTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.binderId,
        referencedTable: $state.db.binders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$BindersTableFilterComposer(
            ComposerState(
                $state.db, $state.db.binders, joinBuilder, parentComposers)));
    return composer;
  }

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

class $$BinderCardsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $BinderCardsTable> {
  $$BinderCardsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get pageIndex => $state.composableBuilder(
      column: $state.table.pageIndex,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get slotIndex => $state.composableBuilder(
      column: $state.table.slotIndex,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isPlaceholder => $state.composableBuilder(
      column: $state.table.isPlaceholder,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get placeholderLabel => $state.composableBuilder(
      column: $state.table.placeholderLabel,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$BindersTableOrderingComposer get binderId {
    final $$BindersTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.binderId,
        referencedTable: $state.db.binders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$BindersTableOrderingComposer(ComposerState(
                $state.db, $state.db.binders, joinBuilder, parentComposers)));
    return composer;
  }

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

typedef $$PokedexTableCreateCompanionBuilder = PokedexCompanion Function({
  Value<int> id,
  required String name,
});
typedef $$PokedexTableUpdateCompanionBuilder = PokedexCompanion Function({
  Value<int> id,
  Value<String> name,
});

class $$PokedexTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PokedexTable,
    PokedexData,
    $$PokedexTableFilterComposer,
    $$PokedexTableOrderingComposer,
    $$PokedexTableCreateCompanionBuilder,
    $$PokedexTableUpdateCompanionBuilder> {
  $$PokedexTableTableManager(_$AppDatabase db, $PokedexTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PokedexTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PokedexTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) =>
              PokedexCompanion(
            id: id,
            name: name,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
          }) =>
              PokedexCompanion.insert(
            id: id,
            name: name,
          ),
        ));
}

class $$PokedexTableFilterComposer
    extends FilterComposer<_$AppDatabase, $PokedexTable> {
  $$PokedexTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$PokedexTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $PokedexTable> {
  $$PokedexTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
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
  $$UserCardsTableTableManager get userCards =>
      $$UserCardsTableTableManager(_db, _db.userCards);
  $$CardMarketPricesTableTableManager get cardMarketPrices =>
      $$CardMarketPricesTableTableManager(_db, _db.cardMarketPrices);
  $$TcgPlayerPricesTableTableManager get tcgPlayerPrices =>
      $$TcgPlayerPricesTableTableManager(_db, _db.tcgPlayerPrices);
  $$PortfolioHistoryTableTableManager get portfolioHistory =>
      $$PortfolioHistoryTableTableManager(_db, _db.portfolioHistory);
  $$BindersTableTableManager get binders =>
      $$BindersTableTableManager(_db, _db.binders);
  $$BinderCardsTableTableManager get binderCards =>
      $$BinderCardsTableTableManager(_db, _db.binderCards);
  $$PokedexTableTableManager get pokedex =>
      $$PokedexTableTableManager(_db, _db.pokedex);
}
