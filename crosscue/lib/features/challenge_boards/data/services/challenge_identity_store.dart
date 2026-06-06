import 'package:crosscue/features/settings/data/daos/app_settings_dao.dart';

class ChallengeIdentityStore {
  const ChallengeIdentityStore({required this.dao});

  static const _playerIdKey = 'challenge_player_id';
  static const _authTokenKey = 'challenge_auth_token';

  final AppSettingsDao dao;

  Future<ChallengeIdentity?> read() async {
    final playerId = await dao.getValue(_playerIdKey);
    final authToken = await dao.getValue(_authTokenKey);
    if (playerId == null || authToken == null) return null;
    return ChallengeIdentity(playerId: playerId, authToken: authToken);
  }

  Future<void> write(ChallengeIdentity identity) async {
    await dao.setValue(_playerIdKey, identity.playerId);
    await dao.setValue(_authTokenKey, identity.authToken);
  }
}

class ChallengeIdentity {
  const ChallengeIdentity({
    required this.playerId,
    required this.authToken,
  });

  final String playerId;
  final String authToken;
}
