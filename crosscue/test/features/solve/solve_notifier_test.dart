import 'dart:async';
import 'dart:typed_data';

import 'package:crosscue/core/domain/models/clue.dart';
import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/grid.dart';
import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/core/domain/models/solution_cell.dart';
import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:crosscue/features/import/domain/repositories/import_repository.dart';
import 'package:crosscue/features/import/presentation/providers/import_providers.dart';
import 'package:crosscue/features/settings/domain/models/boot_settings.dart';
import 'package:crosscue/features/settings/domain/repositories/app_settings_repository.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:crosscue/features/solve/domain/models/cell_progress.dart';
import 'package:crosscue/features/solve/domain/models/check_result.dart';
import 'package:crosscue/features/solve/domain/models/focus_position.dart';
import 'package:crosscue/features/solve/domain/repositories/solve_repository.dart';
import 'package:crosscue/features/solve/presentation/notifiers/solve_notifier.dart';
import 'package:crosscue/features/solve/presentation/providers/solve_providers.dart';
import 'package:crosscue/features/stats/domain/models/stats_data.dart';
import 'package:crosscue/features/stats/domain/repositories/stats_repository.dart';
import 'package:crosscue/features/stats/presentation/providers/stats_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(
      solveState.focus,
      const FocusPosition(row: 0, col: 1, direction: Direction.across),
    );
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
    notifier.inputLetter('X');

    notifier.backspace();
    var solveState = container.read(provider).value!;
    expect(
      solveState.focus,
      const FocusPosition(row: 0, col: 1, direction: Direction.across),
    );
    expect(solveState.progress.cell(0, 1).letter, isEmpty);
    expect(solveState.progress.cell(0, 0).letter, equals('A'));

    notifier.backspace();
    solveState = container.read(provider).value!;
    expect(
      solveState.focus,
      const FocusPosition(row: 0, col: 0, direction: Direction.across),
    );
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
        appSettingsProvider
            .overrideWithValue(const _FakeAppSettingsRepository()),
        bootSettingsProvider.overrideWithValue(BootSettings.defaults),
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

  test('checked-correct cells cannot be overwritten or backspaced', () async {
    final puzzle = _puzzle();
    final container = _containerFor(puzzle, _checkedCorrectProgress());
    addTearDown(container.dispose);

    final provider = solveProvider(Uri.encodeComponent(puzzle.id));
    await container.read(provider.future);

    final notifier = container.read(provider.notifier);
    expect(notifier.inputLetter('Z'), isFalse);
    notifier.backspace();

    final solveState = container.read(provider).value!;
    expect(solveState.progress.cell(0, 0).letter, equals('A'));
    expect(
      solveState.progress.cell(0, 0).state,
      CellState.checkedCorrect,
    );
  });

  test('tapping filled cells keeps focus on the tapped cell', () async {
    final puzzle = _crossingPuzzle();
    final container = _containerFor(puzzle, _crossingProgress());
    addTearDown(container.dispose);

    final provider = solveProvider(Uri.encodeComponent(puzzle.id));
    await container.read(provider.future);

    final focus = container.read(provider.notifier).tapCell(0, 1);

    expect(
      focus,
      const FocusPosition(row: 0, col: 1, direction: Direction.down),
    );
  });

  test('tapping a checked-correct cell moves to perpendicular open cell',
      () async {
    final puzzle = _crossingPuzzle();
    final container = _containerFor(puzzle, _checkedCrossingProgress());
    addTearDown(container.dispose);

    final provider = solveProvider(Uri.encodeComponent(puzzle.id));
    await container.read(provider.future);

    final focus = container.read(provider.notifier).tapCell(0, 1);

    expect(
      focus,
      const FocusPosition(row: 1, col: 1, direction: Direction.down),
    );
  });

  test('skip filled cells wraps within the active word', () async {
    final puzzle = _threeCellPuzzle();
    final container = _containerFor(
      puzzle,
      _skipWrapProgress(),
      skipFilledCells: true,
    );
    addTearDown(container.dispose);

    final provider = solveProvider(Uri.encodeComponent(puzzle.id));
    await container.read(provider.future);
    // Sync sanity-check: settings load synchronously from bootSettingsProvider.
    expect(container.read(skipFilledCellsProvider), isTrue);

    final notifier = container.read(provider.notifier);
    notifier.moveFocusTo(0, 2, Direction.across);
    notifier.inputLetter('C');

    final solveState = container.read(provider).value!;
    expect(
      solveState.focus,
      const FocusPosition(row: 0, col: 1, direction: Direction.across),
    );
  });

  test('completing a word advances to the next incomplete clue', () async {
    final puzzle = _twoWordPuzzle();
    final container = _containerFor(puzzle, _twoWordAlmostCompleteProgress());
    addTearDown(container.dispose);

    final provider = solveProvider(Uri.encodeComponent(puzzle.id));
    await container.read(provider.future);

    final notifier = container.read(provider.notifier);
    notifier.moveFocusTo(0, 1, Direction.across);
    notifier.inputLetter('B');

    final solveState = container.read(provider).value!;
    expect(
      solveState.focus,
      const FocusPosition(row: 1, col: 0, direction: Direction.across),
    );
  });

  // ----------------------------------------------------------------------
  // Rebus entry — see docs/architecture/rebus-entry.md
  // ----------------------------------------------------------------------

  test('inputRebus normalizes and ignores empty input', () async {
    final puzzle = _puzzle();
    final container = _containerFor(puzzle, _blankProgress());
    addTearDown(container.dispose);
    final provider = solveProvider(Uri.encodeComponent(puzzle.id));
    await container.read(provider.future);

    final notifier = container.read(provider.notifier);
    expect(notifier.inputRebus(''), isFalse);
    expect(notifier.inputRebus('   '), isFalse);
    expect(container.read(provider).value!.progress.cell(0, 0).letter, isEmpty);
  });

  test('inputRebus with a single character delegates to inputLetter', () async {
    // Round-trip safety: a 1-char rebus submission should behave identically
    // to typing that letter, so the rebus dialog is never a dead end for
    // users who change their mind.
    final puzzle = _puzzle();
    final container = _containerFor(puzzle, _blankProgress());
    addTearDown(container.dispose);
    final provider = solveProvider(Uri.encodeComponent(puzzle.id));
    await container.read(provider.future);

    final notifier = container.read(provider.notifier);
    notifier.inputRebus('a');

    final solveState = container.read(provider).value!;
    expect(solveState.progress.cell(0, 0).letter, equals('A'));
    expect(
      solveState.focus,
      const FocusPosition(row: 0, col: 1, direction: Direction.across),
    );
  });

  test('inputRebus caps overlong input at 6 characters', () async {
    final puzzle = _puzzle();
    final container = _containerFor(puzzle, _blankProgress());
    addTearDown(container.dispose);
    final provider = solveProvider(Uri.encodeComponent(puzzle.id));
    await container.read(provider.future);

    container.read(provider.notifier).inputRebus('abcdefghij');

    expect(
      container.read(provider).value!.progress.cell(0, 0).letter,
      equals('ABCDEF'),
    );
  });

  test('inputRebus accepts "/" for bidirectional rebuses', () async {
    final puzzle = _puzzle();
    final container = _containerFor(puzzle, _blankProgress());
    addTearDown(container.dispose);
    final provider = solveProvider(Uri.encodeComponent(puzzle.id));
    await container.read(provider.future);

    container.read(provider.notifier).inputRebus('pb/au');

    expect(
      container.read(provider).value!.progress.cell(0, 0).letter,
      equals('PB/AU'),
    );
  });

  test('checkCell marks a first-letter rebus entry as correct', () async {
    // checkCells must agree with the completion rule so users don't see a
    // red ✗ on a "J" entry that completes a JACK rebus.
    final puzzle = _rebusPuzzle();
    final container = _containerFor(puzzle, _blankProgress2x1());
    addTearDown(container.dispose);

    final provider = solveProvider(Uri.encodeComponent(puzzle.id));
    await container.read(provider.future);

    final notifier = container.read(provider.notifier);
    notifier.inputLetter('J');
    notifier.moveFocusTo(0, 0, Direction.across);
    final result = notifier.checkCell();

    expect(result, CheckResult.allCorrect);
    expect(
      container.read(provider).value!.progress.cell(0, 0).state,
      CellState.checkedCorrect,
    );
  });

  test('completion accepts the first letter of a rebus answer', () async {
    // NYT-style forgiving rule (see solution_cell_test.dart for the
    // acceptance table). A solver who never finds the Rebus key can still
    // complete a JACK rebus by typing "J".
    final puzzle = _rebusPuzzle();
    final solveRepository = _FakeSolveRepository(_blankProgress2x1());
    final container = ProviderContainer(
      overrides: [
        importRepositoryProvider
            .overrideWithValue(_FakeImportRepository(puzzle)),
        solveRepositoryProvider.overrideWithValue(solveRepository),
        statsRepositoryProvider.overrideWithValue(_FakeStatsRepository()),
        appSettingsProvider
            .overrideWithValue(const _FakeAppSettingsRepository()),
        bootSettingsProvider.overrideWithValue(BootSettings.defaults),
      ],
    );
    addTearDown(container.dispose);

    final provider = solveProvider(Uri.encodeComponent(puzzle.id));
    await container.read(provider.future);

    final notifier = container.read(provider.notifier);
    notifier.inputLetter('J'); // rebus cell, accepts "J" alone for JACK
    notifier.inputLetter('B'); // normal cell

    final completed = await solveRepository.completed.future;
    expect(completed.status, PuzzleStatus.solved);
    expect(completed.completionType, CompletionType.clean);
  });
}

