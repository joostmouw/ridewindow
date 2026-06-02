// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hourly_score.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HourlyScore {
  double get overall;
  double get temperatureScore;
  double get rainScore;
  double get windScore;
  DateTime get time;

  /// Create a copy of HourlyScore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HourlyScoreCopyWith<HourlyScore> get copyWith =>
      _$HourlyScoreCopyWithImpl<HourlyScore>(this as HourlyScore, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HourlyScore &&
            (identical(other.overall, overall) || other.overall == overall) &&
            (identical(other.temperatureScore, temperatureScore) ||
                other.temperatureScore == temperatureScore) &&
            (identical(other.rainScore, rainScore) ||
                other.rainScore == rainScore) &&
            (identical(other.windScore, windScore) ||
                other.windScore == windScore) &&
            (identical(other.time, time) || other.time == time));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, overall, temperatureScore, rainScore, windScore, time);

  @override
  String toString() {
    return 'HourlyScore(overall: $overall, temperatureScore: $temperatureScore, rainScore: $rainScore, windScore: $windScore, time: $time)';
  }
}

/// @nodoc
abstract mixin class $HourlyScoreCopyWith<$Res> {
  factory $HourlyScoreCopyWith(
          HourlyScore value, $Res Function(HourlyScore) _then) =
      _$HourlyScoreCopyWithImpl;
  @useResult
  $Res call(
      {double overall,
      double temperatureScore,
      double rainScore,
      double windScore,
      DateTime time});
}

/// @nodoc
class _$HourlyScoreCopyWithImpl<$Res> implements $HourlyScoreCopyWith<$Res> {
  _$HourlyScoreCopyWithImpl(this._self, this._then);

  final HourlyScore _self;
  final $Res Function(HourlyScore) _then;

  /// Create a copy of HourlyScore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? overall = null,
    Object? temperatureScore = null,
    Object? rainScore = null,
    Object? windScore = null,
    Object? time = null,
  }) {
    return _then(_self.copyWith(
      overall: null == overall
          ? _self.overall
          : overall // ignore: cast_nullable_to_non_nullable
              as double,
      temperatureScore: null == temperatureScore
          ? _self.temperatureScore
          : temperatureScore // ignore: cast_nullable_to_non_nullable
              as double,
      rainScore: null == rainScore
          ? _self.rainScore
          : rainScore // ignore: cast_nullable_to_non_nullable
              as double,
      windScore: null == windScore
          ? _self.windScore
          : windScore // ignore: cast_nullable_to_non_nullable
              as double,
      time: null == time
          ? _self.time
          : time // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [HourlyScore].
extension HourlyScorePatterns on HourlyScore {
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
    TResult Function(_HourlyScore value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HourlyScore() when $default != null:
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
    TResult Function(_HourlyScore value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HourlyScore():
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
    TResult? Function(_HourlyScore value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HourlyScore() when $default != null:
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
    TResult Function(double overall, double temperatureScore, double rainScore,
            double windScore, DateTime time)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HourlyScore() when $default != null:
        return $default(_that.overall, _that.temperatureScore, _that.rainScore,
            _that.windScore, _that.time);
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
    TResult Function(double overall, double temperatureScore, double rainScore,
            double windScore, DateTime time)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HourlyScore():
        return $default(_that.overall, _that.temperatureScore, _that.rainScore,
            _that.windScore, _that.time);
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
    TResult? Function(double overall, double temperatureScore, double rainScore,
            double windScore, DateTime time)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HourlyScore() when $default != null:
        return $default(_that.overall, _that.temperatureScore, _that.rainScore,
            _that.windScore, _that.time);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _HourlyScore implements HourlyScore {
  const _HourlyScore(
      {required this.overall,
      required this.temperatureScore,
      required this.rainScore,
      required this.windScore,
      required this.time});

  @override
  final double overall;
  @override
  final double temperatureScore;
  @override
  final double rainScore;
  @override
  final double windScore;
  @override
  final DateTime time;

  /// Create a copy of HourlyScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HourlyScoreCopyWith<_HourlyScore> get copyWith =>
      __$HourlyScoreCopyWithImpl<_HourlyScore>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HourlyScore &&
            (identical(other.overall, overall) || other.overall == overall) &&
            (identical(other.temperatureScore, temperatureScore) ||
                other.temperatureScore == temperatureScore) &&
            (identical(other.rainScore, rainScore) ||
                other.rainScore == rainScore) &&
            (identical(other.windScore, windScore) ||
                other.windScore == windScore) &&
            (identical(other.time, time) || other.time == time));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, overall, temperatureScore, rainScore, windScore, time);

  @override
  String toString() {
    return 'HourlyScore(overall: $overall, temperatureScore: $temperatureScore, rainScore: $rainScore, windScore: $windScore, time: $time)';
  }
}

/// @nodoc
abstract mixin class _$HourlyScoreCopyWith<$Res>
    implements $HourlyScoreCopyWith<$Res> {
  factory _$HourlyScoreCopyWith(
          _HourlyScore value, $Res Function(_HourlyScore) _then) =
      __$HourlyScoreCopyWithImpl;
  @override
  @useResult
  $Res call(
      {double overall,
      double temperatureScore,
      double rainScore,
      double windScore,
      DateTime time});
}

/// @nodoc
class __$HourlyScoreCopyWithImpl<$Res> implements _$HourlyScoreCopyWith<$Res> {
  __$HourlyScoreCopyWithImpl(this._self, this._then);

  final _HourlyScore _self;
  final $Res Function(_HourlyScore) _then;

  /// Create a copy of HourlyScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? overall = null,
    Object? temperatureScore = null,
    Object? rainScore = null,
    Object? windScore = null,
    Object? time = null,
  }) {
    return _then(_HourlyScore(
      overall: null == overall
          ? _self.overall
          : overall // ignore: cast_nullable_to_non_nullable
              as double,
      temperatureScore: null == temperatureScore
          ? _self.temperatureScore
          : temperatureScore // ignore: cast_nullable_to_non_nullable
              as double,
      rainScore: null == rainScore
          ? _self.rainScore
          : rainScore // ignore: cast_nullable_to_non_nullable
              as double,
      windScore: null == windScore
          ? _self.windScore
          : windScore // ignore: cast_nullable_to_non_nullable
              as double,
      time: null == time
          ? _self.time
          : time // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
