// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ride_slot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RideSlot {
  /// Inclusive start of slot.
  DateTime get start;

  /// Exclusive end of slot — [start, end) convention.
  DateTime get end;
  double get overallScore;
  RideTier get tier;
  List<HourlyScore> get hours;

  /// Create a copy of RideSlot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RideSlotCopyWith<RideSlot> get copyWith =>
      _$RideSlotCopyWithImpl<RideSlot>(this as RideSlot, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RideSlot &&
            (identical(other.start, start) || other.start == start) &&
            (identical(other.end, end) || other.end == end) &&
            (identical(other.overallScore, overallScore) ||
                other.overallScore == overallScore) &&
            (identical(other.tier, tier) || other.tier == tier) &&
            const DeepCollectionEquality().equals(other.hours, hours));
  }

  @override
  int get hashCode => Object.hash(runtimeType, start, end, overallScore, tier,
      const DeepCollectionEquality().hash(hours));

  @override
  String toString() {
    return 'RideSlot(start: $start, end: $end, overallScore: $overallScore, tier: $tier, hours: $hours)';
  }
}

/// @nodoc
abstract mixin class $RideSlotCopyWith<$Res> {
  factory $RideSlotCopyWith(RideSlot value, $Res Function(RideSlot) _then) =
      _$RideSlotCopyWithImpl;
  @useResult
  $Res call(
      {DateTime start,
      DateTime end,
      double overallScore,
      RideTier tier,
      List<HourlyScore> hours});
}

/// @nodoc
class _$RideSlotCopyWithImpl<$Res> implements $RideSlotCopyWith<$Res> {
  _$RideSlotCopyWithImpl(this._self, this._then);

  final RideSlot _self;
  final $Res Function(RideSlot) _then;

  /// Create a copy of RideSlot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? start = null,
    Object? end = null,
    Object? overallScore = null,
    Object? tier = null,
    Object? hours = null,
  }) {
    return _then(_self.copyWith(
      start: null == start
          ? _self.start
          : start // ignore: cast_nullable_to_non_nullable
              as DateTime,
      end: null == end
          ? _self.end
          : end // ignore: cast_nullable_to_non_nullable
              as DateTime,
      overallScore: null == overallScore
          ? _self.overallScore
          : overallScore // ignore: cast_nullable_to_non_nullable
              as double,
      tier: null == tier
          ? _self.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as RideTier,
      hours: null == hours
          ? _self.hours
          : hours // ignore: cast_nullable_to_non_nullable
              as List<HourlyScore>,
    ));
  }
}

/// Adds pattern-matching-related methods to [RideSlot].
extension RideSlotPatterns on RideSlot {
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
    TResult Function(_RideSlot value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RideSlot() when $default != null:
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
    TResult Function(_RideSlot value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RideSlot():
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
    TResult? Function(_RideSlot value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RideSlot() when $default != null:
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
    TResult Function(DateTime start, DateTime end, double overallScore,
            RideTier tier, List<HourlyScore> hours)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RideSlot() when $default != null:
        return $default(_that.start, _that.end, _that.overallScore, _that.tier,
            _that.hours);
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
    TResult Function(DateTime start, DateTime end, double overallScore,
            RideTier tier, List<HourlyScore> hours)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RideSlot():
        return $default(_that.start, _that.end, _that.overallScore, _that.tier,
            _that.hours);
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
    TResult? Function(DateTime start, DateTime end, double overallScore,
            RideTier tier, List<HourlyScore> hours)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RideSlot() when $default != null:
        return $default(_that.start, _that.end, _that.overallScore, _that.tier,
            _that.hours);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _RideSlot implements RideSlot {
  const _RideSlot(
      {required this.start,
      required this.end,
      required this.overallScore,
      required this.tier,
      required final List<HourlyScore> hours})
      : _hours = hours;

  /// Inclusive start of slot.
  @override
  final DateTime start;

  /// Exclusive end of slot — [start, end) convention.
  @override
  final DateTime end;
  @override
  final double overallScore;
  @override
  final RideTier tier;
  final List<HourlyScore> _hours;
  @override
  List<HourlyScore> get hours {
    if (_hours is EqualUnmodifiableListView) return _hours;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hours);
  }

  /// Create a copy of RideSlot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RideSlotCopyWith<_RideSlot> get copyWith =>
      __$RideSlotCopyWithImpl<_RideSlot>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RideSlot &&
            (identical(other.start, start) || other.start == start) &&
            (identical(other.end, end) || other.end == end) &&
            (identical(other.overallScore, overallScore) ||
                other.overallScore == overallScore) &&
            (identical(other.tier, tier) || other.tier == tier) &&
            const DeepCollectionEquality().equals(other._hours, _hours));
  }

  @override
  int get hashCode => Object.hash(runtimeType, start, end, overallScore, tier,
      const DeepCollectionEquality().hash(_hours));

  @override
  String toString() {
    return 'RideSlot(start: $start, end: $end, overallScore: $overallScore, tier: $tier, hours: $hours)';
  }
}

/// @nodoc
abstract mixin class _$RideSlotCopyWith<$Res>
    implements $RideSlotCopyWith<$Res> {
  factory _$RideSlotCopyWith(_RideSlot value, $Res Function(_RideSlot) _then) =
      __$RideSlotCopyWithImpl;
  @override
  @useResult
  $Res call(
      {DateTime start,
      DateTime end,
      double overallScore,
      RideTier tier,
      List<HourlyScore> hours});
}

/// @nodoc
class __$RideSlotCopyWithImpl<$Res> implements _$RideSlotCopyWith<$Res> {
  __$RideSlotCopyWithImpl(this._self, this._then);

  final _RideSlot _self;
  final $Res Function(_RideSlot) _then;

  /// Create a copy of RideSlot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? start = null,
    Object? end = null,
    Object? overallScore = null,
    Object? tier = null,
    Object? hours = null,
  }) {
    return _then(_RideSlot(
      start: null == start
          ? _self.start
          : start // ignore: cast_nullable_to_non_nullable
              as DateTime,
      end: null == end
          ? _self.end
          : end // ignore: cast_nullable_to_non_nullable
              as DateTime,
      overallScore: null == overallScore
          ? _self.overallScore
          : overallScore // ignore: cast_nullable_to_non_nullable
              as double,
      tier: null == tier
          ? _self.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as RideTier,
      hours: null == hours
          ? _self._hours
          : hours // ignore: cast_nullable_to_non_nullable
              as List<HourlyScore>,
    ));
  }
}

// dart format on
