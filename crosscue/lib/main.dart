import 'package:crosscue/app.dart';
import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/features/settings/data/daos/app_settings_dao.dart';
import 'package:crosscue/features/settings/data/repositories/app_settings_repository_impl.dart';
import 'package:crosscue/features/settings/domain/models/boot_settings.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open the database once and load every sync-readable setting before the
  // first frame. The same AppDatabase instance is shared with Riverpod via
  // the override below so we don't open a second SQLite connection.
  final db = AppDatabase();
  final settingsRepo = AppSettingsRepositoryImpl(dao: AppSettingsDao(db));
  BootSettings boot;
  try {
    boot = await settingsRepo.loadBootSettings();
  } on Object {
    // First-run errors (corrupt cache, migration glitch) should not block
    // launch — fall back to defaults so the user can at least open Settings
    // and clear data. The DB read will retry naturally on next mutation.
    boot = BootSettings.defaults;
  }

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        bootSettingsProvider.overrideWithValue(boot),
      ],
      child: const CrosscueApp(),
    ),
  );
}
