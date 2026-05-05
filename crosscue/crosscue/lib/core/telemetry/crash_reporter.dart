/// Crash reporting interface. Sentry integration added in post-MVP.
/// All callers use this interface so the vendor can be swapped without
/// touching feature code.
///
/// IMPORTANT: Never log puzzle content, clue text, solution, or user guesses.
abstract class CrashReporter {
  Future<void> init({required bool enabled});
  Future<void> reportError(Object error, StackTrace stackTrace,
      {Map<String, dynamic>? extras});
  Future<void> setEnabled(bool enabled);
}

/// No-op crash reporter used until Sentry is wired in post-MVP.
class NoOpCrashReporter implements CrashReporter {
  const NoOpCrashReporter();

  @override
  Future<void> init({required bool enabled}) async {}

  @override
  Future<void> reportError(Object error, StackTrace stackTrace,
      {Map<String, dynamic>? extras}) async {}

  @override
  Future<void> setEnabled(bool enabled) async {}
}
