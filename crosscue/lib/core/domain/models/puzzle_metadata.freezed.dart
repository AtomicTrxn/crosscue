// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'puzzle_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PuzzleMetadata {
  String get id;
  String get sourceId;
  String get title;
  String get author;
  String get copyright;
  PuzzleFormat get format;
  int get width;
  int get height;
  DateTime get importedAt;
  String? get sourcePuzzleId;
  DateTime? get publishDate;
  String? get notes;
  String? get checksum;
  String? get difficulty;

  /// Number of non-black (fillable) cells in the grid. Denormalized from
  /// the canonical JSON at import time so list-view consumers (Archive
  /// completion-fraction pie, Stats, future projections) can compute
  /// progress without paying the full JSON-decode cost. See issue #122.
  ///
  /// Defaults to 0 for rows migrated from schema versions ≤ 5 that
  /// failed to parse during the v5 → v6 backfill — callers that treat
  /// the value as an authoritative cell count must guard against the
  /// 0 sentinel (in practice, freshly inserted rows are always > 0).
  int get fillableCellCount;

  /// Create a copy of PuzzleMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PuzzleMetadataCopyWith<PuzzleMetadata> get copyWith =>
      _$PuzzleMetadataCopyWithImpl<PuzzleMetadata>(
          this as PuzzleMetadata, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PuzzleMetadata &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sourceId, sourceId) ||
                other.sourceId == sourceId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.copyright, copyright) ||
                other.copyright == copyright) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.importedAt, importedAt) ||
                other.importedAt == importedAt) &&
            (identical(other.sourcePuzzleId, sourcePuzzleId) ||
                other.sourcePuzzleId == sourcePuzzleId) &&
            (identical(other.publishDate, publishDate) ||
                other.publishDate == publishDate) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.checksum, checksum) ||
                other.checksum == checksum) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.fillableCellCount, fillableCellCount) ||
                other.fillableCellCount == fillableCellCount));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      sourceId,
      title,
      author,
      copyright,
      format,
      width,
      height,
      importedAt,
      sourcePuzzleId,
      publishDate,
      notes,
      checksum,
      difficulty,
      fillableCellCount);

  @override
  String toString() {
    return 'PuzzleMetadata(id: $id, sourceId: $sourceId, title: $title, author: $author, copyright: $copyright, format: $format, width: $width, height: $height, importedAt: $importedAt, sourcePuzzleId: $sourcePuzzleId, publishDate: $publishDate, notes: $notes, checksum: $checksum, difficulty: $difficulty, fillableCellCount: $fillableCellCount)';
  }
}

/// @nodoc
abstract mixin class $PuzzleMetadataCopyWith<$Res> {
  factory $PuzzleMetadataCopyWith(
          PuzzleMetadata value, $Res Function(PuzzleMetadata) _then) =
      _$PuzzleMetadataCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String sourceId,
      String title,
      String author,
      String copyright,
      PuzzleFormat format,
      int width,
      int height,
      DateTime importedAt,
      String? sourcePuzzleId,
      DateTime? publishDate,
      String? notes,
      String? checksum,
      String? difficulty,
      int fillableCellCount});
}

