import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/avatar/avatar_picker_sheet.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/avatar/preset_avatars.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/board_sheets.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/confirm_dialogs.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/edit_name_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('display-name sheet disables save while invalid', (tester) async {
    await tester.pumpWidget(
      _SheetHarness(
        onPressed: (context) => showEditNameSheet(context, initial: ''),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final save = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Save'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(save.onPressed, isNull);
    expect(find.text('Enter a display name.'), findsOneWidget);
  });

  testWidgets('profile sheet uses current avatar as change-avatar control',
      (tester) async {
    await tester.pumpWidget(
      _SheetHarness(
        onPressed: (context) => showEditNameSheet(
          context,
          initial: 'Maya',
          currentAvatar: const PlayerAvatar.silhouette(2),
          onChangeAvatar: () async => const PlayerAvatar.silhouette(3),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Display name'), findsNothing);
    expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('profile sheet shows reset-recovery action when provided',
      (tester) async {
    var resetTaps = 0;
    await tester.pumpWidget(
      _SheetHarness(
        onPressed: (context) => showEditNameSheet(
          context,
          initial: 'Maya',
          onResetRecovery: () => resetTaps++,
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Reset recovery code'), findsOneWidget);
    await tester.tap(find.text('Reset recovery code'));
    await tester.pumpAndSettle();
    expect(resetTaps, 1);
  });

  testWidgets('profile sheet hides reset-recovery action by default',
      (tester) async {
    await tester.pumpWidget(
      _SheetHarness(
        onPressed: (context) => showEditNameSheet(context, initial: 'Maya'),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Reset recovery code'), findsNothing);
  });

  testWidgets('avatar picker saves any selected default avatar',
      (tester) async {
    AvatarChoice? result;
    await tester.pumpWidget(
      _SheetHarness(
        onPressed: (context) async {
          result = await showAvatarPickerSheet(context, selected: 1);
          return result;
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('avatar-look-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save avatar'));
    await tester.pumpAndSettle();

    expect(result?.look, 3);
  });

  test('the preset catalog carries the ten chosen looks in order', () {
    expect(
      kPresetAvatars.map((spec) => spec.label).toList(),
      [
        'Sushi',
        'Ravioli',
        'Rainbow',
        'Party hat',
        'Lollipop',
        'Ferris wheel',
        'Cat',
        'Dog',
        'Rabbit',
        'Penguin',
      ],
    );
  });

  testWidgets('avatar picker scrolls to the last preset and saves it',
      (tester) async {
    AvatarChoice? result;
    await tester.pumpWidget(
      _SheetHarness(
        onPressed: (context) async {
          result = await showAvatarPickerSheet(context, selected: 1);
          return result;
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    const lastLook = ValueKey('avatar-look-10');
    // Scroll the grid to its end (its max extent is well under one viewport)
    // so the last row is fully hittable, not just first-pixel visible.
    await tester.drag(find.byType(GridView), const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(lastLook));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save avatar'));
    await tester.pumpAndSettle();

    expect(result?.look, 10);
  });

  testWidgets('avatar picker keeps the add-photo tile after the presets',
      (tester) async {
    await tester.pumpWidget(
      _SheetHarness(
        onPressed: (context) async => showAvatarPickerSheet(context),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(GridView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('avatar-add-photo')), findsOneWidget);
  });

  testWidgets('invite sheet renders full, member, limit, and invalid states',
      (tester) async {
    final cases = <InvitePreview, String>{
      const InvitePreview(
        result: InviteResult.boardFull,
        boardName: 'Full board',
        playerCount: 20,
        daysUntilExpiry: 5,
      ): 'Board is full',
      const InvitePreview(
        result: InviteResult.alreadyMember,
        boardName: 'My board',
        playerCount: 4,
        daysUntilExpiry: 5,
      ): 'Go to board',
      const InvitePreview(
        result: InviteResult.playerLimitReached,
        boardName: 'Limit board',
        playerCount: 4,
        daysUntilExpiry: 5,
      ): 'Leave one to join a new board',
      const InvitePreview(
        result: InviteResult.invalidOrExpired,
        boardName: 'Old board',
        playerCount: 0,
        daysUntilExpiry: 0,
      ): 'This link has expired or is invalid',
    };

    for (final entry in cases.entries) {
      await tester.pumpWidget(
        _SheetHarness(
          onPressed: (context) => showInviteSheet(context, entry.key),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.textContaining(entry.value), findsWidgets);
      await tester.tap(
        find.text(
          entry.key.result == InviteResult.invalidOrExpired
              ? 'Done'
              : 'Not now',
        ),
      );
      await tester.pumpAndSettle();
    }
  });

  testWidgets('confirm dialogs use expected consequence copy', (tester) async {
    await tester.pumpWidget(
      const _SheetHarness(onPressed: showRegenerateDialog),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Regenerate invite link?'), findsOneWidget);
    expect(
      find.textContaining('current link will stop working'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _SheetHarness(
        onPressed: (context) => showLeaveDialog(context, 'Friday Crew'),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Leave Friday Crew?'), findsOneWidget);
    expect(find.text('Leave board'), findsOneWidget);
  });
}

class _SheetHarness extends StatelessWidget {
  const _SheetHarness({required this.onPressed});

  final Future<Object?> Function(BuildContext context) onPressed;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => onPressed(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }
}
