// ignore_for_file: avoid_classes_with_only_static_members
import 'dart:convert';
import 'dart:typed_data';

/// Builds minimal valid (or intentionally invalid) AcrossLite .puz binary
/// fixtures entirely in memory — no licensed puzzle files are required.
///
/// Layout reference:
///   https://github.com/century-arcade/xd/blob/master/doc/puz-file-format.md
///
/// The parser under test does NOT validate checksums, so all CRC/checksum
/// fields are left as zeros to keep the builder simple.
class PuzFixtureBuilder {
  // -------------------------------------------------------------------------
  // Public factory methods
  // -------------------------------------------------------------------------

  /// A minimal, fully-valid 3×3 all-white puzzle.
  ///
  /// Grid (all white):
  ///   A B C      row 0  → numbered: (0,0)=1  (0,1)=2  (0,2)=3
  ///   D E F      row 1  → numbered: (1,0)=4
  ///   G H I      row 2  → numbered: (2,0)=5
  ///
  /// Clue order for .puz (interleaved by number, across before down):
  ///   1A  1D  2D  3D  4A  5A   → 6 clue texts
  static Uint8List minimal3x3() => build(
        width: 3,
        height: 3,
        grid: ['ABC', 'DEF', 'GHI'],
        title: 'Test Puzzle',
        author: 'Test Author',
        copyright: '© 2026',
        clueTexts: [
          '1-Across', // 1A: A B C
          '1-Down', // 1D: A D G
          '2-Down', // 2D: B E H
          '3-Down', // 3D: C F I
          '4-Across', // 4A: D E F
          '5-Across', // 5A: G H I
        ],
      );

  /// A 3×3 puzzle with a standard rebus cell (1-based RTBL key).
  ///
  /// Cell (0,0) solution is "EST" instead of a single letter.
  /// GRBS slot 1 → RTBL key "01" (standard Across Lite).
  static Uint8List rebus3x3() => build(
        width: 3,
        height: 3,
        grid: ['EBC', 'DEF', 'GHI'],
        title: 'Rebus Puzzle',
        author: 'Tester',
        copyright: '2026',
        clueTexts: [
          '1-Across',
          '1-Down',
          '2-Down',
          '3-Down',
          '4-Across',
          '5-Across',
        ],
        grbsMap: {0: 1}, // cell index 0 → slot 1 (1-based)
        rtblMap: {1: 'EST'}, // key 1 → "EST"
      );

  /// A 3×3 puzzle with a Crosshare-style rebus cell (0-based RTBL key).
  ///
  /// Crosshare writes GRBS slot values as 1-based but stores RTBL keys as
  /// 0-based (slot − 1).  Cell (0,0) should resolve to "EST".
  static Uint8List crosshareRebus3x3() => build(
        width: 3,
        height: 3,
        grid: ['EBC', 'DEF', 'GHI'],
        title: 'Crosshare Rebus',
        author: 'Tester',
        copyright: '2026',
        clueTexts: [
          '1-Across',
          '1-Down',
          '2-Down',
          '3-Down',
          '4-Across',
          '5-Across',
        ],
        grbsMap: {0: 1}, // cell 0 → slot 1 (1-based, as Crosshare writes)
        rtblMap: {0: 'EST'}, // key 0 (0-based, Crosshare style) → "EST"
      );

  /// A 3×3 puzzle with a circled cell marked with GEXT bit 0x10 (standard).
  static Uint8List circles3x3() => build(
        width: 3,
        height: 3,
        grid: ['ABC', 'DEF', 'GHI'],
        title: 'Circles Puzzle',
        author: 'Tester',
        copyright: '2026',
        clueTexts: [
          '1-Across',
          '1-Down',
          '2-Down',
          '3-Down',
          '4-Across',
          '5-Across',
        ],
        gextMap: {0: 0x10}, // standard bit
      );

  /// A 3×3 puzzle with a circled cell marked with GEXT bit 0x80 (Crosshare).
  static Uint8List circlesGext80_3x3() => build(
        width: 3,
        height: 3,
        grid: ['ABC', 'DEF', 'GHI'],
        title: 'Circles 0x80 Puzzle',
        author: 'Tester',
        copyright: '2026',
        clueTexts: [
          '1-Across',
          '1-Down',
          '2-Down',
          '3-Down',
          '4-Across',
          '5-Across',
        ],
        gextMap: {0: 0x80}, // Crosshare alternate circle bit
      );

