# Dependency Audit — Issue #65

Audit run with:

```bash
cd crosscue
flutter pub outdated
```

Date: May 17, 2026

## Decisions

| Package | Decision | Rationale |
|---------|----------|-----------|
| `file_picker` | Bump now to `^11.0.2` | Latest stable still supports the current Dart floor and includes an Android path-traversal fix; migrate the removed `FilePicker.platform` API to the static calls introduced by the newer major version. |
| `drift` / `drift_dev` | Defer on the current `2.31.x` line | Latest `2.33.x` requires Dart 3.10; take with a deliberate SDK-floor update. |
| `drift_flutter` | Defer on `0.2.x` | Keep aligned with the current Drift line until the Dart 3.10 upgrade pass. |
| `sqlite3_flutter_libs` | Defer on `0.5.x` | `0.6.0+eol` requires Dart 3.10 and belongs with the future `sqlite3` 3.x migration. |
| `sqlite3` | Defer on `2.x` | `3.x` is part of the same Dart 3.10 migration set as Drift and `sqlite3_flutter_libs`. |
| `package_info_plus` | Defer on `9.x` | `10.x` requires Dart 3.10 / newer Flutter baselines. |
| `share_plus` | Defer on `12.x` | `13.x` requires Dart 3.10 / newer Flutter baselines. |

## Notes

- The declared SDK floor is now `>=3.5.0` because the locked Drift line already
  requires Dart 3.5; the previous `>=3.4.0` declaration understated the actual
  supported floor.
- The next coordinated dependency pass should decide whether to raise the floor
  to Dart 3.10 and migrate the deferred set together rather than piecemeal.
