import 'entitlement_service.dart';

/// Phase 1 entitlement service — all features are free.
/// No ads, no paywalls, no feature gating in Phase 1.
class FreeEntitlementService implements EntitlementService {
  const FreeEntitlementService();

  @override
  Future<bool> isProUnlocked() async => false;

  @override
  Future<bool> hasFeature(String featureKey) async => true;
}
