# Crosscue — local CI helpers
# Mirrors .github/workflows/ci.yml exactly.
# Run from the repo root.

FLUTTER := flutter
DART    := dart
DIR     := crosscue

.PHONY: ci format analyze test generated build install-hooks

## Run all checks in pipeline order (format → analyze+test+generated → build)
ci: format analyze test generated build

## Stage 1 — formatting
format:
	@echo "▶ format"
	cd $(DIR) && $(DART) format --output=none --set-exit-if-changed .

## Stage 2 — parallel checks (run individually or via `ci`)
analyze:
	@echo "▶ analyze"
	cd $(DIR) && $(FLUTTER) analyze

test:
	@echo "▶ test"
	cd $(DIR) && $(FLUTTER) test

generated:
	@echo "▶ generated files"
	cd $(DIR) && $(DART) run build_runner build
	cd $(DIR) && git diff --exit-code

## Install git hooks (run once after cloning)
install-hooks:
	@bash scripts/install-hooks.sh

## Stage 3 — build
build:
	@echo "▶ build debug APK"
	cd $(DIR) && $(FLUTTER) build apk --debug --no-pub
