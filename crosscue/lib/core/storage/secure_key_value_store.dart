import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal key-value storage for secrets, backed by the platform keystore
/// (iOS/macOS Keychain, Android Keystore-encrypted shared preferences).
///
/// Values stored here are device-local by design: they are excluded from OS
/// backups (see `android/app/src/main/res/xml/backup_rules.xml`) and use
/// this-device-only Keychain accessibility, so they do not follow the user to
/// a new device. Durable secrets that must survive restore (e.g. the
/// Challenge Boards recovery bundle) belong in the app database instead.
abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  FlutterSecureKeyValueStore([FlutterSecureStorage? storage])
      : _storage = storage ?? _defaultStorage;

  /// The Android preferences file name is pinned so the backup-exclusion
  /// rules in res/xml can reference it; restoring Keystore-encrypted
  /// ciphertext onto another device is useless and can throw on read.
  static const androidPreferencesName = 'crosscue_secure_prefs';

  static const _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: androidPreferencesName,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } on Exception {
      // A corrupted keystore entry reads as "absent" rather than wedging the
      // caller forever; callers recover the way they would from a fresh
      // install (e.g. Challenge Boards restores identity from its recovery
      // bundle, which rotates the token).
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
