# Contributing

## Read First

Before writing code, read these docs in order:

| Doc | What it covers |
|-----|---------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Layer rules, feature structure, data flow, new-feature checklist |
| [GitHub Issues](https://github.com/AtomicTrxn/crosscue/issues) | Open, planned, and deferred work |
| [MODELS.md](MODELS.md) | Domain models, field lists, database mappings, ID formats |
| [CONVENTIONS.md](CONVENTIONS.md) | Project coding rules |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Build, run, install, release, and debugging notes |

## Commands

All `make` targets run from the repo root. All direct `flutter` and `dart`
commands run from `crosscue/`.

```bash
# Hosted PR-equivalent checks
make ci

# Individual checks
make format
make analyze
make test
make generated
make build

# Run a single test file
cd crosscue && flutter test test/features/import/puz_parser_test.dart

# Code generation after @freezed / @riverpod / Drift changes
cd crosscue && dart run build_runner build

# Run on emulator
cd crosscue && flutter run -d <device-id>
```

Run `make ci` before pushing or opening a pull request. The pre-push hook
enforces it on pushes to `main`; feature-branch pushes are not blocked.

## Architecture Notes

Crosscue uses feature-local clean architecture:

- domain models never import Flutter
- presentation never touches Drift tables directly
- repositories are exposed through interface-typed Riverpod providers
- shared infrastructure lives under `lib/core/`
- feature code lives under `lib/features/<name>/`

Important local conventions:

- use `Routes` constants instead of raw route strings
- puzzle IDs contain `:`, so encode before navigation and decode on read
- parsers and repositories return `Result<T, E>` rather than throwing across
  layer boundaries
- run `build_runner` after changes to generated models, providers, or tables

## CI

Regular pull requests and pushes to `main` emit two required checks:

- `Static checks`: formatting, analysis, and generated-file verification for
  app-affecting changes
- `Test`: Flutter tests for app-affecting changes

Documentation-only changes still emit those checks, but they finish quickly
without setting up Flutter. Release workflows run the full app checks and build
signed release artifacts.
