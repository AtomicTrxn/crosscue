import 'dart:math';

/// Minimal RFC 4122 UUID v4 generator (random).
///
/// Avoids adding the `uuid` package; the only consumer is sync provenance
/// (`puzzle_completions.client_uuid`) where any 128-bit unique id is fine —
/// the v4 format is just convenient and well-recognised.
class Uuid {
  const Uuid._();

  static final _rng = Random.secure();

  /// Returns a lowercase canonical UUID v4 string,
  /// e.g. `f47ac10b-58cc-4372-a567-0e02b2c3d479`.
  static String v4() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    // Version 4 in the high nibble of byte 6.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Variant 10xx in the high two bits of byte 8.
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int i) => bytes[i].toRadixString(16).padLeft(2, '0');
    final b = List<String>.generate(16, hex);
    return '${b[0]}${b[1]}${b[2]}${b[3]}-'
        '${b[4]}${b[5]}-'
        '${b[6]}${b[7]}-'
        '${b[8]}${b[9]}-'
        '${b[10]}${b[11]}${b[12]}${b[13]}${b[14]}${b[15]}';
  }
}
