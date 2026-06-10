import 'package:crosscue/features/archive/domain/models/archive_entry.dart';
import 'package:crosscue/features/archive/presentation/widgets/archive_entry_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ArchiveEntry entry({
    int? sessionId = 1,
    String sessionStatus = 'not_started',
    String? completionType,
    int? elapsedMs,
  }) {
    return ArchiveEntry(
      puzzleId: 'p1',
      title: 'Test Puzzle',
      author: 'Setter',
      width: 5,
      height: 5,
      importedAt: DateTime.utc(2026, 6, 1),
      sessionId: sessionId,
      sessionStatus: sessionStatus,
      completionType: completionType,
      elapsedMs: elapsedMs,
    );
  }

  Future<ArchiveEntryStatus> resolve(
    WidgetTester tester,
    ArchiveEntry? value,
  ) async {
    late ArchiveEntryStatus status;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            status = ArchiveEntryStatus.of(context, value);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return status;
  }

  testWidgets('a missing entry reads as not started', (tester) async {
    final status = await resolve(tester, null);
    expect(status.icon, Icons.radio_button_unchecked_rounded);
    expect(status.noteLabel, isNull);
  });

  testWidgets('clean solve outranks plain completion', (tester) async {
    final status = await resolve(
      tester,
      entry(sessionStatus: 'completed', completionType: 'clean'),
    );
    expect(status.icon, Icons.star_rounded);
    expect(status.noteLabel, isNull);
  });

  testWidgets('completed solves show the elapsed time', (tester) async {
    final status = await resolve(
      tester,
      entry(
        sessionStatus: 'completed',
        completionType: 'checked',
        elapsedMs: 90000,
      ),
    );
    expect(status.icon, Icons.check_circle_outline_rounded);
    expect(status.noteLabel, 'Completed · 1:30');
  });

  testWidgets('revealed sessions are labeled Revealed', (tester) async {
    final status = await resolve(
      tester,
      entry(sessionStatus: 'revealed', completionType: 'revealed'),
    );
    expect(status.icon, Icons.check_circle_outline_rounded);
    expect(status.noteLabel, 'Revealed');
  });

  testWidgets('in-progress sessions show elapsed time', (tester) async {
    final status = await resolve(
      tester,
      entry(sessionStatus: 'in_progress', elapsedMs: 45000),
    );
    expect(status.icon, Icons.timelapse_rounded);
    expect(status.noteLabel, 'In progress · 0:45');
  });
}
