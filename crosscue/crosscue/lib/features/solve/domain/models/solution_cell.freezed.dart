// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'solution_cell.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SolutionCell {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is SolutionCell);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SolutionCell()';
  }
}

/// @nodoc
class $SolutionCellCopyWith<$Res> {
  $SolutionCellCopyWith(SolutionCell _, $Res Function(SolutionCell) __);
}

/// Adds pattern-matching-related methods to [SolutionCell].
extension SolutionCellPatterns on SolutionCell {
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
    TResult Function(_SolutionCell value)? $default, {
    TResult Function(_BlackCell value)? black,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SolutionCell() when $default != null:
        return $default(_that);
      case _BlackCell() when black != null:
        return black(_that);
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
    TResult Function(_SolutionCell value) $default, {
    required TResult Function(_BlackCell value) black,
  }) {
    final _that = this;
    switch (_that) {
      case _SolutionCell():
        return $default(_that);
      case _BlackCell():
        return black(_that);
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
    TResult? Function(_SolutionCell value)? $default, {
    TResult? Function(_BlackCell value)? black,
  }) {
    final _that = this;
    switch (_that) {
      case _SolutionCell() when $default != null:
        return $default(_that);
      case _BlackCell() when black != null:
        return black(_that);
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
    TResult Function(bool isBlack, String solution, int? number, bool circled)?
        $default, {
    TResult Function()? black,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SolutionCell() when $default != null:
        return $default(
            _that.isBlack, _that.solution, _that.number, _that.circled);
      case _BlackCell() when black != null:
        return black();
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
    TResult Function(bool isBlack, String solution, int? number, bool circled)
        $default, {
    required TResult Function() black,
  }) {
    final _that = this;
    switch (_that) {
      case _SolutionCell():
        return $default(
            _that.isBlack, _that.solution, _that.number, _that.circled);
      case _BlackCell():
        return black();
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
    TResult? Function(bool isBlack, String solution, int? number, bool circled)?
        $default, {
    TResult? Function()? black,
  }) {
    final _that = this;
    switch (_that) {
      case _SolutionCell() when $default != null:
        return $default(
            _that.isBlack, _that.solution, _that.number, _that.circled);
      case _BlackCell() when black != null:
        return black();
      case _:
        return null;
    }
  }
}

/// @nodoc

class _SolutionCell implements SolutionCell {
  const _SolutionCell(
      {required this.isBlack,
      required this.solution,
      this.number,
      this.circled = false});

  final bool isBlack;
  final String solution;
  final int? number;
  @JsonKey()
  final bool circled;

  /// Create a copy of SolutionCell
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SolutionCellCopyWith<_SolutionCell> get copyWith =>
      __$SolutionCellCopyWithImpl<_SolutionCell>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SolutionCell &&
            (identical(other.isBlack, isBlack) || other.isBlack == isBlack) &&
            (identical(other.solution, solution) ||
                other.solution == solution) &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.circled, circled) || other.circled == circled));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, isBlack, solution, number, circled);

  @override
  String toString() {
    return 'SolutionCell(isBlack: $isBlack, solution: $solution, number: $number, circled: $circled)';
  }
}

/// @nodoc
abstract mixin class _$SolutionCellCopyWith<$Res>
    implements $SolutionCellCopyWith<$Res> {
  factory _$SolutionCellCopyWith(
          _SolutionCell value, $Res Function(_SolutionCell) _then) =
      __$SolutionCellCopyWithImpl;
  @useResult
  $Res call({bool isBlack, String solution, int? number, bool circled});
}

/// @nodoc
class __$SolutionCellCopyWithImpl<$Res>
    implements _$SolutionCellCopyWith<$Res> {
  __$SolutionCellCopyWithImpl(this._self, this._then);

  final _SolutionCell _self;
  final $Res Function(_SolutionCell) _then;

  /// Create a copy of SolutionCell
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? isBlack = null,
    Object? solution = null,
    Object? number = freezed,
    Object? circled = null,
  }) {
    return _then(_SolutionCell(
      isBlack: null == isBlack
          ? _self.isBlack
          : isBlack // ignore: cast_nullable_to_non_nullable
              as bool,
      solution: null == solution
          ? _self.solution
          : solution // ignore: cast_nullable_to_non_nullable
              as String,
      number: freezed == number
          ? _self.number
          : number // ignore: cast_nullable_to_non_nullable
              as int?,
      circled: null == circled
          ? _self.circled
          : circled // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _BlackCell implements SolutionCell {
  const _BlackCell();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _BlackCell);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'SolutionCell.black()';
  }
}

// dart format on
