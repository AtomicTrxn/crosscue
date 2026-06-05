import 'dart:io';

import 'package:crosscue/core/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Color Guide engineering reference', () {
    test('matches CrosscueColors constants', () {
      final guide =
          File('../design/Crosscue Color Guide.html').readAsStringSync();
      final rows = _parseEngineeringRows(guide);

      expect(rows.length, greaterThan(20));

      final failures = <String>[];
      for (final row in rows) {
        for (final column in _columns) {
          final expected = _guideColorValue(row.valueFor(column));
          if (expected == null) continue;

          final constantName = _constantNameFor(row.token, column);
          if (constantName == null) continue;

          final actual = _crosscueColorValues[constantName];
          if (actual == null) {
            failures.add('${row.token} ${column.label}: missing $constantName');
          } else if (actual != expected) {
            failures.add(
              '${row.token} ${column.label}: guide $expected != '
              '$constantName $actual',
            );
          }
        }
      }

      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  });
}

const _columns = [
  _Column.light,
  _Column.dark,
  _Column.colorblindLight,
  _Column.colorblindDark,
];

const _tokenConstants = <String, _TokenConstants>{
  'gridBlockedCell': _TokenConstants('gridBlackLight', 'gridBlackDark'),
  'gridEmptyCell': _TokenConstants('gridEmptyLight', 'gridEmptyDark'),
  'gridActiveWord': _TokenConstants('wordHLLight', 'wordHLDark'),
  'gridFocusedCell': _TokenConstants('cellActiveLight', 'cellActiveDark'),
  'gridRevealedCell': _TokenConstants('revealedLight', 'revealedDark'),
  'completedCellBg': _TokenConstants('completedCellBg', 'completedCellBg'),
  'gridNormalLetter': _TokenConstants('onSurface1Light', 'onSurface1Dark'),
  'gridCorrectLetter': _TokenConstants(
    'gridCorrectLetterLight',
    'gridCorrectLetterDark',
    colorblindLight: 'gridCbCorrectLetterLight',
    colorblindDark: 'gridCbCorrectLetterDark',
  ),
  'gridIncorrectLetter': _TokenConstants(
    'gridWrongLetterLight',
    'gridWrongLetterDark',
    colorblindLight: 'gridCbWrongLetterLight',
    colorblindDark: 'gridCbWrongLetterDark',
  ),
  'completedCellFg': _TokenConstants('completedCellFg', 'completedCellFg'),
  'gridInnerBorder': _TokenConstants('gridBorderLight', 'gridBorderDark'),
  'gridOuterBorder': _TokenConstants(
    'gridOuterBorderLight',
    'gridOuterBorderDark',
  ),
  'gridClueNumber': _TokenConstants(
    'gridClueNumberLight',
    'gridClueNumberDark',
  ),
  'background': _TokenConstants('bgLight', 'bgDark'),
  'surface': _TokenConstants('surfaceLight', 'surfaceDark'),
  'divider': _TokenConstants('dividerLight', 'dividerDark'),
  'onSurface1': _TokenConstants('onSurface1Light', 'onSurface1Dark'),
  'onSurface2': _TokenConstants('onSurface2Light', 'onSurface2Dark'),
  'onSurface3': _TokenConstants('onSurface3Light', 'onSurface3Dark'),
  'primary': _TokenConstants('primary', 'primaryLight'),
  'primaryContainer': _TokenConstants('primaryContLight', 'primaryContDark'),
  'keyboardBg': _TokenConstants('keyboardBg', 'keyboardBgDark'),
  'keyDefault': _TokenConstants('keyDefault', 'keyDefaultDark'),
  'keyDelete': _TokenConstants('keyDelete', 'keyDeleteDark'),
  'correct': _TokenConstants('correctLight', 'correctDark'),
  'incorrect': _TokenConstants('incorrectLight', 'incorrectDark'),
  'deepNavy': _TokenConstants('deepNavy', 'deepNavy'),
  'completionOverlay': _TokenConstants('barrierDeepNavy', 'barrierDeepNavy'),
  'difficultyEasy': _TokenConstants('correctLight', 'correctLight'),
  'onbHeroGradStart': _TokenConstants(
    'onbHeroGradStartLight',
    'onbHeroGradStartDark',
  ),
  'onbHeroGradEnd': _TokenConstants(
    'onbHeroGradEndLight',
    'onbHeroGradEndDark',
  ),
  'onbCardSelectedBorder': _TokenConstants('primary', 'primaryLight'),
};

