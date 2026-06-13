// Architectural guard tests (#259).
//
// These lock the layer rules from ARCHITECTURE.md mechanically so they can't
// erode by review vigilance alone (the F2 finding — a feature that grew its
// own blanket lint ignores + parallel theme stack — is the cautionary tale).
//
// Each test scans `lib/**` as source text, skipping generated files. All four
// rules hold with EMPTY allowlists today; an allowlist entry may only be added
// with a written justification in the diff.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Every non-generated Dart file under `lib/`, with its repo-relative path.
Iterable<({String path, String contents})> _libDartFiles() sync* {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    fail('Expected to run from the crosscue/ package root.');
  }
  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart') ||
        entity.path.endsWith('.freezed.dart')) {
      continue;
    }
    yield (path: p.relative(entity.path), contents: entity.readAsStringSync());
  }
}

/// True if [relative] is under a `<segment>` directory anywhere in its path.
bool _underDir(String relative, String segment) =>
    p.split(relative).contains(segment);

void main() {
  test('no file under lib/ carries a blanket // ignore_for_file', () {
    // Blanket file-level lint suppression hides real issues across a whole
    // file. Targeted `// ignore:` on a single line is fine; this bans only
    // the file-wide form. Expected allowlist: empty.
    const allowed = <String>{};
    final pattern = RegExp(r'//\s*ignore_for_file\s*:');

    final offenders = [
      for (final f in _libDartFiles())
        if (!allowed.contains(f.path) && pattern.hasMatch(f.contents)) f.path,
    ];

    expect(
      offenders,
      isEmpty,
      reason: 'These files use a blanket `// ignore_for_file:`. Replace with a '
          'targeted `// ignore:` on the specific line, or fix the lint. If a '
          'file genuinely needs the blanket form, add it to `allowed` with a '
          'justification.\n\nOffenders:\n  ${offenders.join('\n  ')}',
    );
  });

  test('domain layer never imports Flutter or Drift', () {
    // ARCHITECTURE.md layer rules: Domain owns models/enums/interfaces and
    // may import nothing outside core/utils. Flutter and Drift are the two
    // that would most easily creep in. `package:meta` is the sanctioned
    // source of annotations like @immutable (code-review finding 13).
    final banned = <RegExp>[
      RegExp(r"import 'package:flutter/"),
      RegExp(r"import 'package:drift/"),
    ];

    final offenders = <String>[];
    for (final f in _libDartFiles()) {
      if (!_underDir(f.path, 'domain')) continue;
      for (final pattern in banned) {
        if (pattern.hasMatch(f.contents)) {
          offenders.add('${f.path} — ${pattern.pattern}');
          break;
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Domain files must not import Flutter or Drift (ARCHITECTURE.md → '
          'Layer Rules). Use `package:meta` for annotations; keep persistence '
          'and widget concerns in the data/presentation layers.\n\n'
          'Offenders:\n  ${offenders.join('\n  ')}',
    );
  });

  test('feature presentation never touches Drift or DB tables directly', () {
    // Presentation reads repositories via providers, never the database. A
    // drift import or a core/database/tables reference in a presentation file
    // means a layer was skipped.
    final banned = <RegExp>[
      RegExp(r"import 'package:drift/"),
      RegExp(r'core/database/tables/'),
    ];

    final offenders = <String>[];
    for (final f in _libDartFiles()) {
      if (!(_underDir(f.path, 'features') &&
          _underDir(f.path, 'presentation'))) {
        continue;
      }
      for (final pattern in banned) {
        if (pattern.hasMatch(f.contents)) {
          offenders.add('${f.path} — ${pattern.pattern}');
          break;
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Presentation files must not import Drift or reference '
          'core/database/tables (ARCHITECTURE.md → Layer Rules). Go through a '
          'repository provider instead.\n\nOffenders:\n  ${offenders.join('\n  ')}',
    );
  });

  test('feature-local theme files are not imported across feature boundaries',
      () {
    // challenge_boards has a presentation/theme adapter over core/theme. It's
    // allowed to exist, but only challenge_boards may import it — nothing else
    // should grow a dependency on another feature's theme (the F2 parallel-
    // theme-stack risk). App-wide tokens live in core/theme.
    final featureThemePattern =
        RegExp(r"import 'package:crosscue/features/([^/]+)/[^']*/theme/");

    final offenders = <String>[];
    for (final f in _libDartFiles()) {
      for (final match in featureThemePattern.allMatches(f.contents)) {
        final ownerFeature = match.group(1)!;
        // OK when the importing file lives in that same feature.
        if (_underDir(f.path, 'features') &&
            p.split(f.path).contains(ownerFeature)) {
          continue;
        }
        offenders.add('${f.path} — imports $ownerFeature theme');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A feature imported another feature\'s presentation/theme. Feature '
          'theme files are feature-local adapters; shared tokens belong in '
          'core/theme.\n\nOffenders:\n  ${offenders.join('\n  ')}',
    );
  });
}
