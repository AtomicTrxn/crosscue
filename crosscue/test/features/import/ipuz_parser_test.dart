import 'dart:convert';
import 'dart:typed_data';

import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/core/utils/result.dart';
import 'package:crosscue/features/import/data/parsers/ipuz_parser.dart';
import 'package:crosscue/features/import/domain/models/parse_error.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixture helpers (all synthesized — no licensed puzzle content)
// ---------------------------------------------------------------------------

Uint8List _jsonBytes(Object obj) =>
    Uint8List.fromList(utf8.encode(jsonEncode(obj)));

/// Base 3×3 structure reused across many fixtures.
///
/// Grid (all white):
///   A B C   (0,0)=1  (0,1)=2  (0,2)=3
///   D E F   (1,0)=4
///   G H I   (2,0)=5
Map<String, dynamic> _base3x3({
  String title = 'Test Puzzle',
  String author = 'Test Author',
  String copyright = '© 2026',
  List<List<dynamic>>? solution,
  List<List<dynamic>>? puzzle,
  Map<String, dynamic>? clues,
  Map<String, dynamic> extra = const {},
}) {
  return {
    'version': 'http://ipuz.org/v2',
    'kind': ['http://ipuz.org/crossword#1'],
    'title': title,
    'author': author,
    'copyright': copyright,
    'dimensions': {'width': 3, 'height': 3},
    'puzzle': puzzle ??
        [
          [
            {'cell': 1},
            {'cell': 2},
            {'cell': 3}
          ],
          [
            {'cell': 4},
            0,
            0
          ],
          [
            {'cell': 5},
            0,
            0
          ],
        ],
    'solution': solution ??
        [
          ['A', 'B', 'C'],
          ['D', 'E', 'F'],
          ['G', 'H', 'I'],
        ],
    'clues': clues ??
        {
          'Across': [
            [1, '1 Across'],
            [4, '4 Across'],
            [5, '5 Across'],
          ],
          'Down': [
            [1, '1 Down'],
            [2, '2 Down'],
            [3, '3 Down'],
          ],
        },
    ...extra,
  };
}

Uint8List _minimal3x3() => _jsonBytes(_base3x3());

/// Clues with lowercase direction keys ('across'/'down').
Uint8List _lowercaseClueKeys() => _jsonBytes(_base3x3(
      clues: {
        'across': [
          [1, '1 Across'],
          [4, '4 Across'],
          [5, '5 Across'],
        ],
        'down': [
          [1, '1 Down'],
          [2, '2 Down'],
          [3, '3 Down'],
        ],
      },
    ));

/// Clues with all-uppercase direction keys ('ACROSS'/'DOWN').
Uint8List _uppercaseClueKeys() => _jsonBytes(_base3x3(
      clues: {
        'ACROSS': [
          [1, '1 Across'],
          [4, '4 Across'],
          [5, '5 Across'],
        ],
        'DOWN': [
          [1, '1 Down'],
          [2, '2 Down'],
          [3, '3 Down'],
        ],
      },
    ));

/// Clues in object format {number, clue}.
Uint8List _objectFormatClues() => _jsonBytes(_base3x3(
      clues: {
        'Across': [
          {'number': 1, 'clue': '1 Across (obj)'},
          {'number': 4, 'clue': '4 Across (obj)'},
          {'number': 5, 'clue': '5 Across (obj)'},
        ],
        'Down': [
          {'number': 1, 'clue': '1 Down (obj)'},
          {'number': 2, 'clue': '2 Down (obj)'},
          {'number': 3, 'clue': '3 Down (obj)'},
        ],
      },
    ));

/// Clues with HTML in the text.
Uint8List _htmlClues() => _jsonBytes(_base3x3(
      clues: {
        'Across': [
          [1, '<b>Bold</b> clue &amp; more'],
          [4, '4 Across'],
          [5, '5 Across'],
        ],
        'Down': [
          [1, '1 Down'],
          [2, '2 Down'],
          [3, '3 Down'],
        ],
      },
    ));

/// Puzzle with 'date' in ISO YYYY-MM-DD format.
Uint8List _withIsoDate() => _jsonBytes(_base3x3(
      extra: {'date': '2026-05-01'},
    ));

/// Puzzle with 'date' in US MM/DD/YYYY format.
Uint8List _withUsDate() => _jsonBytes(_base3x3(
      extra: {'date': '05/01/2026'},
    ));

/// Puzzle with a 'date' that cannot be parsed (stays null, no error).
Uint8List _withBadDate() => _jsonBytes(_base3x3(
      extra: {'date': 'not a date'},
    ));

