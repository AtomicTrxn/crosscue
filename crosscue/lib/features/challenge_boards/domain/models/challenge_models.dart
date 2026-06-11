import 'dart:typed_data';

import 'package:meta/meta.dart';

/// Crosscue · Challenge Boards — domain models.
///
/// Pure data classes (immutable). Wire these to your repository / Riverpod
/// providers. No serialization is prescribed — adapt to your API layer.

/// How a player's avatar is rendered.
enum AvatarKind { initials, silhouette, photo }

enum ChallengeRankingMode {
  fastestTime('fastest_time', 'Fastest time', 'Best'),
  averageTime('average_time', 'Average time', 'Avg'),
  totalTime('total_time', 'Total time', 'Total');

  const ChallengeRankingMode(this.apiValue, this.label, this.metricLabel);

  final String apiValue;
  final String label;
  final String metricLabel;

  static ChallengeRankingMode fromApi(Object? value) {
    return ChallengeRankingMode.values.firstWhere(
      (mode) => mode.apiValue == value,
      orElse: () => ChallengeRankingMode.averageTime,
    );
  }
}

@immutable
class PlayerAvatar {
  final AvatarKind kind;

  /// 1..10 when [kind] is silhouette (see kPresetAvatars).
  final int silhouetteLook;

  /// Local/remote image reference when [kind] is photo (already normalized).
  final String? photoUrl;

  /// In-memory normalized PNG bytes while the UI-first implementation has no
  /// remote avatar storage yet.
  final Uint8List? photoBytes;
  const PlayerAvatar.initials()
      : kind = AvatarKind.initials,
        silhouetteLook = 1,
        photoUrl = null,
        photoBytes = null;
  const PlayerAvatar.silhouette(this.silhouetteLook)
      : kind = AvatarKind.silhouette,
        photoUrl = null,
        photoBytes = null;
  const PlayerAvatar.photo(this.photoUrl)
      : kind = AvatarKind.photo,
        silhouetteLook = 1,
        photoBytes = null;
  const PlayerAvatar.photoBytes(this.photoBytes)
      : kind = AvatarKind.photo,
        silhouetteLook = 1,
        photoUrl = null;
}

@immutable
class Player {
  final String id;

  /// ≤ 10 chars, validated (see util/display_name_validator.dart).
  final String displayName;
  final PlayerAvatar avatar;
  final bool isMe;
  const Player({
    required this.id,
    required this.displayName,
    this.avatar = const PlayerAvatar.initials(),
    this.isMe = false,
  });

  Player copyWith({
    String? id,
    String? displayName,
    PlayerAvatar? avatar,
    bool? isMe,
  }) {
    return Player(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      isMe: isMe ?? this.isMe,
    );
  }
}

/// A player's standing within a board for one period (week or lifetime).
@immutable
class Standing {
  final int rank;
  final int outOf;

  /// Clean solves = finished with no checks or reveals.
  final int cleanSolves;

  /// Average clean solve time, pre-formatted "m:ss" for display.
  final String avgClean;
  final String bestClean;
  final String totalClean;
  const Standing({
    required this.rank,
    required this.outOf,
    required this.cleanSolves,
    required this.avgClean,
    this.bestClean = '—',
    this.totalClean = '—',
  });

  bool get isFirst => rank == 1;

  String metricFor(ChallengeRankingMode mode) {
    return switch (mode) {
      ChallengeRankingMode.fastestTime => bestClean,
      ChallengeRankingMode.averageTime => avgClean,
      ChallengeRankingMode.totalTime => totalClean,
    };
  }
}

/// A board the signed-in player belongs to, with their weekly standing.
@immutable
class Board {
  final String id;
  final String name;
  final int playerCount;
  final ChallengeRankingMode rankingMode;

  /// The signed-in player's standing this UTC week.
  final Standing myWeekly;
  const Board({
    required this.id,
    required this.name,
    required this.playerCount,
    required this.myWeekly,
    this.rankingMode = ChallengeRankingMode.averageTime,
  });
}

@immutable
class CreateBoardDraft {
  const CreateBoardDraft({
    required this.name,
    required this.rankingMode,
  });

  final String name;
  final ChallengeRankingMode rankingMode;
}

/// Compact lifetime aggregate (completed UTC weeks only).
@immutable
class LifetimeStats {
  final String avgClean; // "4:46"
  final int cleanSolves; // 128
  final String bestClean; // "2:18"
  final String rankingStatus; // "Top 25% in 4 of 5 boards"
  final int weeksCounted;
  const LifetimeStats({
    required this.avgClean,
    required this.cleanSolves,
    required this.bestClean,
    required this.rankingStatus,
    required this.weeksCounted,
  });

  /// Lifetime ranking unlocks at 5 clean solves.
  bool get hasEnoughSample => cleanSolves >= 5;
  int get cleanSolvesToUnlock => (5 - cleanSolves).clamp(0, 5);
}

