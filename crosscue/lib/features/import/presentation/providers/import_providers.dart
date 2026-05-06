import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/features/import/data/repositories/import_repository_impl.dart';
import 'package:crosscue/features/import/domain/repositories/import_repository.dart';

part 'import_providers.g.dart';

@Riverpod(keepAlive: true)
ImportRepository importRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return ImportRepositoryImpl(dao: db.puzzleDao);
}