  /// A 3×3 puzzle whose title contains a non-ASCII UTF-8 character (ñ).
  static Uint8List utf8Title3x3() {
    final bytes = build(
      width: 3,
      height: 3,
      grid: ['ABC', 'DEF', 'GHI'],
      title: 'placeholder',
      author: 'Tester',
      copyright: '2026',
      clueTexts: [
        '1-Across',
        '1-Down',
        '2-Down',
        '3-Down',
        '4-Across',
        '5-Across',
      ],
    );
    // Patch the title string starting at the strings section (0x34 + 9*2 = 0x52).
    // Replace the null-terminated 'placeholder\0' with 'Mañana\0' in UTF-8.
    final copy = Uint8List.fromList(bytes);

    // Find 'placeholder\0' and replace with 'Ma\xC3\xB1ana\0' (UTF-8 ñ = C3 B1)
    final titleUtf8 = utf8.encode('Mañana') + [0x00];
    final oldTitle = latin1.encode('placeholder') + [0x00];
    final idx = _indexOf(copy, oldTitle);
    if (idx == -1) return bytes; // shouldn't happen

    final result = BytesBuilder();
    result.add(copy.sublist(0, idx));
    result.add(titleUtf8);
    result.add(copy.sublist(idx + oldTitle.length));
    return result.toBytes();
  }

