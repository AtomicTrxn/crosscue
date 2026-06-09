import 'package:crosscue/features/settings/data/daos/app_settings_dao.dart';

class ChallengeIdentityStore {
  const ChallengeIdentityStore({required this.dao});

  static const _playerIdKey = 'challenge_player_id';
  static const _authTokenKey = 'challenge_auth_token';
  static const _recoverySecretKey = 'challenge_recovery_secret';

  final AppSettingsDao dao;

  /// The usable runtime identity: requires both a player id and an auth token.
  Future<ChallengeIdentity?> read() async {
    final playerId = await dao.getValue(_playerIdKey);
    final authToken = await dao.getValue(_authTokenKey);
    if (playerId == null || authToken == null) return null;
    return ChallengeIdentity(
      playerId: playerId,
      authToken: authToken,
      recoverySecret: await dao.getValue(_recoverySecretKey),
    );
  }

  /// The recovery bundle survives auth-token loss (e.g. device restore). It is
  /// readable even when no auth token is present so identity can be restored
  /// before bootstrapping a new player.
  Future<ChallengeRecoveryBundle?> readRecoveryBundle() async {
    final playerId = await dao.getValue(_playerIdKey);
    final recoverySecret = await dao.getValue(_recoverySecretKey);
    if (playerId == null || recoverySecret == null) return null;
    return ChallengeRecoveryBundle(
      playerId: playerId,
      recoverySecret: recoverySecret,
    );
  }

  /// Persists the identity. The recovery secret is only written when present so
  /// a token refresh (restore) never clears an existing bundle.
  Future<void> write(ChallengeIdentity identity) async {
    await dao.setValue(_playerIdKey, identity.playerId);
    await dao.setValue(_authTokenKey, identity.authToken);
    final recoverySecret = identity.recoverySecret;
    if (recoverySecret != null) {
      await dao.setValue(_recoverySecretKey, recoverySecret);
    }
  }

  /// Replaces only the recovery secret, e.g. after server-side rotation.
  Future<void> writeRecoverySecret(String recoverySecret) =>
      dao.setValue(_recoverySecretKey, recoverySecret);

  /// Forgets the player id, auth token, and recovery bundle on this device,
  /// e.g. after server-side player deletion.
  Future<void> clear() async {
    await dao.removeValue(_playerIdKey);
    await dao.removeValue(_authTokenKey);
    await dao.removeValue(_recoverySecretKey);
  }
}

class ChallengeIdentity {
  const ChallengeIdentity({
    required this.playerId,
    required this.authToken,
    this.recoverySecret,
  });

  final String playerId;
  final String authToken;
  final String? recoverySecret;
}

class ChallengeRecoveryBundle {
  const ChallengeRecoveryBundle({
    required this.playerId,
    required this.recoverySecret,
  });

  final String playerId;
  final String recoverySecret;
}
