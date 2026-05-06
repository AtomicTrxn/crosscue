import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:crosscue/core/database/app_database.dart';
import 'package:crosscue/core/database/tables/clues_table.dart';
import 'package:crosscue/core/database/tables/puzzles_table.dart';
import 'package:crosscue/features/solve/domain/models/clue.dart';
import 'package:crosscue/features/solve/domain/models/enums.dart';
import 'package:crosscue/features/solve/domain/models/puzzle.dart';
import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'grid_serializer.dart';

part 'puzzle_dao.g.dart';

@DriftAccessor(tables: [PuzzlesTable, CluesTable])
class PuzzleDao extends DatabaseAccessor<AppDatabase> with _$PuzzleDaoMixin {
  PuzzleDao(super.db);

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Returns all puzzles ordered by import date descending.
  Future<List<PuzzleMetadata>> getAllMetadata() async {
    final rows = await (select(puzzlesTable)
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .get();
    return rows.map(_rowToMetadata).toList();
  }

  /// Returns a single puzzle's metadata, or null if not found.
  Future<PuzzleMetadata?> getMetadata(String id) async {
    final row = await (select(puzzlesTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _rowToMetadata(row);
  }

  /// Checks whether a puzzle with the given [checksum] already exists.
  Future<bool> existsByChecksum(String checksum) async {
    final row = await (select(puzzlesTable)
          ..where((t) => t.checksum.equals(checksum))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// Loads a full [Puzzle] (metadata + clues) from the DB.
  /// Returns null if not found.
  Future<Puzzle?> getPuzzle(String id) async {
    final puzzleRow = await (select(puzzlesTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (puzzleRow == null) return null;

    final clueRows = await (select(cluesTable)
          ..where((t) => t.puzzleId.equals(id))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();

    final metadata = _rowToMetadata(puzzleRow);
    final clues = clueRows.map(_clueRowToClue).toList();

    final json = jsonDecode(puzzleRow.canonicalJson) as Map<String, dynamic>;
    final grid = GridSerializer.fromJson(json);

    return Puzzle(
      metadata: metadata,
      grid: grid,
      clues: clues,
      notes: puzzleRow.notes ?? '',
    );
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Inserts a [Puzzle] into the DB (puzzle row + all clue rows).
  Future<void> insertPuzzle(Puzzle puzzle) async {
    final now = DateTime.now().toUtc();
    final canonical = GridSerializer.encode(puzzle);

    await transaction(() async {
      await into(puzzlesTable).insert(
        PuzzlesTableCompanion.insert(
          id: puzzle.id,
          sourceId: puzzle.metadata.sourceId,
          format: puzzle.metadata.format.name,
          title: puzzle.metadata.title,
          author: Value(puzzle.metadata.author),
          copyright: Value(puzzle.metadata.copyright),
          notes: Value(puzzle.metadata.notes),
          width: puzzle.metadata.width,
          height: puzzle.metadata.height,
          checksum: puzzle.metadata.checksum ?? '',
          difficulty: Value(puzzle.metadata.difficulty),
          canonicalJson: canonical,
          createdAt: now,
          updatedAt: now,
        ),
      );

      for (var i = 0; i < puzzle.clues.length; i++) {
        final clue = puzzle.clues[i];
        await into(cluesTable).insert(
          CluesTableCompanion.insert(
            puzzleId: puzzle.id,
            direction: clue.direction.name,
            number: clue.number,
            sortOrder: i,
            startRow: clue.startRow,
            startCol: clue.startCol,
            clueText: clue.text,
            answerLength: clue.length,
          ),
        );
      }
    });
  }

  /// Deletes a puzzle and its clues (cascades via FK).
  Future<void> deletePuzzle(String id) async {
    await (delete(puzzlesTable)..where((t) => t.id.equals(id))).go();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  PuzzleMetadata _rowToMetadata(PuzzleRow row) {
    return PuzzleMetadata(
      id: row.id,
      sourceId: row.sourceId,
      title: row.title,
      author: row.author ?? '',
      copyright: row.copyright ?? '',
      format: PuzzleFormat.values.byName(row.format),
      width: row.width,
      height: row.height,
      totalClues: 0, // loaded lazily
      importedAt: row.createdAt,
      publishDate: row.publishDate,
      notes: row.notes,
      checksum: row.checksum,
      difficulty: row.difficulty,
    );
  }

  Clue _clueRowToClue(ClueRow row) {
    return Clue(
      number: row.number,
      direction: Direction.values.byName(row.direction),
      text: row.clueText,
      startRow: row.startRow,
      startCol: row.startCol,
      length: row.answerLength,
    );
  }
}
