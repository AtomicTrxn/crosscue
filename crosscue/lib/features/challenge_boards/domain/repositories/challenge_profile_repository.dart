import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';

abstract interface class ChallengeProfileRepository {
  Future<Player> getProfile();
  Future<Player> updateDisplayName(String displayName);
  Future<Player> updateAvatar(PlayerAvatar avatar);
}
