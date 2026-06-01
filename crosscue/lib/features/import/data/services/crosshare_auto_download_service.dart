import 'package:crosscue/features/import/data/downloaders/crosshare_downloader.dart';
import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:crosscue/features/import/domain/repositories/import_repository.dart';
import 'package:crosscue/features/import/presentation/providers/import_providers.dart';
import 'package:crosscue/features/settings/domain/repositories/app_settings_repository.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'crosshare_auto_download_service.g.dart';

// Status string constants shared between service and UI.
abstract final class CrosshareStatus {
  static const success = 'success';
  static const duplicate = 'duplicate';
  static const notFound = 'not_found';
  static const networkError = 'network_error';
}

/// Live, in-memory progress of the silent auto-download.
///
/// Lets the home screen tell "today's puzzle is on its way" apart from "there
/// is no puzzle." This is deliberately separate from the persisted
/// [CrosshareStatus] keys, which are read with acceptable loading flicker on
/// the settings screen — the home screen needs a reactive, synchronous signal.
enum CrosshareAutoDownloadPhase {
  /// Nothing in flight — idle, finished, or short-circuited (auto-download is
  /// off, or today's puzzle is already downloaded).
  idle,

  /// A download (possibly mid-retry) is currently running.
  inProgress,

  /// The last run exhausted its retries on a transient network error.
  failed,
}

/// Holds the current [CrosshareAutoDownloadPhase] for the UI to watch.
///
/// [CrosshareAutoDownloadService] is the only writer, via the `onPhase`
/// callback wired up in [crosshareAutoDownloadServiceProvider].
@Riverpod(keepAlive: true)
class CrosshareAutoDownloadProgress extends _$CrosshareAutoDownloadProgress {
  @override
  CrosshareAutoDownloadPhase build() => CrosshareAutoDownloadPhase.idle;

  void report(CrosshareAutoDownloadPhase phase) => state = phase;
}

/// Silent background service that downloads today's Crosshare daily mini when
/// the auto-download setting is enabled and the puzzle hasn't been fetched yet
/// today.
///
/// This is intentionally separate from [CrosshareNotifier], which owns the
/// interactive UI state on the settings screen. The service writes the same
/// settings keys so the config screen always shows an up-to-date status, and
/// reports live progress through [onPhase] so the home screen can show an
/// honest "fetching today's puzzle…" state.
class CrosshareAutoDownloadService {
  CrosshareAutoDownloadService({
    required CrosshareDownloader downloader,
    required AppSettingsRepository settings,
    required ImportRepository importRepo,
    void Function(CrosshareAutoDownloadPhase phase)? onPhase,
    Duration retryBackoff = const Duration(seconds: 1),
    int maxAttempts = 3,
  })  : _downloader = downloader,
        _settings = settings,
        _importRepo = importRepo,
        _onPhase = onPhase,
        _retryBackoff = retryBackoff,
        _maxAttempts = maxAttempts;

  final CrosshareDownloader _downloader;
  final AppSettingsRepository _settings;
  final ImportRepository _importRepo;
  final void Function(CrosshareAutoDownloadPhase phase)? _onPhase;

  /// Base backoff between retries; the Nth retry waits `_retryBackoff * N`.
  final Duration _retryBackoff;

  /// Total tries (initial attempt + retries) for a transient network failure.
  final int _maxAttempts;

  /// Called on app launch and when the app returns to the foreground.
  /// Returns immediately (does nothing, no phase change) if auto-download is
  /// off or already done today — keeping cold start cheap when today is cached.
  Future<void> attemptIfNeeded() async {
    final enabled = await _settings.getCrosshareAutoDownload();
    if (!enabled) return;

    final today = _todayString();
    final lastDate = await _settings.getCrosshareLastDownloadedDate();
    if (lastDate == today) return; // Already downloaded today

    _emit(CrosshareAutoDownloadPhase.inProgress);
    final terminal = await _download(today);
    _emit(terminal);
  }

  /// Runs the download with retry + exponential backoff. Returns the terminal
  /// phase to surface: [CrosshareAutoDownloadPhase.failed] when transient
  /// network retries are exhausted, [CrosshareAutoDownloadPhase.idle]
  /// otherwise (success, duplicate, not-yet-published, or a non-transient
  /// error not worth retrying).
  Future<CrosshareAutoDownloadPhase> _download(String today) async {
    for (var attempt = 1;; attempt++) {
      final outcome = await _attemptOnce(today);
      if (!outcome.retryable || attempt >= _maxAttempts) {
        return outcome.status == CrosshareStatus.networkError
            ? CrosshareAutoDownloadPhase.failed
            : CrosshareAutoDownloadPhase.idle;
      }
      // Exponential backoff: 1×, 2×, … the base between attempts.
      await Future<void>.delayed(_retryBackoff * attempt);
    }
  }

  /// One download+import attempt. Persists the status keys (as before) and
  /// returns the status plus whether the failure is worth retrying. Only a
  /// transient `networkError` from the downloader is retryable — a missing
  /// puzzle (`notFound`), a changed page structure, or a parse failure won't
  /// fix themselves on a quick retry.
  Future<({String status, bool retryable})> _attemptOnce(String today) async {
    final dlResult = await _downloader.downloadToday();

    if (dlResult.isErr) {
      final (status, retryable) = switch (dlResult.error) {
        CrosshareDownloadError.notFound => (CrosshareStatus.notFound, false),
        CrosshareDownloadError.networkError => (
            CrosshareStatus.networkError,
            true,
          ),
        CrosshareDownloadError.malformedPage => (
            CrosshareStatus.networkError,
            false,
          ),
      };
      await _settings.setCrosshareLastAttemptStatus(status);
      return (status: status, retryable: retryable);
    }

    final importResult = await _importRepo.importBytes(
      dlResult.value,
      sourceId: 'crosshare_daily_mini',
      publishDate: DateTime.now(),
    );
    switch (importResult) {
      case JobSuccess():
        await _settings.setCrosshareLastDownloadedDate(today);
        await _settings.setCrosshareLastAttemptStatus(CrosshareStatus.success);
        return (status: CrosshareStatus.success, retryable: false);
      case JobDuplicate():
        // Puzzle already in library — count as downloaded so we don't retry.
        await _settings.setCrosshareLastDownloadedDate(today);
        await _settings.setCrosshareLastAttemptStatus(
          CrosshareStatus.duplicate,
        );
        return (status: CrosshareStatus.duplicate, retryable: false);
      case JobFailure():
        await _settings.setCrosshareLastAttemptStatus(
          CrosshareStatus.networkError,
        );
        return (status: CrosshareStatus.networkError, retryable: false);
    }
  }

  void _emit(CrosshareAutoDownloadPhase phase) => _onPhase?.call(phase);

  static String _todayString() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }
}

@Riverpod(keepAlive: true)
CrosshareAutoDownloadService crosshareAutoDownloadService(Ref ref) {
  return CrosshareAutoDownloadService(
    downloader: ref.watch(crosshareDownloaderProvider),
    settings: ref.watch(appSettingsProvider),
    importRepo: ref.watch(importRepositoryProvider),
    onPhase: (phase) =>
        ref.read(crosshareAutoDownloadProgressProvider.notifier).report(phase),
  );
}
