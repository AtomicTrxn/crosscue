import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:crosscue/features/import/data/downloaders/crosshare_downloader.dart';
import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:crosscue/features/import/domain/repositories/import_repository.dart';
import 'package:crosscue/features/import/presentation/providers/import_providers.dart';
import 'package:crosscue/features/settings/domain/repositories/app_settings_repository.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';

part 'crosshare_auto_download_service.g.dart';

// Status string constants shared between service and UI.
abstract final class CrosshareStatus {
  static const success = 'success';
  static const duplicate = 'duplicate';
  static const notFound = 'not_found';
  static const networkError = 'network_error';
}

/// Silent background service that downloads today's Crosshare daily mini when
/// the auto-download setting is enabled and the puzzle hasn't been fetched yet
/// today.
///
/// This is intentionally separate from [CrosshareNotifier], which owns the
/// interactive UI state on the settings screen. The service writes the same
/// settings keys so the config screen always shows an up-to-date status.
class CrosshareAutoDownloadService {
  const CrosshareAutoDownloadService({
    required CrosshareDownloader downloader,
    required AppSettingsRepository settings,
    required ImportRepository importRepo,
  })  : _downloader = downloader,
        _settings = settings,
        _importRepo = importRepo;

  final CrosshareDownloader _downloader;
  final AppSettingsRepository _settings;
  final ImportRepository _importRepo;

  /// Called on app launch and when the app returns to the foreground.
  /// Returns immediately (does nothing) if auto-download is off or already done
  /// today.
  Future<void> attemptIfNeeded() async {
    final enabled = await _settings.getCrosshareAutoDownload();
    if (!enabled) return;

    final today = _todayString();
    final lastDate = await _settings.getCrosshareLastDownloadedDate();
    if (lastDate == today) return; // Already downloaded today

    await _download(today);
  }

  Future<void> _download(String today) async {
    final dlResult = await _downloader.downloadToday();

    if (dlResult.isErr) {
      final status = switch (dlResult.error) {
        CrosshareDownloadError.notFound => CrosshareStatus.notFound,
        CrosshareDownloadError.networkError => CrosshareStatus.networkError,
        CrosshareDownloadError.malformedPage => CrosshareStatus.networkError,
      };
      await _settings.setCrosshareLastAttemptStatus(status);
      return;
    }

    final importResult = await _importRepo.importBytes(
      dlResult.value,
      sourceId: 'crosshare_daily_mini',
    );
    switch (importResult) {
      case JobSuccess():
        await _settings.setCrosshareLastDownloadedDate(today);
        await _settings.setCrosshareLastAttemptStatus(CrosshareStatus.success);
      case JobDuplicate():
        // Puzzle already in library — count as downloaded so we don't retry.
        await _settings.setCrosshareLastDownloadedDate(today);
        await _settings.setCrosshareLastAttemptStatus(
          CrosshareStatus.duplicate,
        );
      case JobFailure():
        await _settings.setCrosshareLastAttemptStatus(
          CrosshareStatus.networkError,
        );
    }
  }

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
  );
}
