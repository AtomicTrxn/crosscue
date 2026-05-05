import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/archive_repository_impl.dart';
import '../../domain/models/archive_entry.dart';

part 'archive_providers.g.dart';

/// Singleton repository for the Archive feature.
@Riverpod(keepAlive: true)
ArchiveRepositoryImpl archiveRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return ArchiveRepositoryImpl(
    puzzleDao: db.puzzleDao,
    sessionDao: db.solveSessionDao,
  );
}

/// All archive entries (puzzles + their latest session status), import-date desc.
/// Invalidated by the archive screen after a delete, and by ImportNotifier after
/// a successful import.
@riverpod
Future<List<ArchiveEntry>> archiveEntries(Ref ref) {
  return ref.watch(archiveRepositoryProvider).getArchiveEntries();
}
