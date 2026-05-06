// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'focus_position.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FocusPosition {
  int get row;
  int get col;
  Direction get direction;

  /// Create a copy of FocusPosition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FocusPositionCopyWith<FocusPosition> get copyWith =>
      _$FocusPositionCopyWithImpl<FocusPosition>(
          this as FocusPosition, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FocusPosition &&
            (identical(other.row, row) || other.row == row) &&
            (identical(other.col, col) || other.col == col) &&
            (identical(other.direction, direction) ||
                other.direction == direction));
  }

  @override
  int get hashCode => Object.hash(runtimeType, row, col, direction);

  @override
  String toString() {
    return 'FocusPosition(row: $row, col: $col, direction: $direction)';
  }
}

/// @nodoc
abstract mixin class $FocusPositionCopyWith<$Res> {
  factory $FocusPositionCopyWith(
          FocusPosition value, $Res Function(FocusPosition) _then) =
      _$FocusPositionCopyWithImpl;
  @useResult
  $Res call({int row, int col, Direction direction});
}

/// @nodoc
class _$FocusPositionCopyWithImpl<$Res>
    implements $FocusPositionCopyWith<$Res> {
  _$FocusPositionCopyWithImpl(this._self, this._then);

  final FocusPosition _self;
  final $Res Function(FocusPosition) _then;

  /// Create a copy of FocusPosition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? row = null,
    Object? col = null,
    Object? direction = null,
  }) {
    return _then(_self.copyWith(
      row: null == row
          ? _self.row
          : row // ignore: cast_nullable_to_non_nullable
              as int,
      col: null == col
          ? _self.col
          : col // ignore: cast_nullable_to_non_nullable
              as int,
      direction: null == direction
          ? _self.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as Direction,
    ));
  }
}

/// Adds pattern-matching-related methods to [FocusPosition].
extension FocusPositionPatterns on FocusPosition {
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
    TResult Function(_FocusPosition value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FocusPosition() when $default != null:
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
    TResult Function(_FocusPosition value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FocusPosition():
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
    TResult? Function(_FocusPosition value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FocusPosition() when $default != null:
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
    TResult Function(int row, int col, Direction direction)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FocusPosition() when $default != null:
        return $default(_that.row, _that.col, _that.direction);
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
    TResult Function(int row, int col, Direction direction) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FocusPosition():
        return $default(_that.row, _that.col, _that.direction);
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
    TResult? Function(int row, int col, Direction direction)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FocusPosition() when $default != null:
        return $default(_that.row, _that.col, _that.direction);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _FocusPosition implements FocusPosition {
  const _FocusPosition(
      {required this.row, required this.col, required this.direction});

  @override
  final int row;
  @override
  final int col;
  @override
  final Direction direction;

  /// Create a copy of FocusPosition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FocusPositionCopyWith<_FocusPosition> get copyWith =>
      __$FocusPositionCopyWithImpl<_FocusPosition>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FocusPosition &&
            (identical(other.row, row) || other.row == row) &&
            (identical(other.col, col) || other.col == col) &&
            (identical(other.direction, direction) ||
                other.direction == direction));
  }

  @override
  int get hashCode => Object.hash(runtimeType, row, col, direction);

  @override
  String toString() {
    return 'FocusPosition(row: $row, col: $col, direction: $direction)';
  }
}

/// @nodoc
abstract mixin class _$FocusPositionCopyWith<$Res>
    implements $FocusPositionCopyWith<$Res> {
  factory _$FocusPositionCopyWith(
          _FocusPosition value, $Res Function(_FocusPosition) _then) =
      __$FocusPositionCopyWithImpl;
  @override
  @useResult
  $Res call({int row, int col, Direction direction});
}

/// @nodoc
class __$FocusPositionCopyWithImpl<$Res>
    implements _$FocusPositionCopyWith<$Res> {
  __$FocusPositionCopyWithImpl(this._self, this._then);

  final _FocusPosition _self;
  final $Res Function(_FocusPosition) _then;

  /// Create a copy of FocusPosition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? row = null,
    Object? col = null,
    Object? direction = null,
  }) {
    return _then(_FocusPosition(
      row: null == row
          ? _self.row
          : row // ignore: cast_nullable_to_non_nullable
              as int,
      col: null == col
          ? _self.col
          : col // ignore: cast_nullable_to_non_nullable
              as int,
      direction: null == direction
          ? _self.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as Direction,
    ));
  }
}

// dart format on
