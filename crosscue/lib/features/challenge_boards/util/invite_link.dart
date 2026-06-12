import 'package:crosscue/core/routing/routes.dart';
import 'package:flutter/foundation.dart';

/// Public hosts that serve Crosscue challenge-board invite links.
///
/// The first entry is the canonical host used when generating share URLs
/// (Cloudflare Pages, live today); every entry is accepted on parse. The
/// `crosscue.app` apex is kept so links keep working if/when the domain is
/// registered later. This list is the single place client-side hosts are
/// defined — update it here if the Pages project name ever changes.
const List<String> kInviteLinkHosts = ['crosscue.pages.dev', 'crosscue.app'];

/// First path segment of an invite link (`/join/<boardId>`).
const String inviteLinkPathSegment = 'join';

/// A parsed challenge-board invite.
///
/// Invite URLs look like
/// `https://crosscue.pages.dev/join/<boardId>?token=<secret>` (see issue
/// #159). They reach the app two ways, both handled by [tryParse]:
///   * as the full public URL via App Links / Universal Links, and
///   * as the bare `/join/<boardId>?token=...` path, since go_router strips the
///     scheme/host from platform deep links before matching.
@immutable
class InviteLink {
  const InviteLink({required this.boardId, required this.token});

  final String boardId;
  final String token;

  /// The canonical shareable URL for this invite.
  Uri toShareUri() => Uri(
        scheme: 'https',
        host: kInviteLinkHosts.first,
        pathSegments: [inviteLinkPathSegment, boardId],
        queryParameters: {'token': token},
      );

  /// Parses [uri] into an [InviteLink], or returns null when it is not a
  /// well-formed invite. Accepts both the full public URL and the bare in-app
  /// path; if a host is present it must be one of [kInviteLinkHosts].
  static InviteLink? tryParse(Uri uri) {
    if (uri.host.isNotEmpty && !kInviteLinkHosts.contains(uri.host)) {
      return null;
    }

    final segments = uri.pathSegments;
    if (segments.length != 2) return null;
    if (segments[0] != inviteLinkPathSegment) return null;

    final boardId = segments[1];
    final token = uri.queryParameters['token'];
    if (boardId.isEmpty || token == null || token.isEmpty) return null;

    return InviteLink(boardId: boardId, token: token);
  }

  /// Convenience over [tryParse] for a raw string (e.g. a pasted link).
  static InviteLink? tryParseString(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri == null ? null : tryParse(uri);
  }

  @override
  bool operator ==(Object other) =>
      other is InviteLink && other.boardId == boardId && other.token == token;

  @override
  int get hashCode => Object.hash(boardId, token);

  @override
  String toString() => 'InviteLink(boardId: $boardId, token: <redacted>)';
}

/// Resolves the in-app location for an incoming `/join/:boardId` deep link.
///
/// A valid invite lands on the Challenge join surface carrying the board id and
/// token as query parameters; a malformed invite falls back to the Challenge
/// tab rather than erroring out.
String inviteDeepLinkRedirect(Uri uri) {
  final invite = InviteLink.tryParse(uri);
  if (invite == null) return Routes.challenge;
  return Uri(
    path: Routes.challengeJoin,
    queryParameters: {'board': invite.boardId, 'token': invite.token},
  ).toString();
}
