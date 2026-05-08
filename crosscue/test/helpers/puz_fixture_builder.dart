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

  /// A 3×3 puzzle with a rebus cell.
  ///
  /// Cell (0,0) solution is "EST" instead of a single letter.
  /// GRBS slot 1 → RTBL "01:EST;"
  static Uint8List rebus3x3() {
    // Solution byte for (0,0): any letter (overridden by RTBL)
    // Use 'E' as the single-byte placeholder.
    final bytes = build(
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
      grbsMap: {0: 1}, // cell index 0 → slot 1
      rtblMap: {1: 'EST'},
    );
    return bytes;
  }

  /// A 3×3 puzzle with a circled cell at index 0 (top-left).
  ///
  /// GEXT bit 0x10 marks cell as circled (standard spec).
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
        gextMap: {0: 0x10}, // cell 0 flagged as circled
      );

  /// A file whose first 12 bytes after offset 0x02 do NOT match "ACROSS&DOWN\0".
  static Uint8List badMagic() {
    final base = minimal3x3();
    final copy = Uint8List.fromList(base);
    copy[0x02] = 0x00; // corrupt the first magic byte
    return copy;
  }

  /// A file with the scramble tag set to non-zero (solution is locked).
  static Uint8List scrambled() {
    final base = minimal3x3();
    final copy = Uint8List.fromList(base);
    copy[0x32] = 4; // scramble tag = 4
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
  /// [clueTexts] must match the .puz interleaved ordering (all-across sorted
  /// by number, then all-down sorted by number — but the PuzParser itself
  /// interleaves them, so pass them in that interleaved order).
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
    Map<int, int> grbsMap = const {}, // cellIndex → rebus slot (1-based)
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
    buf.add([scrambled ? 4 : 0, 0x00]); // 0x32-0x33 scramble tag

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
      // Format: " 01:EST; 02:TION;" (leading space, padded 2-digit slot, colon,
      // value, semicolon) — matches the split+trim logic in PuzParser.
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
