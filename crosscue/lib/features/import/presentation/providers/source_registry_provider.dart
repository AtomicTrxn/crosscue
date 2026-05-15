import 'package:crosscue/features/import/data/sources/crosshare_source.dart';
import 'package:crosscue/features/import/data/sources/local_import_source.dart';
import 'package:crosscue/features/import/data/sources/source_registry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'source_registry_provider.g.dart';

/// App-wide registry of puzzle sources that are known to Crosscue.
///
/// Sources are registered here only after their license status is cleared by
/// the source-review process in [SourceRegistry].
@Riverpod(keepAlive: true)
SourceRegistry sourceRegistry(Ref ref) {
  return SourceRegistry()
    ..register(const LocalImportSource())
    ..register(const CrosshareSource());
}
