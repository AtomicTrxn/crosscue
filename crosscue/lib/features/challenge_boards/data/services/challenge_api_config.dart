import 'package:flutter/foundation.dart';

enum ChallengeApiEnvironment { sample, local, staging, production, custom }

@immutable
class ChallengeApiConfig {
  const ChallengeApiConfig({
    required this.environment,
    required this.baseUrl,
  });

  static const environmentDefine = 'CHALLENGE_API_ENV';
  static const baseUrlDefine = 'CHALLENGE_API_BASE_URL';

  static const _environmentName = String.fromEnvironment(
    environmentDefine,
    defaultValue: 'sample',
  );
  static const _baseUrlOverride = String.fromEnvironment(baseUrlDefine);

  final ChallengeApiEnvironment environment;
  final String? baseUrl;

  bool get usesApi => baseUrl != null;
  bool get isSample => !usesApi;

  String get label {
    return switch (environment) {
      ChallengeApiEnvironment.sample => 'sample',
      ChallengeApiEnvironment.local => 'local',
      ChallengeApiEnvironment.staging => 'staging',
      ChallengeApiEnvironment.production => 'production',
      ChallengeApiEnvironment.custom => 'custom',
    };
  }

  static ChallengeApiConfig fromDartDefines({
    TargetPlatform? platform,
  }) {
    return resolve(
      environmentName: _environmentName,
      baseUrlOverride: _baseUrlOverride,
      platform: platform ?? defaultTargetPlatform,
    );
  }

  static ChallengeApiConfig resolve({
    required String environmentName,
    required String baseUrlOverride,
    required TargetPlatform platform,
  }) {
    final environment = _parseEnvironment(environmentName);
    final trimmedOverride = baseUrlOverride.trim();
    if (trimmedOverride.isNotEmpty) {
      return ChallengeApiConfig(
        environment: environment == ChallengeApiEnvironment.sample
            ? ChallengeApiEnvironment.custom
            : environment,
        baseUrl: _trimTrailingSlash(trimmedOverride),
      );
    }

    if (environment == ChallengeApiEnvironment.local) {
      return ChallengeApiConfig(
        environment: environment,
        baseUrl: _localWorkerUrl(platform),
      );
    }

    return ChallengeApiConfig(environment: environment, baseUrl: null);
  }

  static ChallengeApiEnvironment _parseEnvironment(String raw) {
    return switch (raw.trim().toLowerCase()) {
      '' || 'sample' || 'mock' => ChallengeApiEnvironment.sample,
      'local' || 'dev' || 'development' => ChallengeApiEnvironment.local,
      'staging' => ChallengeApiEnvironment.staging,
      'prod' || 'production' => ChallengeApiEnvironment.production,
      'custom' => ChallengeApiEnvironment.custom,
      _ => ChallengeApiEnvironment.sample,
    };
  }

  static String _localWorkerUrl(TargetPlatform platform) {
    if (platform == TargetPlatform.android) return 'http://10.0.2.2:8787';
    return 'http://127.0.0.1:8787';
  }

  static String _trimTrailingSlash(String value) {
    return value.replaceFirst(RegExp(r'/+$'), '');
  }
}
