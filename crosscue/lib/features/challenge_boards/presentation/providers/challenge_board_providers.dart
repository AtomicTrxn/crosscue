import 'package:crosscue/core/providers/core_providers.dart';
import 'package:crosscue/features/challenge_boards/data/repositories/api_challenge_repository.dart';
import 'package:crosscue/features/challenge_boards/data/repositories/sample_challenge_repository.dart';
import 'package:crosscue/features/challenge_boards/data/services/challenge_api_config.dart';
import 'package:crosscue/features/challenge_boards/data/services/challenge_board_api.dart';
import 'package:crosscue/features/challenge_boards/data/services/challenge_identity_store.dart';
import 'package:crosscue/features/challenge_boards/data/services/challenge_result_outbox.dart';
import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/domain/repositories/challenge_board_repository.dart';
import 'package:crosscue/features/challenge_boards/domain/repositories/challenge_profile_repository.dart';
import 'package:crosscue/features/challenge_boards/domain/repositories/challenge_result_repository.dart';
import 'package:crosscue/features/challenge_boards/domain/services/challenge_result_submitter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _sampleChallengeRepository = SampleChallengeRepository();

final challengeApiConfigProvider = Provider<ChallengeApiConfig>(
  (ref) => ChallengeApiConfig.fromDartDefines(),
);

final sampleChallengeRepositoryProvider = Provider<SampleChallengeRepository>(
  (ref) => _sampleChallengeRepository,
);

final challengeIdentityStoreProvider = Provider<ChallengeIdentityStore>((ref) {
  return ChallengeIdentityStore(
    dao: ref.watch(appDatabaseProvider).appSettingsDao,
  );
});

final challengeBoardApiProvider = Provider<ChallengeBoardApi?>((ref) {
  final config = ref.watch(challengeApiConfigProvider);
  final baseUrl = config.baseUrl;
  if (baseUrl == null) return null;
  return ChallengeBoardApi(
    dio: ref.watch(dioProvider),
    identityStore: ref.watch(challengeIdentityStoreProvider),
    baseUrl: baseUrl,
  );
});

final apiChallengeRepositoryProvider = Provider<ApiChallengeRepository?>((ref) {
  final api = ref.watch(challengeBoardApiProvider);
  if (api == null) return null;
  return ApiChallengeRepository(api: api);
});

final challengeBoardRepositoryProvider =
    Provider<ChallengeBoardRepository>((ref) {
  final apiRepository = ref.watch(apiChallengeRepositoryProvider);
  if (apiRepository != null) return apiRepository;
  return ref.watch(sampleChallengeRepositoryProvider);
});

final challengeProfileRepositoryProvider =
    Provider<ChallengeProfileRepository>((ref) {
  final apiRepository = ref.watch(apiChallengeRepositoryProvider);
  if (apiRepository != null) return apiRepository;
  return ref.watch(sampleChallengeRepositoryProvider);
});

final challengeResultRepositoryProvider =
    Provider<ChallengeResultRepository>((ref) {
  final apiRepository = ref.watch(apiChallengeRepositoryProvider);
  if (apiRepository != null) return apiRepository;
  return ref.watch(sampleChallengeRepositoryProvider);
});

final challengeResultOutboxProvider = Provider<ChallengeResultOutbox>((ref) {
  return ChallengeResultOutbox(
    dao: ref.watch(appDatabaseProvider).appSettingsDao,
  );
});

final challengeResultSubmitterProvider = Provider<ChallengeResultSubmitter>(
  (ref) {
    return ChallengeResultSubmitter(
      repository: ref.watch(challengeResultRepositoryProvider),
      outbox: ref.watch(challengeResultOutboxProvider),
      enabled: ref.watch(challengeBoardApiProvider) != null,
    );
  },
);

final challengeBoardsProvider = FutureProvider<List<Board>>((ref) async {
  ref.watch(sampleChallengeRepositoryProvider);
  await ref.watch(challengeResultSubmitterProvider).flush();
  return ref.watch(challengeBoardRepositoryProvider).listBoards();
});

final challengeProfileProvider = FutureProvider<Player>((ref) async {
  ref.watch(sampleChallengeRepositoryProvider);
  return ref.watch(challengeProfileRepositoryProvider).getProfile();
});

final challengeLifetimeProvider = FutureProvider<LifetimeStats>((ref) async {
  await ref.watch(challengeResultSubmitterProvider).flush();
  final apiRepository = ref.watch(apiChallengeRepositoryProvider);
  if (apiRepository != null) return apiRepository.getLifetimeStats();
  return ref.watch(sampleChallengeRepositoryProvider).lifetimeStats;
});

final challengeBoardDetailProvider =
    FutureProvider.family<BoardDetail, String>((ref, boardId) async {
  ref.watch(sampleChallengeRepositoryProvider);
  await ref.watch(challengeResultSubmitterProvider).flush();
  return ref.watch(challengeBoardRepositoryProvider).getBoardDetail(boardId);
});
