import 'package:crosscue/features/challenge_boards/presentation/challenge_action_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DioException apiError(String code, {int status = 400}) => DioException(
        requestOptions: RequestOptions(path: '/challenge'),
        type: DioExceptionType.badResponse,
        response: Response<Object?>(
          requestOptions: RequestOptions(path: '/challenge'),
          statusCode: status,
          data: {
            'error': {'code': code, 'message': 'server-only detail'},
          },
        ),
      );

  test('maps Challenge API error codes to safe action messages', () {
    final cases = <Object, String>{
      apiError('invalid_or_expired_invite', status: 410):
          'This invite is invalid or has expired. Ask for a fresh link.',
      apiError('board_full', status: 409):
          'This board is full. Ask the owner to make room.',
      apiError('board_limit_reached', status: 409):
          'You’re already in the maximum number of boards. Leave one to join another.',
      apiError('not_owner', status: 403): 'Only the board owner can do that.',
      apiError('member_not_found', status: 404):
          'That player is no longer on this board.',
      apiError('rate_limited', status: 429):
          'Too many requests. Please try again shortly.',
      apiError('client_too_old', status: 426):
          'Update Crosscue to continue using Challenge Boards.',
    };

    for (final entry in cases.entries) {
      expect(challengeActionErrorMessage(entry.key), entry.value);
    }
  });

  test('maps timeout, network, and unknown errors without exposing details',
      () {
    final requestOptions = RequestOptions(path: '/challenge');
    expect(
      challengeActionErrorMessage(
        DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.receiveTimeout,
        ),
      ),
      'Challenge Boards is taking too long to respond. Try again.',
    );
    expect(
      challengeActionErrorMessage(
        DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionError,
        ),
      ),
      'Couldn’t reach Challenge Boards. Check your connection and try again.',
    );
    expect(
      challengeActionErrorMessage(StateError('secret implementation detail')),
      'Couldn’t complete that Challenge Boards action. Please try again.',
    );
    expect(
      challengeActionErrorMessage(
        DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.badResponse,
          response: Response<Object?>(
            requestOptions: requestOptions,
            statusCode: 500,
            data: {'code': 123},
          ),
        ),
      ),
      'Couldn’t complete that Challenge Boards action. Please try again.',
    );
  });

  testWidgets('shows the mapped error as visible feedback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showChallengeActionError(
                context,
                apiError('rate_limited', status: 429),
              ),
              child: const Text('Trigger'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Trigger'));
    await tester.pump();

    expect(
      find.text('Too many requests. Please try again shortly.'),
      findsOneWidget,
    );
  });
}
