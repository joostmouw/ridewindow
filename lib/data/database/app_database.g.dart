// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ForecastCacheEntriesTable extends ForecastCacheEntries
    with TableInfo<$ForecastCacheEntriesTable, ForecastCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ForecastCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
      'lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
      'lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _fetchedAtMeta =
      const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
      'fetched_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, lat, lon, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'forecast_cache_entries';
  @override
  VerificationContext validateIntegrity(Insertable<ForecastCacheEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lat')) {
      context.handle(
          _latMeta, lat.isAcceptableOrUnknown(data['lat']!, _latMeta));
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
          _lonMeta, lon.isAcceptableOrUnknown(data['lon']!, _lonMeta));
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(_fetchedAtMeta,
          fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta));
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ForecastCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ForecastCacheEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      lat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lat'])!,
      lon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lon'])!,
      fetchedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}fetched_at'])!,
    );
  }

  @override
  $ForecastCacheEntriesTable createAlias(String alias) {
    return $ForecastCacheEntriesTable(attachedDatabase, alias);
  }
}

class ForecastCacheEntry extends DataClass
    implements Insertable<ForecastCacheEntry> {
  final int id;
  final double lat;
  final double lon;
  final DateTime fetchedAt;
  const ForecastCacheEntry(
      {required this.id,
      required this.lat,
      required this.lon,
      required this.fetchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  ForecastCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return ForecastCacheEntriesCompanion(
      id: Value(id),
      lat: Value(lat),
      lon: Value(lon),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory ForecastCacheEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ForecastCacheEntry(
      id: serializer.fromJson<int>(json['id']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  ForecastCacheEntry copyWith(
          {int? id, double? lat, double? lon, DateTime? fetchedAt}) =>
      ForecastCacheEntry(
        id: id ?? this.id,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  ForecastCacheEntry copyWithCompanion(ForecastCacheEntriesCompanion data) {
    return ForecastCacheEntry(
      id: data.id.present ? data.id.value : this.id,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ForecastCacheEntry(')
          ..write('id: $id, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lat, lon, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ForecastCacheEntry &&
          other.id == this.id &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.fetchedAt == this.fetchedAt);
}

class ForecastCacheEntriesCompanion
    extends UpdateCompanion<ForecastCacheEntry> {
  final Value<int> id;
  final Value<double> lat;
  final Value<double> lon;
  final Value<DateTime> fetchedAt;
  const ForecastCacheEntriesCompanion({
    this.id = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.fetchedAt = const Value.absent(),
  });
  ForecastCacheEntriesCompanion.insert({
    this.id = const Value.absent(),
    required double lat,
    required double lon,
    required DateTime fetchedAt,
  })  : lat = Value(lat),
        lon = Value(lon),
        fetchedAt = Value(fetchedAt);
  static Insertable<ForecastCacheEntry> custom({
    Expression<int>? id,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<DateTime>? fetchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
    });
  }

  ForecastCacheEntriesCompanion copyWith(
      {Value<int>? id,
      Value<double>? lat,
      Value<double>? lon,
      Value<DateTime>? fetchedAt}) {
    return ForecastCacheEntriesCompanion(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ForecastCacheEntriesCompanion(')
          ..write('id: $id, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }
}

class $HourlyForecastEntriesTable extends HourlyForecastEntries
    with TableInfo<$HourlyForecastEntriesTable, HourlyForecastEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HourlyForecastEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _cacheIdMeta =
      const VerificationMeta('cacheId');
  @override
  late final GeneratedColumn<int> cacheId = GeneratedColumn<int>(
      'cache_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES forecast_cache_entries (id)'));
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<int> time = GeneratedColumn<int>(
      'time', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _temperatureCMeta =
      const VerificationMeta('temperatureC');
  @override
  late final GeneratedColumn<double> temperatureC = GeneratedColumn<double>(
      'temperature_c', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _apparentTemperatureCMeta =
      const VerificationMeta('apparentTemperatureC');
  @override
  late final GeneratedColumn<double> apparentTemperatureC =
      GeneratedColumn<double>('apparent_temperature_c', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _precipitationMmMeta =
      const VerificationMeta('precipitationMm');
  @override
  late final GeneratedColumn<double> precipitationMm = GeneratedColumn<double>(
      'precipitation_mm', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _precipitationProbabilityMeta =
      const VerificationMeta('precipitationProbability');
  @override
  late final GeneratedColumn<double> precipitationProbability =
      GeneratedColumn<double>('precipitation_probability', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _windspeedKmhMeta =
      const VerificationMeta('windspeedKmh');
  @override
  late final GeneratedColumn<double> windspeedKmh = GeneratedColumn<double>(
      'windspeed_kmh', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _winddirectionDegMeta =
      const VerificationMeta('winddirectionDeg');
  @override
  late final GeneratedColumn<double> winddirectionDeg = GeneratedColumn<double>(
      'winddirection_deg', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        cacheId,
        time,
        temperatureC,
        apparentTemperatureC,
        precipitationMm,
        precipitationProbability,
        windspeedKmh,
        winddirectionDeg
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hourly_forecast_entries';
  @override
  VerificationContext validateIntegrity(
      Insertable<HourlyForecastEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cache_id')) {
      context.handle(_cacheIdMeta,
          cacheId.isAcceptableOrUnknown(data['cache_id']!, _cacheIdMeta));
    } else if (isInserting) {
      context.missing(_cacheIdMeta);
    }
    if (data.containsKey('time')) {
      context.handle(
          _timeMeta, time.isAcceptableOrUnknown(data['time']!, _timeMeta));
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('temperature_c')) {
      context.handle(
          _temperatureCMeta,
          temperatureC.isAcceptableOrUnknown(
              data['temperature_c']!, _temperatureCMeta));
    }
    if (data.containsKey('apparent_temperature_c')) {
      context.handle(
          _apparentTemperatureCMeta,
          apparentTemperatureC.isAcceptableOrUnknown(
              data['apparent_temperature_c']!, _apparentTemperatureCMeta));
    }
    if (data.containsKey('precipitation_mm')) {
      context.handle(
          _precipitationMmMeta,
          precipitationMm.isAcceptableOrUnknown(
              data['precipitation_mm']!, _precipitationMmMeta));
    }
    if (data.containsKey('precipitation_probability')) {
      context.handle(
          _precipitationProbabilityMeta,
          precipitationProbability.isAcceptableOrUnknown(
              data['precipitation_probability']!,
              _precipitationProbabilityMeta));
    }
    if (data.containsKey('windspeed_kmh')) {
      context.handle(
          _windspeedKmhMeta,
          windspeedKmh.isAcceptableOrUnknown(
              data['windspeed_kmh']!, _windspeedKmhMeta));
    }
    if (data.containsKey('winddirection_deg')) {
      context.handle(
          _winddirectionDegMeta,
          winddirectionDeg.isAcceptableOrUnknown(
              data['winddirection_deg']!, _winddirectionDegMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HourlyForecastEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HourlyForecastEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      cacheId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cache_id'])!,
      time: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}time'])!,
      temperatureC: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}temperature_c']),
      apparentTemperatureC: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}apparent_temperature_c']),
      precipitationMm: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}precipitation_mm']),
      precipitationProbability: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}precipitation_probability']),
      windspeedKmh: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}windspeed_kmh']),
      winddirectionDeg: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}winddirection_deg']),
    );
  }

  @override
  $HourlyForecastEntriesTable createAlias(String alias) {
    return $HourlyForecastEntriesTable(attachedDatabase, alias);
  }
}

class HourlyForecastEntry extends DataClass
    implements Insertable<HourlyForecastEntry> {
  final int id;
  final int cacheId;
  final int time;
  final double? temperatureC;
  final double? apparentTemperatureC;
  final double? precipitationMm;
  final double? precipitationProbability;
  final double? windspeedKmh;
  final double? winddirectionDeg;
  const HourlyForecastEntry(
      {required this.id,
      required this.cacheId,
      required this.time,
      this.temperatureC,
      this.apparentTemperatureC,
      this.precipitationMm,
      this.precipitationProbability,
      this.windspeedKmh,
      this.winddirectionDeg});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cache_id'] = Variable<int>(cacheId);
    map['time'] = Variable<int>(time);
    if (!nullToAbsent || temperatureC != null) {
      map['temperature_c'] = Variable<double>(temperatureC);
    }
    if (!nullToAbsent || apparentTemperatureC != null) {
      map['apparent_temperature_c'] = Variable<double>(apparentTemperatureC);
    }
    if (!nullToAbsent || precipitationMm != null) {
      map['precipitation_mm'] = Variable<double>(precipitationMm);
    }
    if (!nullToAbsent || precipitationProbability != null) {
      map['precipitation_probability'] =
          Variable<double>(precipitationProbability);
    }
    if (!nullToAbsent || windspeedKmh != null) {
      map['windspeed_kmh'] = Variable<double>(windspeedKmh);
    }
    if (!nullToAbsent || winddirectionDeg != null) {
      map['winddirection_deg'] = Variable<double>(winddirectionDeg);
    }
    return map;
  }

  HourlyForecastEntriesCompanion toCompanion(bool nullToAbsent) {
    return HourlyForecastEntriesCompanion(
      id: Value(id),
      cacheId: Value(cacheId),
      time: Value(time),
      temperatureC: temperatureC == null && nullToAbsent
          ? const Value.absent()
          : Value(temperatureC),
      apparentTemperatureC: apparentTemperatureC == null && nullToAbsent
          ? const Value.absent()
          : Value(apparentTemperatureC),
      precipitationMm: precipitationMm == null && nullToAbsent
          ? const Value.absent()
          : Value(precipitationMm),
      precipitationProbability: precipitationProbability == null && nullToAbsent
          ? const Value.absent()
          : Value(precipitationProbability),
      windspeedKmh: windspeedKmh == null && nullToAbsent
          ? const Value.absent()
          : Value(windspeedKmh),
      winddirectionDeg: winddirectionDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(winddirectionDeg),
    );
  }

  factory HourlyForecastEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HourlyForecastEntry(
      id: serializer.fromJson<int>(json['id']),
      cacheId: serializer.fromJson<int>(json['cacheId']),
      time: serializer.fromJson<int>(json['time']),
      temperatureC: serializer.fromJson<double?>(json['temperatureC']),
      apparentTemperatureC:
          serializer.fromJson<double?>(json['apparentTemperatureC']),
      precipitationMm: serializer.fromJson<double?>(json['precipitationMm']),
      precipitationProbability:
          serializer.fromJson<double?>(json['precipitationProbability']),
      windspeedKmh: serializer.fromJson<double?>(json['windspeedKmh']),
      winddirectionDeg: serializer.fromJson<double?>(json['winddirectionDeg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cacheId': serializer.toJson<int>(cacheId),
      'time': serializer.toJson<int>(time),
      'temperatureC': serializer.toJson<double?>(temperatureC),
      'apparentTemperatureC': serializer.toJson<double?>(apparentTemperatureC),
      'precipitationMm': serializer.toJson<double?>(precipitationMm),
      'precipitationProbability':
          serializer.toJson<double?>(precipitationProbability),
      'windspeedKmh': serializer.toJson<double?>(windspeedKmh),
      'winddirectionDeg': serializer.toJson<double?>(winddirectionDeg),
    };
  }

  HourlyForecastEntry copyWith(
          {int? id,
          int? cacheId,
          int? time,
          Value<double?> temperatureC = const Value.absent(),
          Value<double?> apparentTemperatureC = const Value.absent(),
          Value<double?> precipitationMm = const Value.absent(),
          Value<double?> precipitationProbability = const Value.absent(),
          Value<double?> windspeedKmh = const Value.absent(),
          Value<double?> winddirectionDeg = const Value.absent()}) =>
      HourlyForecastEntry(
        id: id ?? this.id,
        cacheId: cacheId ?? this.cacheId,
        time: time ?? this.time,
        temperatureC:
            temperatureC.present ? temperatureC.value : this.temperatureC,
        apparentTemperatureC: apparentTemperatureC.present
            ? apparentTemperatureC.value
            : this.apparentTemperatureC,
        precipitationMm: precipitationMm.present
            ? precipitationMm.value
            : this.precipitationMm,
        precipitationProbability: precipitationProbability.present
            ? precipitationProbability.value
            : this.precipitationProbability,
        windspeedKmh:
            windspeedKmh.present ? windspeedKmh.value : this.windspeedKmh,
        winddirectionDeg: winddirectionDeg.present
            ? winddirectionDeg.value
            : this.winddirectionDeg,
      );
  HourlyForecastEntry copyWithCompanion(HourlyForecastEntriesCompanion data) {
    return HourlyForecastEntry(
      id: data.id.present ? data.id.value : this.id,
      cacheId: data.cacheId.present ? data.cacheId.value : this.cacheId,
      time: data.time.present ? data.time.value : this.time,
      temperatureC: data.temperatureC.present
          ? data.temperatureC.value
          : this.temperatureC,
      apparentTemperatureC: data.apparentTemperatureC.present
          ? data.apparentTemperatureC.value
          : this.apparentTemperatureC,
      precipitationMm: data.precipitationMm.present
          ? data.precipitationMm.value
          : this.precipitationMm,
      precipitationProbability: data.precipitationProbability.present
          ? data.precipitationProbability.value
          : this.precipitationProbability,
      windspeedKmh: data.windspeedKmh.present
          ? data.windspeedKmh.value
          : this.windspeedKmh,
      winddirectionDeg: data.winddirectionDeg.present
          ? data.winddirectionDeg.value
          : this.winddirectionDeg,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HourlyForecastEntry(')
          ..write('id: $id, ')
          ..write('cacheId: $cacheId, ')
          ..write('time: $time, ')
          ..write('temperatureC: $temperatureC, ')
          ..write('apparentTemperatureC: $apparentTemperatureC, ')
          ..write('precipitationMm: $precipitationMm, ')
          ..write('precipitationProbability: $precipitationProbability, ')
          ..write('windspeedKmh: $windspeedKmh, ')
          ..write('winddirectionDeg: $winddirectionDeg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      cacheId,
      time,
      temperatureC,
      apparentTemperatureC,
      precipitationMm,
      precipitationProbability,
      windspeedKmh,
      winddirectionDeg);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HourlyForecastEntry &&
          other.id == this.id &&
          other.cacheId == this.cacheId &&
          other.time == this.time &&
          other.temperatureC == this.temperatureC &&
          other.apparentTemperatureC == this.apparentTemperatureC &&
          other.precipitationMm == this.precipitationMm &&
          other.precipitationProbability == this.precipitationProbability &&
          other.windspeedKmh == this.windspeedKmh &&
          other.winddirectionDeg == this.winddirectionDeg);
}

class HourlyForecastEntriesCompanion
    extends UpdateCompanion<HourlyForecastEntry> {
  final Value<int> id;
  final Value<int> cacheId;
  final Value<int> time;
  final Value<double?> temperatureC;
  final Value<double?> apparentTemperatureC;
  final Value<double?> precipitationMm;
  final Value<double?> precipitationProbability;
  final Value<double?> windspeedKmh;
  final Value<double?> winddirectionDeg;
  const HourlyForecastEntriesCompanion({
    this.id = const Value.absent(),
    this.cacheId = const Value.absent(),
    this.time = const Value.absent(),
    this.temperatureC = const Value.absent(),
    this.apparentTemperatureC = const Value.absent(),
    this.precipitationMm = const Value.absent(),
    this.precipitationProbability = const Value.absent(),
    this.windspeedKmh = const Value.absent(),
    this.winddirectionDeg = const Value.absent(),
  });
  HourlyForecastEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int cacheId,
    required int time,
    this.temperatureC = const Value.absent(),
    this.apparentTemperatureC = const Value.absent(),
    this.precipitationMm = const Value.absent(),
    this.precipitationProbability = const Value.absent(),
    this.windspeedKmh = const Value.absent(),
    this.winddirectionDeg = const Value.absent(),
  })  : cacheId = Value(cacheId),
        time = Value(time);
  static Insertable<HourlyForecastEntry> custom({
    Expression<int>? id,
    Expression<int>? cacheId,
    Expression<int>? time,
    Expression<double>? temperatureC,
    Expression<double>? apparentTemperatureC,
    Expression<double>? precipitationMm,
    Expression<double>? precipitationProbability,
    Expression<double>? windspeedKmh,
    Expression<double>? winddirectionDeg,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cacheId != null) 'cache_id': cacheId,
      if (time != null) 'time': time,
      if (temperatureC != null) 'temperature_c': temperatureC,
      if (apparentTemperatureC != null)
        'apparent_temperature_c': apparentTemperatureC,
      if (precipitationMm != null) 'precipitation_mm': precipitationMm,
      if (precipitationProbability != null)
        'precipitation_probability': precipitationProbability,
      if (windspeedKmh != null) 'windspeed_kmh': windspeedKmh,
      if (winddirectionDeg != null) 'winddirection_deg': winddirectionDeg,
    });
  }

  HourlyForecastEntriesCompanion copyWith(
      {Value<int>? id,
      Value<int>? cacheId,
      Value<int>? time,
      Value<double?>? temperatureC,
      Value<double?>? apparentTemperatureC,
      Value<double?>? precipitationMm,
      Value<double?>? precipitationProbability,
      Value<double?>? windspeedKmh,
      Value<double?>? winddirectionDeg}) {
    return HourlyForecastEntriesCompanion(
      id: id ?? this.id,
      cacheId: cacheId ?? this.cacheId,
      time: time ?? this.time,
      temperatureC: temperatureC ?? this.temperatureC,
      apparentTemperatureC: apparentTemperatureC ?? this.apparentTemperatureC,
      precipitationMm: precipitationMm ?? this.precipitationMm,
      precipitationProbability:
          precipitationProbability ?? this.precipitationProbability,
      windspeedKmh: windspeedKmh ?? this.windspeedKmh,
      winddirectionDeg: winddirectionDeg ?? this.winddirectionDeg,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cacheId.present) {
      map['cache_id'] = Variable<int>(cacheId.value);
    }
    if (time.present) {
      map['time'] = Variable<int>(time.value);
    }
    if (temperatureC.present) {
      map['temperature_c'] = Variable<double>(temperatureC.value);
    }
    if (apparentTemperatureC.present) {
      map['apparent_temperature_c'] =
          Variable<double>(apparentTemperatureC.value);
    }
    if (precipitationMm.present) {
      map['precipitation_mm'] = Variable<double>(precipitationMm.value);
    }
    if (precipitationProbability.present) {
      map['precipitation_probability'] =
          Variable<double>(precipitationProbability.value);
    }
    if (windspeedKmh.present) {
      map['windspeed_kmh'] = Variable<double>(windspeedKmh.value);
    }
    if (winddirectionDeg.present) {
      map['winddirection_deg'] = Variable<double>(winddirectionDeg.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HourlyForecastEntriesCompanion(')
          ..write('id: $id, ')
          ..write('cacheId: $cacheId, ')
          ..write('time: $time, ')
          ..write('temperatureC: $temperatureC, ')
          ..write('apparentTemperatureC: $apparentTemperatureC, ')
          ..write('precipitationMm: $precipitationMm, ')
          ..write('precipitationProbability: $precipitationProbability, ')
          ..write('windspeedKmh: $windspeedKmh, ')
          ..write('winddirectionDeg: $winddirectionDeg')
          ..write(')'))
        .toString();
  }
}

class $AvailabilityGridEntriesTable extends AvailabilityGridEntries
    with TableInfo<$AvailabilityGridEntriesTable, AvailabilityGridEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AvailabilityGridEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dayOfWeekMeta =
      const VerificationMeta('dayOfWeek');
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
      'day_of_week', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _hourMeta = const VerificationMeta('hour');
  @override
  late final GeneratedColumn<int> hour = GeneratedColumn<int>(
      'hour', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
      'state', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, dayOfWeek, hour, state];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'availability_grid_entries';
  @override
  VerificationContext validateIntegrity(
      Insertable<AvailabilityGridEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
          _dayOfWeekMeta,
          dayOfWeek.isAcceptableOrUnknown(
              data['day_of_week']!, _dayOfWeekMeta));
    } else if (isInserting) {
      context.missing(_dayOfWeekMeta);
    }
    if (data.containsKey('hour')) {
      context.handle(
          _hourMeta, hour.isAcceptableOrUnknown(data['hour']!, _hourMeta));
    } else if (isInserting) {
      context.missing(_hourMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
          _stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AvailabilityGridEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AvailabilityGridEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      dayOfWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day_of_week'])!,
      hour: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hour'])!,
      state: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}state'])!,
    );
  }

  @override
  $AvailabilityGridEntriesTable createAlias(String alias) {
    return $AvailabilityGridEntriesTable(attachedDatabase, alias);
  }
}

class AvailabilityGridEntry extends DataClass
    implements Insertable<AvailabilityGridEntry> {
  final int id;
  final int dayOfWeek;
  final int hour;
  final String state;
  const AvailabilityGridEntry(
      {required this.id,
      required this.dayOfWeek,
      required this.hour,
      required this.state});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day_of_week'] = Variable<int>(dayOfWeek);
    map['hour'] = Variable<int>(hour);
    map['state'] = Variable<String>(state);
    return map;
  }

  AvailabilityGridEntriesCompanion toCompanion(bool nullToAbsent) {
    return AvailabilityGridEntriesCompanion(
      id: Value(id),
      dayOfWeek: Value(dayOfWeek),
      hour: Value(hour),
      state: Value(state),
    );
  }

  factory AvailabilityGridEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AvailabilityGridEntry(
      id: serializer.fromJson<int>(json['id']),
      dayOfWeek: serializer.fromJson<int>(json['dayOfWeek']),
      hour: serializer.fromJson<int>(json['hour']),
      state: serializer.fromJson<String>(json['state']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayOfWeek': serializer.toJson<int>(dayOfWeek),
      'hour': serializer.toJson<int>(hour),
      'state': serializer.toJson<String>(state),
    };
  }

  AvailabilityGridEntry copyWith(
          {int? id, int? dayOfWeek, int? hour, String? state}) =>
      AvailabilityGridEntry(
        id: id ?? this.id,
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        hour: hour ?? this.hour,
        state: state ?? this.state,
      );
  AvailabilityGridEntry copyWithCompanion(
      AvailabilityGridEntriesCompanion data) {
    return AvailabilityGridEntry(
      id: data.id.present ? data.id.value : this.id,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      hour: data.hour.present ? data.hour.value : this.hour,
      state: data.state.present ? data.state.value : this.state,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AvailabilityGridEntry(')
          ..write('id: $id, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('hour: $hour, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dayOfWeek, hour, state);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AvailabilityGridEntry &&
          other.id == this.id &&
          other.dayOfWeek == this.dayOfWeek &&
          other.hour == this.hour &&
          other.state == this.state);
}

class AvailabilityGridEntriesCompanion
    extends UpdateCompanion<AvailabilityGridEntry> {
  final Value<int> id;
  final Value<int> dayOfWeek;
  final Value<int> hour;
  final Value<String> state;
  const AvailabilityGridEntriesCompanion({
    this.id = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.hour = const Value.absent(),
    this.state = const Value.absent(),
  });
  AvailabilityGridEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int dayOfWeek,
    required int hour,
    required String state,
  })  : dayOfWeek = Value(dayOfWeek),
        hour = Value(hour),
        state = Value(state);
  static Insertable<AvailabilityGridEntry> custom({
    Expression<int>? id,
    Expression<int>? dayOfWeek,
    Expression<int>? hour,
    Expression<String>? state,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (hour != null) 'hour': hour,
      if (state != null) 'state': state,
    });
  }

  AvailabilityGridEntriesCompanion copyWith(
      {Value<int>? id,
      Value<int>? dayOfWeek,
      Value<int>? hour,
      Value<String>? state}) {
    return AvailabilityGridEntriesCompanion(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      hour: hour ?? this.hour,
      state: state ?? this.state,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(dayOfWeek.value);
    }
    if (hour.present) {
      map['hour'] = Variable<int>(hour.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AvailabilityGridEntriesCompanion(')
          ..write('id: $id, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('hour: $hour, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ForecastCacheEntriesTable forecastCacheEntries =
      $ForecastCacheEntriesTable(this);
  late final $HourlyForecastEntriesTable hourlyForecastEntries =
      $HourlyForecastEntriesTable(this);
  late final $AvailabilityGridEntriesTable availabilityGridEntries =
      $AvailabilityGridEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [forecastCacheEntries, hourlyForecastEntries, availabilityGridEntries];
}

typedef $$ForecastCacheEntriesTableCreateCompanionBuilder
    = ForecastCacheEntriesCompanion Function({
  Value<int> id,
  required double lat,
  required double lon,
  required DateTime fetchedAt,
});
typedef $$ForecastCacheEntriesTableUpdateCompanionBuilder
    = ForecastCacheEntriesCompanion Function({
  Value<int> id,
  Value<double> lat,
  Value<double> lon,
  Value<DateTime> fetchedAt,
});

final class $$ForecastCacheEntriesTableReferences extends BaseReferences<
    _$AppDatabase, $ForecastCacheEntriesTable, ForecastCacheEntry> {
  $$ForecastCacheEntriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HourlyForecastEntriesTable,
      List<HourlyForecastEntry>> _hourlyForecastEntriesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.hourlyForecastEntries,
          aliasName: $_aliasNameGenerator(
              db.forecastCacheEntries.id, db.hourlyForecastEntries.cacheId));

  $$HourlyForecastEntriesTableProcessedTableManager
      get hourlyForecastEntriesRefs {
    final manager = $$HourlyForecastEntriesTableTableManager(
            $_db, $_db.hourlyForecastEntries)
        .filter((f) => f.cacheId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_hourlyForecastEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ForecastCacheEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ForecastCacheEntriesTable> {
  $$ForecastCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> hourlyForecastEntriesRefs(
      Expression<bool> Function($$HourlyForecastEntriesTableFilterComposer f)
          f) {
    final $$HourlyForecastEntriesTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.hourlyForecastEntries,
            getReferencedColumn: (t) => t.cacheId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$HourlyForecastEntriesTableFilterComposer(
                  $db: $db,
                  $table: $db.hourlyForecastEntries,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ForecastCacheEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ForecastCacheEntriesTable> {
  $$ForecastCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnOrderings(column));
}

class $$ForecastCacheEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ForecastCacheEntriesTable> {
  $$ForecastCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  Expression<T> hourlyForecastEntriesRefs<T extends Object>(
      Expression<T> Function($$HourlyForecastEntriesTableAnnotationComposer a)
          f) {
    final $$HourlyForecastEntriesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.hourlyForecastEntries,
            getReferencedColumn: (t) => t.cacheId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$HourlyForecastEntriesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.hourlyForecastEntries,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ForecastCacheEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ForecastCacheEntriesTable,
    ForecastCacheEntry,
    $$ForecastCacheEntriesTableFilterComposer,
    $$ForecastCacheEntriesTableOrderingComposer,
    $$ForecastCacheEntriesTableAnnotationComposer,
    $$ForecastCacheEntriesTableCreateCompanionBuilder,
    $$ForecastCacheEntriesTableUpdateCompanionBuilder,
    (ForecastCacheEntry, $$ForecastCacheEntriesTableReferences),
    ForecastCacheEntry,
    PrefetchHooks Function({bool hourlyForecastEntriesRefs})> {
  $$ForecastCacheEntriesTableTableManager(
      _$AppDatabase db, $ForecastCacheEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ForecastCacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ForecastCacheEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ForecastCacheEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<double> lat = const Value.absent(),
            Value<double> lon = const Value.absent(),
            Value<DateTime> fetchedAt = const Value.absent(),
          }) =>
              ForecastCacheEntriesCompanion(
            id: id,
            lat: lat,
            lon: lon,
            fetchedAt: fetchedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required double lat,
            required double lon,
            required DateTime fetchedAt,
          }) =>
              ForecastCacheEntriesCompanion.insert(
            id: id,
            lat: lat,
            lon: lon,
            fetchedAt: fetchedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ForecastCacheEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({hourlyForecastEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (hourlyForecastEntriesRefs) db.hourlyForecastEntries
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (hourlyForecastEntriesRefs)
                    await $_getPrefetchedData<ForecastCacheEntry,
                            $ForecastCacheEntriesTable, HourlyForecastEntry>(
                        currentTable: table,
                        referencedTable: $$ForecastCacheEntriesTableReferences
                            ._hourlyForecastEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ForecastCacheEntriesTableReferences(db, table, p0)
                                .hourlyForecastEntriesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.cacheId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ForecastCacheEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ForecastCacheEntriesTable,
        ForecastCacheEntry,
        $$ForecastCacheEntriesTableFilterComposer,
        $$ForecastCacheEntriesTableOrderingComposer,
        $$ForecastCacheEntriesTableAnnotationComposer,
        $$ForecastCacheEntriesTableCreateCompanionBuilder,
        $$ForecastCacheEntriesTableUpdateCompanionBuilder,
        (ForecastCacheEntry, $$ForecastCacheEntriesTableReferences),
        ForecastCacheEntry,
        PrefetchHooks Function({bool hourlyForecastEntriesRefs})>;
typedef $$HourlyForecastEntriesTableCreateCompanionBuilder
    = HourlyForecastEntriesCompanion Function({
  Value<int> id,
  required int cacheId,
  required int time,
  Value<double?> temperatureC,
  Value<double?> apparentTemperatureC,
  Value<double?> precipitationMm,
  Value<double?> precipitationProbability,
  Value<double?> windspeedKmh,
  Value<double?> winddirectionDeg,
});
typedef $$HourlyForecastEntriesTableUpdateCompanionBuilder
    = HourlyForecastEntriesCompanion Function({
  Value<int> id,
  Value<int> cacheId,
  Value<int> time,
  Value<double?> temperatureC,
  Value<double?> apparentTemperatureC,
  Value<double?> precipitationMm,
  Value<double?> precipitationProbability,
  Value<double?> windspeedKmh,
  Value<double?> winddirectionDeg,
});

final class $$HourlyForecastEntriesTableReferences extends BaseReferences<
    _$AppDatabase, $HourlyForecastEntriesTable, HourlyForecastEntry> {
  $$HourlyForecastEntriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ForecastCacheEntriesTable _cacheIdTable(_$AppDatabase db) =>
      db.forecastCacheEntries.createAlias($_aliasNameGenerator(
          db.hourlyForecastEntries.cacheId, db.forecastCacheEntries.id));

  $$ForecastCacheEntriesTableProcessedTableManager get cacheId {
    final $_column = $_itemColumn<int>('cache_id')!;

    final manager =
        $$ForecastCacheEntriesTableTableManager($_db, $_db.forecastCacheEntries)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cacheIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$HourlyForecastEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $HourlyForecastEntriesTable> {
  $$HourlyForecastEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get time => $composableBuilder(
      column: $table.time, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get temperatureC => $composableBuilder(
      column: $table.temperatureC, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get apparentTemperatureC => $composableBuilder(
      column: $table.apparentTemperatureC,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get precipitationMm => $composableBuilder(
      column: $table.precipitationMm,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get precipitationProbability => $composableBuilder(
      column: $table.precipitationProbability,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get windspeedKmh => $composableBuilder(
      column: $table.windspeedKmh, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get winddirectionDeg => $composableBuilder(
      column: $table.winddirectionDeg,
      builder: (column) => ColumnFilters(column));

  $$ForecastCacheEntriesTableFilterComposer get cacheId {
    final $$ForecastCacheEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cacheId,
        referencedTable: $db.forecastCacheEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ForecastCacheEntriesTableFilterComposer(
              $db: $db,
              $table: $db.forecastCacheEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HourlyForecastEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $HourlyForecastEntriesTable> {
  $$HourlyForecastEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get time => $composableBuilder(
      column: $table.time, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get temperatureC => $composableBuilder(
      column: $table.temperatureC,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get apparentTemperatureC => $composableBuilder(
      column: $table.apparentTemperatureC,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get precipitationMm => $composableBuilder(
      column: $table.precipitationMm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get precipitationProbability => $composableBuilder(
      column: $table.precipitationProbability,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get windspeedKmh => $composableBuilder(
      column: $table.windspeedKmh,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get winddirectionDeg => $composableBuilder(
      column: $table.winddirectionDeg,
      builder: (column) => ColumnOrderings(column));

  $$ForecastCacheEntriesTableOrderingComposer get cacheId {
    final $$ForecastCacheEntriesTableOrderingComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.cacheId,
            referencedTable: $db.forecastCacheEntries,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ForecastCacheEntriesTableOrderingComposer(
                  $db: $db,
                  $table: $db.forecastCacheEntries,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$HourlyForecastEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HourlyForecastEntriesTable> {
  $$HourlyForecastEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<double> get temperatureC => $composableBuilder(
      column: $table.temperatureC, builder: (column) => column);

  GeneratedColumn<double> get apparentTemperatureC => $composableBuilder(
      column: $table.apparentTemperatureC, builder: (column) => column);

  GeneratedColumn<double> get precipitationMm => $composableBuilder(
      column: $table.precipitationMm, builder: (column) => column);

  GeneratedColumn<double> get precipitationProbability => $composableBuilder(
      column: $table.precipitationProbability, builder: (column) => column);

  GeneratedColumn<double> get windspeedKmh => $composableBuilder(
      column: $table.windspeedKmh, builder: (column) => column);

  GeneratedColumn<double> get winddirectionDeg => $composableBuilder(
      column: $table.winddirectionDeg, builder: (column) => column);

  $$ForecastCacheEntriesTableAnnotationComposer get cacheId {
    final $$ForecastCacheEntriesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.cacheId,
            referencedTable: $db.forecastCacheEntries,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ForecastCacheEntriesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.forecastCacheEntries,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$HourlyForecastEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HourlyForecastEntriesTable,
    HourlyForecastEntry,
    $$HourlyForecastEntriesTableFilterComposer,
    $$HourlyForecastEntriesTableOrderingComposer,
    $$HourlyForecastEntriesTableAnnotationComposer,
    $$HourlyForecastEntriesTableCreateCompanionBuilder,
    $$HourlyForecastEntriesTableUpdateCompanionBuilder,
    (HourlyForecastEntry, $$HourlyForecastEntriesTableReferences),
    HourlyForecastEntry,
    PrefetchHooks Function({bool cacheId})> {
  $$HourlyForecastEntriesTableTableManager(
      _$AppDatabase db, $HourlyForecastEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HourlyForecastEntriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$HourlyForecastEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HourlyForecastEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> cacheId = const Value.absent(),
            Value<int> time = const Value.absent(),
            Value<double?> temperatureC = const Value.absent(),
            Value<double?> apparentTemperatureC = const Value.absent(),
            Value<double?> precipitationMm = const Value.absent(),
            Value<double?> precipitationProbability = const Value.absent(),
            Value<double?> windspeedKmh = const Value.absent(),
            Value<double?> winddirectionDeg = const Value.absent(),
          }) =>
              HourlyForecastEntriesCompanion(
            id: id,
            cacheId: cacheId,
            time: time,
            temperatureC: temperatureC,
            apparentTemperatureC: apparentTemperatureC,
            precipitationMm: precipitationMm,
            precipitationProbability: precipitationProbability,
            windspeedKmh: windspeedKmh,
            winddirectionDeg: winddirectionDeg,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int cacheId,
            required int time,
            Value<double?> temperatureC = const Value.absent(),
            Value<double?> apparentTemperatureC = const Value.absent(),
            Value<double?> precipitationMm = const Value.absent(),
            Value<double?> precipitationProbability = const Value.absent(),
            Value<double?> windspeedKmh = const Value.absent(),
            Value<double?> winddirectionDeg = const Value.absent(),
          }) =>
              HourlyForecastEntriesCompanion.insert(
            id: id,
            cacheId: cacheId,
            time: time,
            temperatureC: temperatureC,
            apparentTemperatureC: apparentTemperatureC,
            precipitationMm: precipitationMm,
            precipitationProbability: precipitationProbability,
            windspeedKmh: windspeedKmh,
            winddirectionDeg: winddirectionDeg,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$HourlyForecastEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({cacheId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (cacheId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.cacheId,
                    referencedTable: $$HourlyForecastEntriesTableReferences
                        ._cacheIdTable(db),
                    referencedColumn: $$HourlyForecastEntriesTableReferences
                        ._cacheIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$HourlyForecastEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $HourlyForecastEntriesTable,
        HourlyForecastEntry,
        $$HourlyForecastEntriesTableFilterComposer,
        $$HourlyForecastEntriesTableOrderingComposer,
        $$HourlyForecastEntriesTableAnnotationComposer,
        $$HourlyForecastEntriesTableCreateCompanionBuilder,
        $$HourlyForecastEntriesTableUpdateCompanionBuilder,
        (HourlyForecastEntry, $$HourlyForecastEntriesTableReferences),
        HourlyForecastEntry,
        PrefetchHooks Function({bool cacheId})>;
typedef $$AvailabilityGridEntriesTableCreateCompanionBuilder
    = AvailabilityGridEntriesCompanion Function({
  Value<int> id,
  required int dayOfWeek,
  required int hour,
  required String state,
});
typedef $$AvailabilityGridEntriesTableUpdateCompanionBuilder
    = AvailabilityGridEntriesCompanion Function({
  Value<int> id,
  Value<int> dayOfWeek,
  Value<int> hour,
  Value<String> state,
});

class $$AvailabilityGridEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $AvailabilityGridEntriesTable> {
  $$AvailabilityGridEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dayOfWeek => $composableBuilder(
      column: $table.dayOfWeek, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hour => $composableBuilder(
      column: $table.hour, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnFilters(column));
}

class $$AvailabilityGridEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AvailabilityGridEntriesTable> {
  $$AvailabilityGridEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
      column: $table.dayOfWeek, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hour => $composableBuilder(
      column: $table.hour, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state => $composableBuilder(
      column: $table.state, builder: (column) => ColumnOrderings(column));
}

class $$AvailabilityGridEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AvailabilityGridEntriesTable> {
  $$AvailabilityGridEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<int> get hour =>
      $composableBuilder(column: $table.hour, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);
}

class $$AvailabilityGridEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AvailabilityGridEntriesTable,
    AvailabilityGridEntry,
    $$AvailabilityGridEntriesTableFilterComposer,
    $$AvailabilityGridEntriesTableOrderingComposer,
    $$AvailabilityGridEntriesTableAnnotationComposer,
    $$AvailabilityGridEntriesTableCreateCompanionBuilder,
    $$AvailabilityGridEntriesTableUpdateCompanionBuilder,
    (
      AvailabilityGridEntry,
      BaseReferences<_$AppDatabase, $AvailabilityGridEntriesTable,
          AvailabilityGridEntry>
    ),
    AvailabilityGridEntry,
    PrefetchHooks Function()> {
  $$AvailabilityGridEntriesTableTableManager(
      _$AppDatabase db, $AvailabilityGridEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AvailabilityGridEntriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$AvailabilityGridEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AvailabilityGridEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> dayOfWeek = const Value.absent(),
            Value<int> hour = const Value.absent(),
            Value<String> state = const Value.absent(),
          }) =>
              AvailabilityGridEntriesCompanion(
            id: id,
            dayOfWeek: dayOfWeek,
            hour: hour,
            state: state,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int dayOfWeek,
            required int hour,
            required String state,
          }) =>
              AvailabilityGridEntriesCompanion.insert(
            id: id,
            dayOfWeek: dayOfWeek,
            hour: hour,
            state: state,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AvailabilityGridEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $AvailabilityGridEntriesTable,
        AvailabilityGridEntry,
        $$AvailabilityGridEntriesTableFilterComposer,
        $$AvailabilityGridEntriesTableOrderingComposer,
        $$AvailabilityGridEntriesTableAnnotationComposer,
        $$AvailabilityGridEntriesTableCreateCompanionBuilder,
        $$AvailabilityGridEntriesTableUpdateCompanionBuilder,
        (
          AvailabilityGridEntry,
          BaseReferences<_$AppDatabase, $AvailabilityGridEntriesTable,
              AvailabilityGridEntry>
        ),
        AvailabilityGridEntry,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ForecastCacheEntriesTableTableManager get forecastCacheEntries =>
      $$ForecastCacheEntriesTableTableManager(_db, _db.forecastCacheEntries);
  $$HourlyForecastEntriesTableTableManager get hourlyForecastEntries =>
      $$HourlyForecastEntriesTableTableManager(_db, _db.hourlyForecastEntries);
  $$AvailabilityGridEntriesTableTableManager get availabilityGridEntries =>
      $$AvailabilityGridEntriesTableTableManager(
          _db, _db.availabilityGridEntries);
}
