import 'package:crosscue/core/domain/models/enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'focus_position.freezed.dart';

@freezed
abstract class FocusPosition with _$FocusPosition {
  const factory FocusPosition({
    required int row,
    required int col,
    required Direction direction,
  }) = _FocusPosition;
}
