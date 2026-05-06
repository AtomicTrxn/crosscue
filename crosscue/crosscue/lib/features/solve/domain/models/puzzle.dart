import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/models/puzzle_metadata.dart';
import 'clue.dart';
import 'grid.dart';
import 'solution_cell.dart';

part 'puzzle.freezed.dart';

/// Full in-memory puzzle: metadata + grid + clues.
///
/// Grid<T> is a plain Dart class (generics are incompatible with Freezed
/// unions), so we wrap it with a custom equality/hashCode pair.
@freezed
abstract class Puzzle with _$Puzzle {
  const Puzzle._(); // enables custom getters

  const factory Puzzle({
    required PuzzleMetadata metadata,
    required Grid<SolutionCell> grid,
    required List<Clue> clues,

    /// Optional notes / instructions from the constructor.
    @Default('') String notes,
  }) = _Puzzle;

  // --- convenience getters ---

  String get id => metadata.id;
  int get width => metadata.width;
  int get height => metadata.height;

  List<Clue> get acrossClues =>
      clues.where((c) => c.direction.name == 'across').toList();

  List<Clue> get downClues =>
      clues.where((c) => c.direction.name == 'down').toList();

  Clue? clueFor(int number, String direction) {
    for (final c in clues) {
      if (c.number == number && c.direction.name == direction) return c;
    }
    return null;
  }
}
