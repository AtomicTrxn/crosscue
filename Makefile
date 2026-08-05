# Crosscue — local CI helpers
# Mirrors .github/workflows/ci.yml exactly.
# Run from the repo root.

FLUTTER := flutter
DART    := dart
DIR     := crosscue
# Hosted CI and release builds pin this version (kept in sync with
# .github/workflows/ci.yml's FLUTTER_VERSION by scripts/ci-flutter.sh, which
# parses it directly rather than duplicating it here). Individual targets
# below (format/analyze/test/generated) default to whatever Flutter is on
# PATH for fast dev-loop iteration; `make ci` overrides FLUTTER/DART to the
# pinned SDK so the pre-push gate can't silently diverge from hosted CI.
HOSTED_FLUTTER_VERSION := 3.44.0

.PHONY: ci check toolchain static format analyze test generated worker build install-hooks \
        _require-tag release-github release-publish-github release-testflight release-all \
        release-play-internal release-play-alpha release-play-beta release-play-production

## Match the hosted PR CI checks — using the *pinned* Flutter SDK hosted CI
## enforces (scripts/ci-flutter.sh), not whatever's on PATH. `make format` /
## `make analyze` / etc. below still use PATH Flutter for fast dev-loop
## iteration; `ci` is the pre-push gate and must match hosted CI exactly, or
## a local-only toolchain drift (e.g. a `dart format`/build_runner output
## change between Dart patch versions) passes here and only fails after
## you've already pushed and burned a hosted Actions run. See
## DEPLOYMENT.md § Verify locally.
ci:
	@PINNED_BIN=$$(scripts/ci-flutter.sh) && \
		(cd $(DIR) && $$PINNED_BIN/flutter pub get) && \
		$(MAKE) check FLUTTER=$$PINNED_BIN/flutter DART=$$PINNED_BIN/dart

## Run all hosted PR checks.
check: toolchain static test worker

## Report the local Flutter runtime used by Make targets. This is informational:
## CI/release workflows enforce the pinned version above.
toolchain:
	@echo "▶ toolchain (hosted CI/release: $(HOSTED_FLUTTER_VERSION))"
	@$(FLUTTER) --version | sed -n '1p'

## Run static checks that share one setup pass in hosted CI.
static: format analyze generated

## Stage 1 — formatting
format:
	@echo "▶ format"
	cd $(DIR) && $(DART) format --output=none --set-exit-if-changed .

## Stage 2 — checks (run individually or via `check`)
analyze:
	@echo "▶ analyze"
	cd $(DIR) && $(FLUTTER) analyze

test:
	@echo "▶ test"
	cd $(DIR) && $(FLUTTER) test

generated:
	@echo "▶ generated files"
	cd $(DIR) && $(DART) run build_runner build
	cd $(DIR) && git diff --exit-code -- \
		'*.g.dart' '*.freezed.dart'

## Challenge-boards Worker tests + typecheck (hosted "Worker checks" job).
worker:
	@echo "▶ worker tests + typecheck"
	cd $(DIR)/backend/challenge_boards && npm install --no-audit --no-fund \
		&& npm test && npm run typecheck

## Install git hooks (run once after cloning)
install-hooks:
	@bash scripts/install-hooks.sh

## Optional local build verification (not part of hosted PR CI)
build:
	@echo "▶ build debug APK"
	cd $(DIR) && $(FLUTTER) build apk --debug --no-pub

## ─── Release dispatch ─────────────────────────────────────────────────
## All release targets require TAG=vX.Y.Z (must already exist as a git tag
## on origin). Every release rebuilds from the tag and creates/updates a
## *draft* GitHub Release. Store uploads are layered on top. Publish only
## after signed-build verification and QA using release-publish-github.

TAG ?=

_require-tag:
	@if [ -z "$(TAG)" ]; then \
		echo "✗ TAG=vX.Y.Z is required (e.g. make release-github TAG=v1.2.8)"; \
		exit 1; \
	fi

## Mode 1 — build Android + iOS and create/update a draft GitHub Release;
## no store uploads — test_flight and play_store both default to false.
release-github: _require-tag
	@echo "▶ release-github $(TAG)"
	gh workflow run release.yml -f tag=$(TAG)

## Publish an existing draft only after signed-build verification and QA.
## This repeats the signed build gates but does not upload to either store.
release-publish-github: _require-tag
	@echo "▶ release-publish-github $(TAG)"
	gh workflow run release.yml -f tag=$(TAG) -f publish_github_release=true

## Mode 2 — TestFlight (also creates/updates the draft GitHub release)
release-testflight: _require-tag
	@echo "▶ release-testflight $(TAG)"
	gh workflow run release.yml -f tag=$(TAG) -f test_flight=true

## Mode 4 — both stores in one dispatch: TestFlight + Play (TRACK=internal
## by default). The everyday "ship to both platforms" command.
TRACK ?= internal
release-all: _require-tag
	@echo "▶ release-all $(TAG) (TestFlight + Play $(TRACK))"
	gh workflow run release.yml -f tag=$(TAG) -f test_flight=true \
		-f play_store=true -f track=$(TRACK)

## Mode 3 — Play Store only (also creates/updates the draft GitHub release)
release-play-internal: _require-tag
	@echo "▶ release-play-internal $(TAG)"
	gh workflow run release.yml -f tag=$(TAG) -f play_store=true -f track=internal

release-play-alpha: _require-tag
	@echo "▶ release-play-alpha $(TAG)"
	gh workflow run release.yml -f tag=$(TAG) -f play_store=true -f track=alpha

release-play-beta: _require-tag
	@echo "▶ release-play-beta $(TAG)"
	gh workflow run release.yml -f tag=$(TAG) -f play_store=true -f track=beta

release-play-production: _require-tag
	@echo "▶ release-play-production $(TAG)"
	gh workflow run release.yml -f tag=$(TAG) -f play_store=true -f track=production
