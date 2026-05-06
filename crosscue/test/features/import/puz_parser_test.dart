import 'dart:typed_data';

import 'package:crosscue/core/utils/result.dart';
import 'package:crosscue/features/import/data/parsers/puz_parser.dart';
import 'package:crosscue/features/import/domain/models/parse_error.dart';
import 'package:crosscue/features/solve/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/puz_fixture_builder.dart';

void main() {
  const parser = PuzParser();

  // ---------------------------------------------------------------------------
  // canParse
  // ---------------------------------------------------------------------------

  group('canParse', () {
    test('returns true for valid .puz magic', () {
      expect(parser.canParse(PuzFixtureBuilder.minimal3x3()), isTrue);
    });

    test('returns false for empty bytes', () {
      expect(parser.canParse(Uint8List(0)), isFalse);
    });

    test('returns false when magic is wrong', () {
      expect(parser.canParse(PuzFixtureBuilder.badMagic()), isFalse);
    });

    test('returns false for .ipuz JSON bytes', () {
      const json = '{"kind":["http://ipuz.org/crossword#1"],'
          '"dimensions":{"width":3,"height":3}}';
      expect(parser.canParse(Uint8List.fromList(json.codeUnits)), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // parse — golden path
  // ---------------------------------------------------------------------------

  group('parse golden path (3×3 all-white grid)', () {
    late dynamic puzzle;

    setUpAll(() {
      final r = parser.parse(PuzFixtureBuilder.minimal3x3());
      if (r is! Ok) {
        fail('Expected Ok but got Err: ${(r as Err).error}');
      }
      puzzle = r.value;
    });

    test('returns Ok', () {
      final r = parser.parse(PuzFixtureBuilder.minimal3x3());
      expect(r, isA<Ok>());
    });

    test('grid dimensions are 3×3', () {
      expect(puzzle.metadata.width, equals(3));
      expect(puzzle.metadata.height, equals(3));
    });

    test('title is parsed', () {
      expect(puzzle.metadata.title, equals('Test Puzzle'));
    });

    test('author is parsed', () {
      expect(puzzle.metadata.author, equals('Test Author'));
    });

    test('copyright is parsed', () {
      expect(puzzle.metadata.copyright, equals('© 2026'));
    });

    test('format is PuzzleFormat.puz', () {
      expect(puzzle.metadata.format, equals(PuzzleFormat.puz));
    });

    test('sourceId is local_import', () {
      expect(puzzle.metadata.sourceId, equals('local_import'));
    });

    test('id starts with "local:"', () {
      expect(puzzle.metadata.id, startsWith('local:'));
    });

    test('all 9 cells are white (no black cells)', () {
      final grid = puzzle.grid;
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          expect(grid.cell(r, c).isBlack, isFalse,
              reason: 'cell ($r,$c) should be white');
        }
      }
    });

    test('cell (0,0) solution is A', () {
      expect(puzzle.grid.cell(0, 0).solution, equals('A'));
    });

    test('cell (1,1) solution is E', () {
      expect(puzzle.grid.cell(1, 1).solution, equals('E'));
    });

    test('cell (2,2) solution is I', () {
      expect(puzzle.grid.cell(2, 2).solution, equals('I'));
    });

    test('clue count is 6 (3 across + 3 down)', () {
      expect(puzzle.clues.length, equals(6));
    });

    test('clue (0,0) is 1-Across with text "1-Across"', () {
      final c = puzzle.clues.firstWhere(
          (c) => c.number == 1 && c.direction == Direction.across);
      expect(c.text, equals('1-Across'));
      expect(c.startRow, equals(0));
      expect(c.startCol, equals(0));
      expect(c.length, equals(3));
    });

    test('clue (0,0) is 1-Down with text "1-Down"', () {
      final c = puzzle.clues
          .firstWhere((c) => c.number == 1 && c.direction == Direction.down);
      expect(c.text, equals('1-Down'));
      expect(c.startRow, equals(0));
      expect(c.startCol, equals(0));
      expect(c.length, equals(3));
    });

    test('across clues span the correct rows', () {
      final acrossClues = puzzle.clues
          .where((c) => c.direction == Direction.across)
          .toList();
      expect(acrossClues.map((c) => c.number).toSet(), equals({1, 4, 5}));
    });

    test('down clues span the correct columns', () {
      final downClues = puzzle.clues
          .where((c) => c.direction == Direction.down)
          .toList();
      expect(downClues.map((c) => c.number).toSet(), equals({1, 2, 3}));
    });

    test('same puzzle bytes produce the same id (deterministic)', () {
      final r2 = parser.parse(PuzFixtureBuilder.minimal3x3());
      expect((r2 as Ok).value.metadata.id, equals(puzzle.metadata.id));
    });
  });

  // ---------------------------------------------------------------------------
  // Rebus (GRBS + RTBL extension blocks)
  // ---------------------------------------------------------------------------

  group('rebus cells', () {
    test('cell (0,0) solution is the rebus string "EST"', () {
      final r = parser.parse(PuzFixtureBuilder.rebus3x3());
      final puzzle = (r as Ok).value;
      expect(puzzle.grid.cell(0, 0).solution, equals('EST'));
    });

    test('non-rebus cells keep their single-letter solution', () {
      final r = parser.parse(PuzFixtureBuilder.rebus3x3());
      final puzzle = (r as Ok).value;
      expect(puzzle.grid.cell(0, 1).solution, equals('B'));
    });
  });

  // ---------------------------------------------------------------------------
  // Circles (GEXT extension block, bit 0x10)
  // ---------------------------------------------------------------------------

  group('circled cells', () {
    test('cell (0,0) is circled when GEXT bit 0x10 is set', () {
      final r = parser.parse(PuzFixtureBuilder.circles3x3());
      final puzzle = (r as Ok).value;
      expect(puzzle.grid.cell(0, 0).circled, isTrue);
    });

    test('cell (0,1) is NOT circled', () {
      final r = parser.parse(PuzFixtureBuilder.circles3x3());
      final puzzle = (r as Ok).value;
      expect(puzzle.grid.cell(0, 1).circled, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Error cases
  // ---------------------------------------------------------------------------

  group('error cases', () {
    test('bad magic → Err(invalidFormat)', () {
      final r = parser.parse(PuzFixtureBuilder.badMagic());
      expect(r, isA<Err>());
      expect((r as Err).error, equals(ParseError.invalidFormat));
    });

    test('scrambled tag → Err(unsupportedFormat)', () {
      final r = parser.parse(PuzFixtureBuilder.scrambled());
      expect(r, isA<Err>());
      expect((r as Err).error, equals(ParseError.unsupportedFormat));
    });

    test('truncated file → Err(invalidFormat)', () {
      final r = parser.parse(PuzFixtureBuilder.truncated());
      expect(r, isA<Err>());
      expect((r as Err).error, isIn([ParseError.invalidFormat, ParseError.missingData]));
    });

    test('oversized file → Err(fileTooLarge)', () {
      final r = parser.parse(PuzFixtureBuilder.oversized());
      expect(r, isA<Err>());
      expect((r as Err).error, equals(ParseError.fileTooLarge));
    });

    test('zero-width grid → Err(missingData)', () {
      // Build a file with width=0 to trip the dimension guard.
      final bytes = PuzFixtureBuilder.build(
        width: 3,
        height: 3,
        grid: ['ABC', 'DEF', 'GHI'],
        clueTexts: ['1-Across', '1-Down', '2-Down', '3-Down', '4-Across', '5-Across'],
      );
      // Overwrite width byte to 0
      final copy = Uint8List.fromList(bytes);
      copy[0x2C] = 0;
      final r = parser.parse(copy);
      expect(r, isA<Err>());
      expect((r as Err).error, equals(ParseError.missingData));
    });
  });
}
