import 'package:crosscue/features/challenge_boards/data/services/challenge_api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChallengeApiConfig', () {
    test('defaults to sample mode when no API config is provided', () {
      final config = ChallengeApiConfig.resolve(
        environmentName: '',
        baseUrlOverride: '',
        platform: TargetPlatform.iOS,
      );

      expect(config.environment, ChallengeApiEnvironment.sample);
      expect(config.baseUrl, isNull);
      expect(config.usesApi, isFalse);
      expect(config.isSample, isTrue);
    });

    test('local mode uses Android emulator host address on Android', () {
      final config = ChallengeApiConfig.resolve(
        environmentName: 'local',
        baseUrlOverride: '',
        platform: TargetPlatform.android,
      );

      expect(config.environment, ChallengeApiEnvironment.local);
      expect(config.baseUrl, 'http://10.0.2.2:8787');
      expect(config.usesApi, isTrue);
    });

    test('local mode uses loopback for iOS simulator and desktop hosts', () {
      final config = ChallengeApiConfig.resolve(
        environmentName: 'local',
        baseUrlOverride: '',
        platform: TargetPlatform.iOS,
      );

      expect(config.environment, ChallengeApiEnvironment.local);
      expect(config.baseUrl, 'http://127.0.0.1:8787');
    });

    test('explicit base URL enables staging or production API mode', () {
      final staging = ChallengeApiConfig.resolve(
        environmentName: 'staging',
        baseUrlOverride: 'https://staging.example.test/',
        platform: TargetPlatform.iOS,
      );
      final production = ChallengeApiConfig.resolve(
        environmentName: 'production',
        baseUrlOverride: 'https://api.example.test/',
        platform: TargetPlatform.iOS,
      );

      expect(staging.environment, ChallengeApiEnvironment.staging);
      expect(staging.baseUrl, 'https://staging.example.test');
      expect(production.environment, ChallengeApiEnvironment.production);
      expect(production.baseUrl, 'https://api.example.test');
    });

    test('staging and production without a base URL fail fast', () {
      for (final name in ['staging', 'production']) {
        expect(
          () => ChallengeApiConfig.resolve(
            environmentName: name,
            baseUrlOverride: '',
            platform: TargetPlatform.iOS,
          ),
          throwsStateError,
          reason: '$name must not silently fall back to sample data',
        );
      }
    });

    test('base URL without an environment is treated as custom API mode', () {
      final config = ChallengeApiConfig.resolve(
        environmentName: 'sample',
        baseUrlOverride: 'http://localhost:8787',
        platform: TargetPlatform.iOS,
      );

      expect(config.environment, ChallengeApiEnvironment.custom);
      expect(config.baseUrl, 'http://localhost:8787');
    });
  });
}
