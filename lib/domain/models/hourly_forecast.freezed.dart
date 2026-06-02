// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hourly_forecast.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HourlyForecast {
  @JsonKey(name: 'temperature_2m')
  double? get temperatureC;
  @JsonKey(name: 'apparent_temperature')
  double? get apparentTemperatureC;
  @JsonKey(name: 'precipitation')
  double? get precipitationMm;
  @JsonKey(name: 'precipitation_probability')
  double? get precipitationProbability;
  @JsonKey(name: 'windspeed_10m')
  double? get windspeedKmh;
  @JsonKey(name: 'winddirection_10m')
  double? get winddirectionDeg;
  DateTime get time;

  /// Create a copy of HourlyForecast
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HourlyForecastCopyWith<HourlyForecast> get copyWith =>
      _$HourlyForecastCopyWithImpl<HourlyForecast>(
          this as HourlyForecast, _$identity);

  /// Serializes this HourlyForecast to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HourlyForecast &&
            (identical(other.temperatureC, temperatureC) ||
                other.temperatureC == temperatureC) &&
            (identical(other.apparentTemperatureC, apparentTemperatureC) ||
                other.apparentTemperatureC == apparentTemperatureC) &&
            (identical(other.precipitationMm, precipitationMm) ||
                other.precipitationMm == precipitationMm) &&
            (identical(
                    other.precipitationProbability, precipitationProbability) ||
                other.precipitationProbability == precipitationProbability) &&
            (identical(other.windspeedKmh, windspeedKmh) ||
                other.windspeedKmh == windspeedKmh) &&
            (identical(other.winddirectionDeg, winddirectionDeg) ||
                other.winddirectionDeg == winddirectionDeg) &&
            (identical(other.time, time) || other.time == time));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      temperatureC,
      apparentTemperatureC,
      precipitationMm,
      precipitationProbability,
      windspeedKmh,
      winddirectionDeg,
      time);

  @override
  String toString() {
    return 'HourlyForecast(temperatureC: $temperatureC, apparentTemperatureC: $apparentTemperatureC, precipitationMm: $precipitationMm, precipitationProbability: $precipitationProbability, windspeedKmh: $windspeedKmh, winddirectionDeg: $winddirectionDeg, time: $time)';
  }
}

/// @nodoc
abstract mixin class $HourlyForecastCopyWith<$Res> {
  factory $HourlyForecastCopyWith(
          HourlyForecast value, $Res Function(HourlyForecast) _then) =
      _$HourlyForecastCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(name: 'temperature_2m') double? temperatureC,
      @JsonKey(name: 'apparent_temperature') double? apparentTemperatureC,
      @JsonKey(name: 'precipitation') double? precipitationMm,
      @JsonKey(name: 'precipitation_probability')
      double? precipitationProbability,
      @JsonKey(name: 'windspeed_10m') double? windspeedKmh,
      @JsonKey(name: 'winddirection_10m') double? winddirectionDeg,
      DateTime time});
}

