// Round-trip tests for completion persistence — locks the
// `_statusFromDb` / `_deriveCompletionType` inverse-mapping invariant
// called out in `docs/architecture/completion-authority.md` (rule 4).
//
// Each scenario drives the SolveNotifier to a terminal state through the
// real SolveRepositoryImpl + an in-memory database, disposes the notifier,
// then recreates it against the same database and asserts the resumed
// status survives. If `_deriveCompletionType` (notifier) and `_statusFromDb`
// (repo) ever drift, these tests fail.

import 'dart:async';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/features/import/data/repositories/import_repository_impl.dart';
import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:crosscue/features/import/presentation/providers/import_providers.dart';
import 'package:crosscue/features/settings/domain/models/boot_settings.dart';
import 'package:crosscue/features/settings/domain/repositories/app_settings_repository.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/solve/data/repositories/solve_repository_impl.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';
import 'package:crosscue/features/solve/domain/models/focus_position.dart';
import 'package:crosscue/features/solve/domain/repositories/solve_repository.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_notifier.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_state.dart';
import 'package:crosscue/features/solve/presentation/providers/solve_providers.dart';
import 'package:crosscue/features/stats/domain/models/stats_data.dart';
import 'package:crosscue/features/stats/domain/repositories/stats_repository.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/puz_fixture_builder.dart';

