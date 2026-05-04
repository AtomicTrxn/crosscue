// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'puzzle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Puzzle {
  PuzzleMetadata get metadata;
  Grid<SolutionCell> get grid;
  List<Clue> get clues;

  /// Optional notes / instructions from the constructor.
  String get notes;

  /// Create a copy of Puzzle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PuzzleCopyWith<Puzzle> get copyWith =>
      _$PuzzleCopyWithImpl<Puzzle>(this as Puzzle, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Puzzle &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            (identical(other.grid, grid) || other.grid == grid) &&
            const DeepCollectionEquality().equals(other.clues, clues) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode => Object.hash(runtimeType, metadata, grid,
      const DeepCollectionEquality().hash(clues), notes);

  @override
  String toString() {
    return 'Puzzle(metadata: $metadata, grid: $grid, clues: $clues, notes: $notes)';
  }
}

/// @nodoc
abstract mixin class $PuzzleCopyWith<$Res> {
  factory $PuzzleCopyWith(Puzzle value, $Res Function(Puzzle) _then) =
      _$PuzzleCopyWithImpl;
  @useResult
  $Res call(
      {PuzzleMetadata metadata,
      Grid<SolutionCell> grid,
      List<Clue> clues,
      String notes});

  $PuzzleMetadataCopyWith<$Res> get metadata;
}

/// @nodoc
class _$PuzzleCopyWithImpl<$Res> implements $PuzzleCopyWith<$Res> {
  _$PuzzleCopyWithImpl(this._self, this._then);

  final Puzzle _self;
  final $Res Function(Puzzle) _then;

  /// Create a copy of Puzzle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metadata = null,
    Object? grid = null,
    Object? clues = null,
    Object? notes = null,
  }) {
    return _then(_self.copyWith(
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as PuzzleMetadata,
      grid: null == grid
          ? _self.grid
          : grid // ignore: cast_nullable_to_non_nullable
              as Grid<SolutionCell>,
      clues: null == clues
          ? _self.clues
          : clues // ignore: cast_nullable_to_non_nullable
              as List<Clue>,
      notes: null == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }

  /// Create a copy of Puzzle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PuzzleMetadataCopyWith<$Res> get metadata {
    return $PuzzleMetadataCopyWith<$Res>(_self.metadata, (value) {
      return _then(_self.copyWith(metadata: value));
    });
  }
}

/// Adds pattern-matching-related methods to [Puzzle].
extension PuzzlePatterns on Puzzle {
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
    TResult Function(_Puzzle value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Puzzle() when $default != null:
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
    TResult Function(_Puzzle value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Puzzle():
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
    TResult? Function(_Puzzle value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Puzzle() when $default != null:
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
    TResult Function(PuzzleMetadata metadata, Grid<SolutionCell> grid,
            List<Clue> clues, String notes)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Puzzle() when $default != null:
        return $default(_that.metadata, _that.grid, _that.clues, _that.notes);
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
    TResult Function(PuzzleMetadata metadata, Grid<SolutionCell> grid,
            List<Clue> clues, String notes)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Puzzle():
        return $default(_that.metadata, _that.grid, _that.clues, _that.notes);
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
    TResult? Function(PuzzleMetadata metadata, Grid<SolutionCell> grid,
            List<Clue> clues, String notes)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Puzzle() when $default != null:
        return $default(_that.metadata, _that.grid, _that.clues, _that.notes);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _Puzzle extends Puzzle {
  const _Puzzle(
      {required this.metadata,
      required this.grid,
      required final List<Clue> clues,
      this.notes = ''})
      : _clues = clues,
        super._();

  @override
  final PuzzleMetadata metadata;
  @override
  final Grid<SolutionCell> grid;
  final List<Clue> _clues;
  @override
  List<Clue> get clues {
    if (_clues is EqualUnmodifiableListView) return _clues;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_clues);
  }

  /// Optional notes / instructions from the constructor.
  @override
  @JsonKey()
  final String notes;

  /// Create a copy of Puzzle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PuzzleCopyWith<_Puzzle> get copyWith =>
      __$PuzzleCopyWithImpl<_Puzzle>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Puzzle &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            (identical(other.grid, grid) || other.grid == grid) &&
            const DeepCollectionEquality().equals(other._clues, _clues) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode => Object.hash(runtimeType, metadata, grid,
      const DeepCollectionEquality().hash(_clues), notes);

  @override
  String toString() {
    return 'Puzzle(metadata: $metadata, grid: $grid, clues: $clues, notes: $notes)';
  }
}

/// @nodoc
abstract mixin class _$PuzzleCopyWith<$Res> implements $PuzzleCopyWith<$Res> {
  factory _$PuzzleCopyWith(_Puzzle value, $Res Function(_Puzzle) _then) =
      __$PuzzleCopyWithImpl;
  @override
  @useResult
  $Res call(
      {PuzzleMetadata metadata,
      Grid<SolutionCell> grid,
      List<Clue> clues,
      String notes});

  @override
  $PuzzleMetadataCopyWith<$Res> get metadata;
}

/// @nodoc
class __$PuzzleCopyWithImpl<$Res> implements _$PuzzleCopyWith<$Res> {
  __$PuzzleCopyWithImpl(this._self, this._then);

  final _Puzzle _self;
  final $Res Function(_Puzzle) _then;

  /// Create a copy of Puzzle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? metadata = null,
    Object? grid = null,
    Object? clues = null,
    Object? notes = null,
  }) {
    return _then(_Puzzle(
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as PuzzleMetadata,
      grid: null == grid
          ? _self.grid
          : grid // ignore: cast_nullable_to_non_nullable
              as Grid<SolutionCell>,
      clues: null == clues
          ? _self._clues
          : clues // ignore: cast_nullable_to_non_nullable
              as List<Clue>,
      notes: null == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }

  /// Create a copy of Puzzle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PuzzleMetadataCopyWith<$Res> get metadata {
    return $PuzzleMetadataCopyWith<$Res>(_self.metadata, (value) {
      return _then(_self.copyWith(metadata: value));
    });
  }
}

// dart format on
