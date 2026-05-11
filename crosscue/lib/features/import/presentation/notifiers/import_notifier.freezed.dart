// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'import_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ImportState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ImportState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ImportState()';
  }
}

/// @nodoc
class $ImportStateCopyWith<$Res> {
  $ImportStateCopyWith(ImportState _, $Res Function(ImportState) __);
}

/// Adds pattern-matching-related methods to [ImportState].
extension ImportStatePatterns on ImportState {
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
    TResult Function(ImportIdle value)? idle,
    TResult Function(ImportPicking value)? picking,
    TResult Function(ImportParsing value)? parsing,
    TResult Function(ImportSuccess value)? success,
    TResult Function(ImportDuplicate value)? duplicate,
    TResult Function(ImportFailure value)? failure,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ImportIdle() when idle != null:
        return idle(_that);
      case ImportPicking() when picking != null:
        return picking(_that);
      case ImportParsing() when parsing != null:
        return parsing(_that);
      case ImportSuccess() when success != null:
        return success(_that);
      case ImportDuplicate() when duplicate != null:
        return duplicate(_that);
      case ImportFailure() when failure != null:
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
    required TResult Function(ImportIdle value) idle,
    required TResult Function(ImportPicking value) picking,
    required TResult Function(ImportParsing value) parsing,
    required TResult Function(ImportSuccess value) success,
    required TResult Function(ImportDuplicate value) duplicate,
    required TResult Function(ImportFailure value) failure,
  }) {
    final _that = this;
    switch (_that) {
      case ImportIdle():
        return idle(_that);
      case ImportPicking():
        return picking(_that);
      case ImportParsing():
        return parsing(_that);
      case ImportSuccess():
        return success(_that);
      case ImportDuplicate():
        return duplicate(_that);
      case ImportFailure():
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
    TResult? Function(ImportIdle value)? idle,
    TResult? Function(ImportPicking value)? picking,
    TResult? Function(ImportParsing value)? parsing,
    TResult? Function(ImportSuccess value)? success,
    TResult? Function(ImportDuplicate value)? duplicate,
    TResult? Function(ImportFailure value)? failure,
  }) {
    final _that = this;
    switch (_that) {
      case ImportIdle() when idle != null:
        return idle(_that);
      case ImportPicking() when picking != null:
        return picking(_that);
      case ImportParsing() when parsing != null:
        return parsing(_that);
      case ImportSuccess() when success != null:
        return success(_that);
      case ImportDuplicate() when duplicate != null:
        return duplicate(_that);
      case ImportFailure() when failure != null:
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
    TResult Function()? picking,
    TResult Function(String fileName)? parsing,
    TResult Function(String puzzleId, String title)? success,
    TResult Function(String fileName)? duplicate,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case ImportIdle() when idle != null:
        return idle();
      case ImportPicking() when picking != null:
        return picking();
      case ImportParsing() when parsing != null:
        return parsing(_that.fileName);
      case ImportSuccess() when success != null:
        return success(_that.puzzleId, _that.title);
      case ImportDuplicate() when duplicate != null:
        return duplicate(_that.fileName);
      case ImportFailure() when failure != null:
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
    required TResult Function() picking,
    required TResult Function(String fileName) parsing,
    required TResult Function(String puzzleId, String title) success,
    required TResult Function(String fileName) duplicate,
    required TResult Function(String message) failure,
  }) {
    final _that = this;
    switch (_that) {
      case ImportIdle():
        return idle();
      case ImportPicking():
        return picking();
      case ImportParsing():
        return parsing(_that.fileName);
      case ImportSuccess():
        return success(_that.puzzleId, _that.title);
      case ImportDuplicate():
        return duplicate(_that.fileName);
      case ImportFailure():
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
    TResult? Function()? picking,
    TResult? Function(String fileName)? parsing,
    TResult? Function(String puzzleId, String title)? success,
    TResult? Function(String fileName)? duplicate,
    TResult? Function(String message)? failure,
  }) {
    final _that = this;
    switch (_that) {
      case ImportIdle() when idle != null:
        return idle();
      case ImportPicking() when picking != null:
        return picking();
      case ImportParsing() when parsing != null:
        return parsing(_that.fileName);
      case ImportSuccess() when success != null:
        return success(_that.puzzleId, _that.title);
      case ImportDuplicate() when duplicate != null:
        return duplicate(_that.fileName);
      case ImportFailure() when failure != null:
        return failure(_that.message);
      case _:
        return null;
    }
  }
}

/// @nodoc

class ImportIdle implements ImportState {
  const ImportIdle();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ImportIdle);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ImportState.idle()';
  }
}

/// @nodoc

class ImportPicking implements ImportState {
  const ImportPicking();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is ImportPicking);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'ImportState.picking()';
  }
}

/// @nodoc

class ImportParsing implements ImportState {
  const ImportParsing({required this.fileName});