/// @nodoc
class _$HourlyForecastCopyWithImpl<$Res>
    implements $HourlyForecastCopyWith<$Res> {
  _$HourlyForecastCopyWithImpl(this._self, this._then);

  final HourlyForecast _self;
  final $Res Function(HourlyForecast) _then;

  /// Create a copy of HourlyForecast
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? temperatureC = freezed,
    Object? apparentTemperatureC = freezed,
    Object? precipitationMm = freezed,
    Object? precipitationProbability = freezed,
    Object? windspeedKmh = freezed,
    Object? winddirectionDeg = freezed,
    Object? time = null,
  }) {
    return _then(_self.copyWith(
      temperatureC: freezed == temperatureC
          ? _self.temperatureC
          : temperatureC // ignore: cast_nullable_to_non_nullable
              as double?,
      apparentTemperatureC: freezed == apparentTemperatureC
          ? _self.apparentTemperatureC
          : apparentTemperatureC // ignore: cast_nullable_to_non_nullable
              as double?,
      precipitationMm: freezed == precipitationMm
          ? _self.precipitationMm
          : precipitationMm // ignore: cast_nullable_to_non_nullable
              as double?,
      precipitationProbability: freezed == precipitationProbability
          ? _self.precipitationProbability
          : precipitationProbability // ignore: cast_nullable_to_non_nullable
              as double?,
      windspeedKmh: freezed == windspeedKmh
          ? _self.windspeedKmh
          : windspeedKmh // ignore: cast_nullable_to_non_nullable
              as double?,
      winddirectionDeg: freezed == winddirectionDeg
          ? _self.winddirectionDeg
          : winddirectionDeg // ignore: cast_nullable_to_non_nullable
              as double?,
      time: null == time
          ? _self.time
          : time // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [HourlyForecast].
extension HourlyForecastPatterns on HourlyForecast {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_HourlyForecast value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HourlyForecast() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_HourlyForecast value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HourlyForecast():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_HourlyForecast value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HourlyForecast() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            @JsonKey(name: 'temperature_2m') double? temperatureC,
            @JsonKey(name: 'apparent_temperature') double? apparentTemperatureC,
            @JsonKey(name: 'precipitation') double? precipitationMm,
            @JsonKey(name: 'precipitation_probability')
            double? precipitationProbability,
            @JsonKey(name: 'windspeed_10m') double? windspeedKmh,
            @JsonKey(name: 'winddirection_10m') double? winddirectionDeg,
            DateTime time)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HourlyForecast() when $default != null:
        return $default(
            _that.temperatureC,
            _that.apparentTemperatureC,
            _that.precipitationMm,
            _that.precipitationProbability,
            _that.windspeedKmh,
            _that.winddirectionDeg,
            _that.time);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            @JsonKey(name: 'temperature_2m') double? temperatureC,
            @JsonKey(name: 'apparent_temperature') double? apparentTemperatureC,
            @JsonKey(name: 'precipitation') double? precipitationMm,
            @JsonKey(name: 'precipitation_probability')
            double? precipitationProbability,
            @JsonKey(name: 'windspeed_10m') double? windspeedKmh,
            @JsonKey(name: 'winddirection_10m') double? winddirectionDeg,
            DateTime time)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HourlyForecast():
        return $default(
            _that.temperatureC,
            _that.apparentTemperatureC,
            _that.precipitationMm,
            _that.precipitationProbability,
            _that.windspeedKmh,
            _that.winddirectionDeg,
            _that.time);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            @JsonKey(name: 'temperature_2m') double? temperatureC,
            @JsonKey(name: 'apparent_temperature') double? apparentTemperatureC,
            @JsonKey(name: 'precipitation') double? precipitationMm,
            @JsonKey(name: 'precipitation_probability')
            double? precipitationProbability,
            @JsonKey(name: 'windspeed_10m') double? windspeedKmh,
            @JsonKey(name: 'winddirection_10m') double? winddirectionDeg,
            DateTime time)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HourlyForecast() when $default != null:
        return $default(
            _that.temperatureC,
            _that.apparentTemperatureC,
            _that.precipitationMm,
            _that.precipitationProbability,
            _that.windspeedKmh,
            _that.winddirectionDeg,
            _that.time);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _HourlyForecast implements HourlyForecast {
  const _HourlyForecast(
      {@JsonKey(name: 'temperature_2m') required this.temperatureC,
      @JsonKey(name: 'apparent_temperature') required this.apparentTemperatureC,
      @JsonKey(name: 'precipitation') required this.precipitationMm,
      @JsonKey(name: 'precipitation_probability')
      required this.precipitationProbability,
      @JsonKey(name: 'windspeed_10m') required this.windspeedKmh,
      @JsonKey(name: 'winddirection_10m') required this.winddirectionDeg,
      required this.time});
  factory _HourlyForecast.fromJson(Map<String, dynamic> json) =>
      _$HourlyForecastFromJson(json);

  @override
  @JsonKey(name: 'temperature_2m')
  final double? temperatureC;
  @override
  @JsonKey(name: 'apparent_temperature')
  final double? apparentTemperatureC;
  @override
  @JsonKey(name: 'precipitation')
  final double? precipitationMm;
  @override
  @JsonKey(name: 'precipitation_probability')
  final double? precipitationProbability;
  @override
  @JsonKey(name: 'windspeed_10m')
  final double? windspeedKmh;
  @override
  @JsonKey(name: 'winddirection_10m')
  final double? winddirectionDeg;
  @override
  final DateTime time;

  /// Create a copy of HourlyForecast
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HourlyForecastCopyWith<_HourlyForecast> get copyWith =>
      __$HourlyForecastCopyWithImpl<_HourlyForecast>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$HourlyForecastToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HourlyForecast &&
            (identical(other.temperatureC, temperatureC) ||
                other.temperatureC == temperatureC) &&
            (identical(other.apparentTemperatureC, apparentTemperatureC) ||
                other.apparentTemperatureC == apparentTemperatureC) &&
            (identical(other.precipitationMm, precipitationMm) ||
                other.precipitationMm == precipitationMm) &&
            (identical(
                    other.precipitationProbability, precipitationProbability) ||
                other.precipitationProbability == precipitationProbability) &&
            (identical(other.windspeedKmh, windspeedKmh) ||
                other.windspeedKmh == windspeedKmh) &&
            (identical(other.winddirectionDeg, winddirectionDeg) ||
                other.winddirectionDeg == winddirectionDeg) &&
            (identical(other.time, time) || other.time == time));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      temperatureC,
      apparentTemperatureC,
      precipitationMm,
      precipitationProbability,
      windspeedKmh,
      winddirectionDeg,
      time);

  @override
  String toString() {
    return 'HourlyForecast(temperatureC: $temperatureC, apparentTemperatureC: $apparentTemperatureC, precipitationMm: $precipitationMm, precipitationProbability: $precipitationProbability, windspeedKmh: $windspeedKmh, winddirectionDeg: $winddirectionDeg, time: $time)';
  }
}

