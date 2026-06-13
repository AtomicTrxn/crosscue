import 'dart:convert';
import 'dart:typed_data';

import 'package:crosscue/features/challenge_boards/data/services/challenge_identity_store.dart';
import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/domain/repositories/challenge_board_repository.dart';
import 'package:dio/dio.dart';

class ChallengeBoardApi {
  ChallengeBoardApi({
    required Dio dio,
    required ChallengeIdentityStore identityStore,
    required String baseUrl,
    String? clientIdentity,
  })  : _dio = dio,
        _identityStore = identityStore,
        _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
        _clientIdentity = clientIdentity;

  final Dio _dio;
  final ChallengeIdentityStore _identityStore;
  final String _baseUrl;

  /// `<platform>/<semver>` identity sent as [clientHeaderName] on every
  /// request so the Worker's minimum-client gate can act on it (#256).
  final String? _clientIdentity;

  /// Wire header for the Worker's force-upgrade lever (#256).
  static const clientHeaderName = 'x-crosscue-client';

  /// True when [error] is the Worker's structured 426 `client_too_old`
  /// response — the UI should ask the user to update Crosscue rather than
  /// offer a retry (#256).
  static bool isClientTooOld(Object error) =>
      error is DioException && error.response?.statusCode == 426;

  Map<String, String> get _clientHeaders => switch (_clientIdentity) {
        null => const {},
        final identity => {clientHeaderName: identity},
      };

  Options _clientOptions() => Options(headers: {..._clientHeaders});

  Future<Player> bootstrap({String displayName = 'Player'}) async {
    final response = await _dio.post<Object?>(
      '$_baseUrl/players/bootstrap',
      data: {'displayName': displayName},
      options: _clientOptions(),
    );
    final data = _dataMap(response);
    final player = _player(data['player'], isMe: true);
    final token = data['authToken'] as String;
    await _identityStore.write(
      ChallengeIdentity(
        playerId: player.id,
        authToken: token,
        recoverySecret: data['recoverySecret'] as String?,
      ),
    );
    return player;
  }

  /// Exchanges a stored recovery bundle for a fresh auth token, restoring an
  /// existing anonymous player instead of creating a new one.
  Future<Player> restore(ChallengeRecoveryBundle bundle) async {
    final response = await _dio.post<Object?>(
      '$_baseUrl/players/restore',
      data: {
        'playerId': bundle.playerId,
        'recoverySecret': bundle.recoverySecret,
      },
      options: _clientOptions(),
    );
    final data = _dataMap(response);
    final player = _player(data['player'], isMe: true);
    final token = data['authToken'] as String;
    await _identityStore.write(
      ChallengeIdentity(
        playerId: player.id,
        authToken: token,
        recoverySecret: bundle.recoverySecret,
      ),
    );
    return player;
  }

  /// Rotates the server-side recovery secret and persists the new value,
  /// invalidating older recovery bundles.
  Future<void> rotateRecovery() async {
    final response = await _dio.post<Object?>(
      '$_baseUrl/players/recovery/rotate',
      options: await _authOptions(),
    );
    final secret = _dataMap(response)['recoverySecret'] as String?;
    if (secret != null) {
      await _identityStore.writeRecoverySecret(secret);
    }
  }

  Future<Player> getProfile() async {
    final response = await _dio.get<Object?>(
      '$_baseUrl/players/me',
      options: await _authOptions(),
    );
    return _player(_dataMap(response)['player'], isMe: true);
  }

  Future<Player> updateDisplayName(String displayName) async {
    final response = await _dio.patch<Object?>(
      '$_baseUrl/players/me',
      data: {'displayName': displayName},
      options: await _authOptions(),
    );
    return _player(_dataMap(response)['player'], isMe: true);
  }

  Future<Player> updateAvatar(PlayerAvatar avatar) async {
    final data = switch (avatar.kind) {
      AvatarKind.photo => {
          'kind': 'photo',
          if (avatar.photoBytes != null)
            'photoPngBase64': base64Encode(avatar.photoBytes!),
        },
      AvatarKind.silhouette => {
          'kind': 'silhouette',
          'silhouetteLook': avatar.silhouetteLook,
        },
      AvatarKind.initials => {'kind': 'initials'},
    };
    final response = await _dio.post<Object?>(
      '$_baseUrl/players/me/avatar',
      data: data,
      options: await _authOptions(),
    );
    return _player(_dataMap(response)['player'], isMe: true);
  }