/// @nodoc
class _$PuzzleMetadataCopyWithImpl<$Res>
    implements $PuzzleMetadataCopyWith<$Res> {
  _$PuzzleMetadataCopyWithImpl(this._self, this._then);

  final PuzzleMetadata _self;
  final $Res Function(PuzzleMetadata) _then;

  /// Create a copy of PuzzleMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sourceId = null,
    Object? title = null,
    Object? author = null,
    Object? copyright = null,
    Object? format = null,
    Object? width = null,
    Object? height = null,
    Object? importedAt = null,
    Object? sourcePuzzleId = freezed,
    Object? publishDate = freezed,
    Object? notes = freezed,
    Object? checksum = freezed,
    Object? difficulty = freezed,
    Object? fillableCellCount = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sourceId: null == sourceId
          ? _self.sourceId
          : sourceId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _self.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      copyright: null == copyright
          ? _self.copyright
          : copyright // ignore: cast_nullable_to_non_nullable
              as String,
      format: null == format
          ? _self.format
          : format // ignore: cast_nullable_to_non_nullable
              as PuzzleFormat,
      width: null == width
          ? _self.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _self.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      importedAt: null == importedAt
          ? _self.importedAt
          : importedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      sourcePuzzleId: freezed == sourcePuzzleId
          ? _self.sourcePuzzleId
          : sourcePuzzleId // ignore: cast_nullable_to_non_nullable
              as String?,
      publishDate: freezed == publishDate
          ? _self.publishDate
          : publishDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      checksum: freezed == checksum
          ? _self.checksum
          : checksum // ignore: cast_nullable_to_non_nullable
              as String?,
      difficulty: freezed == difficulty
          ? _self.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String?,
      fillableCellCount: null == fillableCellCount
          ? _self.fillableCellCount
          : fillableCellCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [PuzzleMetadata].
extension PuzzleMetadataPatterns on PuzzleMetadata {
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
    TResult Function(_PuzzleMetadata value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PuzzleMetadata() when $default != null:
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
    TResult Function(_PuzzleMetadata value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PuzzleMetadata():
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
    TResult? Function(_PuzzleMetadata value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PuzzleMetadata() when $default != null:
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
    TResult Function(
            String id,
            String sourceId,
            String title,
            String author,
            String copyright,
            PuzzleFormat format,
            int width,
            int height,
            DateTime importedAt,
            String? sourcePuzzleId,
            DateTime? publishDate,
            String? notes,
            String? checksum,
            String? difficulty,
            int fillableCellCount)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PuzzleMetadata() when $default != null:
        return $default(
            _that.id,
            _that.sourceId,
            _that.title,
            _that.author,
            _that.copyright,
            _that.format,
            _that.width,
            _that.height,
            _that.importedAt,
            _that.sourcePuzzleId,
            _that.publishDate,
            _that.notes,
            _that.checksum,
            _that.difficulty,
            _that.fillableCellCount);
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
    TResult Function(
            String id,
            String sourceId,
            String title,
            String author,
            String copyright,
            PuzzleFormat format,
            int width,
            int height,
            DateTime importedAt,
            String? sourcePuzzleId,
            DateTime? publishDate,
            String? notes,
            String? checksum,
            String? difficulty,
            int fillableCellCount)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PuzzleMetadata():
        return $default(
            _that.id,
            _that.sourceId,
            _that.title,
            _that.author,
            _that.copyright,
            _that.format,
            _that.width,
            _that.height,
            _that.importedAt,
            _that.sourcePuzzleId,
            _that.publishDate,
            _that.notes,
            _that.checksum,
            _that.difficulty,
            _that.fillableCellCount);
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
    TResult? Function(
            String id,
            String sourceId,
            String title,
            String author,
            String copyright,
            PuzzleFormat format,
            int width,
            int height,
            DateTime importedAt,
            String? sourcePuzzleId,
            DateTime? publishDate,
            String? notes,
            String? checksum,
            String? difficulty,
            int fillableCellCount)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PuzzleMetadata() when $default != null:
        return $default(
            _that.id,
            _that.sourceId,
            _that.title,
            _that.author,
            _that.copyright,
            _that.format,
            _that.width,
            _that.height,
            _that.importedAt,
            _that.sourcePuzzleId,
            _that.publishDate,
            _that.notes,
            _that.checksum,
            _that.difficulty,
            _that.fillableCellCount);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _PuzzleMetadata implements PuzzleMetadata {
  const _PuzzleMetadata(
      {required this.id,
      required this.sourceId,
      required this.title,
      required this.author,
      required this.copyright,
      required this.format,
      required this.width,
      required this.height,
      required this.importedAt,
      this.sourcePuzzleId,
      this.publishDate,
      this.notes,
      this.checksum,
      this.difficulty,
      this.fillableCellCount = 0});

  @override
  final String id;
  @override
  final String sourceId;
  @override
  final String title;
  @override
  final String author;
  @override
  final String copyright;
  @override
  final PuzzleFormat format;
  @override
  final int width;
  @override
  final int height;
  @override
  final DateTime importedAt;
  @override
  final String? sourcePuzzleId;
  @override
  final DateTime? publishDate;
  @override
  final String? notes;
  @override
  final String? checksum;
  @override
  final String? difficulty;

  /// Number of non-black (fillable) cells in the grid. Denormalized from
  /// the canonical JSON at import time so list-view consumers (Archive
  /// completion-fraction pie, Stats, future projections) can compute
  /// progress without paying the full JSON-decode cost. See issue #122.
  ///
  /// Defaults to 0 for rows migrated from schema versions ≤ 5 that
  /// failed to parse during the v5 → v6 backfill — callers that treat
  /// the value as an authoritative cell count must guard against the
  /// 0 sentinel (in practice, freshly inserted rows are always > 0).
  @override
  @JsonKey()
  final int fillableCellCount;

  /// Create a copy of PuzzleMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PuzzleMetadataCopyWith<_PuzzleMetadata> get copyWith =>
      __$PuzzleMetadataCopyWithImpl<_PuzzleMetadata>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PuzzleMetadata &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sourceId, sourceId) ||
                other.sourceId == sourceId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.copyright, copyright) ||
                other.copyright == copyright) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.importedAt, importedAt) ||
                other.importedAt == importedAt) &&
            (identical(other.sourcePuzzleId, sourcePuzzleId) ||
                other.sourcePuzzleId == sourcePuzzleId) &&
            (identical(other.publishDate, publishDate) ||
                other.publishDate == publishDate) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.checksum, checksum) ||
                other.checksum == checksum) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.fillableCellCount, fillableCellCount) ||
                other.fillableCellCount == fillableCellCount));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      sourceId,
      title,
      author,
      copyright,
      format,
      width,
      height,
      importedAt,
      sourcePuzzleId,
      publishDate,
      notes,
      checksum,
      difficulty,
      fillableCellCount);

  @override
  String toString() {
    return 'PuzzleMetadata(id: $id, sourceId: $sourceId, title: $title, author: $author, copyright: $copyright, format: $format, width: $width, height: $height, importedAt: $importedAt, sourcePuzzleId: $sourcePuzzleId, publishDate: $publishDate, notes: $notes, checksum: $checksum, difficulty: $difficulty, fillableCellCount: $fillableCellCount)';
  }
}

