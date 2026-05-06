/// Abstract entitlement service. Phase 1 uses FreeEntitlementService.
/// Phase 2+ will replace with RevenueCat or similar without changing callers.
abstract class EntitlementService {
  Future<bool> isProUnlocked();
  Future<bool> hasFeature(String featureKey);
}
