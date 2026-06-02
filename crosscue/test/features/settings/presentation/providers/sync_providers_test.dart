// Tests for SyncController — drives the real SyncOrchestrator against an
// in-memory database and FakeSyncTransport (#142). Verifies the enable /
// disable / sync-now actions move both the live state and the persisted
// `syncEnabled` flag correctly.

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/core/sync/models/sync_state.dart';
import 'package:crosscue/core/sync/transport/fake_sync_transport.dart';
import 'package:crosscue/core/sync/transport/no_op_sync_transport.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/settings/presentation/providers/sync_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        syncTransportProvider
            .overrideWithValue(FakeSyncTransport(store: <String, String>{})),
      ],
    );
  }

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('starts disabled and not opted-in', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    final vm = await container.read(syncControllerProvider.future);

    expect(vm.enabled, isFalse);
    expect(vm.syncState, isA<SyncDisabled>());
    expect(
      vm.available,
      isTrue,
      reason: 'FakeSyncTransport reports an account',
    );
    expect(await container.read(appSettingsProvider).getSyncEnabled(), isFalse);
  });

  test('available is false when no cloud account is reachable', () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        // NoOpSyncTransport.account() returns null → signed out.
        syncTransportProvider.overrideWithValue(const NoOpSyncTransport()),
      ],
    );
    addTearDown(container.dispose);

    final vm = await container.read(syncControllerProvider.future);
    expect(vm.available, isFalse);
  });

  test('enable persists the flag, links the account, and runs a pass',
      () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(syncControllerProvider.future);

    await container.read(syncControllerProvider.notifier).enable();

    final vm = container.read(syncControllerProvider).asData!.value;
    expect(vm.enabled, isTrue);
    expect(
      vm.syncState,
      isA<SyncIdle>(),
      reason: 'a linked account moves the orchestrator to idle after sync',
    );
    expect(vm.account, isNotNull);
    expect(vm.lastResult, isNotNull);
    expect(await container.read(appSettingsProvider).getSyncEnabled(), isTrue);
  });

  test('disable persists off and returns to SyncDisabled', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(syncControllerProvider.future);
    await container.read(syncControllerProvider.notifier).enable();

    await container.read(syncControllerProvider.notifier).disable();

    final vm = container.read(syncControllerProvider).asData!.value;
    expect(vm.enabled, isFalse);
    expect(vm.syncState, isA<SyncDisabled>());
    expect(await container.read(appSettingsProvider).getSyncEnabled(), isFalse);
  });

  test('the persisted flag survives a fresh controller (re-enable on boot)',
      () async {
    // Opt in via one container...
    final first = makeContainer();
    await first.read(syncControllerProvider.future);
    await first.read(syncControllerProvider.notifier).enable();
    first.dispose();

    // ...a fresh container over the same DB sees the persisted flag.
    final second = makeContainer();
    addTearDown(second.dispose);
    final vm = await second.read(syncControllerProvider.future);
    expect(vm.enabled, isTrue);
  });
}
