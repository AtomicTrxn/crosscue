import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/import_repository_impl.dart';

part 'import_providers.g.dart';

@Riverpod(keepAlive: true)
ImportRepositoryImpl importRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return ImportRepositoryImpl(dao: db.puzzleDao);
}