  final String fileName;

  /// Create a copy of ImportState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ImportParsingCopyWith<ImportParsing> get copyWith =>
      _$ImportParsingCopyWithImpl<ImportParsing>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ImportParsing &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, fileName);

  @override
  String toString() {
    return 'ImportState.parsing(fileName: $fileName)';
  }
}

/// @nodoc
abstract mixin class $ImportParsingCopyWith<$Res>
    implements $ImportStateCopyWith<$Res> {
  factory $ImportParsingCopyWith(
          ImportParsing value, $Res Function(ImportParsing) _then) =
      _$ImportParsingCopyWithImpl;
  @useResult
  $Res call({String fileName});
}

/// @nodoc
class _$ImportParsingCopyWithImpl<$Res>
    implements $ImportParsingCopyWith<$Res> {
  _$ImportParsingCopyWithImpl(this._self, this._then);

  final ImportParsing _self;
  final $Res Function(ImportParsing) _then;

  /// Create a copy of ImportState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? fileName = null,
  }) {
    return _then(ImportParsing(
      fileName: null == fileName
          ? _self.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class ImportSuccess implements ImportState {
  const ImportSuccess({required this.puzzleId, required this.title});

  final String puzzleId;
  final String title;

  /// Create a copy of ImportState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ImportSuccessCopyWith<ImportSuccess> get copyWith =>
      _$ImportSuccessCopyWithImpl<ImportSuccess>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ImportSuccess &&
            (identical(other.puzzleId, puzzleId) ||
                other.puzzleId == puzzleId) &&
            (identical(other.title, title) || other.title == title));
  }

  @override
  int get hashCode => Object.hash(runtimeType, puzzleId, title);

  @override
  String toString() {
    return 'ImportState.success(puzzleId: $puzzleId, title: $title)';
  }
}

/// @nodoc
abstract mixin class $ImportSuccessCopyWith<$Res>
    implements $ImportStateCopyWith<$Res> {
  factory $ImportSuccessCopyWith(
          ImportSuccess value, $Res Function(ImportSuccess) _then) =
      _$ImportSuccessCopyWithImpl;
  @useResult
  $Res call({String puzzleId, String title});
}

/// @nodoc
class _$ImportSuccessCopyWithImpl<$Res>
    implements $ImportSuccessCopyWith<$Res> {
  _$ImportSuccessCopyWithImpl(this._self, this._then);

  final ImportSuccess _self;
  final $Res Function(ImportSuccess) _then;

  /// Create a copy of ImportState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? puzzleId = null,
    Object? title = null,
  }) {
    return _then(ImportSuccess(
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

class ImportDuplicate implements ImportState {
  const ImportDuplicate({required this.fileName});

  final String fileName;

  /// Create a copy of ImportState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ImportDuplicateCopyWith<ImportDuplicate> get copyWith =>
      _$ImportDuplicateCopyWithImpl<ImportDuplicate>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ImportDuplicate &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, fileName);

  @override
  String toString() {
    return 'ImportState.duplicate(fileName: $fileName)';
  }
}

/// @nodoc
abstract mixin class $ImportDuplicateCopyWith<$Res>
    implements $ImportStateCopyWith<$Res> {
  factory $ImportDuplicateCopyWith(
          ImportDuplicate value, $Res Function(ImportDuplicate) _then) =
      _$ImportDuplicateCopyWithImpl;
  @useResult
  $Res call({String fileName});
}

/// @nodoc
class _$ImportDuplicateCopyWithImpl<$Res>
    implements $ImportDuplicateCopyWith<$Res> {
  _$ImportDuplicateCopyWithImpl(this._self, this._then);

  final ImportDuplicate _self;
  final $Res Function(ImportDuplicate) _then;

  /// Create a copy of ImportState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? fileName = null,
  }) {
    return _then(ImportDuplicate(
      fileName: null == fileName
          ? _self.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class ImportFailure implements ImportState {
  const ImportFailure({required this.message});

  final String message;

  /// Create a copy of ImportState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ImportFailureCopyWith<ImportFailure> get copyWith =>
      _$ImportFailureCopyWithImpl<ImportFailure>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ImportFailure &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() {
    return 'ImportState.failure(message: $message)';
  }
}

/// @nodoc
abstract mixin class $ImportFailureCopyWith<$Res>
    implements $ImportStateCopyWith<$Res> {
  factory $ImportFailureCopyWith(
          ImportFailure value, $Res Function(ImportFailure) _then) =
      _$ImportFailureCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$ImportFailureCopyWithImpl<$Res>
    implements $ImportFailureCopyWith<$Res> {
  _$ImportFailureCopyWithImpl(this._self, this._then);

  final ImportFailure _self;
  final $Res Function(ImportFailure) _then;

  /// Create a copy of ImportState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(ImportFailure(
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
