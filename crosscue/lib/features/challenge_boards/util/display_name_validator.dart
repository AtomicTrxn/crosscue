// ignore_for_file: always_use_package_imports, directives_ordering, require_trailing_commas, deprecated_member_use, prefer_const_constructors, unused_import, unnecessary_import, avoid_dynamic_calls
import '../models/challenge_models.dart';

/// Crosscue · Display-name validation.
///
/// Rules (from spec):
///  • required after trimming
///  • max 10 characters
///  • letters, numbers, spaces, underscores, hyphens only
///  • reject control characters
///  • reject excessive repeated whitespace (2+ consecutive spaces)
class DisplayNameValidator {
  static final RegExp _allowed = RegExp(r'^[A-Za-z0-9 _-]+$');
  static final RegExp _control = RegExp(r'[\u0000-\u001F\u007F]');
  static final RegExp _repeatWs = RegExp(r'\s{2,}');

  /// Returns a user-facing error string, or null when valid.
  static String? validate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'Enter a display name.';
    if (value.runes.length > ChallengeLimits.displayNameMaxLen) {
      return 'Max ${ChallengeLimits.displayNameMaxLen} characters.';
    }
    if (_control.hasMatch(raw)) return 'Remove special characters.';
    if (_repeatWs.hasMatch(raw)) return 'Avoid repeated spaces.';
    if (!_allowed.hasMatch(value)) {
      return 'Use letters, numbers, spaces, _ or - only';
    }
    return null;
  }

  static bool isValid(String raw) => validate(raw) == null;

  /// Counter value shown next to the field (counts the trimmed-but-as-typed
  /// length; we count runes so emoji-width input can't overflow silently).
  static int counter(String raw) => raw.runes.length;
}
