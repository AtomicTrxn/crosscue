import 'package:crosscue/core/storage/secure_key_value_store.dart';

/// In-memory [SecureKeyValueStore] for tests; no platform channels.
class InMemorySecureKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
