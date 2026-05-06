import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/features/solve/data/repositories/solve_repository_impl.dart';
import 'package:crosscue/features/solve/domain/repositories/solve_repository.dart';

part 'solve_providers.g.dart';

@Riverpod(keepAlive: true)
SolveRepository solveRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return SolveRepositoryImpl(dao: db.solveSessionDao);
}
