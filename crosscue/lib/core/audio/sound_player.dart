import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:crosscue/core/telemetry/crash_reporter.dart';

class SoundPlayer {
  SoundPlayer({required CrashReporter crashReporter})
      : _player = AudioPlayer(),
        _crashReporter = crashReporter;

  final AudioPlayer _player;
  final CrashReporter _crashReporter;
  Uint8List? _beepBytes;

  Future<void> playFeedback() async {
    try {
      _beepBytes ??= _generateBeep();
      await _player.stop();
      await _player.play(BytesSource(_beepBytes!));
    } catch (error, stackTrace) {
      // Audio failures are non-fatal — the rest of the solve flow doesn't
      // depend on the beep. Forward to the crash reporter so they can be
      // diagnosed if the user has crash reporting enabled.
      unawaited(_crashReporter.reportError(error, stackTrace));
    }
  }

  Future<void> dispose() => _player.dispose();

  Uint8List _generateBeep() {
    const sampleRate = 44100;
    const durationMs = 80;
    const frequency = 440.0;
    const amplitude = 0.4;
    final sampleCount = (sampleRate * durationMs / 1000).round();
    final dataBytes = sampleCount * 2;
    final bytes = BytesBuilder();

    void writeString(String value) => bytes.add(value.codeUnits);
    void writeUint16(int value) {
      bytes.add([
        value & 0xff,
        (value >> 8) & 0xff,
      ]);
    }

    void writeUint32(int value) {
      bytes.add([
        value & 0xff,
        (value >> 8) & 0xff,
        (value >> 16) & 0xff,
        (value >> 24) & 0xff,
      ]);
    }

    writeString('RIFF');
    writeUint32(36 + dataBytes);
    writeString('WAVEfmt ');
    writeUint32(16);
    writeUint16(1); // PCM
    writeUint16(1); // mono
    writeUint32(sampleRate);
    writeUint32(sampleRate * 2);
    writeUint16(2);
    writeUint16(16);
    writeString('data');
    writeUint32(dataBytes);

    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      final progressMs = i * 1000 / sampleRate;
      final envelope = switch (progressMs) {
        < 5 => progressMs / 5,
        > 65 => ((durationMs - progressMs) / 15).clamp(0.0, 1.0),
        _ => 1.0,
      };
      final sample =
          math.sin(2 * math.pi * frequency * t) * amplitude * envelope * 32767;
      writeUint16(sample.round().clamp(-32768, 32767) & 0xffff);
    }

    return bytes.toBytes();
  }
}
