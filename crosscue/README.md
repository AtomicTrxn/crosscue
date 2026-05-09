# Crosscue — Flutter App

Android crossword puzzle app built with Flutter. See the [project root](../) for full documentation.

## Quick Start

```bash
# All commands run from this directory (crosscue/)

# Run on emulator
flutter run -d <device-id>

# Build + install debug APK
flutter build apk --debug --no-pub
adb -s <device-id> install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s <device-id> shell am start -n com.crosscue.crosscue/.MainActivity

# Regenerate after model/notifier/table changes
dart run build_runner build

# Full CI pipeline (run from repo root)
cd .. && make ci
```
