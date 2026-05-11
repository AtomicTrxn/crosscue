import 'dart:convert';
import 'dart:typed_data';

/// Builds minimal valid ipuz puzzle fixtures for use in tests.
abstract final class IpuzFixture {
  /// A minimal 3×3 all-white ipuz puzzle.
  static Uint8List minimal3x3() {
    const json = '{"version":"http://ipuz.org/v2",'
        '"kind":["http://ipuz.org/crossword#1"],'
        '"dimensions":{"width":3,"height":3},'
        '"title":"Ipuz Puzzle",'
        '"puzzle":[[{"cell":1},{"cell":2},{"cell":3}],'
        '[{"cell":4},{"cell":5},{"cell":6}],'
        '[{"cell":7},{"cell":8},{"cell":9}]],'
        '"solution":[["A","B","C"],["D","E","F"],["G","H","I"]],'
        '"clues":{'
        '"Across":[["1","Clue 1A"],["4","Clue 4A"],["7","Clue 7A"]],'
        '"Down":[["1","Clue 1D"],["2","Clue 2D"],["3","Clue 3D"]]'
        '}}';
    return Uint8List.fromList(utf8.encode(json));
  }
}
