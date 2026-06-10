import 'dart:convert';

import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';
import 'package:crosscue/features/settings/data/daos/app_settings_dao.dart';

class ChallengeResultOutbox {
  ChallengeResultOutbox({required AppSettingsDao dao}) : _dao = dao;

  /// Public so the sync layer's device-local exclusion list can be
  /// cross-checked in tests: the pending queue must never sync, or another
  /// device could re-submit it (see SettingsSyncAdapter.excludedKeys).
  static const storageKey = 'challenge_result_outbox_v1';

  final AppSettingsDao _dao;

  Future<List<ChallengeSolveSubmission>> read() async {
    final raw = await _dao.getValue(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded.whereType<Map>().map((item) {
      return ChallengeSolveSubmission.fromJson(
        Map<String, Object?>.from(item),
      );
    }).toList(growable: false);
  }

  Future<void> add(ChallengeSolveSubmission submission) async {
    final submissions = await read();
    final deduped = [
      ...submissions.where(
        (item) =>
            item.sourceId != submission.sourceId ||
            item.sourcePuzzleId != submission.sourcePuzzleId,
      ),
      submission,
    ];
    await replace(deduped);
  }

  Future<void> replace(List<ChallengeSolveSubmission> submissions) {
    return _dao.setValue(
      storageKey,
      jsonEncode(
        submissions.map((submission) => submission.toJson()).toList(),
      ),
    );
  }
}
