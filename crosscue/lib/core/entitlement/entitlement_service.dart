/// Abstract entitlement service. The shipping build wires
/// [FreeEntitlementService]; the interface exists so a paid-tier
/// implementation (e.g. RevenueCat) can be dropped in later without changing
/// callers.
abstract class EntitlementService {
  Future<bool> isProUnlocked();
  Future<bool> hasFeature(String featureKey);
}
