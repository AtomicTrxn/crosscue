// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clue.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Clue {
  int get number;
  Direction get direction;
  String get text;

  /// Starting row/col of the answer in the grid.
  int get startRow;
  int get startCol;

  /// Number of letters in the answer.
  int get length;

  /// Create a copy of Clue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ClueCopyWith<Clue> get copyWith =>
      _$ClueCopyWithImpl<Clue>(this as Clue, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Clue &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.direction, direction) ||
                other.direction == direction) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.startRow, startRow) ||
                other.startRow == startRow) &&
            (identical(other.startCol, startCol) ||
                other.startCol == startCol) &&
            (identical(other.length, length) || other.length == length));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, number, direction, text, startRow, startCol, length);

  @override
  String toString() {
    return 'Clue(number: $number, direction: $direction, text: $text, startRow: $startRow, startCol: $startCol, length: $length)';
  }
}

/// @nodoc
abstract mixin class $ClueCopyWith<$Res> {
  factory $ClueCopyWith(Clue value, $Res Function(Clue) _then) =
      _$ClueCopyWithImpl;
  @useResult
  $Res call(
      {int number,
      Direction direction,
      String text,
      int startRow,
      int startCol,
      int length});
}

/// @nodoc
class _$ClueCopyWithImpl<$Res> implements $ClueCopyWith<$Res> {
  _$ClueCopyWithImpl(this._self, this._then);

  final Clue _self;
  final $Res Function(Clue) _then;

  /// Create a copy of Clue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? number = null,
    Object? direction = null,
    Object? text = null,
    Object? startRow = null,
    Object? startCol = null,
    Object? length = null,
  }) {
    return _then(_self.copyWith(
      number: null == number
          ? _self.number
          : number // ignore: cast_nullable_to_non_nullable
              as int,
      direction: null == direction
          ? _self.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as Direction,
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      startRow: null == startRow
          ? _self.startRow
          : startRow // ignore: cast_nullable_to_non_nullable
              as int,
      startCol: null == startCol
          ? _self.startCol
          : startCol // ignore: cast_nullable_to_non_nullable
              as int,
      length: null == length
          ? _self.length
          : length // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [Clue].
extension CluePatterns on Clue {
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
    TResult Function(_Clue value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Clue() when $default != null:
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
    TResult Function(_Clue value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Clue():
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
    TResult? Function(_Clue value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Clue() when $default != null:
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
    TResult Function(int number, Direction direction, String text, int startRow,
            int startCol, int length)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Clue() when $default != null:
        return $default(_that.number, _that.direction, _that.text,
            _that.startRow, _that.startCol, _that.length);
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
    TResult Function(int number, Direction direction, String text, int startRow,
            int startCol, int length)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Clue():
        return $default(_that.number, _that.direction, _that.text,
            _that.startRow, _that.startCol, _that.length);
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
    TResult? Function(int number, Direction direction, String text,
            int startRow, int startCol, int length)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Clue() when $default != null:
        return $default(_that.number, _that.direction, _that.text,
            _that.startRow, _that.startCol, _that.length);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _Clue implements Clue {
  const _Clue(
      {required this.number,
      required this.direction,
      required this.text,
      required this.startRow,
      required this.startCol,
      required this.length});

  @override
  final int number;
  @override
  final Direction direction;
  @override
  final String text;

  /// Starting row/col of the answer in the grid.
  @override
  final int startRow;
  @override
  final int startCol;

  /// Number of letters in the answer.
  @override
  final int length;

  /// Create a copy of Clue
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ClueCopyWith<_Clue> get copyWith =>
      __$ClueCopyWithImpl<_Clue>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Clue &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.direction, direction) ||
                other.direction == direction) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.startRow, startRow) ||
                other.startRow == startRow) &&
            (identical(other.startCol, startCol) ||
                other.startCol == startCol) &&
            (identical(other.length, length) || other.length == length));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, number, direction, text, startRow, startCol, length);

  @override
  String toString() {
    return 'Clue(number: $number, direction: $direction, text: $text, startRow: $startRow, startCol: $startCol, length: $length)';
  }
}

/// @nodoc
abstract mixin class _$ClueCopyWith<$Res> implements $ClueCopyWith<$Res> {
  factory _$ClueCopyWith(_Clue value, $Res Function(_Clue) _then) =
      __$ClueCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int number,
      Direction direction,
      String text,
      int startRow,
      int startCol,
      int length});
}

/// @nodoc
class __$ClueCopyWithImpl<$Res> implements _$ClueCopyWith<$Res> {
  __$ClueCopyWithImpl(this._self, this._then);

  final _Clue _self;
  final $Res Function(_Clue) _then;

  /// Create a copy of Clue
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? number = null,
    Object? direction = null,
    Object? text = null,
    Object? startRow = null,
    Object? startCol = null,
    Object? length = null,
  }) {
    return _then(_Clue(
      number: null == number
          ? _self.number
          : number // ignore: cast_nullable_to_non_nullable
              as int,
      direction: null == direction
          ? _self.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as Direction,
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      startRow: null == startRow
          ? _self.startRow
          : startRow // ignore: cast_nullable_to_non_nullable
              as int,
      startCol: null == startCol
          ? _self.startCol
          : startCol // ignore: cast_nullable_to_non_nullable
              as int,
      length: null == length
          ? _self.length
          : length // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
