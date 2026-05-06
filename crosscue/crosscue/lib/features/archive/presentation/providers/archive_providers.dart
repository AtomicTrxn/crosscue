import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/features/archive/data/repositories/archive_repository_impl.dart';
import 'package:crosscue/features/archive/domain/models/archive_entry.dart';
import 'package:crosscue/features/archive/domain/repositories/archive_repository.dart';

part 'archive_providers.g.dart';

/// Singleton repository for the Archive feature.
@Riverpod(keepAlive: true)
ArchiveRepository archiveRepository(Ref ref) {
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
