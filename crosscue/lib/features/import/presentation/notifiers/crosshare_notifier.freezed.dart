// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'crosshare_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CrosshareState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is CrosshareState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'CrosshareState()';
  }
}

/// @nodoc
class $CrosshareStateCopyWith<$Res> {
  $CrosshareStateCopyWith(CrosshareState _, $Res Function(CrosshareState) __);
}

/// Adds pattern-matching-related methods to [CrosshareState].
extension CrosshareStatePatterns on CrosshareState {
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
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CrosshareIdle value)? idle,
    TResult Function(CrosshareDownloading value)? downloading,
    TResult Function(CrosshareSuccess value)? success,
    TResult Function(CrosshareDuplicate value)? duplicate,
    TResult Function(CrosshareFailure value)? failure,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case CrosshareIdle() when idle != null:
        return idle(_that);
      case CrosshareDownloading() when downloading != null:
        return downloading(_that);
      case CrosshareSuccess() when success != null:
        return success(_that);
      case CrosshareDuplicate() when duplicate != null:
        return duplicate(_that);
      case CrosshareFailure() when failure != null:
        return failure(_that);
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
  TResult map<TResult extends Object?>({
    required TResult Function(CrosshareIdle value) idle,
    required TResult Function(CrosshareDownloading value) downloading,
    required TResult Function(CrosshareSuccess value) success,
    required TResult Function(CrosshareDuplicate value) duplicate,
    required TResult Function(CrosshareFailure value) failure,
  }) {
    final _that = this;
    switch (_that) {
      case CrosshareIdle():
        return idle(_that);
      case CrosshareDownloading():
        return downloading(_that);
      case CrosshareSuccess():
        return success(_that);
      case CrosshareDuplicate():
        return duplicate(_that);
      case CrosshareFailure():
        return failure(_that);
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
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CrosshareIdle value)? idle,
    TResult? Function(CrosshareDownloading value)? downloading,
    TResult? Function(CrosshareSuccess value)? success,
    TResult? Function(CrosshareDuplicate value)? duplicate,
    TResult? Function(CrosshareFailure value)? failure,
  }) {
    final _that = this;
    switch (_that) {
      case CrosshareIdle() when idle != null:
        return idle(_that);
      case CrosshareDownloading() when downloading != null:
        return downloading(_that);
      case CrosshareSuccess() when success != null:
        return success(_that);
      case CrosshareDuplicate() when duplicate != null:
        return duplicate(_that);
      case CrosshareFailure() when failure != null:
        return failure(_that);
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
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function()? downloading,
    TResult Function(String puzzleId, String title)? success,
    TResult Function()? duplicate,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case CrosshareIdle() when idle != null:
        return idle();
      case CrosshareDownloading() when downloading != null:
        return downloading();
      case CrosshareSuccess() when success != null:
        return success(_that.puzzleId, _that.title);
      case CrosshareDuplicate() when duplicate != null:
        return duplicate();
      case CrosshareFailure() when failure != null:
        return failure(_that.message);
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
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function() downloading,
    required TResult Function(String puzzleId, String title) success,
    required TResult Function() duplicate,
    required TResult Function(String message) failure,
  }) {
    final _that = this;
    switch (_that) {
      case CrosshareIdle():
        return idle();
      case CrosshareDownloading():
        return downloading();
      case CrosshareSuccess():
        return success(_that.puzzleId, _that.title);
      case CrosshareDuplicate():
        return duplicate();
      case CrosshareFailure():
        return failure(_that.message);
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
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function()? downloading,
    TResult? Function(String puzzleId, String title)? success,
    TResult? Function()? duplicate,
    TResult? Function(String message)? failure,
  }) {
    final _that = this;
    switch (_that) {
      case CrosshareIdle() when idle != null:
        return idle();
      case CrosshareDownloading() when downloading != null:
        return downloading();
      case CrosshareSuccess() when success != null:
        return success(_that.puzzleId, _that.title);
      case CrosshareDuplicate() when duplicate != null:
        return duplicate();
      case CrosshareFailure() when failure != null:
        return failure(_that.message);
      case _:
        return null;
    }
  }
}

/// @nodoc

class CrosshareIdle implements CrosshareState {
  const CrosshareIdle();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is CrosshareIdle);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'CrosshareState.idle()';
  }
}

/// @nodoc

class CrosshareDownloading implements CrosshareState {
  const CrosshareDownloading();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is CrosshareDownloading);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'CrosshareState.downloading()';
  }
}

/// @nodoc

class CrosshareSuccess implements CrosshareState {
  const CrosshareSuccess({required this.puzzleId, required this.title});

  final String puzzleId;
  final String title;

  /// Create a copy of CrosshareState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CrosshareSuccessCopyWith<CrosshareSuccess> get copyWith =>
      _$CrosshareSuccessCopyWithImpl<CrosshareSuccess>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CrosshareSuccess &&
            (identical(other.puzzleId, puzzleId) ||
                other.puzzleId == puzzleId) &&
            (identical(other.title, title) || other.title == title));
  }

  @override
  int get hashCode => Object.hash(runtimeType, puzzleId, title);

  @override
  String toString() {
    return 'CrosshareState.success(puzzleId: $puzzleId, title: $title)';
  }
}

/// @nodoc
abstract mixin class $CrosshareSuccessCopyWith<$Res>
    implements $CrosshareStateCopyWith<$Res> {
  factory $CrosshareSuccessCopyWith(
          CrosshareSuccess value, $Res Function(CrosshareSuccess) _then) =
      _$CrosshareSuccessCopyWithImpl;
  @useResult
  $Res call({String puzzleId, String title});
}

/// @nodoc
class _$CrosshareSuccessCopyWithImpl<$Res>
    implements $CrosshareSuccessCopyWith<$Res> {
  _$CrosshareSuccessCopyWithImpl(this._self, this._then);

  final CrosshareSuccess _self;
  final $Res Function(CrosshareSuccess) _then;

  /// Create a copy of CrosshareState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? puzzleId = null,
    Object? title = null,
  }) {
    return _then(CrosshareSuccess(
      puzzleId: null == puzzleId
          ? _self.puzzleId
          : puzzleId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class CrosshareDuplicate implements CrosshareState {
  const CrosshareDuplicate();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is CrosshareDuplicate);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'CrosshareState.duplicate()';
  }
}

/// @nodoc

class CrosshareFailure implements CrosshareState {
  const CrosshareFailure({required this.message});

  final String message;

  /// Create a copy of CrosshareState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CrosshareFailureCopyWith<CrosshareFailure> get copyWith =>
      _$CrosshareFailureCopyWithImpl<CrosshareFailure>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CrosshareFailure &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() {
    return 'CrosshareState.failure(message: $message)';
  }
}

/// @nodoc
abstract mixin class $CrosshareFailureCopyWith<$Res>
    implements $CrosshareStateCopyWith<$Res> {
  factory $CrosshareFailureCopyWith(
          CrosshareFailure value, $Res Function(CrosshareFailure) _then) =
      _$CrosshareFailureCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$CrosshareFailureCopyWithImpl<$Res>
    implements $CrosshareFailureCopyWith<$Res> {
  _$CrosshareFailureCopyWithImpl(this._self, this._then);

  final CrosshareFailure _self;
  final $Res Function(CrosshareFailure) _then;

  /// Create a copy of CrosshareState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(CrosshareFailure(
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
