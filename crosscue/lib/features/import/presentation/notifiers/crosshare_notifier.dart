import 'dart:async';

import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/core/telemetry/crash_reporter.dart';
import 'package:crosscue/features/import/data/downloaders/crosshare_downloader.dart';
import 'package:crosscue/features/import/data/services/crosshare_auto_download_service.dart';
import 'package:crosscue/features/import/domain/models/import_job_result.dart';
import 'package:crosscue/features/import/domain/models/parse_error.dart';
import 'package:crosscue/features/import/domain/repositories/import_repository.dart';
import 'package:crosscue/features/import/domain/services/crosshare_daily_date.dart';
import 'package:crosscue/features/import/presentation/providers/import_providers.dart';
import 'package:crosscue/features/settings/domain/repositories/app_settings_repository.dart';
import 'package:crosscue/features/settings/presentation/providers/settings_providers.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'crosshare_notifier.freezed.dart';
part 'crosshare_notifier.g.dart';

// ---------------------------------------------------------------------------
// UI state
// ---------------------------------------------------------------------------

@freezed
class CrosshareState with _$CrosshareState {
  const factory CrosshareState.idle() = CrosshareIdle;
  const factory CrosshareState.downloading() = CrosshareDownloading;
  const factory CrosshareState.success({
    required String puzzleId,
    required String title,
  }) = CrosshareSuccess;
  const factory CrosshareState.duplicate() = CrosshareDuplicate;
  const factory CrosshareState.failure({required String message}) =
      CrosshareFailure;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

@riverpod
class CrosshareNotifier extends _$CrosshareNotifier {
  // Dependencies are resolved once in build() and held as fields so they are
  // never accessed via ref.read() after an await suspension point. Calling
  // ref.read() mid-async on an isAutoDispose notifier risks a StateError if
  // the ref is invalidated between suspension points.
  late final CrosshareDownloader _downloader;
  late final ImportRepository _importRepo;
  late final AppSettingsRepository _settings;
  late final CrashReporter _crashReporter;

  @override
  CrosshareState build() {
    _downloader = ref.read(crosshareDownloaderProvider);
    _importRepo = ref.read(importRepositoryProvider);
    _settings = ref.read(appSettingsProvider);
    _crashReporter = ref.read(crashReporterProvider);
    return const CrosshareIdle();
  }

  Future<void> download() async {
    state = const CrosshareDownloading();

    try {
      await _runDownload();
    } catch (e, st) {
      // Safety net: if anything unexpected escapes _runDownload, recover
      // rather than leaving the UI permanently stuck in the spinning state.
      // CrashReporter respects the user's crash-reporting opt-in.
      unawaited(_crashReporter.reportError(e, st));
      state = const CrosshareFailure(
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  Future<void> _runDownload() async {
    final dlResult = await _downloader.downloadTodayWithMetadata();
    if (dlResult.isErr) {
      final statusStr = switch (dlResult.error) {
        CrosshareDownloadError.notFound => CrosshareStatus.notFound,
        CrosshareDownloadError.networkError => CrosshareStatus.networkError,
        CrosshareDownloadError.malformedPage => CrosshareStatus.networkError,
      };
      await _persistStatus(statusStr);
      state = CrosshareFailure(message: _downloadErrorMessage(dlResult.error));
      _invalidateStatusProviders();
      return;
    }

    final entry = dlResult.value.entry;

    final importResult = await _importRepo.importBytes(
      dlResult.value.bytes,
      sourceId: 'crosshare_daily_mini',
      sourcePuzzleId: entry.id,
      publishDate: entry.date,
    );
    final todayStr = crosshareUtcDateString(entry.date);

    switch (importResult) {
      case JobSuccess(:final puzzle):
        await _persistStatus(CrosshareStatus.success, date: todayStr);
        state =
            CrosshareSuccess(puzzleId: puzzle.id, title: puzzle.metadata.title);
      case JobDuplicate():
        await _persistStatus(CrosshareStatus.duplicate, date: todayStr);
        state = const CrosshareDuplicate();
      case JobFailure(:final error):
        await _persistStatus(CrosshareStatus.networkError);
        state = CrosshareFailure(message: _parseErrorMessage(error));
    }

    _invalidateStatusProviders();
  }

  void reset() => state = const CrosshareIdle();

  Future<void> _persistStatus(String status, {String? date}) async {
    await _settings.setCrosshareLastAttemptStatus(status);
    if (date != null) {
      await _settings.setCrosshareLastDownloadedDate(date);
    }
  }

  /// Invalidates the cached status providers so the config screen immediately
  /// reflects the outcome of this download attempt.
  void _invalidateStatusProviders() {
    ref.invalidate(crosshareLastDownloadedDateProvider);
    ref.invalidate(crosshareLastAttemptStatusProvider);
  }

  String _downloadErrorMessage(CrosshareDownloadError error) {
    return switch (error) {
      CrosshareDownloadError.notFound =>
        "Today's puzzle isn't available yet. Try again later.",
      CrosshareDownloadError.networkError =>
        'Could not reach Crosshare. Check your connection and try again.',
      CrosshareDownloadError.malformedPage =>
        'Unable to parse puzzle data. The Crosshare page may have changed.',
    };
  }

  String _parseErrorMessage(ParseError error) {
    return switch (error) {
      ParseError.unsupportedFormat =>
        'The downloaded puzzle format is not supported.',
      ParseError.invalidFormat => 'The downloaded file appears to be invalid.',
      ParseError.missingData =>
        'The downloaded puzzle is incomplete or corrupted.',
      _ => 'Failed to import the downloaded puzzle.',
    };
  }
}
