import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/core/domain/models/solution_cell.dart';
import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:crosscue/features/import/domain/repositories/import_repository.dart';
import 'package:crosscue/features/import/presentation/providers/import_providers.dart';
import 'package:crosscue/features/settings/domain/repositories/app_settings_repository.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';
import 'package:crosscue/features/solve/domain/models/focus_position.dart';
import 'package:crosscue/features/solve/domain/repositories/solve_repository.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_notifier.dart';
import 'package:crosscue/features/solve/presentation/providers/solve_providers.dart';
import 'package:crosscue/features/stats/domain/models/stats_data.dart';
import 'package:crosscue/features/stats/domain/repositories/stats_repository.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';

void main() {
  test('rebus input writes a multi-letter cell and advances once', () async {
    final puzzle = _puzzle();
    final container = _containerFor(puzzle, _blankProgress());
    addTearDown(container.dispose);

    final provider = solveProvider(Uri.encodeComponent(puzzle.id));
    await container.read(provider.future);

    final wordComplete = container.read(provider.notifier).inputRebus('est');
    final solveState = container.read(provider).value!;

    expect(wordComplete, isFalse);
    expect(solveState.progress.cell(0, 0).letter, equals('EST'));
    expect(solveState.focus,
        const FocusPosition(row: 0, col: 1, direction: Direction.across));
  });

  test('backspace clears current cell before retreating within the word',
      () async {
    final puzzle = _puzzle();
    final container = _containerFor(puzzle, _blankProgress());
    addTearDown(container.dispose);

    final provider = solveProvider(Uri.encodeComponent(puzzle.id));
    await container.read(provider.future);

    final notifier = container.read(provider.notifier);
    notifier.inputLetter('A');
    notifier.inputLetter('B');

    notifier.backspace();
    var solveState = container.read(provider).value!;
    expect(solveState.focus,
        const FocusPosition(row: 0, col: 1, direction: Direction.across));
    expect(solveState.progress.cell(0, 1).letter, isEmpty);
    expect(solveState.progress.cell(0, 0).letter, equals('A'));

    notifier.backspace();
    solveState = container.read(provider).value!;
    expect(solveState.focus,
        const FocusPosition(row: 0, col: 0, direction: Direction.across));
    expect(solveState.progress.cell(0, 0).letter, isEmpty);
  });

  test('checking final correct grid completes the puzzle as checked', () async {
    final puzzle = _puzzle();
    final solveRepository = _FakeSolveRepository(_filledProgress());
    final container = ProviderContainer(
      overrides: [
        importRepositoryProvider
            .overrideWithValue(_FakeImportRepository(puzzle)),
        solveRepositoryProvider.overrideWithValue(solveRepository),
        statsRepositoryProvider.overrideWithValue(_FakeStatsRepository()),
        appSettingsProvider.overrideWithValue(_FakeAppSettingsRepository()),
      ],
    );
    addTearDown(container.dispose);

    final provider = solveProvider(Uri.encodeComponent(puzzle.id));
    await container.read(provider.future);

    final result = container.read(provider.notifier).checkGrid();
    expect(result, CheckResult.allCorrect);

    final completed = await solveRepository.completed.future;
    expect(completed.status, PuzzleStatus.solvedWithHelp);
    expect(completed.completionType, CompletionType.checked);
    expect(container.read(provider).value?.status, PuzzleStatus.solvedWithHelp);
  });
}

ProviderContainer _containerFor(Puzzle puzzle, Grid<CellProgress> progress) {
  return ProviderContainer(
    overrides: [
      importRepositoryProvider.overrideWithValue(_FakeImportRepository(puzzle)),
      solveRepositoryProvider.overrideWithValue(_FakeSolveRepository(progress)),
      statsRepositoryProvider.overrideWithValue(_FakeStatsRepository()),
      appSettingsProvider.overrideWithValue(_FakeAppSettingsRepository()),
    ],
  );
}

Puzzle _puzzle() {
  return Puzzle(
    metadata: PuzzleMetadata(
      id: 'test:puzzle',
      sourceId: 'test',
      title: 'Test',
      author: 'Tester',
      copyright: '',
      format: PuzzleFormat.puz,
      width: 2,
      height: 1,
      totalClues: 3,
      importedAt: DateTime.utc(2026),
    ),
    grid: Grid(
      width: 2,
      height: 1,
      cells: const [
        SolutionCell(solution: 'A', number: 1),
        SolutionCell(solution: 'B', number: 2),
      ],
    ),
    clues: const [
      Clue(
        number: 1,
        direction: Direction.across,
        text: 'Across',
        startRow: 0,
        startCol: 0,
        length: 2,
      ),
      Clue(
        number: 1,
        direction: Direction.down,
        text: 'A down',
        startRow: 0,
        startCol: 0,
        length: 1,
      ),
      Clue(
        number: 2,
        direction: Direction.down,
        text: 'B down',
        startRow: 0,
        startCol: 1,
        length: 1,
      ),
    ],
  );
}

Grid<CellProgress> _filledProgress() {
  return Grid(
    width: 2,
    height: 1,
    cells: const [
      CellProgress(letter: 'A', state: CellState.filled),
      CellProgress(letter: 'B', state: CellState.filled),
    ],
  );
}

Grid<CellProgress> _blankProgress() {
  return Grid(
    width: 2,
    height: 1,
    cells: const [
      CellProgress.blank,
      CellProgress.blank,
    ],
  );
}

final class _FakeImportRepository implements ImportRepository {
  const _FakeImportRepository(this.puzzle);

  final Puzzle puzzle;

  @override
  Future<void> deletePuzzle(String id) async {}

  @override
  Future<List<PuzzleMetadata>> getAllMetadata() async => [puzzle.metadata];

  @override
  Future<Puzzle?> getPuzzle(String id) async => id == puzzle.id ? puzzle : null;

  @override
  Future<ImportJobResult> importBytes(Uint8List bytes) async =>
      ImportJobResult.success(puzzle);
}

final class _FakeSolveRepository implements SolveRepository {
  _FakeSolveRepository(this.progress);

  final Grid<CellProgress> progress;
  final completed = _CompleterCompletion();

  @override
  Future<SessionLoadResult> createOrResumeSession(Puzzle puzzle) async {
    return SessionLoadResult(
      sessionId: 1,
      progress: progress,
      focus: const FocusPosition(row: 0, col: 0, direction: Direction.across),
      elapsedMs: 0,
      isPaused: false,
      isResumed: false,
    );
  }

  @override
  Future<void> markComplete({
    required int sessionId,
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
    completed.complete(
      _CompletedStatus(
        status: status,
        completionType: completionType,
      ),
    );
  }

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
  }) async {}
}

final class _FakeStatsRepository implements StatsRepository {
  @override
  Future<StatsData> getStats() async => StatsData.empty;
}

final class _FakeAppSettingsRepository implements AppSettingsRepository {
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
  Future<ThemeMode> getThemeMode() async => ThemeMode.system;

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
  Future<void> setThemeMode(ThemeMode mode) async {}
}

final class _CompletedStatus {
  const _CompletedStatus({
    required this.status,
    required this.completionType,
  });

  final PuzzleStatus status;
  final CompletionType completionType;
}

final class _CompleterCompletion {
  final _completer = Completer<_CompletedStatus>();

  Future<_CompletedStatus> get future => _completer.future;

  void complete(_CompletedStatus value) {
    if (!_completer.isCompleted) _completer.complete(value);
  }
}
