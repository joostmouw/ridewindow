// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weather_tolerances.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WeatherTolerances {
  double get tempMinIdealC;
  double get tempMaxIdealC;
  double get windMaxIdealKmh;
  double get rainMaxIdealMm;

  /// Create a copy of WeatherTolerances
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WeatherTolerancesCopyWith<WeatherTolerances> get copyWith =>
      _$WeatherTolerancesCopyWithImpl<WeatherTolerances>(
          this as WeatherTolerances, _$identity);

  /// Serializes this WeatherTolerances to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WeatherTolerances &&
            (identical(other.tempMinIdealC, tempMinIdealC) ||
                other.tempMinIdealC == tempMinIdealC) &&
            (identical(other.tempMaxIdealC, tempMaxIdealC) ||
                other.tempMaxIdealC == tempMaxIdealC) &&
            (identical(other.windMaxIdealKmh, windMaxIdealKmh) ||
                other.windMaxIdealKmh == windMaxIdealKmh) &&
            (identical(other.rainMaxIdealMm, rainMaxIdealMm) ||
                other.rainMaxIdealMm == rainMaxIdealMm));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, tempMinIdealC, tempMaxIdealC,
      windMaxIdealKmh, rainMaxIdealMm);

  @override
  String toString() {
    return 'WeatherTolerances(tempMinIdealC: $tempMinIdealC, tempMaxIdealC: $tempMaxIdealC, windMaxIdealKmh: $windMaxIdealKmh, rainMaxIdealMm: $rainMaxIdealMm)';
  }
}

/// @nodoc
abstract mixin class $WeatherTolerancesCopyWith<$Res> {
  factory $WeatherTolerancesCopyWith(
          WeatherTolerances value, $Res Function(WeatherTolerances) _then) =
      _$WeatherTolerancesCopyWithImpl;
  @useResult
  $Res call(
      {double tempMinIdealC,
      double tempMaxIdealC,
      double windMaxIdealKmh,
      double rainMaxIdealMm});
}

