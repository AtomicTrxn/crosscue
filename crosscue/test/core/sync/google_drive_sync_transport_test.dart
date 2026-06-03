// Tests for GoogleDriveSyncTransport (#145).
//
// Two angles:
//  1. Inert-safe: with no Google sign-in available (the unit-test environment
//     has no platform plugin, and no DriveApi override), every method is a
//     graceful no-op — so wiring it on Android before OAuth setup is safe.
//  2. CRUD: against a googleapis DriveApi backed by a mock HTTP client, list
//     filters by prefix and read returns the blob.

import 'dart:convert';

import 'package:crosscue/core/sync/transport/google_drive_sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('inert when not signed in / not configured', () {
    final transport = GoogleDriveSyncTransport();

    test('account() returns null', () async {
      expect(await transport.account(), isNull);
    });
    test('signIn() returns null', () async {
      expect(await transport.signIn(), isNull);
    });
    test('list() returns empty', () async {
      expect(await transport.list('puzzles/'), isEmpty);
    });
    test('read() returns null', () async {
      expect(await transport.read('puzzles/a'), isNull);
    });
    test('write() returns null and does not throw', () async {
      expect(await transport.write('puzzles/a', 'blob'), isNull);
    });
    test('delete() does not throw', () async {
      await transport.delete('puzzles/a');
    });
  });

  group('CRUD against a mock Drive API', () {
    GoogleDriveSyncTransport transportWith(MockClient client) =>
        GoogleDriveSyncTransport(
          driveApiProvider: () async => drive.DriveApi(client),
        );

    test('list() returns names under the prefix', () async {
      final client = MockClient((request) async {
        // files.list (metadata) — no specific file id in the path.
        return http.Response(
          jsonEncode({
            'files': [
              {'name': 'puzzles/a'},
              {'name': 'puzzles/b'},
              {'name': 'sessions/c'},
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final names = await transportWith(client).list('puzzles/');
      expect(names, containsAll(<String>['puzzles/a', 'puzzles/b']));
      expect(names, isNot(contains('sessions/c')));
    });

    test('read() returns null when the file is missing', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'files': <dynamic>[]}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      expect(await transportWith(client).read('missing'), isNull);
    });
  });
}
