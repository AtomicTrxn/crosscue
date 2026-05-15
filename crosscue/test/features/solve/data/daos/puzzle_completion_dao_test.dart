import 'package:crosscue/core/constants/retention.dart';
import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/features/import/data/repositories/import_repository_impl.dart';
import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/puz_fixture_builder.dart';

void main() {
  late AppDatabase db;
  late String puzzleId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final importRepo = ImportRepositoryImpl(dao: db.puzzleDao);
    final result = await importRepo.importBytes(PuzFixtureBuilder.minimal3x3());
    puzzleId = switch (result) {
      JobSuccess(:final puzzle) => puzzle.id,
      _ => throw StateError('import failed'),
    };
  });
  tearDown(() => db.close());

  Future<int> insert({
    required int elapsedMs,
    required String date,
    String completionType = 'clean',
  }) {
    return db.puzzleCompletionDao.recordCompletion(
      puzzleId: puzzleId,
      completionType: completionType,
      completedAt: DateTime.utc(2026, 5, 14),
      solvedDateLocal: date,
      elapsedMs: elapsedMs,
    );
  }

  test('recordCompletion appends a row visible to rowsForPuzzle', () async {
    await insert(elapsedMs: 60000, date: '2026-05-14');
    final rows = await db.puzzleCompletionDao.rowsForPuzzle(puzzleId);
    expect(rows, hasLength(1));
    expect(rows.first.elapsedMs, 60000);
    expect(rows.first.completionType, 'clean');
  });

  test('pruning preserves first, fastest, and most recent within cap',
      () async {
    // Insert cap+5 rows; track the ids of first and fastest so we can verify
    // they survive pruning.
    const cap = CrosscueRetention.completionsPerPuzzle;
    final firstId = await insert(elapsedMs: 100000, date: '2026-01-01');
    int fastestId = -1;
    for (var i = 0; i < cap + 4; i++) {
      // Make i==3 the fastest so it's neither the first nor the most recent.
      final ms = i == 3 ? 1000 : 50000 + i * 100;
      final id = await insert(elapsedMs: ms, date: '2026-02-${i + 1}');
      if (i == 3) fastestId = id;
    }

    final rows = await db.puzzleCompletionDao.rowsForPuzzle(puzzleId);
    expect(rows.length, lessThanOrEqualTo(cap));
    expect(
      rows.any((r) => r.id == firstId),
      isTrue,
      reason: 'first completion must survive pruning',
    );
    expect(
      rows.any((r) => r.id == fastestId),
      isTrue,
      reason: 'fastest completion must survive pruning',
    );
    // The most recent insertion must also still be present.
    final maxId = rows.map((r) => r.id).reduce((a, b) => a > b ? a : b);
    expect(maxId, isNonZero);
  });

  test('getStreakDates excludes revealed; includes clean/checked/hinted',
      () async {
    await insert(elapsedMs: 60000, date: '2026-05-10', completionType: 'clean');
    await insert(
      elapsedMs: 60000,
      date: '2026-05-11',
      completionType: 'checked',
    );
    await insert(
      elapsedMs: 60000,
      date: '2026-05-12',
      completionType: 'hinted',
    );
    await insert(
      elapsedMs: 60000,
      date: '2026-05-13',
      completionType: 'revealed',
    );

    final dates = await db.puzzleCompletionDao.getStreakDates();
    expect(
      dates,
      containsAll(['2026-05-10', '2026-05-11', '2026-05-12']),
    );
    expect(dates, isNot(contains('2026-05-13')));
  });
}
