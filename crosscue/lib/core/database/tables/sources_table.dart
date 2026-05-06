import 'package:drift/drift.dart';
import 'package:crosscue/features/solve/domain/models/enums.dart';

/// TypeConverter: LicenseStatus (camelCase Dart enum) ↔ snake_case DB string.
class LicenseStatusConverter extends TypeConverter<LicenseStatus, String> {
  const LicenseStatusConverter();

  @override
  LicenseStatus fromSql(String fromDb) {
    return switch (fromDb) {
      'user_import' => LicenseStatus.userImport,
      'explicit_permission' => LicenseStatus.explicitPermission,
      'open_license' => LicenseStatus.openLicense,
      'needs_review' => LicenseStatus.needsReview,
      'prohibited' => LicenseStatus.prohibited,
      _ => LicenseStatus.needsReview,
    };
  }

  @override
  String toSql(LicenseStatus value) {
    return switch (value) {
      LicenseStatus.userImport => 'user_import',
      LicenseStatus.explicitPermission => 'explicit_permission',
      LicenseStatus.openLicense => 'open_license',
      LicenseStatus.needsReview => 'needs_review',
      LicenseStatus.prohibited => 'prohibited',
    };
  }
}

@DataClassName('SourceRow')
class SourcesTable extends Table {
  @override
  String get tableName => 'sources';

  // Stable text primary key: 'local_import', 'universal', 'latimes', etc.
  TextColumn get id => text()();
  TextColumn get displayName => text()();
  TextColumn get type => text()(); // SourceType enum as string
  TextColumn get homepageUrl => text().nullable()();
  TextColumn get termsUrl => text().nullable()();
  TextColumn get attribution => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();
  TextColumn get licenseStatus =>
      text().map(const LicenseStatusConverter()).withDefault(const Constant('needs_review'))();
  TextColumn get licenseUrl => text().nullable()();
  TextColumn get permissionContact => text().nullable()();
  BoolColumn get attributionRequired =>
      boolean().withDefault(const Constant(false))();
  TextColumn get cachePolicy => text().nullable()();
  BoolColumn get rawPayloadRetention =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get commercialUseAllowed =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastLegalReviewAt => dateTime().nullable()();
  DateTimeColumn get lastCheckedAt => dateTime().nullable()();
  DateTimeColumn get lastSuccessAt => dateTime().nullable()();
  TextColumn get etag => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
