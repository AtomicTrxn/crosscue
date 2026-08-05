/// One-shot, time-bounded holder for a solve route resolved from a
/// share-sheet puzzle import (see `_handleSharedMedia` in `app.dart`),
/// consumed by `appRouter`'s `redirect` in `app_router.dart`.
///
/// Why this exists: on a cold launch via the iOS Share Extension, iOS hands
/// the app a redirect URL (`ShareMedia-<bundle id>://...`) purely to
/// relaunch/foreground it. That URL isn't a real app route, but because
/// `FlutterDeepLinkingEnabled` is on, Flutter's engine still delivers it to
/// go_router as the platform's initial route — where it happens to resolve
/// to `/`. That platform-route delivery is asynchronous and can land
/// *after* the explicit `.go()` call `app.dart` makes once the shared file
/// has actually finished importing, silently clobbering the correct
/// navigation back to `/`. Stashing the intended destination here and
/// re-asserting it from `redirect` — which go_router re-evaluates for every
/// navigation, including that stray platform one — makes the correct
/// destination win regardless of ordering, the same way the existing
/// onboarding gate overrides wherever the router first resolved to.
library;

String? _pendingShareRoute;
DateTime? _pendingShareRouteSetAt;

/// Only guards against a stray platform-route delivery shortly after cold
/// start; bounded so a consumed-but-unused value can never cause a stale
/// redirect later in the session.
const _pendingShareRouteTtl = Duration(seconds: 5);

void setPendingShareRoute(String route) {
  _pendingShareRoute = route;
  _pendingShareRouteSetAt = DateTime.now();
}

/// Read-only except for TTL expiry — does not consume the value just
/// because it was read, since the caller may need to see it survive
/// multiple `redirect` evaluations (its own `.go()` call's pass, then
/// possibly a later stray one). Call [clearPendingShareRoute] once it's
/// actually used to redirect.
String? peekPendingShareRoute() {
  final route = _pendingShareRoute;
  final setAt = _pendingShareRouteSetAt;
  if (route == null || setAt == null) return null;
  if (DateTime.now().difference(setAt) > _pendingShareRouteTtl) {
    clearPendingShareRoute();
    return null;
  }
  return route;
}

void clearPendingShareRoute() {
  _pendingShareRoute = null;
  _pendingShareRouteSetAt = null;
}
