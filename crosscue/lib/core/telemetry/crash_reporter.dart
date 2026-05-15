import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Crash reporting interface. The shipping build wires [LocalCrashReporter];
/// a remote vendor (e.g. Sentry) can be swapped in later without touching
/// feature code.
///
/// IMPORTANT: Never log puzzle content, clue text, solution, or user guesses.
abstract class CrashReporter {
  Future<void> init({required bool enabled});
  Future<void> reportError(
    Object error,
    StackTrace stackTrace, {
    Map<String, dynamic>? extras,
  });
  Future<String?> readLog();
  Future<void> setEnabled(bool enabled);
}

/// Local-only crash reporter.
///
/// Never transmits data. Entries are appended to the app documents directory
/// and capped to a small rolling file for future diagnostics export.
class LocalCrashReporter implements CrashReporter {
  LocalCrashReporter();

  static const _maxBytes = 500 * 1024;
  static const _fileName = 'crash_log.txt';

  bool _enabled = false;

  @override
  Future<void> init({required bool enabled}) async {
    _enabled = enabled;
  }

  @override
  Future<void> reportError(
    Object error,
    StackTrace stackTrace, {
    Map<String, dynamic>? extras,
  }) async {
    if (!_enabled) return;

    final file = await _logFile();
    final entry = StringBuffer()
      ..writeln('--- ${DateTime.now().toIso8601String()} ---')
      ..writeln('error: $error');
    if (extras != null && extras.isNotEmpty) {
      entry.writeln('extras: ${_sanitizeExtras(extras)}');
    }
    entry
      ..writeln('stack:')
      ..writeln(stackTrace)
      ..writeln();

    await file.writeAsString(entry.toString(), mode: FileMode.append);
    await _trimIfNeeded(file);
  }

  @override
  Future<String?> readLog() async {
    final file = await _logFile();
    if (!await file.exists()) return null;
    final value = await file.readAsString();
    return value.trim().isEmpty ? null : value;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
  }

  Future<File> _logFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _trimIfNeeded(File file) async {
    final exists = await file.exists();
    if (!exists) return;
    final length = await file.length();
    if (length <= _maxBytes) return;

    final text = await file.readAsString();
    final keepFrom = (text.length * 0.35).floor();
    final trimmed = text.substring(keepFrom);
    final firstEntry = trimmed.indexOf('--- ');
    await file.writeAsString(
      firstEntry >= 0 ? trimmed.substring(firstEntry) : trimmed,
      mode: FileMode.write,
    );
  }

  Map<String, Object?> _sanitizeExtras(Map<String, dynamic> extras) {
    return {
      for (final entry in extras.entries)
        if (!_blockedExtraKey(entry.key)) entry.key: entry.value,
    };
  }

  bool _blockedExtraKey(String key) {
    final normalized = key.toLowerCase();
    return normalized.contains('puzzle') ||
        normalized.contains('clue') ||
        normalized.contains('solution') ||
        normalized.contains('answer') ||
        normalized.contains('guess') ||
        normalized.contains('letter');
  }
}
