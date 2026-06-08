// ignore_for_file: always_use_package_imports, directives_ordering, require_trailing_commas, deprecated_member_use, prefer_const_constructors, unused_import, unnecessary_import, avoid_dynamic_calls
import '../models/challenge_models.dart';

/// Sample data mirroring the HTML mockups. Replace with real providers.
abstract final class SampleData {
  static const me = Player(
    id: 'me',
    displayName: 'Maya',
    avatar: PlayerAvatar.silhouette(1),
    isMe: true,
  );

  static const boards = <Board>[
    Board(
        id: 'b1',
        name: 'The Cruciverbalists',
        playerCount: 12,
        myWeekly:
            Standing(rank: 1, outOf: 12, cleanSolves: 11, avgClean: '3:52')),
    Board(
        id: 'b2',
        name: 'Friday Night Crew',
        playerCount: 8,
        myWeekly:
            Standing(rank: 2, outOf: 8, cleanSolves: 9, avgClean: '4:18')),
    Board(
        id: 'b3',
        name: 'Office Puzzlers',
        playerCount: 5,
        myWeekly:
            Standing(rank: 4, outOf: 5, cleanSolves: 6, avgClean: '5:40')),
    Board(
        id: 'b4',
        name: 'Sunday Solvers',
        playerCount: 3,
        myWeekly:
            Standing(rank: 2, outOf: 3, cleanSolves: 7, avgClean: '4:33')),
    Board(
        id: 'b5',
        name: 'Mum & Dad',
        playerCount: 2,
        myWeekly:
            Standing(rank: 1, outOf: 2, cleanSolves: 5, avgClean: '6:02')),
  ];

  static const lifetime = LifetimeStats(
    avgClean: '4:46',
    cleanSolves: 128,
    bestClean: '2:18',
    rankingStatus: 'Top 25% in 4 of 5 boards',
    weeksCounted: 16,
  );

  static const lifetimeInsufficient = LifetimeStats(
    avgClean: '—',
    cleanSolves: 3,
    bestClean: '—',
    rankingStatus: '',
    weeksCounted: 0,
  );

  /// Neutral lifetime for the no-backend (sample) gate: nothing recorded yet,
  /// so nothing to rank. Used instead of [lifetime] so the shipped Challenge
  /// tab never shows fabricated lifetime standings. See issue #198.
  static const lifetimeEmpty = LifetimeStats(
    avgClean: '—',
    cleanSolves: 0,
    bestClean: '—',
    rankingStatus: 'Solve 5 clean puzzles to unlock lifetime ranking',
    weeksCounted: 0,
  );

  static const weeklyLeaderboard = <LeaderboardEntry>[
    LeaderboardEntry(
        rank: 1,
        cleanSolves: 11,
        avgClean: '3:52',
        player: Player(
            id: 'p1',
            displayName: 'Priya',
            avatar: PlayerAvatar.silhouette(1))),
    LeaderboardEntry(rank: 2, cleanSolves: 9, avgClean: '4:18', player: me),
    LeaderboardEntry(
        rank: 3,
        cleanSolves: 8,
        avgClean: '4:40',
        player: Player(
            id: 'p3', displayName: 'Sam', avatar: PlayerAvatar.silhouette(2))),
    LeaderboardEntry(
        rank: 4,
        cleanSolves: 7,
        avgClean: '5:01',
        player: Player(
            id: 'p4',
            displayName: 'Jordan',
            avatar: PlayerAvatar.silhouette(3))),
    LeaderboardEntry(
        rank: 5,
        cleanSolves: 6,
        avgClean: '4:55',
        player: Player(id: 'p5', displayName: 'Alex')),
    LeaderboardEntry(
        rank: 6,
        cleanSolves: 5,
        avgClean: '5:30',
        player: Player(id: 'p6', displayName: 'Riley')),
    LeaderboardEntry(
        rank: 7,
        cleanSolves: 4,
        avgClean: '6:10',
        player: Player(id: 'p7', displayName: 'Chris')),
    LeaderboardEntry(
        rank: 8,
        cleanSolves: 2,
        avgClean: '7:02',
        player: Player(id: 'p8', displayName: 'Dana')),
  ];

  static const invitePreview = InvitePreview(
    result: InviteResult.valid,
    boardName: 'The Cruciverbalists',
    playerCount: 12,
    daysUntilExpiry: 28,
  );
}
