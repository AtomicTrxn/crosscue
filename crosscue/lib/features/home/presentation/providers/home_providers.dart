import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:crosscue/core/domain/models/puzzle_metadata.dart';
import 'package:crosscue/features/import/presentation/providers/import_providers.dart';

part 'home_providers.g.dart';

@riverpod
Future<List<PuzzleMetadata>> puzzleList(Ref ref) async {
  // Invalidated after a successful import so Home refreshes immediately.
  final repo = ref.watch(importRepositoryProvider);
  return repo.getAllMetadata();
}
