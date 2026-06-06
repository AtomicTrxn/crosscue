// ignore_for_file: always_use_package_imports, directives_ordering, require_trailing_commas, deprecated_member_use, prefer_const_constructors, unused_import, unnecessary_import, avoid_dynamic_calls
import 'package:crosscue/features/challenge_boards/models/challenge_models.dart';

abstract interface class ChallengeProfileRepository {
  Future<Player> getProfile();
  Future<Player> updateDisplayName(String displayName);
  Future<Player> updateAvatar(PlayerAvatar avatar);
}
