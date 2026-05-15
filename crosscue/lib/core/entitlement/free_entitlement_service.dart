import 'package:crosscue/core/entitlement/entitlement_service.dart';

/// Entitlement service that grants every feature unconditionally. No ads,
/// no paywalls, no feature gating in the shipping build.
class FreeEntitlementService implements EntitlementService {
  const FreeEntitlementService();

  @override
  Future<bool> isProUnlocked() async => false;

  @override
  Future<bool> hasFeature(String featureKey) async => true;
}