/// @nodoc
abstract mixin class _$PuzzleMetadataCopyWith<$Res>
    implements $PuzzleMetadataCopyWith<$Res> {
  factory _$PuzzleMetadataCopyWith(
          _PuzzleMetadata value, $Res Function(_PuzzleMetadata) _then) =
      __$PuzzleMetadataCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String sourceId,
      String title,
      String author,
      String copyright,
      PuzzleFormat format,
      int width,
      int height,
      DateTime importedAt,
      String? sourcePuzzleId,
      DateTime? publishDate,
      String? notes,
      String? checksum,
      String? difficulty,
      int fillableCellCount});
}

/// @nodoc
class __$PuzzleMetadataCopyWithImpl<$Res>
    implements _$PuzzleMetadataCopyWith<$Res> {
  __$PuzzleMetadataCopyWithImpl(this._self, this._then);

  final _PuzzleMetadata _self;
  final $Res Function(_PuzzleMetadata) _then;

  /// Create a copy of PuzzleMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? sourceId = null,
    Object? title = null,
    Object? author = null,
    Object? copyright = null,
    Object? format = null,
    Object? width = null,
    Object? height = null,
    Object? importedAt = null,
    Object? sourcePuzzleId = freezed,
    Object? publishDate = freezed,
    Object? notes = freezed,
    Object? checksum = freezed,
    Object? difficulty = freezed,
    Object? fillableCellCount = null,
  }) {
    return _then(_PuzzleMetadata(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sourceId: null == sourceId
          ? _self.sourceId
          : sourceId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _self.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      copyright: null == copyright
          ? _self.copyright
          : copyright // ignore: cast_nullable_to_non_nullable
              as String,
      format: null == format
          ? _self.format
          : format // ignore: cast_nullable_to_non_nullable
              as PuzzleFormat,
      width: null == width
          ? _self.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _self.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      importedAt: null == importedAt
          ? _self.importedAt
          : importedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      sourcePuzzleId: freezed == sourcePuzzleId
          ? _self.sourcePuzzleId
          : sourcePuzzleId // ignore: cast_nullable_to_non_nullable
              as String?,
      publishDate: freezed == publishDate
          ? _self.publishDate
          : publishDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      checksum: freezed == checksum
          ? _self.checksum
          : checksum // ignore: cast_nullable_to_non_nullable
              as String?,
      difficulty: freezed == difficulty
          ? _self.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String?,
      fillableCellCount: null == fillableCellCount
          ? _self.fillableCellCount
          : fillableCellCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
