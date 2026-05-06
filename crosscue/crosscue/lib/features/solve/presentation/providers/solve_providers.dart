import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/solve_repository_impl.dart';
import '../../domain/repositories/solve_repository.dart';

part 'solve_providers.g.dart';

@Riverpod(keepAlive: true)
SolveRepository solveRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return SolveRepositoryImpl(dao: db.solveSessionDao);
}
