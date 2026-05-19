import 'package:crosscue/core/domain/models/solution_cell.dart';
import 'package:flutter_test/flutter_test.dart';

/// Acceptance rules from docs/architecture/rebus-entry.md §4.6.
///
/// These tests pin the NYT-aligned behavior:
///   - Exact case-insensitive match wins.
///   - First-letter alone satisfies a single-direction rebus
///     (so a solver who never finds the Rebus key can still complete).
///   - Bidirectional ("PB/AU") rebuses accept either half, reversed
///     canonical, or first letter of either half.
void main() {
  group('SolutionCell.accepts — non-rebus cell', () {
    const cell = SolutionCell(solution: 'A');

    test('matches the exact letter (case-insensitive)', () {
      expect(cell.accepts('A'), isTrue);
      expect(cell.accepts('a'), isTrue);
    });
    test('rejects different letters', () {
      expect(cell.accepts('B'), isFalse);
    });
    test('rejects empty input', () {
      expect(cell.accepts(''), isFalse);
    });
  });

  group('SolutionCell.accepts — single rebus (e.g. JACK)', () {
    const cell = SolutionCell(solution: 'JACK');

    test('matches the full rebus answer', () {
      expect(cell.accepts('JACK'), isTrue);
      expect(cell.accepts('jack'), isTrue);
    });
    test('matches the first letter alone (NYT forgiving rule)', () {
      expect(cell.accepts('J'), isTrue);
      expect(cell.accepts('j'), isTrue);
    });
    test('rejects partial answers that are not the first letter', () {
      expect(cell.accepts('JA'), isFalse);
      expect(cell.accepts('JAC'), isFalse);
      expect(cell.accepts('K'), isFalse);
      expect(cell.accepts('ACK'), isFalse);
    });
    test('rejects unrelated letters', () {
      expect(cell.accepts('X'), isFalse);
    });
  });

  group('SolutionCell.accepts — bidirectional rebus (PB/AU)', () {
    const cell = SolutionCell(solution: 'PB/AU');

    test('matches the canonical combined form', () {
      expect(cell.accepts('PB/AU'), isTrue);
      expect(cell.accepts('pb/au'), isTrue);
    });
    test('matches the reversed combined form', () {
      expect(cell.accepts('AU/PB'), isTrue);
      expect(cell.accepts('au/pb'), isTrue);
    });
    test('matches either half alone', () {
      expect(cell.accepts('PB'), isTrue);
      expect(cell.accepts('AU'), isTrue);
    });
    test('matches the first letter of either half', () {
      expect(cell.accepts('P'), isTrue);
      expect(cell.accepts('A'), isTrue);
    });
    test('rejects other partials and unrelated letters', () {
      expect(cell.accepts('B'), isFalse);
      expect(cell.accepts('U'), isFalse);
      expect(cell.accepts('PA'), isFalse);
      expect(cell.accepts('PB/'), isFalse);
    });
  });

  group('SolutionCell.accepts — black cells and empties', () {
    test('black cells reject everything', () {
      expect(SolutionCell.black.accepts('A'), isFalse);
      expect(SolutionCell.black.accepts('JACK'), isFalse);
    });
    test('empty-solution cells reject everything', () {
      expect(const SolutionCell().accepts('A'), isFalse);
    });
  });
}