Puzzle _rebusPuzzle() {
  // 2x1 puzzle: rebus "JACK" in (0,0), plain "B" in (0,1).
  return Puzzle(
    metadata: PuzzleMetadata(
      id: 'test:rebus',
      sourceId: 'test',
      title: 'Rebus',
      author: 'Tester',
      copyright: '',
      format: PuzzleFormat.puz,
      width: 2,
      height: 1,
      importedAt: DateTime.utc(2026),
    ),
    grid: Grid(
      width: 2,
      height: 1,
      cells: const [
        SolutionCell(solution: 'JACK', number: 1),
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

Grid<CellProgress> _blankProgress2x1() {
  return Grid(
    width: 2,
    height: 1,
    cells: const [
      CellProgress.blank,
      CellProgress.blank,
    ],
  );
}

ProviderContainer _containerFor(
  Puzzle puzzle,
  Grid<CellProgress> progress, {
  bool skipFilledCells = false,
}) {
  return ProviderContainer(
    overrides: [
      importRepositoryProvider.overrideWithValue(_FakeImportRepository(puzzle)),
      solveRepositoryProvider.overrideWithValue(_FakeSolveRepository(progress)),
      statsRepositoryProvider.overrideWithValue(_FakeStatsRepository()),
      appSettingsProvider.overrideWithValue(
        _FakeAppSettingsRepository(skipFilledCells: skipFilledCells),
      ),
      bootSettingsProvider.overrideWithValue(
        BootSettings(
          hasSeenOnboarding: true,
          themeMode: BootSettings.defaults.themeMode,
          hapticsEnabled: BootSettings.defaults.hapticsEnabled,
          soundsEnabled: BootSettings.defaults.soundsEnabled,
          colorblindMode: BootSettings.defaults.colorblindMode,
          skipFilledCells: skipFilledCells,
          crashReporting: BootSettings.defaults.crashReporting,
          crosshareAutoDownload: BootSettings.defaults.crosshareAutoDownload,
        ),
      ),
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

Grid<CellProgress> _checkedCorrectProgress() {
  return Grid(
    width: 2,
    height: 1,
    cells: const [
      CellProgress(letter: 'A', state: CellState.checkedCorrect),
      CellProgress.blank,
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

Puzzle _crossingPuzzle() {
  return Puzzle(
    metadata: PuzzleMetadata(
      id: 'test:crossing',
      sourceId: 'test',
      title: 'Crossing',
      author: 'Tester',
      copyright: '',
      format: PuzzleFormat.puz,
      width: 3,
      height: 3,
      importedAt: DateTime.utc(2026),
    ),
    grid: Grid(
      width: 3,
      height: 3,
      cells: const [
        SolutionCell(solution: 'C', number: 1),
        SolutionCell(solution: 'A', number: 2),
        SolutionCell(solution: 'T'),
        SolutionCell.black,
        SolutionCell(solution: 'R'),
        SolutionCell.black,
        SolutionCell.black,
        SolutionCell(solution: 'T'),
        SolutionCell.black,
      ],
    ),
    clues: const [
      Clue(
        number: 1,
        direction: Direction.across,
        text: 'Across',
        startRow: 0,
        startCol: 0,
        length: 3,
      ),
      Clue(
        number: 2,
        direction: Direction.down,
        text: 'Down',
        startRow: 0,
        startCol: 1,
        length: 3,
      ),
    ],
  );
}

Grid<CellProgress> _crossingProgress() {
  return Grid(
    width: 3,
    height: 3,
    cells: const [
      CellProgress(letter: 'C'),
      CellProgress(letter: 'A'),
      CellProgress(letter: 'T'),
      CellProgress.blank,
      CellProgress.blank,
      CellProgress.blank,
      CellProgress.blank,
      CellProgress.blank,
      CellProgress.blank,
    ],
  );
}

Grid<CellProgress> _checkedCrossingProgress() {
  return Grid(
    width: 3,
    height: 3,
    cells: const [
      CellProgress(letter: 'C'),
      CellProgress(letter: 'A', state: CellState.checkedCorrect),
      CellProgress(letter: 'T'),
      CellProgress.blank,
      CellProgress.blank,
      CellProgress.blank,
      CellProgress.blank,
      CellProgress.blank,
      CellProgress.blank,
    ],
  );
}

Puzzle _threeCellPuzzle() {
  return Puzzle(
    metadata: PuzzleMetadata(
      id: 'test:three-cell',
      sourceId: 'test',
      title: 'Three Cell',
      author: 'Tester',
      copyright: '',
      format: PuzzleFormat.puz,
      width: 3,
      height: 1,
      importedAt: DateTime.utc(2026),
    ),
    grid: Grid(
      width: 3,
      height: 1,
      cells: const [
        SolutionCell(solution: 'A', number: 1),
        SolutionCell(solution: 'B', number: 2),
        SolutionCell(solution: 'C', number: 3),
      ],
    ),
    clues: const [
      Clue(
        number: 1,
        direction: Direction.across,
        text: 'Across',
        startRow: 0,
        startCol: 0,
        length: 3,
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
      Clue(
        number: 3,
        direction: Direction.down,
        text: 'C down',
        startRow: 0,
        startCol: 2,
        length: 1,
      ),
    ],
  );
}

Grid<CellProgress> _skipWrapProgress() {
  return Grid(
    width: 3,
    height: 1,
    cells: const [
      CellProgress(letter: 'A'),
      CellProgress.blank,
      CellProgress.blank,
    ],
  );
}

Puzzle _twoWordPuzzle() {
  return Puzzle(
    metadata: PuzzleMetadata(
      id: 'test:two-word',
      sourceId: 'test',
      title: 'Two Word',
      author: 'Tester',
      copyright: '',
      format: PuzzleFormat.puz,
      width: 2,
      height: 2,
      importedAt: DateTime.utc(2026),
    ),
    grid: Grid(
      width: 2,
      height: 2,
      cells: const [
        SolutionCell(solution: 'A', number: 1),
        SolutionCell(solution: 'B', number: 2),
        SolutionCell(solution: 'C', number: 3),
        SolutionCell(solution: 'D', number: 4),
      ],
    ),
    clues: const [
      Clue(
        number: 1,
        direction: Direction.across,
        text: 'First across',
        startRow: 0,
        startCol: 0,
        length: 2,
      ),
      Clue(
        number: 3,
        direction: Direction.across,
        text: 'Second across',
        startRow: 1,
        startCol: 0,
        length: 2,
      ),
    ],
  );
}

Grid<CellProgress> _twoWordAlmostCompleteProgress() {
  return Grid(
    width: 2,
    height: 2,
    cells: const [
      CellProgress(letter: 'A'),
      CellProgress.blank,
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
  Stream<List<PuzzleMetadata>> watchAllMetadata() =>
      Stream.value([puzzle.metadata]);

  @override
  Future<Puzzle?> getPuzzle(String id) async => id == puzzle.id ? puzzle : null;

  @override
  Future<ImportJobResult> importBytes(
    Uint8List bytes, {
    String sourceId = 'local_import',
    String? sourcePuzzleId,
    DateTime? publishDate,
  }) async =>
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
      status: PuzzleStatus.inProgress,
      elapsedMs: 0,
      isPaused: false,
      isResumed: false,
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
  const _FakeAppSettingsRepository({this.skipFilledCells = false});

  final bool skipFilledCells;

  @override
  Future<BootSettings> loadBootSettings() async => BootSettings(
        hasSeenOnboarding: true,
        themeMode: BootSettings.defaults.themeMode,
        hapticsEnabled: true,
        soundsEnabled: false,
        colorblindMode: BootSettings.defaults.colorblindMode,
        skipFilledCells: skipFilledCells,
        crashReporting: false,
        crosshareAutoDownload: true,
      );

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
  Future<bool> getSkipFilledCells() async => skipFilledCells;

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
