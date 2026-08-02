package dev.tomhess.crosscue

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

// Explicit edge-to-edge opt-in for Android 15/SDK 35+ (Play Console advisory
// "Edge-to-edge may not display for all users"; see build.gradle.kts for the
// sibling deprecated-API advisory this app also hit, #266).
// FlutterActivity extends plain android.app.Activity, not
// androidx.activity.ComponentActivity, so the androidx.activity
// enableEdgeToEdge() convenience helper doesn't apply here (receiver type
// mismatch) — WindowCompat.setDecorFitsSystemWindows is the same underlying
// mechanism and works on any Activity's Window. Must run before
// super.onCreate() so it's in effect before the Flutter view is attached.
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
    }
}
