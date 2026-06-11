import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/presentation/screens/board_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const me = Player(id: 'p-me', displayName: 'Maya', isMe: true);
  const other = Player(id: 'p-other', displayName: 'Noah');
  const weekly = [
    LeaderboardEntry(rank: 1, player: me, cleanSolves: 3, avgClean: '1:10'),
    LeaderboardEntry(rank: 2, player: other, cleanSolves: 1, avgClean: '2:05'),
  ];

  Widget harness({
    String? ownerPlayerId,
    Future<void> Function(Player)? onRemove,
  }) {
    return MaterialApp(
      home: BoardDetailScreen(
        boardName: 'Friday Crew',
        playerCount: 2,
        weekly: weekly,
        lifetime: weekly,
        ownerPlayerId: ownerPlayerId,
        onRemoveMember: onRemove,
      ),
    );
  }

  testWidgets('owner long-presses a member to trigger removal', (tester) async {
    Player? removed;
    await tester.pumpWidget(
      harness(ownerPlayerId: 'p-me', onRemove: (p) async => removed = p),
    );

    await tester.longPress(find.text('Noah'));
    await tester.pumpAndSettle();

    expect(removed?.id, 'p-other');
    // The owner's own row shows the owner glyph.
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('long-press is inert for non-owners and on your own row',
      (tester) async {
    Player? removed;
    await tester.pumpWidget(
      harness(ownerPlayerId: 'p-other', onRemove: (p) async => removed = p),
    );

    // Not the owner: long-pressing another member does nothing.
    await tester.longPress(find.text('Noah'));
    await tester.pumpAndSettle();
    expect(removed, isNull);

    // Owner case, own row: still inert.
    await tester.pumpWidget(
      harness(ownerPlayerId: 'p-me', onRemove: (p) async => removed = p),
    );
    await tester.longPress(find.text('Maya'));
    await tester.pumpAndSettle();
    expect(removed, isNull);
  });
}