  Future<ChallengeSummaryResponse> listBoards() async {
    final response = await _dio.get<Object?>(
      '$_baseUrl/boards',
      options: await _authOptions(),
    );
    final data = _dataMap(response);
    return ChallengeSummaryResponse(
      boards: _list(data['boards']).map(_board).toList(growable: false),
      lifetime: _lifetime(data['lifetime']),
    );
  }

  Future<CreateBoardResponse> createBoard(CreateBoardDraft draft) async {
    final response = await _dio.post<Object?>(
      '$_baseUrl/boards',
      data: {
        'name': draft.name,
        'rankingMode': draft.rankingMode.apiValue,
      },
      options: await _authOptions(),
    );
    final data = _dataMap(response);
    return CreateBoardResponse(
      board: _board(data['board']),
      inviteLink: data['inviteLink'] as String?,
    );
  }

  Future<BoardDetail> getBoardDetail(String boardId) async {
    final response = await _dio.get<Object?>(
      '$_baseUrl/boards/$boardId',
      options: await _authOptions(),
    );
    final data = _dataMap(response);
    return BoardDetail(
      board: _board(data['board']),
      weekly: _list(data['weekly']).map(_entry).toList(growable: false),
      lifetime: _list(data['lifetime']).map(_entry).toList(growable: false),
    );
  }

  Future<InvitePreview> previewInvite(String inviteLink) async {
    final response = await _dio.post<Object?>(
      '$_baseUrl/invites/preview',
      data: {'inviteLink': inviteLink},
      options: await _authOptions(),
    );
    return _invitePreview(_dataMap(response)['invite']);
  }

  Future<Board?> joinInvite(String inviteLink) async {
    final response = await _dio.post<Object?>(
      '$_baseUrl/invites/join',
      data: {'inviteLink': inviteLink},
      options: await _authOptions(),
    );
    return _board(_dataMap(response)['board']);
  }

  Future<void> removeMember(String boardId, String playerId) async {
    await _dio.delete<Object?>(
      '$_baseUrl/boards/$boardId/members/$playerId',
      options: await _authOptions(),
    );
  }

  Future<void> leaveBoard(String boardId) async {
    await _dio.post<Object?>(
      '$_baseUrl/boards/$boardId/leave',
      options: await _authOptions(),
    );
  }

  Future<String> regenerateInvite(String boardId) async {
    final response = await _dio.post<Object?>(
      '$_baseUrl/boards/$boardId/invite/regenerate',
      options: await _authOptions(),
    );
    return _dataMap(response)['inviteLink'] as String;
  }

  Future<String> freshInviteLink(String boardId) => regenerateInvite(boardId);

  Future<void> submitSolveResult(ChallengeSolveSubmission submission) async {
    await _dio.post<Object?>(
      '$_baseUrl/results',
      data: submission.toJson(),
      options: await _authOptions(),
    );
  }

  /// Deletes the server-side player and clears the local identity. No-op when
  /// no identity exists; never bootstraps a player just to delete it.
  Future<void> deleteAccount() async {
    final identity = await _identityStore.read();
    if (identity == null) return;
    await _dio.delete<Object?>(
      '$_baseUrl/players/me',
      options: Options(
        headers: {
          'authorization': 'Bearer ${identity.authToken}',
          ..._clientHeaders,
        },
      ),
    );
    await _identityStore.clear();
  }

  Future<Options> _authOptions() async {
    var identity = await _identityStore.read();
    if (identity == null) {
      // No usable auth token. Restore an existing player from the recovery
      // bundle (e.g. after a device restore) before bootstrapping a new one.
      final bundle = await _identityStore.readRecoveryBundle();
      if (bundle != null) {
        await restore(bundle);
      } else {
        await bootstrap();
      }
      identity = await _identityStore.read();
    }
    final token = identity?.authToken;
    if (token == null) {
      throw const ChallengeApiException('missing_identity');
    }
    return Options(
      headers: {'authorization': 'Bearer $token', ..._clientHeaders},
    );
  }

  Map<String, Object?> _dataMap(Response<Object?> response) {
    final data = response.data;
    if (data is Map<String, Object?>) return data;
    if (data is Map) return Map<String, Object?>.from(data);
    throw const ChallengeApiException('invalid_response');
  }

  List<Object?> _list(Object? value) {
    if (value is List<Object?>) return value;
    if (value is List) return List<Object?>.from(value);
    return const <Object?>[];
  }

  Board _board(Object? raw) {
    final data = _map(raw);
    return Board(
      id: data['id'] as String,
      name: data['name'] as String,
      playerCount: (data['playerCount'] as num).toInt(),
      rankingMode: ChallengeRankingMode.fromApi(data['rankingMode']),
      ownerPlayerId: data['ownerPlayerId'] as String?,
      myWeekly: _standing(data['myWeekly']),
    );
  }

