import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Maps Challenge Boards transport and API errors to safe, actionable copy.
///
/// Server-provided messages are intentionally never shown directly: they can
/// change independently of the client and may expose implementation detail.
String challengeActionErrorMessage(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 426) {
      return 'Update Crosscue to continue using Challenge Boards.';
    }

    final code = _serverErrorCode(error.response?.data);
    final message = switch (code) {
      'invalid_invite' ||
      'invalid_or_expired_invite' =>
        'This invite is invalid or has expired. Ask for a fresh link.',
      'board_deleted' ||
      'board_not_found' =>
        'This board is no longer available.',
      'board_full' => 'This board is full. Ask the owner to make room.',
      'board_limit_reached' =>
        'You’re already in the maximum number of boards. Leave one to join another.',
      'not_owner' => 'Only the board owner can do that.',
      'member_not_found' => 'That player is no longer on this board.',
      'rate_limited' => 'Too many requests. Please try again shortly.',
      _ => null,
    };
    if (message != null) return message;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Challenge Boards is taking too long to respond. Try again.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      return 'Couldn’t reach Challenge Boards. Check your connection and try again.';
    }
  }

  return 'Couldn’t complete that Challenge Boards action. Please try again.';
}

/// Shows the shared error copy for an interaction that failed asynchronously.
void showChallengeActionError(BuildContext context, Object error) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(challengeActionErrorMessage(error))),
    );
}

String? _serverErrorCode(Object? data) {
  if (data is! Map) return null;
  final nested = data['error'];
  if (nested is Map && nested['code'] is String) {
    return nested['code'] as String;
  }
  final flat = data['code'];
  return flat is String ? flat : null;
}