/// Puzzle with publisher and editor metadata.
Uint8List _withPublisherEditor() => _jsonBytes(_base3x3(
      extra: {
        'intro': 'A fine puzzle',
        'publisher': 'Crossword Co.',
        'editor': 'Ed Itor',
      },
    ));

/// Solution row containing numeric 0 as a black cell.
Uint8List _numericZeroBlack() => _jsonBytes(_base3x3(
      solution: [
        [0, 'B', 'C'],
        ['D', 'E', 'F'],
        ['G', 'H', 'I'],
      ],
      puzzle: [
        [
          '#',
          {'cell': 1},
          {'cell': 2},
        ],
        [
          {'cell': 3},
          0,
          0
        ],
        [
          {'cell': 4},
          0,
          0
        ],
      ],
      clues: {
        'Across': [
          [1, '1 Across'],
          [3, '3 Across'],
          [4, '4 Across'],
        ],
        'Down': [
          [1, '1 Down'],
          [2, '2 Down'],
        ],
      },
    ));

/// Map-valued solution cell where 'value' is numeric (should not be used as answer).
Uint8List _mapCellNumericValue() => _jsonBytes(_base3x3(
      solution: [
        [
          {'cell': 'A', 'value': 1},
          'B',
          'C'
        ],
        ['D', 'E', 'F'],
        ['G', 'H', 'I'],
      ],
    ));

/// Map-valued solution cell where answer is in 'cell' key (rebus).
Uint8List _mapCellRebus() => _jsonBytes(_base3x3(
      solution: [
        [
          {'cell': 'EST'},
          'B',
          'C'
        ],
        ['D', 'E', 'F'],
        ['G', 'H', 'I'],
      ],
    ));

/// Map-valued solution cell where answer is in 'answer' key.
Uint8List _mapCellAnswerKey() => _jsonBytes(_base3x3(
      solution: [
        [
          {'answer': 'X'},
          'B',
          'C'
        ],
        ['D', 'E', 'F'],
        ['G', 'H', 'I'],
      ],
    ));

/// Circle via style.shape == 'circle'.
Uint8List _circleStyleShape() => _jsonBytes(_base3x3(
      puzzle: [
        [
          {
            'cell': 1,
            'style': {'shape': 'circle'}
          },
          {'cell': 2},
          {'cell': 3},
        ],
        [
          {'cell': 4},
          0,
          0
        ],
        [
          {'cell': 5},
          0,
          0
        ],
      ],
    ));

/// Circle via cell-level 'circle: true'.
Uint8List _circleCellTrue() => _jsonBytes(_base3x3(
      puzzle: [
        [
          {'cell': 1, 'circle': true},
          {'cell': 2},
          {'cell': 3},
        ],
        [
          {'cell': 4},
          0,
          0
        ],
        [
          {'cell': 5},
          0,
          0
        ],
      ],
    ));

/// Circle via style.shapebg == 'circle' (existing standard path).
Uint8List _circleStyleShapebg() => _jsonBytes(_base3x3(
      puzzle: [
        [
          {
            'cell': 1,
            'style': {'shapebg': 'circle'}
          },
          {'cell': 2},
          {'cell': 3},
        ],
        [
          {'cell': 4},
          0,
          0
        ],
        [
          {'cell': 5},
          0,
          0
        ],
      ],
    ));

/// 3×3 puzzle with a multi-char rebus solution in cell (0,0).
Uint8List _rebus3x3() => _jsonBytes(_base3x3(
      solution: [
        ['EST', 'B', 'C'],
        ['D', 'E', 'F'],
        ['G', 'H', 'I'],
      ],
      clues: {
        'Across': [
          [1, '1 Across (rebus)'],
          [4, '4 Across'],
          [5, '5 Across'],
        ],
        'Down': [
          [1, '1 Down (rebus)'],
          [2, '2 Down'],
          [3, '3 Down'],
        ],
      },
    ));

/// Barred grid (cell-side bar key in style).
Uint8List _barred3x3() => _jsonBytes(_base3x3(
      puzzle: [
        [
          {
            'cell': 1,
            'style': {'barred': 'R'}
          },
          {'cell': 2},
          {'cell': 3}
        ],
        [
          {'cell': 4},
          0,
          0
        ],
        [
          {'cell': 5},
          0,
          0
        ],
      ],
    ));