  Standing _standing(Object? raw) {
    final data = _map(raw);
    return Standing(
      rank: (data['rank'] as num).toInt(),
      outOf: (data['outOf'] as num).toInt(),
      cleanSolves: (data['cleanSolves'] as num).toInt(),
      avgClean: data['avgClean'] as String,
      bestClean: data['bestClean'] as String? ?? '—',
      totalClean: data['totalClean'] as String? ?? '—',
    );
  }

  LifetimeStats _lifetime(Object? raw) {
    final data = _map(raw);
    return LifetimeStats(
      avgClean: data['avgClean'] as String,
      cleanSolves: (data['cleanSolves'] as num).toInt(),
      bestClean: data['bestClean'] as String,
      rankingStatus: data['rankingStatus'] as String,
      weeksCounted: (data['weeksCounted'] as num).toInt(),
    );
  }

  LeaderboardEntry _entry(Object? raw) {
    final data = _map(raw);
    return LeaderboardEntry(
      rank: (data['rank'] as num).toInt(),
      player: _player(data['player']),
      cleanSolves: (data['cleanSolves'] as num).toInt(),
      avgClean: data['avgClean'] as String,
      bestClean: data['bestClean'] as String? ?? '—',
      totalClean: data['totalClean'] as String? ?? '—',
      weeksCounted: (data['weeksCounted'] as num?)?.toInt(),
    );
  }

  Player _player(Object? raw, {bool? isMe}) {
    final data = _map(raw);
    return Player(
      id: data['id'] as String,
      displayName: data['displayName'] as String,
      avatar: _avatar(data['avatar']),
      isMe: isMe ?? data['isMe'] == true,
    );
  }

  PlayerAvatar _avatar(Object? raw) {
    final data = _map(raw);
    final kind = data['kind'] as String?;
    if (kind == 'photo') {
      // `photoUrl` arrives either as an inline `data:image/png;base64,…`
      // string (legacy D1 storage — supported forever) or, once the server
      // half of #268 lands, as an immutable `https:` URL fetched lazily by
      // the avatar widget. Any other scheme is treated as no photo, so the
      // UI falls back to initials.
      final photoUrl = data['photoUrl'] as String?;
      final bytes = _dataUrlBytes(photoUrl);
      if (bytes != null) return PlayerAvatar.photoBytes(bytes);
      if (photoUrl != null && photoUrl.startsWith('https://')) {
        return PlayerAvatar.photo(photoUrl);
      }
      return const PlayerAvatar.initials();
    }
    if (kind == 'silhouette') {
      return PlayerAvatar.silhouette(
        ((data['silhouetteLook'] as num?) ?? 1).toInt(),
      );
    }
    return const PlayerAvatar.initials();
  }

  Uint8List? _dataUrlBytes(String? photoUrl) {
    if (photoUrl == null || !photoUrl.startsWith('data:image/png;base64,')) {
      return null;
    }
    return base64Decode(photoUrl.substring('data:image/png;base64,'.length));
  }

  InvitePreview _invitePreview(Object? raw) {
    final data = _map(raw);
    return InvitePreview(
      result: switch (data['result'] as String) {
        'valid' => InviteResult.valid,
        'boardFull' => InviteResult.boardFull,
        'alreadyMember' => InviteResult.alreadyMember,
        'playerLimitReached' => InviteResult.playerLimitReached,
        'boardDeleted' => InviteResult.boardDeleted,
        _ => InviteResult.invalidOrExpired,
      },
      boardName: data['boardName'] as String,
      playerCount: (data['playerCount'] as num).toInt(),
      daysUntilExpiry: (data['daysUntilExpiry'] as num).toInt(),
    );
  }

  Map<String, Object?> _map(Object? raw) {
    if (raw is Map<String, Object?>) return raw;
    if (raw is Map) return Map<String, Object?>.from(raw);
    throw const ChallengeApiException('invalid_response');
  }
}

class ChallengeSummaryResponse {
  const ChallengeSummaryResponse({
    required this.boards,
    required this.lifetime,
  });

  final List<Board> boards;
  final LifetimeStats lifetime;
}

class CreateBoardResponse {
  const CreateBoardResponse({
    required this.board,
    required this.inviteLink,
  });

  final Board board;
  final String? inviteLink;
}

class ChallengeApiException implements Exception {
  const ChallengeApiException(this.code);

  final String code;

  @override
  String toString() => 'ChallengeApiException($code)';
}