final _crosscueColorValues = <String, int>{
  'primary': _value(CrosscueColors.primary),
  'primaryLight': _value(CrosscueColors.primaryLight),
  'deepNavy': _value(CrosscueColors.deepNavy),
  'surfaceLight': _value(CrosscueColors.surfaceLight),
  'surfaceDark': _value(CrosscueColors.surfaceDark),
  'bgLight': _value(CrosscueColors.bgLight),
  'bgDark': _value(CrosscueColors.bgDark),
  'onSurface1Light': _value(CrosscueColors.onSurface1Light),
  'onSurface2Light': _value(CrosscueColors.onSurface2Light),
  'onSurface3Light': _value(CrosscueColors.onSurface3Light),
  'onSurface1Dark': _value(CrosscueColors.onSurface1Dark),
  'onSurface2Dark': _value(CrosscueColors.onSurface2Dark),
  'onSurface3Dark': _value(CrosscueColors.onSurface3Dark),
  'dividerLight': _value(CrosscueColors.dividerLight),
  'dividerDark': _value(CrosscueColors.dividerDark),
  'cellActiveLight': _value(CrosscueColors.cellActiveLight),
  'cellActiveDark': _value(CrosscueColors.cellActiveDark),
  'wordHLLight': _value(CrosscueColors.wordHLLight),
  'wordHLDark': _value(CrosscueColors.wordHLDark),
  'cluePanelCrossRowLight': _value(CrosscueColors.cluePanelCrossRowLight),
  'cluePanelCrossRowDark': _value(CrosscueColors.cluePanelCrossRowDark),
  'gridBlackLight': _value(CrosscueColors.gridBlackLight),
  'gridBlackDark': _value(CrosscueColors.gridBlackDark),
  'gridBorderLight': _value(CrosscueColors.gridBorderLight),
  'gridBorderDark': _value(CrosscueColors.gridBorderDark),
  'gridOuterBorderLight': _value(CrosscueColors.gridOuterBorderLight),
  'gridOuterBorderDark': _value(CrosscueColors.gridOuterBorderDark),
  'gridEmptyLight': _value(CrosscueColors.gridEmptyLight),
  'gridEmptyDark': _value(CrosscueColors.gridEmptyDark),
  'gridClueNumberLight': _value(CrosscueColors.gridClueNumberLight),
  'gridClueNumberDark': _value(CrosscueColors.gridClueNumberDark),
  'gridCorrectLetterLight': _value(CrosscueColors.gridCorrectLetterLight),
  'gridWrongLetterLight': _value(CrosscueColors.gridWrongLetterLight),
  'gridCbCorrectLetterLight': _value(CrosscueColors.gridCbCorrectLetterLight),
  'gridCbWrongLetterLight': _value(CrosscueColors.gridCbWrongLetterLight),
  'gridCorrectLetterDark': _value(CrosscueColors.gridCorrectLetterDark),
  'gridCorrectFocusedLetterDark': _value(
    CrosscueColors.gridCorrectFocusedLetterDark,
  ),
  'gridWrongLetterDark': _value(CrosscueColors.gridWrongLetterDark),
  'gridCbCorrectLetterDark': _value(CrosscueColors.gridCbCorrectLetterDark),
  'gridCbWrongLetterDark': _value(CrosscueColors.gridCbWrongLetterDark),
  'correctLight': _value(CrosscueColors.correctLight),
  'correctDark': _value(CrosscueColors.correctDark),
  'incorrectLight': _value(CrosscueColors.incorrectLight),
  'incorrectDark': _value(CrosscueColors.incorrectDark),
  'actionDestructiveLight': _value(CrosscueColors.actionDestructiveLight),
  'actionDestructiveDark': _value(CrosscueColors.actionDestructiveDark),
  'revealedLight': _value(CrosscueColors.revealedLight),
  'revealedDark': _value(CrosscueColors.revealedDark),
  'completedCellBg': _value(CrosscueColors.completedCellBg),
  'completedCellFg': _value(CrosscueColors.completedCellFg),
  'barrierDeepNavy': _value(CrosscueColors.barrierDeepNavy),
  'primaryContLight': _value(CrosscueColors.primaryContLight),
  'primaryContDark': _value(CrosscueColors.primaryContDark),
  'keyboardBg': _value(CrosscueColors.keyboardBg),
  'keyboardBgDark': _value(CrosscueColors.keyboardBgDark),
  'keyDefault': _value(CrosscueColors.keyDefault),
  'keyDefaultDark': _value(CrosscueColors.keyDefaultDark),
  'keyDelete': _value(CrosscueColors.keyDelete),
  'keyDeleteDark': _value(CrosscueColors.keyDeleteDark),
  'dialogSurfaceLight': _value(CrosscueColors.dialogSurfaceLight),
  'dialogSurfaceDark': _value(CrosscueColors.dialogSurfaceDark),
  'dialogScrimLight': _value(CrosscueColors.dialogScrimLight),
  'dialogScrimDark': _value(CrosscueColors.dialogScrimDark),
  'toggleTrackOffLight': _value(CrosscueColors.toggleTrackOffLight),
  'toggleTrackOffDark': _value(CrosscueColors.toggleTrackOffDark),
  'segmentedControlBgLight': _value(CrosscueColors.segmentedControlBgLight),
  'segmentedControlBgDark': _value(CrosscueColors.segmentedControlBgDark),
  'onboardingBackground': _value(CrosscueColors.onboardingBackground),
  'onboardingDotInactive': _value(CrosscueColors.onboardingDotInactive),
  'onbHeroGradStartLight': _value(CrosscueColors.onbHeroGradStartLight),
  'onbHeroGradEndLight': _value(CrosscueColors.onbHeroGradEndLight),
  'onbHeroGradStartDark': _value(CrosscueColors.onbHeroGradStartDark),
  'onbHeroGradEndDark': _value(CrosscueColors.onbHeroGradEndDark),
  'buttonDisabledBgLight': _value(CrosscueColors.buttonDisabledBgLight),
  'buttonDisabledBgDark': _value(CrosscueColors.buttonDisabledBgDark),
  'buttonDisabledTextLight': _value(CrosscueColors.buttonDisabledTextLight),
  'buttonDisabledTextDark': _value(CrosscueColors.buttonDisabledTextDark),
  'seed': _value(CrosscueColors.seed),
};

