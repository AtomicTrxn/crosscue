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
| `drift` / `drift_dev` | Defer on the current `2.31.x` line | `2.33.x` now requires a coordinated sqlite3 3.x migration and conflicts with the current Riverpod generator / Flutter `meta` constraint set. |
| `drift_flutter` | Defer on `0.2.x` | `0.3.0` belongs to the same coordinated Drift/sqlite migration set and cannot be taken independently. |
| `sqlite3_flutter_libs` | Defer on `0.5.x` | `0.6.0+eol` is the migration boundary for sqlite3 3.x and is blocked by the same generator stack conflict. |
| `sqlite3` | Defer on `2.x` | `3.x` is part of the same blocked Drift/sqlite migration set. |
| `package_info_plus` | Defer on `9.x` | `10.x` requires Dart 3.10 / Flutter 3.38.1 and currently conflicts with `file_picker` 11 through incompatible `win32` constraints. |
| `share_plus` | Defer on `12.x` | `13.x` requires Dart 3.10 / Flutter 3.38.1 and currently conflicts with `file_picker` 11 through incompatible `win32` constraints. |

## Notes

- The declared SDK floor is now `>=3.5.0` because the locked Drift line already
  requires Dart 3.5; the previous `>=3.4.0` declaration understated the actual
  supported floor.
- The next coordinated dependency pass should decide whether to raise the floor
  to Dart 3.10 and migrate the deferred set together rather than piecemeal.


## Drift 2.33 review

Issue #63 was reviewed separately after the audit:

- `drift` `2.33.0` and `drift_dev` `2.33.0` are the current 2.33-line releases.
- `drift_flutter` `0.3.0` requires `sqlite3_flutter_libs` `^0.6.0+eol`, which is the migration boundary for the sqlite3 3.x line.
- A dry-run solve for the coordinated upgrade set (`drift:^2.33.0`, `drift_dev:^2.33.0`, `drift_flutter:^0.3.0`, `sqlite3_flutter_libs:^0.6.0+eol`, `sqlite3:^3.3.1`) fails with the current generator stack: `drift_dev >=2.32.1` requires `analyzer >=10.0.0`, while the app’s `riverpod_generator ^4.0.3` path remains constrained by Flutter’s pinned `meta 1.17.0`.
- Migration coverage already exists in `test/core/database/app_database_test.dart`; the blocked work is dependency coordination, not missing migration tests.

Decision: keep the current Drift/sqlite line for now and take the Drift 2.33 move together with the generator/toolchain update that resolves the analyzer/meta constraint boundary.

## `share_plus` 13 review

Issue #61 was reviewed separately after the audit:

- `share_plus` `13.1.0` requires Dart `>=3.10.0` and Flutter `>=3.38.1`.
- A dry-run solve for `share_plus:^13.1.0` fails while the app remains on
  `file_picker:^11.0.2`: `share_plus` 13 pulls `win32` `^6.0.1`, while
  `file_picker` 11 requires `win32` `^5.9.0`.
- Current share flows use the modern `SharePlus.instance.share(ShareParams(...))`
  API already:
  - puzzle completion result sharing
  - stats export from `StatsExportNotifier`
  - stats export from `StatsExportService`

Decision: keep `share_plus` on `12.x` until the next coordinated toolchain
upgrade also resolves the `file_picker` / `win32` compatibility boundary.

## `package_info_plus` 10 review

Issue #62 was reviewed separately after the audit:

- `package_info_plus` `10.1.0` requires Dart `>=3.10.0` and Flutter
  `>=3.38.1`.
- A dry-run solve for `package_info_plus:^10.1.0` fails while the app remains
  on `file_picker:^11.0.2`: `package_info_plus` 10 pulls `win32` `^6.0.1`,
  while `file_picker` 11 requires `win32` `^5.9.0`.
- The Settings → About path already uses the current public API shape:
  `PackageInfo.fromPlatform()` inside `appVersionProvider`.

Decision: keep `package_info_plus` on `9.x` until the same coordinated
toolchain / file-picker upgrade that unlocks the rest of the Dart 3.10 set.
