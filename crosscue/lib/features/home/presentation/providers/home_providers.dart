import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/features/import/domain/services/crosshare_daily_date.dart';
import 'package:crosscue/features/import/presentation/providers/import_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_providers.g.dart';

@riverpod
Stream<List<PuzzleMetadata>> puzzleList(Ref ref) {
  final repo = ref.watch(importRepositoryProvider);
  return repo.watchAllMetadata();
}

@riverpod
DateTime currentLocalDate(Ref ref) {
  return crosshareUtcDate();
}
