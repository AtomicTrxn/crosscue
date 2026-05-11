import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:crosscue/features/import/data/sources/crosshare_source.dart';
import 'package:crosscue/features/import/data/sources/local_import_source.dart';
import 'package:crosscue/features/import/data/sources/source_registry.dart';

part 'source_registry_provider.g.dart';

/// App-wide registry of puzzle sources that are known to Crosscue.
///
/// Phase 1 exposes only the local user-import source. Future network sources
/// must be registered here only after their license status is cleared by the
/// topic-07 guardrails.
@Riverpod(keepAlive: true)
SourceRegistry sourceRegistry(Ref ref) {
  return SourceRegistry()
    ..register(const LocalImportSource())
    ..register(const CrosshareSource());
}
