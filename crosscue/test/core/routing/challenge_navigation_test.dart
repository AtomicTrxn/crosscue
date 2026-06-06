import 'dart:io';

import 'package:crosscue/core/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Challenge replaces Archive in the shell tab labels', () {
    final shell = File('lib/core/routing/app_shell.dart').readAsStringSync();

    expect(shell, contains("label: 'Challenge'"));
    expect(shell, isNot(contains("label: 'Archive'")));
  });

  test('Archive remains available from Settings and Challenge routes exist',
      () {
    final settings =
        File('lib/features/settings/presentation/screens/settings_screen.dart')
            .readAsStringSync();

    expect(settings, contains("title: 'Archive'"));
    expect(settings, contains('Routes.archive'));
    expect(Routes.challenge, '/challenge');
    expect(Routes.challengeJoin, '/challenge/join');
    expect(Routes.challengeBoard('abc'), '/challenge/board/abc');
    expect(Routes.archive, '/archive');
  });
}
