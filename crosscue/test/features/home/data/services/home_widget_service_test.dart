// Unit tests for the home-widget payload builder (#114). Pure/device-free —
// the actual home_widget push needs the iOS extension + App Group (see
// docs/architecture/ios-widget-setup.md), but the JSON contract the widget
// reads is verifiable here, including the additive `leaderboard` slot.

import 'dart:convert';

import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/features/home/data/services/home_widget_service.dart';
import 'package:flutter_test/flutter_test.dart';

PuzzleMetadata _meta(String id) => PuzzleMetadata(
      id: id,
      sourceId: 'local_import',
      title: 'Title $id',
      author: '',
      copyright: '',
      format: PuzzleFormat.ipuz,
      width: 5,
      height: 5,
      importedAt: DateTime(2026, 6, 1),
    );

void main() {
  test('payload carries the versioned schema + a null leaderboard slot', () {
    final payload = buildHomeWidgetPayload(
      currentStreak: 5,
      bestStreak: 9,
      today: _meta('local:abc'),
    );

    expect(payload['version'], kHomeWidgetSchemaVersion);
    expect(payload['streak'], {'current': 5, 'best': 9});

    final today = payload['today']! as Map<String, Object?>;
    expect(today['puzzleId'], 'local:abc');
    expect(today['title'], 'Title local:abc');
    expect(today['route'], startsWith('/solve/'));
    expect(today['route'], contains('local%3Aabc')); // colon URL-encoded

    // Additive contract: the key exists and is null today (becomes an object
    // when the leaderboard ships, #111 — no schema migration).
    expect(payload.containsKey('leaderboard'), isTrue);
    expect(payload['leaderboard'], isNull);
  });

  test('today is null when the library is empty', () {
    final payload = buildHomeWidgetPayload(
      currentStreak: 0,
      bestStreak: 0,
      today: null,
    );
    expect(payload['today'], isNull);
    expect(payload['streak'], {'current': 0, 'best': 0});
  });

  test('payload serializes to JSON without throwing', () {
    final payload = buildHomeWidgetPayload(
      currentStreak: 1,
      bestStreak: 1,
      today: _meta('local:x'),
    );
    expect(() => jsonEncode(payload), returnsNormally);
  });
}
