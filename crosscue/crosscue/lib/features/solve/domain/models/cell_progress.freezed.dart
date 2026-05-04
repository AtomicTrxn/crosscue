// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cell_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CellProgress {
  /// Whatever the user typed (empty string = blank).
  String get letter;
  CellState get state;
  bool get isPencil;

  /// Create a copy of CellProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CellProgressCopyWith<CellProgress> get copyWith =>
      _$CellProgressCopyWithImpl<CellProgress>(
          this as CellProgress, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CellProgress &&
            (identical(other.letter, letter) || other.letter == letter) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.isPencil, isPencil) ||
                other.isPencil == isPencil));
  }

  @override
  int get hashCode => Object.hash(runtimeType, letter, state, isPencil);

  @override
  String toString() {
    return 'CellProgress(letter: $letter, state: $state, isPencil: $isPencil)';
  }
}

/// @nodoc
abstract mixin class $CellProgressCopyWith<$Res> {
  factory $CellProgressCopyWith(
          CellProgress value, $Res Function(CellProgress) _then) =
      _$CellProgressCopyWithImpl;
  @useResult
  $Res call({String letter, CellState state, bool isPencil});
}

/// @nodoc
class _$CellProgressCopyWithImpl<$Res> implements $CellProgressCopyWith<$Res> {
  _$CellProgressCopyWithImpl(this._self, this._then);

  final CellProgress _self;
  final $Res Function(CellProgress) _then;

  /// Create a copy of CellProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? letter = null,
    Object? state = null,
    Object? isPencil = null,
  }) {
    return _then(_self.copyWith(
      letter: null == letter
          ? _self.letter
          : letter // ignore: cast_nullable_to_non_nullable
              as String,
      state: null == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as CellState,
      isPencil: null == isPencil
          ? _self.isPencil
          : isPencil // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [CellProgress].
extension CellProgressPatterns on CellProgress {
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
    TResult Function(_CellProgress value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CellProgress() when $default != null:
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
    TResult Function(_CellProgress value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CellProgress():
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
    TResult? Function(_CellProgress value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CellProgress() when $default != null:
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
    TResult Function(String letter, CellState state, bool isPencil)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CellProgress() when $default != null:
        return $default(_that.letter, _that.state, _that.isPencil);
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
    TResult Function(String letter, CellState state, bool isPencil) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CellProgress():
        return $default(_that.letter, _that.state, _that.isPencil);
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
    TResult? Function(String letter, CellState state, bool isPencil)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CellProgress() when $default != null:
        return $default(_that.letter, _that.state, _that.isPencil);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _CellProgress implements CellProgress {
  const _CellProgress(
      {this.letter = '', this.state = CellState.empty, this.isPencil = false});

  /// Whatever the user typed (empty string = blank).
  @override
  @JsonKey()
  final String letter;
  @override
  @JsonKey()
  final CellState state;
  @override
  @JsonKey()
  final bool isPencil;

  /// Create a copy of CellProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CellProgressCopyWith<_CellProgress> get copyWith =>
      __$CellProgressCopyWithImpl<_CellProgress>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CellProgress &&
            (identical(other.letter, letter) || other.letter == letter) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.isPencil, isPencil) ||
                other.isPencil == isPencil));
  }

  @override
  int get hashCode => Object.hash(runtimeType, letter, state, isPencil);

  @override
  String toString() {
    return 'CellProgress(letter: $letter, state: $state, isPencil: $isPencil)';
  }
}

/// @nodoc
abstract mixin class _$CellProgressCopyWith<$Res>
    implements $CellProgressCopyWith<$Res> {
  factory _$CellProgressCopyWith(
          _CellProgress value, $Res Function(_CellProgress) _then) =
      __$CellProgressCopyWithImpl;
  @override
  @useResult
  $Res call({String letter, CellState state, bool isPencil});
}

/// @nodoc
class __$CellProgressCopyWithImpl<$Res>
    implements _$CellProgressCopyWith<$Res> {
  __$CellProgressCopyWithImpl(this._self, this._then);

  final _CellProgress _self;
  final $Res Function(_CellProgress) _then;

  /// Create a copy of CellProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? letter = null,
    Object? state = null,
    Object? isPencil = null,
  }) {
    return _then(_CellProgress(
      letter: null == letter
          ? _self.letter
          : letter // ignore: cast_nullable_to_non_nullable
              as String,
      state: null == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as CellState,
      isPencil: null == isPencil
          ? _self.isPencil
          : isPencil // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
