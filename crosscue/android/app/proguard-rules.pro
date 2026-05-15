# Crosscue app-specific ProGuard / R8 rules.
#
# Flutter and each plugin contribute their own keep rules via consumer
# proguard files, which the Android Gradle plugin merges in automatically.
# Only add app-level rules here.

# Keep our MainActivity (Flutter looks it up by name via AndroidManifest).
-keep class dev.tomhess.crosscue.MainActivity { *; }

# Suppress noisy "missing class" warnings from optional Play Core split
# install APIs that ship in Flutter's stock manifest but aren't actually
# used by this app (we don't dynamic-feature-split).
-dontwarn com.google.android.play.core.**
