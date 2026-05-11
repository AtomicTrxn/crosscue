import 'package:crosscue/core/domain/models/enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cell_progress.freezed.dart';

/// The player's current state for one grid cell.
@freezed
abstract class CellProgress with _$CellProgress {
  const factory CellProgress({
    /// Whatever the user typed (empty string = blank).
    @Default('') String letter,
    @Default(CellState.empty) CellState state,
    @Default(false) bool isPencil,
  }) = _CellProgress;

  /// Convenience: an untouched blank cell.
  static const CellProgress blank = CellProgress();
}
