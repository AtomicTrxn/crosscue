import 'package:crosscue/core/routing/routes.dart';
import 'package:crosscue/features/challenge_boards/util/invite_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InviteLink.tryParse', () {
    test('parses the full public invite URL on every supported host', () {
      expect(kInviteLinkHosts, contains('crosscue.pages.dev'));
      expect(kInviteLinkHosts, contains('crosscue.app'));
      for (final host in kInviteLinkHosts) {
        final invite = InviteLink.tryParse(
          Uri.parse('https://$host/join/board-123?token=abc123'),
        );
        expect(invite, isNotNull, reason: 'host $host should parse');
        expect(invite!.boardId, 'board-123');
        expect(invite.token, 'abc123');
      }
    });

    test('parses the live Cloudflare Pages host', () {
      final invite = InviteLink.tryParse(
        Uri.parse('https://crosscue.pages.dev/join/board-123?token=abc123'),
      );
      expect(invite, isNotNull);
      expect(invite!.boardId, 'board-123');
      expect(invite.token, 'abc123');
    });

    test('parses the bare in-app path (scheme/host stripped by go_router)', () {
      final invite = InviteLink.tryParse(Uri.parse('/join/b1?token=t1'));
      expect(invite, isNotNull);
      expect(invite!.boardId, 'b1');
      expect(invite.token, 't1');
    });

    test('decodes percent-encoded board id and token', () {
      final invite = InviteLink.tryParse(
        Uri.parse('https://crosscue.app/join/a%20b?token=x%2Fy'),
      );
      expect(invite!.boardId, 'a b');
      expect(invite.token, 'x/y');
    });

    test('rejects a foreign host', () {
      expect(
        InviteLink.tryParse(Uri.parse('https://evil.example/join/b?token=t')),
        isNull,
      );
      // Lookalike pages.dev projects are foreign hosts too.
      expect(
        InviteLink.tryParse(
          Uri.parse('https://crosscue-evil.pages.dev/join/b?token=t'),
        ),
        isNull,
      );
    });

    test('rejects a missing or empty token', () {
      expect(InviteLink.tryParse(Uri.parse('/join/b')), isNull);
      expect(InviteLink.tryParse(Uri.parse('/join/b?token=')), isNull);
    });

    test('rejects the wrong path shape', () {
      expect(InviteLink.tryParse(Uri.parse('/join?token=t')), isNull);
      expect(InviteLink.tryParse(Uri.parse('/board/b?token=t')), isNull);
      expect(InviteLink.tryParse(Uri.parse('/join/b/extra?token=t')), isNull);
    });

    test('round-trips through toShareUri', () {
      const invite = InviteLink(boardId: 'b1', token: 't1');
      final parsed = InviteLink.tryParse(invite.toShareUri());
      expect(parsed, invite);
    });

    test('toShareUri uses the canonical (Pages) host', () {
      const invite = InviteLink(boardId: 'b1', token: 't1');
      expect(invite.toShareUri().host, 'crosscue.pages.dev');
    });

    test('toString redacts the token', () {
      expect(
        const InviteLink(boardId: 'b1', token: 'secret').toString(),
        isNot(contains('secret')),
      );
    });
  });

  group('inviteDeepLinkRedirect', () {
    test('valid invite redirects to the challenge join location with params',
        () {
      final target = inviteDeepLinkRedirect(
        Uri.parse('https://crosscue.app/join/b1?token=t1'),
      );
      final uri = Uri.parse(target);
      expect(uri.path, Routes.challengeJoin);
      expect(uri.queryParameters['board'], 'b1');
      expect(uri.queryParameters['token'], 't1');
    });

    test('malformed invite falls back to the Challenge tab', () {
      expect(
        inviteDeepLinkRedirect(Uri.parse('/join/b1')),
        Routes.challenge,
      );
    });
  });
}
