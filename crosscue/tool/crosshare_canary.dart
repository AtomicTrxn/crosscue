// Live canary for the Crosshare scraper (#257).
//
// `CrosshareDownloader` scrapes crosshare.org HTML (`__NEXT_DATA__`), and
// three user-visible features sit on it: the home "Past puzzles" section,
// daily auto-download, and Challenge Boards eligibility — see
// docs/architecture/compatibility.md → "External dependency: Crosshare".
// A Crosshare markup change degrades all three at once, so this tool runs
// the REAL fetch + parse against the live site to turn a user-reported
// outage into a pre-noticed one.
//
// Network-dependent by design: it lives in tool/ and is run by the
// scheduled .github/workflows/crosshare-canary.yml — never from
// `flutter test` (the unit suite stays hermetic).
//
// Run locally:  cd crosscue && dart run tool/crosshare_canary.dart

import 'dart:io';

import 'package:crosscue/core/utils/result.dart';
import 'package:crosscue/features/import/data/downloaders/crosshare_downloader.dart';
import 'package:crosscue/features/import/data/parsers/puz_parser.dart';
import 'package:crosscue/features/import/domain/models/crosshare_entry.dart';
import 'package:dio/dio.dart';

Future<void> main() async {
  final downloader = CrosshareDownloader(dio: Dio());
  final now = DateTime.now().toUtc();

  // 1. The month listing fetches and parses. Near a UTC month boundary the
  //    current month can legitimately be sparse — fall back one month before
  //    declaring the listing broken.
  var entries = await _fetchMonth(downloader, now.year, now.month);
  if (entries.isEmpty) {
    final previous = DateTime.utc(now.year, now.month - 1);
    stdout.writeln(
      'current month empty; falling back to '
      '${previous.year}-${previous.month}',
    );
    entries = await _fetchMonth(downloader, previous.year, previous.month);
  }
  if (entries.isEmpty) {
    _fail('month listing parsed but contained no entries');
  }
  stdout.writeln('month listing OK: ${entries.length} entries');

  // 2. The newest entry's .puz bytes download and parse as a valid puzzle —
  //    exercising the same path the app uses for every import.
  final sorted = [...entries]..sort((a, b) => b.date.compareTo(a.date));
  final newest = sorted.first;
  final bytes = switch (await downloader.downloadById(newest.id)) {
    Ok(:final value) => value,
    Err(:final error) => _fail('downloadById(${newest.id}) failed: $error'),
  };

  const parser = PuzParser();
  if (!parser.canParse(bytes)) {
    _fail('downloaded bytes for ${newest.id} are not a recognizable .puz');
  }
  final puzzle = switch (parser.parse(
    bytes,
    sourceId: 'crosshare_daily_mini',
    sourcePuzzleId: newest.id,
  )) {
    Ok(:final value) => value,
    Err(:final error) => _fail('parse(${newest.id}) failed: $error'),
  };

  stdout.writeln(
    'download + parse OK: "${puzzle.metadata.title}" '
    '(${puzzle.metadata.width}x${puzzle.metadata.height}, '
    'id=${newest.id}, date=${newest.date.toIso8601String()})',
  );
  stdout.writeln('CANARY PASSED');
}

Future<List<CrosshareEntry>> _fetchMonth(
  CrosshareDownloader downloader,
  int year,
  int month,
) async {
  return switch (await downloader.fetchMonth(year, month)) {
    Ok(:final value) => value,
    Err(:final error) => _fail('fetchMonth($year, $month) failed: $error'),
  };
}

Never _fail(String message) {
  stderr.writeln('CANARY FAILED: $message');
  exit(1);
}
