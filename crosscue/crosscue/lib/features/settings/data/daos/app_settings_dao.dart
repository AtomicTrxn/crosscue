import 'package:drift/drift.dart';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/database/tables/app_settings_table.dart';

part 'app_settings_dao.g.dart';

@DriftAccessor(tables: [AppSettingsTable])
class AppSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$AppSettingsDaoMixin {
  AppSettingsDao(super.db);

  /// Returns the raw JSON string for [key], or null if not set.
  Future<String?> getValue(String key) async {
    final row = await (select(appSettingsTable)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.valueJson;
  }

  /// Upserts [valueJson] for [key].
  Future<void> setValue(String key, String valueJson) =>
      into(appSettingsTable).insertOnConflictUpdate(
        AppSettingsTableCompanion.insert(
          key: key,
          valueJson: valueJson,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
}
