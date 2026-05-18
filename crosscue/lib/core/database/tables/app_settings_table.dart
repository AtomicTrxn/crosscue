import 'package:drift/drift.dart';

/// Key-value settings store. All settings use string keys and JSON-encoded values.
///
/// Canonical keys are defined in the Settings Inventory (architecture-design-review.md):
///   has_seen_onboarding, theme_mode, colorblind_mode_enabled, haptics_enabled,
///   sound_enabled, keyboard_layout, skip_filled_on_advance,
///   daily_reminder_enabled, daily_reminder_time, streak_reminder_enabled,
///   streak_reminder_time, notifications_sound_enabled,
///   notifications_last_scheduled_at, licensed_daily_reminder_enabled,
///   crash_reporting_enabled, streak_milestones_shown,
///   device_id (non-user-configurable)
@DataClassName('AppSettingRow')
class AppSettingsTable extends Table {
  @override
  String get tableName => 'app_settings';

  TextColumn get key => text()();
  TextColumn get valueJson => text()(); // JSON-encoded value
  DateTimeColumn get updatedAt => dateTime()();

  /// Per-key sync version, incremented locally on every write. Compared
  /// against the remote manifest to decide whether to push/pull.
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {key};
}