List<_EngineeringRow> _parseEngineeringRows(String guide) {
  final engMatch = RegExp(
    r'const ENG=\[(.*?)\];',
    dotAll: true,
  ).firstMatch(guide);
  expect(engMatch, isNotNull, reason: 'Could not find const ENG in guide');

  final objectPattern = RegExp(r'\{([^{}]*)\}', dotAll: true);
  return objectPattern
      .allMatches(engMatch!.group(1)!)
      .map((match) => _parseRow(match.group(1)!))
      .whereType<_EngineeringRow>()
      .toList();
}

_EngineeringRow? _parseRow(String objectBody) {
  final fields = <String, String>{};
  final fieldPattern = RegExp(r"(\w+):(?:'([^']*)'|(null|true|false))");
  for (final match in fieldPattern.allMatches(objectBody)) {
    fields[match.group(1)!] = match.group(2) ?? match.group(3)!;
  }

  final token = fields['tok'];
  if (token == null) return null;
  return _EngineeringRow(
    token: token,
    light: fields['l'],
    dark: fields['d'],
    colorblindLight: fields['cbl'],
    colorblindDark: fields['cbd'],
  );
}

int? _guideColorValue(String? value) {
  if (value == null || value == 'null' || value == 'REMOVED') return null;

  final hexMatch = RegExp(r'#([0-9A-Fa-f]{6})').firstMatch(value);
  if (hexMatch == null) return null;

  final rgb = int.parse(hexMatch.group(1)!, radix: 16);
  final opacityMatch = RegExp(r'@(\d+)%').firstMatch(value);
  final alpha = opacityMatch == null
      ? 0xFF
      : (255 * int.parse(opacityMatch.group(1)!) / 100).round();
  return (alpha << 24) | rgb;
}

String? _constantNameFor(String token, _Column column) {
  final constants = _tokenConstants[token];
  if (constants == null) return null;

  return switch (column) {
    _Column.light => constants.light,
    _Column.dark => constants.dark,
    _Column.colorblindLight => constants.colorblindLight,
    _Column.colorblindDark => constants.colorblindDark,
  };
}

int _value(Color color) => color.toARGB32();

enum _Column {
  light('Light'),
  dark('Dark'),
  colorblindLight('CB Light'),
  colorblindDark('CB Dark');

  const _Column(this.label);

  final String label;
}

class _TokenConstants {
  const _TokenConstants(
    this.light,
    this.dark, {
    this.colorblindLight,
    this.colorblindDark,
  });

  final String light;
  final String dark;
  final String? colorblindLight;
  final String? colorblindDark;
}

class _EngineeringRow {
  const _EngineeringRow({
    required this.token,
    required this.light,
    required this.dark,
    required this.colorblindLight,
    required this.colorblindDark,
  });

  final String token;
  final String? light;
  final String? dark;
  final String? colorblindLight;
  final String? colorblindDark;

  String? valueFor(_Column column) => switch (column) {
        _Column.light => light,
        _Column.dark => dark,
        _Column.colorblindLight => colorblindLight,
        _Column.colorblindDark => colorblindDark,
      };
}