/// A leaderboard entry for board detail (weekly or lifetime).
@immutable
class LeaderboardEntry {
  final int rank;
  final Player player;
  final int cleanSolves;
  final String avgClean;
  final String bestClean;
  final String totalClean;

  /// Lifetime view only.
  final int? weeksCounted;
  const LeaderboardEntry({
    required this.rank,
    required this.player,
    required this.cleanSolves,
    required this.avgClean,
    this.bestClean = '—',
    this.totalClean = '—',
    this.weeksCounted,
  });

  String metricFor(ChallengeRankingMode mode) {
    return switch (mode) {
      ChallengeRankingMode.fastestTime => bestClean,
      ChallengeRankingMode.averageTime => avgClean,
      ChallengeRankingMode.totalTime => totalClean,
    };
  }
}

enum LeaderboardMode { weekly, lifetime }

/// A completed puzzle result that can be submitted to Challenge Boards.
enum ChallengeCompletionType { clean, checked, hinted, revealed, unsolved }

@immutable
class ChallengeSolveSubmission {
  const ChallengeSolveSubmission({
    required this.sourceId,
    required this.sourcePuzzleId,
    required this.completedAtUtc,
    required this.elapsedMs,
    required this.completionType,
    required this.cleanSolveEligible,
    this.puzzleTitle,
    this.publishedOn,
  });

  final String sourceId;
  final String sourcePuzzleId;
  final DateTime completedAtUtc;
  final int elapsedMs;
  final ChallengeCompletionType completionType;
  final bool cleanSolveEligible;
  final String? puzzleTitle;
  final DateTime? publishedOn;

  bool get isClean =>
      completionType == ChallengeCompletionType.clean && cleanSolveEligible;

  Map<String, Object?> toJson() {
    return {
      'sourceId': sourceId,
      'sourcePuzzleId': sourcePuzzleId,
      'completedAt': completedAtUtc.toUtc().toIso8601String(),
      'elapsedMs': elapsedMs,
      'completionType': completionType.name,
      'cleanSolveEligible': cleanSolveEligible,
      if (puzzleTitle != null) 'puzzleTitle': puzzleTitle,
      if (publishedOn != null)
        'publishedOn': publishedOn!.toUtc().toIso8601String().split('T').first,
    };
  }

  factory ChallengeSolveSubmission.fromJson(Map<String, Object?> json) {
    return ChallengeSolveSubmission(
      sourceId: json['sourceId'] as String,
      sourcePuzzleId: json['sourcePuzzleId'] as String,
      completedAtUtc: DateTime.parse(json['completedAt'] as String).toUtc(),
      elapsedMs: (json['elapsedMs'] as num).toInt(),
      completionType: ChallengeCompletionType.values.byName(
        json['completionType'] as String,
      ),
      cleanSolveEligible: json['cleanSolveEligible'] == true,
      puzzleTitle: json['puzzleTitle'] as String?,
      publishedOn: json['publishedOn'] == null
          ? null
          : DateTime.parse(json['publishedOn'] as String).toUtc(),
    );
  }
}

/// The result of resolving an invite link.
enum InviteResult {
  valid,
  boardFull,
  alreadyMember,
  playerLimitReached,
  invalidOrExpired,
  boardDeleted,
  offline,
  networkError,
}

@immutable
class InvitePreview {
  final InviteResult result;
  final String boardName;
  final int playerCount;
  final int daysUntilExpiry; // 0..30
  const InvitePreview({
    required this.result,
    required this.boardName,
    required this.playerCount,
    required this.daysUntilExpiry,
  });
}

/// Loading / data / error / offline envelope for any async surface.
enum LoadStatus { loading, data, error, offline }

@immutable
class Loadable<T> {
  final LoadStatus status;
  final T? data;

  /// For offline: how stale the cached [data] is, pre-formatted ("2h ago").
  final String? lastUpdatedLabel;
  const Loadable.loading()
      : status = LoadStatus.loading,
        data = null,
        lastUpdatedLabel = null;
  const Loadable.data(this.data, {this.lastUpdatedLabel})
      : status = LoadStatus.data;
  const Loadable.error()
      : status = LoadStatus.error,
        data = null,
        lastUpdatedLabel = null;
  const Loadable.offline(this.data, {this.lastUpdatedLabel})
      : status = LoadStatus.offline;

  bool get isEmpty => data == null || (data is List && (data as List).isEmpty);
}

/// Product limits (single source of truth).
abstract final class ChallengeLimits {
  static const int maxBoardsPerPlayer = 5;
  static const int maxPlayersPerBoard = 20;
  static const int inviteExpiryDays = 30;
  static const int displayNameMaxLen = 10;
  static const int lifetimeMinSample = 5;
  static const int avatarOutputSize = 512; // px, square; rendered circular
}
