// Unit tests for SharedPuzzleImportService — the OS share-sheet import path
// (#296 Phase 3). Covers: valid puzzle bytes -> success route, garbage bytes
// -> failure with the mapped ParseError message, an oversized file ->
// rejected before its bytes are read, duplicate -> a distinguishable
// result, and the cheap extension-based early-out (skips obviously
// irrelevant files without reading them, but does NOT reject extension-less
// files, which fall through to real content-sniffing).
//
// Uses a hand-written fake ImportRepository (the project has no mock
// framework, matching crosshare_auto_download_service_test.dart's
// convention) plus real temp files on disk, since the service reads bytes
// via dart:io.

import 'dart:io';
import 'dart:typed_data';

import 'package:crosscue/core/domain/models/puzzle.dart';
import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/features/import/data/services/shared_puzzle_import_service.dart';
import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:crosscue/features/import/domain/models/parse_error.dart';
import 'package:crosscue/features/import/domain/repositories/import_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_handler/share_handler.dart';

import '../../../../helpers/puz_fixture_builder.dart';

/// Fake import repo. Returns a fixed [result] from [importBytes]; records
/// call count so tests can assert whether (and how many times) it was
/// invoked — in particular, that the cheap pre-filters reject obviously
/// irrelevant / oversized shares *before* ever reaching it.
class _FakeImportRepo implements ImportRepository {
  _FakeImportRepo(this.result);

  final ImportJobResult result;
  int calls = 0;

  @override
  Future<ImportJobResult> importBytes(
    Uint8List bytes, {
    String sourceId = 'local_import',
    String? sourcePuzzleId,
    DateTime? publishDate,
  }) async {
    calls++;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

/// Minimal stand-in Puzzle — the service only ever reads `.id` off a
/// [JobSuccess]'s puzzle, to build the solve-screen route.
class _FakePuzzle implements Puzzle {
  _FakePuzzle(this.id);

  @override
  final String id;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('shared_puzzle_import_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<String> writeFile(String name, List<int> bytes) async {
    final file = File('${tempDir.path}/$name');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  group('normalizePath', () {
    test('strips the file:// prefix and percent-decodes (iOS format)', () {
      final service = SharedPuzzleImportService(
        importRepository: _FakeImportRepo(const JobDuplicate()),
      );

      final normalized = service.normalizePath(
        'file:///var/mobile/Containers/Shared/My%20Puzzle.puz',
      );

      expect(normalized, '/var/mobile/Containers/Shared/My Puzzle.puz');
    });

    test('passes a plain filesystem path through unchanged (Android format)',
        () {
      final service = SharedPuzzleImportService(
        importRepository: _FakeImportRepo(const JobDuplicate()),
      );
      const path = '/storage/emulated/0/Download/My Puzzle.puz';

      expect(service.normalizePath(path), path);
    });
  });

  group('importAttachment', () {
    test('valid puzzle bytes route to the solve screen on success', () async {
      final repo = _FakeImportRepo(JobSuccess(_FakePuzzle('puzzle-123')));
      final service = SharedPuzzleImportService(importRepository: repo);
      final path =
          await writeFile('shared.puz', PuzFixtureBuilder.minimal3x3());

      final result = await service.importAttachment(
        SharedAttachment(path: path, type: SharedAttachmentType.file),
      );

      expect(result, isA<SharedImportSuccess>());
      expect(
        (result as SharedImportSuccess).route,
        Routes.solveFor('puzzle-123'),
      );
      expect(repo.calls, 1);
    });

    test(
        'an extension-less file is not rejected by the cheap filter and '
        'still reaches the repository', () async {
      final repo = _FakeImportRepo(JobSuccess(_FakePuzzle('puzzle-456')));
      final service = SharedPuzzleImportService(importRepository: repo);
      final path =
          await writeFile('shared_no_ext', PuzFixtureBuilder.minimal3x3());

      final result = await service.importAttachment(
        SharedAttachment(path: path, type: SharedAttachmentType.file),
      );

      expect(result, isA<SharedImportSuccess>());
      expect(repo.calls, 1);
    });

    test('garbage bytes fail with the mapped ParseError message', () async {
      final repo = _FakeImportRepo(const JobFailure(ParseError.invalidFormat));
      final service = SharedPuzzleImportService(importRepository: repo);
      final path = await writeFile('shared.puz', [1, 2, 3, 4, 5]);

      final result = await service.importAttachment(
        SharedAttachment(path: path, type: SharedAttachmentType.file),
      );

      expect(result, isA<SharedImportFailure>());
      final failure = result as SharedImportFailure;
      expect(failure.error, ParseError.invalidFormat);
      expect(
        failure.error.userMessage,
        'Unrecognised puzzle format. Only .puz and .ipuz files are supported.',
      );
      expect(repo.calls, 1);
    });

    test(
        'a share with an obviously non-puzzle extension is rejected '
        'without calling the repository', () async {
      final repo = _FakeImportRepo(const JobDuplicate());
      final service = SharedPuzzleImportService(importRepository: repo);
      final path = await writeFile('photo.jpg', [1, 2, 3]);

      final result = await service.importAttachment(
        SharedAttachment(path: path, type: SharedAttachmentType.file),
      );

      expect(result, isA<SharedImportFailure>());
      expect((result as SharedImportFailure).error, ParseError.invalidFormat);
      expect(repo.calls, 0);
    });

    test('an oversized file is rejected before its bytes are read', () async {
      final repo = _FakeImportRepo(const JobDuplicate());
      final service = SharedPuzzleImportService(importRepository: repo);
      final oversized = Uint8List(
        SharedPuzzleImportService.maxAttachmentBytes + 1,
      );
      final path = await writeFile('huge.puz', oversized);

      final result = await service.importAttachment(
        SharedAttachment(path: path, type: SharedAttachmentType.file),
      );

      expect(result, isA<SharedImportFailure>());
      expect((result as SharedImportFailure).error, ParseError.fileTooLarge);
      expect(repo.calls, 0);
    });

    test('duplicate is a distinguishable result, not a plain failure',
        () async {
      final repo = _FakeImportRepo(const JobDuplicate());
      final service = SharedPuzzleImportService(importRepository: repo);
      final path =
          await writeFile('shared.puz', PuzFixtureBuilder.minimal3x3());

      final result = await service.importAttachment(
        SharedAttachment(path: path, type: SharedAttachmentType.file),
      );

      expect(result, isA<SharedImportDuplicate>());
      expect(result, isNot(isA<SharedImportFailure>()));
      expect(result, isNot(isA<SharedImportSuccess>()));
    });

    test('a missing file fails gracefully instead of throwing', () async {
      final repo = _FakeImportRepo(const JobDuplicate());
      final service = SharedPuzzleImportService(importRepository: repo);

      final result = await service.importAttachment(
        SharedAttachment(
          path: '${tempDir.path}/does_not_exist.puz',
          type: SharedAttachmentType.file,
        ),
      );

      expect(result, isA<SharedImportFailure>());
      expect((result as SharedImportFailure).error, ParseError.unknown);
      expect(repo.calls, 0);
    });
  });
}