/// @nodoc
abstract mixin class _$HourlyForecastCopyWith<$Res>
    implements $HourlyForecastCopyWith<$Res> {
  factory _$HourlyForecastCopyWith(
          _HourlyForecast value, $Res Function(_HourlyForecast) _then) =
      __$HourlyForecastCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'temperature_2m') double? temperatureC,
      @JsonKey(name: 'apparent_temperature') double? apparentTemperatureC,
      @JsonKey(name: 'precipitation') double? precipitationMm,
      @JsonKey(name: 'precipitation_probability')
      double? precipitationProbability,
      @JsonKey(name: 'windspeed_10m') double? windspeedKmh,
      @JsonKey(name: 'winddirection_10m') double? winddirectionDeg,
      DateTime time});
}

/// @nodoc
class __$HourlyForecastCopyWithImpl<$Res>
    implements _$HourlyForecastCopyWith<$Res> {
  __$HourlyForecastCopyWithImpl(this._self, this._then);

  final _HourlyForecast _self;
  final $Res Function(_HourlyForecast) _then;

  /// Create a copy of HourlyForecast
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? temperatureC = freezed,
    Object? apparentTemperatureC = freezed,
    Object? precipitationMm = freezed,
    Object? precipitationProbability = freezed,
    Object? windspeedKmh = freezed,
    Object? winddirectionDeg = freezed,
    Object? time = null,
  }) {
    return _then(_HourlyForecast(
      temperatureC: freezed == temperatureC
          ? _self.temperatureC
          : temperatureC // ignore: cast_nullable_to_non_nullable
              as double?,
      apparentTemperatureC: freezed == apparentTemperatureC
          ? _self.apparentTemperatureC
          : apparentTemperatureC // ignore: cast_nullable_to_non_nullable
              as double?,
      precipitationMm: freezed == precipitationMm
          ? _self.precipitationMm
          : precipitationMm // ignore: cast_nullable_to_non_nullable
              as double?,
      precipitationProbability: freezed == precipitationProbability
          ? _self.precipitationProbability
          : precipitationProbability // ignore: cast_nullable_to_non_nullable
              as double?,
      windspeedKmh: freezed == windspeedKmh
          ? _self.windspeedKmh
          : windspeedKmh // ignore: cast_nullable_to_non_nullable
              as double?,
      winddirectionDeg: freezed == winddirectionDeg
          ? _self.winddirectionDeg
          : winddirectionDeg // ignore: cast_nullable_to_non_nullable
              as double?,
      time: null == time
          ? _self.time
          : time // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