/// @nodoc
class _$WeatherTolerancesCopyWithImpl<$Res>
    implements $WeatherTolerancesCopyWith<$Res> {
  _$WeatherTolerancesCopyWithImpl(this._self, this._then);

  final WeatherTolerances _self;
  final $Res Function(WeatherTolerances) _then;

  /// Create a copy of WeatherTolerances
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tempMinIdealC = null,
    Object? tempMaxIdealC = null,
    Object? windMaxIdealKmh = null,
    Object? rainMaxIdealMm = null,
  }) {
    return _then(_self.copyWith(
      tempMinIdealC: null == tempMinIdealC
          ? _self.tempMinIdealC
          : tempMinIdealC // ignore: cast_nullable_to_non_nullable
              as double,
      tempMaxIdealC: null == tempMaxIdealC
          ? _self.tempMaxIdealC
          : tempMaxIdealC // ignore: cast_nullable_to_non_nullable
              as double,
      windMaxIdealKmh: null == windMaxIdealKmh
          ? _self.windMaxIdealKmh
          : windMaxIdealKmh // ignore: cast_nullable_to_non_nullable
              as double,
      rainMaxIdealMm: null == rainMaxIdealMm
          ? _self.rainMaxIdealMm
          : rainMaxIdealMm // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// Adds pattern-matching-related methods to [WeatherTolerances].
extension WeatherTolerancesPatterns on WeatherTolerances {
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
    TResult Function(_WeatherTolerances value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WeatherTolerances() when $default != null:
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
    TResult Function(_WeatherTolerances value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WeatherTolerances():
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
    TResult? Function(_WeatherTolerances value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WeatherTolerances() when $default != null:
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
    TResult Function(double tempMinIdealC, double tempMaxIdealC,
            double windMaxIdealKmh, double rainMaxIdealMm)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WeatherTolerances() when $default != null:
        return $default(_that.tempMinIdealC, _that.tempMaxIdealC,
            _that.windMaxIdealKmh, _that.rainMaxIdealMm);
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
    TResult Function(double tempMinIdealC, double tempMaxIdealC,
            double windMaxIdealKmh, double rainMaxIdealMm)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WeatherTolerances():
        return $default(_that.tempMinIdealC, _that.tempMaxIdealC,
            _that.windMaxIdealKmh, _that.rainMaxIdealMm);
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
    TResult? Function(double tempMinIdealC, double tempMaxIdealC,
            double windMaxIdealKmh, double rainMaxIdealMm)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WeatherTolerances() when $default != null:
        return $default(_that.tempMinIdealC, _that.tempMaxIdealC,
            _that.windMaxIdealKmh, _that.rainMaxIdealMm);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _WeatherTolerances implements WeatherTolerances {
  const _WeatherTolerances(
      {this.tempMinIdealC = 12.0,
      this.tempMaxIdealC = 26.0,
      this.windMaxIdealKmh = 15.0,
      this.rainMaxIdealMm = 0.5});
  factory _WeatherTolerances.fromJson(Map<String, dynamic> json) =>
      _$WeatherTolerancesFromJson(json);

  @override
  @JsonKey()
  final double tempMinIdealC;
  @override
  @JsonKey()
  final double tempMaxIdealC;
  @override
  @JsonKey()
  final double windMaxIdealKmh;
  @override
  @JsonKey()
  final double rainMaxIdealMm;

  /// Create a copy of WeatherTolerances
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WeatherTolerancesCopyWith<_WeatherTolerances> get copyWith =>
      __$WeatherTolerancesCopyWithImpl<_WeatherTolerances>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WeatherTolerancesToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WeatherTolerances &&
            (identical(other.tempMinIdealC, tempMinIdealC) ||
                other.tempMinIdealC == tempMinIdealC) &&
            (identical(other.tempMaxIdealC, tempMaxIdealC) ||
                other.tempMaxIdealC == tempMaxIdealC) &&
            (identical(other.windMaxIdealKmh, windMaxIdealKmh) ||
                other.windMaxIdealKmh == windMaxIdealKmh) &&
            (identical(other.rainMaxIdealMm, rainMaxIdealMm) ||
                other.rainMaxIdealMm == rainMaxIdealMm));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, tempMinIdealC, tempMaxIdealC,
      windMaxIdealKmh, rainMaxIdealMm);

  @override
  String toString() {
    return 'WeatherTolerances(tempMinIdealC: $tempMinIdealC, tempMaxIdealC: $tempMaxIdealC, windMaxIdealKmh: $windMaxIdealKmh, rainMaxIdealMm: $rainMaxIdealMm)';
  }
}

/// @nodoc
abstract mixin class _$WeatherTolerancesCopyWith<$Res>
    implements $WeatherTolerancesCopyWith<$Res> {
  factory _$WeatherTolerancesCopyWith(
          _WeatherTolerances value, $Res Function(_WeatherTolerances) _then) =
      __$WeatherTolerancesCopyWithImpl;
  @override
  @useResult
  $Res call(
      {double tempMinIdealC,
      double tempMaxIdealC,
      double windMaxIdealKmh,
      double rainMaxIdealMm});
}

/// @nodoc
class __$WeatherTolerancesCopyWithImpl<$Res>
    implements _$WeatherTolerancesCopyWith<$Res> {
  __$WeatherTolerancesCopyWithImpl(this._self, this._then);

  final _WeatherTolerances _self;
  final $Res Function(_WeatherTolerances) _then;

  /// Create a copy of WeatherTolerances
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? tempMinIdealC = null,
    Object? tempMaxIdealC = null,
    Object? windMaxIdealKmh = null,
    Object? rainMaxIdealMm = null,
  }) {
    return _then(_WeatherTolerances(
      tempMinIdealC: null == tempMinIdealC
          ? _self.tempMinIdealC
          : tempMinIdealC // ignore: cast_nullable_to_non_nullable
              as double,
      tempMaxIdealC: null == tempMaxIdealC
          ? _self.tempMaxIdealC
          : tempMaxIdealC // ignore: cast_nullable_to_non_nullable
              as double,
      windMaxIdealKmh: null == windMaxIdealKmh
          ? _self.windMaxIdealKmh
          : windMaxIdealKmh // ignore: cast_nullable_to_non_nullable
              as double,
      rainMaxIdealMm: null == rainMaxIdealMm
          ? _self.rainMaxIdealMm
          : rainMaxIdealMm // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

// dart format on