void main() {
  group('completion round-trip survives notifier dispose', () {
    test('PuzzleStatus.solved (clean) — typed completion', () async {
      await _runRoundTrip(
        prepProgress: (puzzle, repo, sessionId) async =>
            _almostSolvedProgress(puzzle),
        drive: (notifier) => notifier.inputLetter('I'),
        expectedStatus: PuzzleStatus.solved,
        expectedCompletionType: 'clean',
      );
    });

    test('PuzzleStatus.solvedWithHelp — typed completion after checkGrid',
        () async {
      await _runRoundTrip(
        prepProgress: (puzzle, repo, sessionId) async =>
            _almostSolvedProgress(puzzle),
        drive: (notifier) {
          notifier.checkGrid();
          notifier.inputLetter('I');
        },
        expectedStatus: PuzzleStatus.solvedWithHelp,
        expectedCompletionType: 'checked',
      );
    });

    test('PuzzleStatus.solvedWithReveal — typed completion after revealCell',
        () async {
      await _runRoundTrip(
        prepProgress: (puzzle, repo, sessionId) async =>
            _almostSolvedProgress(puzzle),
        drive: (notifier) {
          // Cell (2,2) is the only empty cell after _almostSolvedProgress.
          // Move focus there and reveal; that fills 'I' and triggers
          // completion via _applyRevealProgress → _checkCompletion.
          notifier.moveFocusTo(2, 2, Direction.across);
          notifier.revealCell();
        },
        expectedStatus: PuzzleStatus.solvedWithReveal,
        expectedCompletionType: 'hinted',
      );
    });

    test('PuzzleStatus.revealed — revealPuzzle from blank grid', () async {
      await _runRoundTrip(
        prepProgress: (puzzle, repo, sessionId) async => null,
        drive: (notifier) => notifier.revealPuzzle(),
        expectedStatus: PuzzleStatus.revealed,
        expectedCompletionType: 'revealed',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Reset-while-saving race (divergence window 3 in
  // docs/architecture/completion-authority.md).
  //
  // When the user resets a puzzle that was just completed, the `markComplete`
  // call from completion may still be in-flight. The reset's `saveProgress`
  // can land either before or after `markComplete` finishes. The test
  // simulates the scenario where `markComplete` has already written to both
  // DB tables but its Future is held open (matching the notifier's
  // fire-and-forget pattern in `_persistCompletion`). The reset's
  // `saveProgress` then runs and overwrites the session row back to
  // `in_progress`. We assert:
  //   - `puzzle_completions` retains the completion row (append-only)
  //   - `solve_sessions.status` ends in `in_progress`
  //   - in-memory `SolveState.status` reflects the reset
  // ---------------------------------------------------------------------------

  test(
    'reset while markComplete in flight: completion row retained, session resets',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final importRepo = ImportRepositoryImpl(dao: db.puzzleDao);
      final importResult =
          await importRepo.importBytes(PuzFixtureBuilder.minimal3x3());
      final puzzle = switch (importResult) {
        JobSuccess(:final puzzle) => puzzle,
        JobDuplicate() => throw StateError('unexpected duplicate'),
        JobFailure(:final error) => throw StateError('import failed: $error'),
      };

      final providerKey = Uri.encodeComponent(puzzle.id);

      final spy = _GatedMarkCompleteRepository(
        SolveRepositoryImpl(
          dao: db.solveSessionDao,
          completionDao: db.puzzleCompletionDao,
        ),
      );

      // Pre-fill session with all-but-(2,2) correct.
      final preSession = await spy.createOrResumeSession(puzzle);
      await spy.saveProgress(
        sessionId: preSession.sessionId,
        puzzleWidth: puzzle.width,
        puzzleHeight: puzzle.height,
        progress: _almostSolvedProgress(puzzle),
        focus: const FocusPosition(row: 0, col: 0, direction: Direction.across),
        elapsedMs: 0,
        status: PuzzleStatus.inProgress,
        isPaused: false,
        checkCount: 0,
        revealCount: 0,
        usedCheck: false,
        usedReveal: false,
        cleanSolveEligible: true,
      );

      final container = ProviderContainer(
        overrides: [
          importRepositoryProvider.overrideWithValue(importRepo),
          solveRepositoryProvider.overrideWithValue(spy),
          statsRepositoryProvider.overrideWithValue(_EmptyStatsRepository()),
          appSettingsProvider.overrideWithValue(const _PermissiveAppSettings()),
          bootSettingsProvider.overrideWithValue(BootSettings.defaults),
        ],
      );
      addTearDown(container.dispose);

      final provider = solveProvider(providerKey);
      // Keep the auto-dispose provider alive across `pumpEventQueue` calls
      // below; otherwise the notifier's chained `ref.invalidate(stats)`
      // throws when it fires after the read-only handle is released.
      final subscription = container.listen<AsyncValue<SolveState>>(
        provider,
        (_, __) {},
      );
      addTearDown(subscription.close);

      await container.read(provider.future);
      final notifier = container.read(provider.notifier);
      notifier.moveFocusTo(2, 2, Direction.across);

      // Drive completion. markComplete's inner DB writes run but the outer
      // Future is held by the gate.
      notifier.inputLetter('I');

      // Wait until the inner markComplete DB writes have finished. The
      // notifier's `.then(invalidate stats)` callback hasn't run yet (gate
      // is still closed).
      await spy.innerMarkCompleteFinished;

      // Sanity: both tables show the completion at this point.
      final preReset = await db.solveSessionDao.getLatestSession(puzzle.id);
      expect(preReset!.status, 'completed');
      expect(preReset.completionType, 'clean');
      final preResetCompletions =
          await db.puzzleCompletionDao.rowsForPuzzle(puzzle.id);
      expect(preResetCompletions, hasLength(1));

      // Trigger reset while the markComplete Future is still open.
      notifier.resetPuzzle();

      // Let the reset's fire-and-forget _saveNow finish.
      await pumpEventQueue();

      // Release the still-open markComplete Future and flush microtasks. Any
      // chained `.then` in the notifier runs now; it must NOT re-overwrite
      // the session row, because the DB writes inside markComplete already
      // happened before the gate.
      spy.release();
      await pumpEventQueue();

      // Assertions.
      final session = await db.solveSessionDao.getLatestSession(puzzle.id);
      expect(session, isNotNull);
      expect(
        session!.status,
        'in_progress',
        reason: 'reset must win the session-row race after markComplete',
      );
      expect(
        session.completionType,
        isNull,
        reason: 'reset clears the cached completionType',
      );

      final completions = await db.puzzleCompletionDao.rowsForPuzzle(puzzle.id);
      expect(
        completions,
        hasLength(1),
        reason: 'puzzle_completions is append-only — reset must not delete it',
      );
      expect(completions.single.completionType, 'clean');

      final inMemory = container.read(provider).value!;
      expect(inMemory.status, PuzzleStatus.inProgress);
      expect(inMemory.usedCheck, isFalse);
      expect(inMemory.usedReveal, isFalse);
      expect(inMemory.checkCount, 0);
      expect(inMemory.revealCount, 0);
    },
  );
}

Future<void> _runRoundTrip({
  required Future<Grid<CellProgress>?> Function(
    Puzzle puzzle,
    SolveRepository repo,
    int sessionId,
  ) prepProgress,
  required FutureOr<void> Function(SolveNotifier notifier) drive,
  required PuzzleStatus expectedStatus,
  required String expectedCompletionType,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);

  final importRepo = ImportRepositoryImpl(dao: db.puzzleDao);
  final importResult =
      await importRepo.importBytes(PuzFixtureBuilder.minimal3x3());
  final puzzle = switch (importResult) {
    JobSuccess(:final puzzle) => puzzle,
    JobDuplicate() => throw StateError('unexpected duplicate'),
    JobFailure(:final error) => throw StateError('import failed: $error'),
  };

  final providerKey = Uri.encodeComponent(puzzle.id);

  // --- Container 1: drive to completion, then dispose -----------------------
  final spy = _MarkCompleteSpyRepository(
    SolveRepositoryImpl(
      dao: db.solveSessionDao,
      completionDao: db.puzzleCompletionDao,
    ),
  );

  // Pre-fill the session row if the scenario needs an almost-solved grid.
  final prepared = await prepProgress(puzzle, spy, 0);
  if (prepared != null) {
    final session = await spy.createOrResumeSession(puzzle);
    await spy.saveProgress(
      sessionId: session.sessionId,
      puzzleWidth: puzzle.width,
      puzzleHeight: puzzle.height,
      progress: prepared,
      focus: const FocusPosition(row: 0, col: 0, direction: Direction.across),
      elapsedMs: 0,
      status: PuzzleStatus.inProgress,
      isPaused: false,
      checkCount: 0,
      revealCount: 0,
      usedCheck: false,
      usedReveal: false,
      cleanSolveEligible: true,
    );
  }

  final container1 = ProviderContainer(
    overrides: [
      importRepositoryProvider.overrideWithValue(importRepo),
      solveRepositoryProvider.overrideWithValue(spy),
      statsRepositoryProvider.overrideWithValue(_EmptyStatsRepository()),
      appSettingsProvider.overrideWithValue(const _PermissiveAppSettings()),
      bootSettingsProvider.overrideWithValue(BootSettings.defaults),
    ],
  );

  final provider = solveProvider(providerKey);
  final loaded = await container1.read(provider.future);
  // Focus the last empty cell so `inputLetter` lands there.
  if (prepared != null) {
    container1.read(provider.notifier).moveFocusTo(2, 2, Direction.across);
  }
  expect(loaded.sessionId, isNotNull);

  await drive(container1.read(provider.notifier));

  // Wait for the unawaited markComplete fired from _persistCompletion.
  await spy.markCompleteFinished;

  container1.dispose();

  // --- Container 2: fresh notifier against the same DB ---------------------
  final container2 = ProviderContainer(
    overrides: [
      importRepositoryProvider.overrideWithValue(importRepo),
      solveRepositoryProvider.overrideWithValue(
        SolveRepositoryImpl(
          dao: db.solveSessionDao,
          completionDao: db.puzzleCompletionDao,
        ),
      ),
      statsRepositoryProvider.overrideWithValue(_EmptyStatsRepository()),
      appSettingsProvider.overrideWithValue(const _PermissiveAppSettings()),
      bootSettingsProvider.overrideWithValue(BootSettings.defaults),
    ],
  );
  addTearDown(container2.dispose);

  final resumed = await container2.read(provider.future);
  expect(resumed.status, expectedStatus);

  // Verify the persisted completionType on solve_sessions matches what
  // `_deriveCompletionType` was supposed to produce.
  final row = await db.solveSessionDao.getLatestSession(puzzle.id);
  expect(row, isNotNull);
  expect(row!.completionType, expectedCompletionType);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns a 3x3 progress grid for the minimal3x3 puzzle with every cell
/// filled correctly except (2,2). The notifier resumes from this state and
/// can be driven to completion by typing 'I' (or running checkGrid first
/// to set usedCheck, then typing 'I').
Grid<CellProgress> _almostSolvedProgress(Puzzle puzzle) {
  return Grid<CellProgress>.generate(puzzle.width, puzzle.height, (r, c) {
    if (r == 2 && c == 2) return CellProgress.blank;
    final solution = puzzle.grid.cell(r, c).solution;
    return CellProgress(letter: solution, state: CellState.filled);
  });
}

final class _MarkCompleteSpyRepository implements SolveRepository {
  _MarkCompleteSpyRepository(this.inner);

  final SolveRepository inner;
  final _markCompleteCompleter = Completer<void>();

  Future<void> get markCompleteFinished => _markCompleteCompleter.future;

  @override
  Future<SessionLoadResult> createOrResumeSession(Puzzle puzzle) =>
      inner.createOrResumeSession(puzzle);

  @override
  Future<void> saveProgress({
    required int sessionId,
    required int puzzleWidth,
    required int puzzleHeight,
    required Grid<CellProgress> progress,
    required FocusPosition focus,
    required int elapsedMs,
    required PuzzleStatus status,
    required bool isPaused,
    required int checkCount,
    required int revealCount,
    required bool usedCheck,
    required bool usedReveal,
    required bool cleanSolveEligible,
  }) {
    return inner.saveProgress(
      sessionId: sessionId,
      puzzleWidth: puzzleWidth,
      puzzleHeight: puzzleHeight,
      progress: progress,
      focus: focus,
      elapsedMs: elapsedMs,
      status: status,
      isPaused: isPaused,
      checkCount: checkCount,
      revealCount: revealCount,
      usedCheck: usedCheck,
      usedReveal: usedReveal,
      cleanSolveEligible: cleanSolveEligible,
    );
  }

  @override
  Future<void> markComplete({
    required int sessionId,
    required String puzzleId,
    required int puzzleWidth,
    required int puzzleHeight,
    required Grid<CellProgress> progress,
    required FocusPosition focus,
    required int elapsedMs,
    required PuzzleStatus status,
    required CompletionType completionType,
    required int checkCount,
    required int revealCount,
    required bool usedCheck,
    required bool usedReveal,
    required bool cleanSolveEligible,
  }) async {
    try {
      await inner.markComplete(
        sessionId: sessionId,
        puzzleId: puzzleId,
        puzzleWidth: puzzleWidth,
        puzzleHeight: puzzleHeight,
        progress: progress,
        focus: focus,
        elapsedMs: elapsedMs,
        status: status,
        completionType: completionType,
        checkCount: checkCount,
        revealCount: revealCount,
        usedCheck: usedCheck,
        usedReveal: usedReveal,
        cleanSolveEligible: cleanSolveEligible,
      );
    } finally {
      if (!_markCompleteCompleter.isCompleted) {
        _markCompleteCompleter.complete();
      }
    }
  }
}

/// Wraps a real [SolveRepository] but holds the [markComplete] Future open
/// until [release] is called. The wrapped repo's DB writes still happen
/// inline, so the gate only delays the *return* of the Future — matching
/// the notifier's unawaited `markComplete` pattern.
final class _GatedMarkCompleteRepository implements SolveRepository {
  _GatedMarkCompleteRepository(this.inner);

  final SolveRepository inner;
  final _innerDone = Completer<void>();
  final _gate = Completer<void>();

  Future<void> get innerMarkCompleteFinished => _innerDone.future;

  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Future<SessionLoadResult> createOrResumeSession(Puzzle puzzle) =>
      inner.createOrResumeSession(puzzle);

  @override
  Future<void> saveProgress({
    required int sessionId,
    required int puzzleWidth,
    required int puzzleHeight,
    required Grid<CellProgress> progress,
    required FocusPosition focus,
    required int elapsedMs,
    required PuzzleStatus status,
    required bool isPaused,
    required int checkCount,
    required int revealCount,
    required bool usedCheck,
    required bool usedReveal,
    required bool cleanSolveEligible,
  }) {
    return inner.saveProgress(
      sessionId: sessionId,
      puzzleWidth: puzzleWidth,
      puzzleHeight: puzzleHeight,
      progress: progress,
      focus: focus,
      elapsedMs: elapsedMs,
      status: status,
      isPaused: isPaused,
      checkCount: checkCount,
      revealCount: revealCount,
      usedCheck: usedCheck,
      usedReveal: usedReveal,
      cleanSolveEligible: cleanSolveEligible,
    );
  }

  @override
  Future<void> markComplete({
    required int sessionId,
    required String puzzleId,
    required int puzzleWidth,
    required int puzzleHeight,
    required Grid<CellProgress> progress,
    required FocusPosition focus,
    required int elapsedMs,
    required PuzzleStatus status,
    required CompletionType completionType,
    required int checkCount,
    required int revealCount,
    required bool usedCheck,
    required bool usedReveal,
    required bool cleanSolveEligible,
  }) async {
    await inner.markComplete(
      sessionId: sessionId,
      puzzleId: puzzleId,
      puzzleWidth: puzzleWidth,
      puzzleHeight: puzzleHeight,
      progress: progress,
      focus: focus,
      elapsedMs: elapsedMs,
      status: status,
      completionType: completionType,
      checkCount: checkCount,
      revealCount: revealCount,
      usedCheck: usedCheck,
      usedReveal: usedReveal,
      cleanSolveEligible: cleanSolveEligible,
    );
    if (!_innerDone.isCompleted) _innerDone.complete();
    await _gate.future;
  }
}

final class _EmptyStatsRepository implements StatsRepository {
  @override
  Future<StatsData> getStats() async => StatsData.empty;
}

final class _PermissiveAppSettings implements AppSettingsRepository {
  const _PermissiveAppSettings();

  @override
  Future<BootSettings> loadBootSettings() async => BootSettings.defaults;

  @override
  Future<bool> getCrashReporting() async => false;

  @override
  Future<ColorblindMode> getColorblindMode() async => ColorblindMode.none;

  @override
  Future<bool> getHapticsEnabled() async => true;

  @override
  Future<bool> getHasSeenOnboarding() async => true;

  @override
  Future<bool> getPuzzleReminder() async => false;

  @override
  Future<bool> getSkipFilledCells() async => false;

  @override
  Future<bool> getSoundsEnabled() async => false;

  @override
  Future<bool> getStreakReminder() async => false;

  @override
  Future<AppThemeMode> getThemeMode() async => AppThemeMode.system;

  @override
  Future<void> setCrashReporting(bool value) async {}

  @override
  Future<void> setColorblindMode(ColorblindMode value) async {}

  @override
  Future<void> setHapticsEnabled(bool value) async {}

  @override
  Future<void> setHasSeenOnboarding(bool value) async {}

  @override
  Future<void> setPuzzleReminder(bool value) async {}

  @override
  Future<void> setSkipFilledCells(bool value) async {}

  @override
  Future<void> setSoundsEnabled(bool value) async {}

  @override
  Future<void> setStreakReminder(bool value) async {}

  @override
  Future<void> setThemeMode(AppThemeMode mode) async {}

  @override
  Future<bool> getCrosshareAutoDownload() async => true;

  @override
  Future<void> setCrosshareAutoDownload(bool value) async {}

  @override
  Future<String> getCrosshareLastDownloadedDate() async => '';

  @override
  Future<void> setCrosshareLastDownloadedDate(String date) async {}

  @override
  Future<String> getCrosshareLastAttemptStatus() async => '';

  @override
  Future<void> setCrosshareLastAttemptStatus(String status) async {}
}
