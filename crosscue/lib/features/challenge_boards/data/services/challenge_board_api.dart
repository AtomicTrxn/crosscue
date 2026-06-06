// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';
import 'dart:typed_data';

import 'package:crosscue/features/challenge_boards/data/services/challenge_identity_store.dart';
import 'package:crosscue/features/challenge_boards/domain/repositories/challenge_board_repository.dart';
import 'package:crosscue/features/challenge_boards/models/challenge_models.dart';
import 'package:dio/dio.dart';

class ChallengeBoardApi {
  ChallengeBoardApi({
    required Dio dio,
    required ChallengeIdentityStore identityStore,
    required String baseUrl,
  })  : _dio = dio,
        _identityStore = identityStore,
        _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), '');

  final Dio _dio;
  final ChallengeIdentityStore _identityStore;
  final String _baseUrl;

  Future<Player> bootstrap({String displayName = 'Player'}) async {
    final response = await _dio.post<Object?>(
      '$_baseUrl/players/bootstrap',
      data: {'displayName': displayName},
    );
    final data = _dataMap(response);
    final player = _player(data['player'], isMe: true);
    final token = data['authToken'] as String;
    await _identityStore.write(
      ChallengeIdentity(playerId: player.id, authToken: token),
    );
    return player;
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

  Future<CreateBoardResponse> createBoard(String name) async {
    final response = await _dio.post<Object?>(
      '$_baseUrl/boards',
      data: {'name': name},
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

  Future<Options> _authOptions() async {
    var identity = await _identityStore.read();
    if (identity == null) {
      await bootstrap();
      identity = await _identityStore.read();
    }
    final token = identity?.authToken;
    if (token == null) {
      throw const ChallengeApiException('missing_identity');
    }
    return Options(headers: {'authorization': 'Bearer $token'});
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
      final photoUrl = data['photoUrl'] as String?;
      final bytes = _dataUrlBytes(photoUrl);
      if (bytes != null) return PlayerAvatar.photoBytes(bytes);
      return PlayerAvatar.photo(photoUrl);
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
