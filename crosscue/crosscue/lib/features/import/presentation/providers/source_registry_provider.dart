import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sources/local_import_source.dart';
import '../../data/sources/source_registry.dart';

/// App-wide registry of puzzle sources that are known to Crosscue.
///
/// Phase 1 exposes only the local user-import source. Future network sources
/// must be registered here only after their license status is cleared by the
/// topic-07 guardrails.
final sourceRegistryProvider = Provider<SourceRegistry>((ref) {
  return SourceRegistry()..register(const LocalImportSource());
});
