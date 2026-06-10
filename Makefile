# Crosscue — local CI helpers
# Mirrors .github/workflows/ci.yml exactly.
# Run from the repo root.

FLUTTER := flutter
DART    := dart
DIR     := crosscue

.PHONY: ci check static format analyze test generated worker build install-hooks \
        _require-tag release-github release-testflight release-all \
        release-play-internal release-play-alpha release-play-beta release-play-production

## Match the hosted PR CI checks.
ci: check

## Run all hosted PR checks.
check: static test worker

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
## on origin). Every release rebuilds from the tag and (re-)publishes the
## GitHub Release. Store uploads are layered on top.

TAG ?=

_require-tag:
	@if [ -z "$(TAG)" ]; then \
		echo "✗ TAG=vX.Y.Z is required (e.g. make release-github TAG=v1.2.8)"; \
		exit 1; \
	fi

## Mode 1 — GitHub release only (builds Android + iOS, publishes APK;
## no store uploads — test_flight and play_store both default to false)
release-github: _require-tag
	@echo "▶ release-github $(TAG)"
	gh workflow run release.yml -f tag=$(TAG)

## Mode 2 — TestFlight (also (re)publishes GitHub release with APK)
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

## Mode 3 — Play Store only (also (re)publishes GitHub release with APK + AAB)
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