/// Solution rows that are not lists (defensive shape validation).
Uint8List _malformedSolutionRow() {
  // Manually construct JSON with a non-list solution row
  const raw =
      '{"version":"http://ipuz.org/v2","kind":["http://ipuz.org/crossword#1"],'
      '"dimensions":{"width":3,"height":3},'
      '"solution":["not a list",["A","B","C"],["D","E","F"]],'
      '"clues":{"Across":[],"Down":[]}}';
  return Uint8List.fromList(utf8.encode(raw));
}

/// Dimensions field is present but not a map.
Uint8List _malformedDimensions() {
  const raw =
      '{"version":"http://ipuz.org/v2","kind":["http://ipuz.org/crossword#1"],'
      '"dimensions":"3x3","solution":[],"clues":{"Across":[],"Down":[]}}';
  return Uint8List.fromList(utf8.encode(raw));
}

/// Clues field is present but not a map.
Uint8List _malformedClues() {
  const raw =
      '{"version":"http://ipuz.org/v2","kind":["http://ipuz.org/crossword#1"],'
      '"dimensions":{"width":3,"height":3},'
      '"solution":[["A","B","C"],["D","E","F"],["G","H","I"]],'
      '"clues":"not a map"}';
  return Uint8List.fromList(utf8.encode(raw));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const parser = IpuzParser();

  // ---------------------------------------------------------------------------
  // canParse
  // ---------------------------------------------------------------------------

  group('canParse', () {
    test('returns true for valid .ipuz bytes', () {
      expect(parser.canParse(_minimal3x3()), isTrue);
    });

    test('returns false for .puz binary bytes', () {
      final puzMagic = Uint8List.fromList([
        0x00,
        0x00,
        0x41,
        0x43,
        0x52,
        0x4F,
        0x53,
        0x53,
        0x26,
        0x44,
        0x4F,
        0x57,
        0x4E,
        0x00,
      ]);
      expect(parser.canParse(puzMagic), isFalse);
    });

    test('returns false for non-crossword JSON', () {
      final bytes = _jsonBytes({
        'kind': ['http://ipuz.org/wordplay#1']
      });
      expect(parser.canParse(bytes), isFalse);
    });

    test('returns false for plain text', () {
      expect(parser.canParse(Uint8List.fromList('hello world'.codeUnits)),
          isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // parse — golden path
  // ---------------------------------------------------------------------------

  group('parse golden path (3×3 all-white grid)', () {
    late dynamic puzzle;

    setUpAll(() {
      final r = parser.parse(_minimal3x3());
      if (r is! Ok) {
        fail('Expected Ok but got Err: ${(r as Err).error}');
      }
      puzzle = r.value;
    });

    test('returns Ok', () {
      expect(parser.parse(_minimal3x3()), isA<Ok>());
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

    test('format is PuzzleFormat.ipuz', () {
      expect(puzzle.metadata.format, equals(PuzzleFormat.ipuz));
    });

    test('sourceId is local_import', () {
      expect(puzzle.metadata.sourceId, equals('local_import'));
    });

    test('all 9 cells are white', () {
      final grid = puzzle.grid;
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 3; c++) {
          expect(grid.cell(r, c).isBlack, isFalse,
              reason: 'cell ($r,$c) should be white');
        }
      }
    });

    test('cell solutions match the solution array', () {
      final grid = puzzle.grid;
      expect(grid.cell(0, 0).solution, equals('A'));
      expect(grid.cell(1, 1).solution, equals('E'));
      expect(grid.cell(2, 2).solution, equals('I'));
    });

    test('clue count is 6', () {
      expect(puzzle.clues.length, equals(6));
    });

    test('1-Across has correct text and start position', () {
      final c = puzzle.clues
          .firstWhere((c) => c.number == 1 && c.direction == Direction.across);
      expect(c.text, equals('1 Across'));
      expect(c.startRow, equals(0));
      expect(c.startCol, equals(0));
    });

    test('2-Down has correct start column', () {
      final c = puzzle.clues
          .firstWhere((c) => c.number == 2 && c.direction == Direction.down);
      expect(c.startCol, equals(1));
    });
  });

  // ---------------------------------------------------------------------------
  // Case-insensitive clue direction keys
  // ---------------------------------------------------------------------------

  group('case-insensitive clue direction keys', () {
    test('lowercase keys (across/down) produce 6 clues', () {
      final r = parser.parse(_lowercaseClueKeys());
      expect(r, isA<Ok>());
      expect((r as Ok).value.clues.length, equals(6));
    });

    test('uppercase keys (ACROSS/DOWN) produce 6 clues', () {
      final r = parser.parse(_uppercaseClueKeys());
      expect(r, isA<Ok>());
      expect((r as Ok).value.clues.length, equals(6));
    });

    test('lowercase 1-Across clue text is preserved', () {
      final r = parser.parse(_lowercaseClueKeys());
      final clue = (r as Ok)
          .value
          .clues
          .firstWhere((c) => c.number == 1 && c.direction == Direction.across);
      expect(clue.text, equals('1 Across'));
    });
  });

  // ---------------------------------------------------------------------------
  // Clue object variants and HTML stripping
  // ---------------------------------------------------------------------------

  group('clue format variants', () {
    test('object-format clues {number, clue} are parsed', () {
      final r = parser.parse(_objectFormatClues());
      expect(r, isA<Ok>());
      final clue = (r as Ok)
          .value
          .clues
          .firstWhere((c) => c.number == 1 && c.direction == Direction.across);
      expect(clue.text, equals('1 Across (obj)'));
    });

    test('HTML tags stripped from clue text', () {
      final r = parser.parse(_htmlClues());
      final clue = (r as Ok)
          .value
          .clues
          .firstWhere((c) => c.number == 1 && c.direction == Direction.across);
      expect(clue.text, equals('Bold clue & more'));
    });
  });

  // ---------------------------------------------------------------------------
  // Publish date parsing
  // ---------------------------------------------------------------------------

  group('publish date parsing', () {
    test('ISO YYYY-MM-DD date is parsed into publishDate', () {
      final r = parser.parse(_withIsoDate());
      final puzzle = (r as Ok).value;
      expect(puzzle.metadata.publishDate, isNotNull);
      expect(puzzle.metadata.publishDate!.year, equals(2026));
      expect(puzzle.metadata.publishDate!.month, equals(5));
      expect(puzzle.metadata.publishDate!.day, equals(1));
    });

    test('US MM/DD/YYYY date is parsed into publishDate', () {
      final r = parser.parse(_withUsDate());
      final puzzle = (r as Ok).value;
      expect(puzzle.metadata.publishDate, isNotNull);
      expect(puzzle.metadata.publishDate!.year, equals(2026));
      expect(puzzle.metadata.publishDate!.month, equals(5));
      expect(puzzle.metadata.publishDate!.day, equals(1));
    });

    test('invalid date string leaves publishDate as null (no error)', () {
      final r = parser.parse(_withBadDate());
      expect(r, isA<Ok>());
      expect((r as Ok).value.metadata.publishDate, isNull);
    });

    test('missing date field leaves publishDate as null', () {
      final r = parser.parse(_minimal3x3());
      expect((r as Ok).value.metadata.publishDate, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Metadata enrichment (publisher / editor into notes)
  // ---------------------------------------------------------------------------

  group('metadata enrichment', () {
    test('publisher and editor are appended to notes', () {
      final r = parser.parse(_withPublisherEditor());
      final puzzle = (r as Ok).value;
      expect(puzzle.metadata.notes, contains('Publisher: Crossword Co.'));
      expect(puzzle.metadata.notes, contains('Editor: Ed Itor'));
      expect(puzzle.metadata.notes, contains('A fine puzzle'));
    });
  });

  // ---------------------------------------------------------------------------
  // Block-cell variants
  // ---------------------------------------------------------------------------

  group('block-cell variants', () {
    test('numeric 0 in solution row is treated as a black cell', () {
      final r = parser.parse(_numericZeroBlack());
      expect(r, isA<Ok>());
      expect((r as Ok).value.grid.cell(0, 0).isBlack, isTrue);
    });

    test('non-black cells adjacent to numeric-0 black are white', () {
      final r = parser.parse(_numericZeroBlack());
      expect((r as Ok).value.grid.cell(0, 1).isBlack, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Map-valued solution cells
  // ---------------------------------------------------------------------------

  group('map-valued solution cells', () {
    test('numeric value field is not used as answer text', () {
      final r = parser.parse(_mapCellNumericValue());
      final puzzle = (r as Ok).value;
      // 'cell' key holds 'A'; numeric 'value' = 1 should be ignored
      expect(puzzle.grid.cell(0, 0).solution, equals('A'));
    });

    test('cell key with rebus string is preserved', () {
      final r = parser.parse(_mapCellRebus());
      final puzzle = (r as Ok).value;
      expect(puzzle.grid.cell(0, 0).solution, equals('EST'));
    });

    test('answer key is used as solution when cell key is absent', () {
      final r = parser.parse(_mapCellAnswerKey());
      final puzzle = (r as Ok).value;
      expect(puzzle.grid.cell(0, 0).solution, equals('X'));
    });
  });

  // ---------------------------------------------------------------------------
  // Rebus (multi-char solution cells via plain string)
  // ---------------------------------------------------------------------------

  group('rebus cells', () {
    test('multi-char solution cell (0,0) is preserved as "EST"', () {
      final r = parser.parse(_rebus3x3());
      expect(r, isA<Ok>());
      expect((r as Ok).value.grid.cell(0, 0).solution, equals('EST'));
    });

    test('single-char cells are unaffected', () {
      final r = parser.parse(_rebus3x3());
      expect((r as Ok).value.grid.cell(0, 1).solution, equals('B'));
    });
  });

  // ---------------------------------------------------------------------------
  // Circle / style variants
  // ---------------------------------------------------------------------------

  group('circle style variants', () {
    test('style.shapebg == circle marks cell as circled', () {
      final r = parser.parse(_circleStyleShapebg());
      expect((r as Ok).value.grid.cell(0, 0).circled, isTrue);
    });

    test('style.shape == circle marks cell as circled', () {
      final r = parser.parse(_circleStyleShape());
      expect((r as Ok).value.grid.cell(0, 0).circled, isTrue);
    });

    test('cell-level circle:true marks cell as circled', () {
      final r = parser.parse(_circleCellTrue());
      expect((r as Ok).value.grid.cell(0, 0).circled, isTrue);
    });

    test('non-circled cells are not circled', () {
      final r = parser.parse(_circleStyleShapebg());
      expect((r as Ok).value.grid.cell(0, 1).circled, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Defensive JSON shape validation
  // ---------------------------------------------------------------------------

  group('defensive JSON shape validation', () {
    test('non-list solution row → Err(missingData)', () {
      final r = parser.parse(_malformedSolutionRow());
      expect(r, isA<Err>());
      expect((r as Err).error, equals(ParseError.missingData));
    });

    test('non-map dimensions → Err(missingData)', () {
      final r = parser.parse(_malformedDimensions());
      expect(r, isA<Err>());
      expect((r as Err).error, equals(ParseError.missingData));
    });

    test('non-map clues → Err(missingData)', () {
      final r = parser.parse(_malformedClues());
      expect(r, isA<Err>());
      expect((r as Err).error, equals(ParseError.missingData));
    });
  });

  // ---------------------------------------------------------------------------
  // Error cases
  // ---------------------------------------------------------------------------

  group('error cases', () {
    test('invalid JSON → Err(invalidFormat)', () {
      final bytes = Uint8List.fromList('{not valid json'.codeUnits);
      final r = parser.parse(bytes);
      expect(r, isA<Err>());
      expect((r as Err).error, equals(ParseError.invalidFormat));
    });

    test('missing dimensions → Err(missingData)', () {
      final bytes = _jsonBytes({
        'kind': ['http://ipuz.org/crossword#1'],
        'solution': [[]],
        'clues': {'Across': [], 'Down': []},
      });
      final r = parser.parse(bytes);
      expect(r, isA<Err>());
      expect((r as Err).error, equals(ParseError.missingData));
    });

    test('missing solution → Err(missingData)', () {
      final bytes = _jsonBytes({
        'kind': ['http://ipuz.org/crossword#1'],
        'dimensions': {'width': 3, 'height': 3},
        'clues': {'Across': [], 'Down': []},
      });
      final r = parser.parse(bytes);
      expect(r, isA<Err>());
      expect((r as Err).error, equals(ParseError.missingData));
    });

    test('oversized file → Err(fileTooLarge)', () {
      final r = parser.parse(Uint8List(5 * 1024 * 1024 + 1));
      expect(r, isA<Err>());
      expect((r as Err).error, equals(ParseError.fileTooLarge));
    });

    test('wrong solution row count → Err(missingData)', () {
      final bytes = _jsonBytes({
        'kind': ['http://ipuz.org/crossword#1'],
        'dimensions': {'width': 3, 'height': 3},
        'solution': [
          ['A', 'B', 'C']
        ],
        'clues': {'Across': [], 'Down': []},
      });
      final r = parser.parse(bytes);
      expect(r, isA<Err>());
      expect((r as Err).error, equals(ParseError.missingData));
    });

    test('barred cell-side data → Err(unsupportedFormat)', () {
      final r = parser.parse(_barred3x3());
      expect(r, isA<Err>());
      expect((r as Err).error, equals(ParseError.unsupportedFormat));
    });
  });
}
