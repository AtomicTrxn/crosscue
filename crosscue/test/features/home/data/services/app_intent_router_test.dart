// Unit tests for resolveAppIntentRoute (#115). Verifies the Dart side accepts
// arbitrary string route tokens (not a closed enum) — literal go_router paths
// pass through unchanged, and the app-state tokens resolve against the archive.

import 'package:crosscue/features/archive/domain/models/archive_entry.dart';
import 'package:crosscue/features/archive/domain/repositories/archive_repository.dart';
import 'package:crosscue/features/home/data/services/app_intent_router.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeArchive implements ArchiveRepository {
  _FakeArchive(this._entries);
  final List<ArchiveEntry> _entries;

  @override
  Future<List<ArchiveEntry>> getArchiveEntries() async => _entries;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

ArchiveEntry _entry(
  String id, {
  String status = 'not_started',
  DateTime? lastPlayed,
}) =>
    ArchiveEntry(
      puzzleId: id,
      title: 'Title $id',
      author: '',
      width: 5,
      height: 5,
      importedAt: DateTime(2026, 6, 1),
      sessionStatus: status,
      lastPlayedAt: lastPlayed,
    );

void main() {
  test('a literal go_router path passes straight through (additive contract)',
      () async {
    final route = await resolveAppIntentRoute(
      '/leaderboard/daily',
      archive: _FakeArchive([]),
    );
    expect(route, '/leaderboard/daily');
  });

  test('stats → /stats', () async {
    expect(
      await resolveAppIntentRoute('stats', archive: _FakeArchive([])),
      '/stats',
    );
  });

  test('today → the most-recent puzzle\'s solve route', () async {
    // getArchiveEntries is ordered import-desc, so first = today's featured.
    final route = await resolveAppIntentRoute(
      'today',
      archive: _FakeArchive([_entry('local:abc'), _entry('local:zzz')]),
    );
    expect(route, startsWith('/solve/'));
    expect(route, contains('local%3Aabc'));
  });

  test('today → home when the library is empty', () async {
    expect(
      await resolveAppIntentRoute('today', archive: _FakeArchive([])),
      '/',
    );
  });

  test('continue → most-recently-played in-progress puzzle', () async {
    final route = await resolveAppIntentRoute(
      'continue',
      archive: _FakeArchive([
        _entry(
          'local:old',
          status: 'in_progress',
          lastPlayed: DateTime(2026, 6, 1),
        ),
        _entry(
          'local:new',
          status: 'in_progress',
          lastPlayed: DateTime(2026, 6, 3),
        ),
        _entry('local:done', status: 'completed'),
      ]),
    );
    expect(route, contains('local%3Anew'));
  });

  test('continue → archive when nothing is in progress', () async {
    expect(
      await resolveAppIntentRoute(
        'continue',
        archive: _FakeArchive([_entry('local:done', status: 'completed')]),
      ),
      '/archive',
    );
  });

  test('unknown / empty tokens resolve to null (no navigation)', () async {
    expect(
      await resolveAppIntentRoute('bogus', archive: _FakeArchive([])),
      isNull,
    );
    expect(
      await resolveAppIntentRoute('  ', archive: _FakeArchive([])),
      isNull,
    );
  });
}