  static int _indexOf(Uint8List haystack, List<int> needle) {
    outer:
    for (var i = 0; i <= haystack.length - needle.length; i++) {
      for (var j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) continue outer;
      }
      return i;
    }
    return -1;
  }

  /// A 3×3 puzzle with a hidden cell (byte 0x3A ':') at position (0,0).
  static Uint8List hiddenCell3x3() {
    final bytes = build(
      width: 3,
      height: 3,
      grid: ['ABC', 'DEF', 'GHI'],
      title: 'Hidden Cell',
      author: 'Tester',
      copyright: '2026',
      clueTexts: [
        '1-Across',
        '1-Down',
        '2-Down',
        '3-Down',
        '4-Across',
        '5-Across',
      ],
    );
    final copy = Uint8List.fromList(bytes);
    copy[0x34] = 0x3A; // overwrite solution byte at cell 0 with ':'
    return copy;
  }

  /// A file whose first 12 bytes after offset 0x02 do NOT match "ACROSS&DOWN\0".
  static Uint8List badMagic() {
    final base = minimal3x3();
    final copy = Uint8List.fromList(base);
    copy[0x02] = 0x00; // corrupt the first magic byte
    return copy;
  }

  /// A file with the scramble bit 0x0004 set (solution is locked).
  static Uint8List scrambled() {
    final base = minimal3x3();
    final copy = Uint8List.fromList(base);
    copy[0x32] = 0x04; // bit 0x0004 = scrambled
    copy[0x33] = 0x00;
    return copy;
  }

  /// A file with a nonzero scramble field that does NOT have bit 0x0004 set.
  /// This simulates non-scramble metadata flags that some writers emit.
  static Uint8List nonScrambleFlag() {
    final base = minimal3x3();
    final copy = Uint8List.fromList(base);
    copy[0x32] = 0x01; // bit 0x0001 only — NOT the scramble bit
    copy[0x33] = 0x00;
    return copy;
  }

  /// A file that is shorter than the required header + grid data.
  static Uint8List truncated() => Uint8List.fromList([
        0x00, 0x00, // CRC
        0x41, 0x43, 0x52, 0x4F, 0x53, 0x53, 0x26, 0x44,
        0x4F, 0x57, 0x4E, 0x00, // "ACROSS&DOWN\0"
        // Stops here — far too short
      ]);

  /// A buffer larger than 5 MiB (triggers the file-size guard).
  static Uint8List oversized() => Uint8List(5 * 1024 * 1024 + 1);

  // -------------------------------------------------------------------------
  // Core builder
  // -------------------------------------------------------------------------

  /// Builds a .puz binary from the supplied parameters.
  ///
  /// [grid] must have exactly [height] strings each of length [width].
  /// Use '.' for black cells and an uppercase letter for white cells.
  ///
  /// [clueTexts] must match the .puz interleaved ordering (across before down
  /// for the same number, ascending by number).
  static Uint8List build({
    required int width,
    required int height,
    required List<String> grid,
    String title = 'Test',
    String author = 'Author',
    String copyright = '2026',
    List<String> clueTexts = const [],
    bool scrambled = false,
    String notes = '',
    Map<int, int> grbsMap = const {}, // cellIndex → rebus slot
    Map<int, String> rtblMap = const {}, // slot → multi-letter string
    Map<int, int> gextMap = const {}, // cellIndex → GEXT flag byte
  }) {
    final buf = BytesBuilder();

    // ── Fixed header (0x00–0x33) ──────────────────────────────────────────
    buf.add([0x00, 0x00]); // 0x00-0x01 file CRC (unused by parser)
    buf.add(latin1.encode('ACROSS&DOWN\x00')); // 0x02-0x0D magic (12 bytes)
    buf.add([0x00, 0x00]); // 0x0E-0x0F header CRC
    buf.add(List.filled(8, 0)); // 0x10-0x17 ICHEATED
    buf.add(latin1.encode('1.3\x00')); // 0x18-0x1B version
    buf.add([0x00, 0x00]); // 0x1C-0x1D reserved
    buf.add([0x00, 0x00]); // 0x1E-0x1F scrambled checksum
    buf.add(List.filled(12, 0)); // 0x20-0x2B reserved
    buf.addByte(width); // 0x2C
    buf.addByte(height); // 0x2D
    final nc = clueTexts.length;
    buf.add([nc & 0xFF, (nc >> 8) & 0xFF]); // 0x2E-0x2F num clues
    buf.add([0x01, 0x00]); // 0x30-0x31 bitmask
    buf.add([scrambled ? 0x04 : 0, 0x00]); // 0x32-0x33 scramble tag

    // ── Solution grid ─────────────────────────────────────────────────────
    for (var r = 0; r < height; r++) {
      for (var c = 0; c < width; c++) {
        final ch = r < grid.length && c < grid[r].length ? grid[r][c] : '.';
        buf.addByte(ch.codeUnitAt(0));
      }
    }

    // ── Player grid ('-' empty, '.' black) ───────────────────────────────
    for (var r = 0; r < height; r++) {
      for (var c = 0; c < width; c++) {
        final ch = r < grid.length && c < grid[r].length ? grid[r][c] : '.';
        buf.addByte(ch == '.' ? 0x2E : 0x2D);
      }
    }

    // ── String section ────────────────────────────────────────────────────
    void writeStr(String s) {
      buf.add(latin1.encode(s));
      buf.addByte(0x00);
    }

    writeStr(title);
    writeStr(author);
    writeStr(copyright);
    for (final t in clueTexts) {
      writeStr(t);
    }
    writeStr(notes);

    // ── Extension blocks ─────────────────────────────────────────────────
    final cellCount = width * height;

    if (grbsMap.isNotEmpty) {
      final data = Uint8List(cellCount);
      grbsMap.forEach((idx, slot) => data[idx] = slot);
      _writeExtBlock(buf, 'GRBS', data);
    }

    if (rtblMap.isNotEmpty) {
      // Format: " 01:EST; 02:TION;" — leading space, 2-digit padded slot,
      // colon, value, semicolon.  Matches the split+trim logic in PuzParser.
      final sb = StringBuffer();
      rtblMap.forEach((slot, value) {
        sb.write(' ${slot.toString().padLeft(2, '0')}:$value;');
      });
      _writeExtBlock(
          buf, 'RTBL', Uint8List.fromList(latin1.encode(sb.toString())));
    }

    if (gextMap.isNotEmpty) {
      final data = Uint8List(cellCount);
      gextMap.forEach((idx, flags) => data[idx] = flags);
      _writeExtBlock(buf, 'GEXT', data);
    }

    return buf.toBytes();
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  static void _writeExtBlock(BytesBuilder buf, String tag, Uint8List data) {
    buf.add(latin1.encode(tag)); // 4-byte tag
    buf.add(
        [data.length & 0xFF, (data.length >> 8) & 0xFF]); // length uint16 LE
    buf.add([0x00, 0x00]); // checksum placeholder (ignored by parser)
    buf.add(data);
    buf.addByte(0x00); // null terminator
  }
}
