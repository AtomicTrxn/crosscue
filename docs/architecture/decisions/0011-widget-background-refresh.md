# ADR-0011 — Widget background refresh is best-effort, not an observer

**Status:** Accepted · **Date:** 2026-06 (#175)
**Setup/runbook:** [`../ios-widget-setup.md`](../ios-widget-setup.md)

## Context

The home-screen widget's "today" tile goes stale for users who don't open the
app; platform background execution is unreliable by design.

## Decision

A best-effort daily refresh via iOS `BGAppRefreshTask` + Android WorkManager
(`workmanager` plugin) driving one headless Dart callback
(`core/background/widget_refresh_scheduler.dart`). The callback stands up its
own `ProviderContainer`, runs the existing `attemptIfNeeded()` +
`HomeWidgetService.refresh()`, reads settings via the repository (never the
boot-throwing provider), is scheduled post-first-frame, and is idempotent.

Explicitly **not** a `WidgetsBindingObserver` — it runs in a separate isolate,
preserving the app's two-observer rule.

## Consequences

- iOS controls actual cadence; a stale tile after a long gap is expected
  throttling, not a bug (QA checklist §11 documents this).
- The reliable freshness path remains the in-app on-open refresh.
- The reverse-DNS task identifier must stay identical across the Dart
  scheduler, `Info.plist`, and `AppDelegate.swift` — drift means iOS silently
  never runs it.
