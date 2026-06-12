# ADR-0003 — Shared settings row widget library

**Status:** Accepted · **Date:** 2026 (Sprint 4)

## Context

Settings-adjacent screens were each hand-building switch/nav rows with
slightly different paddings and divider treatments.

## Decision

Shared row widgets (`SettingsSwitchRow`, `SettingsNavRow`,
`SettingsSectionHeader`, `SettingsRowDivider`) live in
`features/settings/presentation/widgets/settings_rows.dart` and are used by
all settings-adjacent screens (including sync and privacy).

## Consequences

- Visual consistency for free; new settings surfaces compose these widgets
  rather than restyling rows.
