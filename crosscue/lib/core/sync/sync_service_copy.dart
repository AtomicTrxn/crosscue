import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Platform-generic user-facing copy for the cross-device sync feature.
///
/// The same screens (Settings + onboarding) back both the iOS (iCloud) and
/// Android (Google Drive) transports, so their copy can't hard-code "iCloud".
/// These helpers resolve the right wording for the current platform.

/// The cloud service backing sync on this platform: iOS → "iCloud",
/// Android → "Google Drive", anything else → "the cloud".
String get syncServiceName {
  if (kIsWeb) return 'the cloud';
  if (Platform.isIOS) return 'iCloud';
  if (Platform.isAndroid) return 'Google Drive';
  return 'the cloud';
}

/// Hint shown when sync can't be enabled because no account is reachable.
/// Only surfaces on ambient-account platforms (iCloud) — Google Drive drives
/// its own sign-in from the toggle, so this never shows there.
String get syncSignInHint {
  if (!kIsWeb && Platform.isIOS) {
    return 'Sign in to iCloud on this device (the Settings app → your name → '
        'iCloud, with iCloud Drive on) to turn on sync.';
  }
  return 'Sign in to $syncServiceName on this device to turn on sync.';
}

/// Status line shown when the orchestrator is signed out (account unavailable).
String get syncUnavailableStatus {
  if (!kIsWeb && Platform.isIOS) {
    return 'iCloud unavailable — sign in to iCloud and enable iCloud Drive for '
        'Crosscue in Settings.';
  }
  return '$syncServiceName unavailable — sign in to turn on sync.';
}
