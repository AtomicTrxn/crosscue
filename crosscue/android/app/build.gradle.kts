import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing properties from key.properties (local dev) or environment variables (CI).
// key.properties is gitignored — never commit it.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "dev.tomhess.crosscue"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "dev.tomhess.crosscue"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val alias     = keystoreProperties.getProperty("keyAlias")      ?: System.getenv("KEY_ALIAS")
            val keyPass   = keystoreProperties.getProperty("keyPassword")   ?: System.getenv("KEY_PASSWORD")
            val storePass = keystoreProperties.getProperty("storePassword") ?: System.getenv("STORE_PASSWORD")
            val storePath = keystoreProperties.getProperty("storeFile")     ?: System.getenv("KEYSTORE_PATH")
            if (alias != null && keyPass != null && storePass != null && storePath != null) {
                keyAlias      = alias
                keyPassword   = keyPass
                storePassword = storePass
                storeFile     = file(storePath)
            }
        }
    }

    buildTypes {
        release {
            // Use release signing when keystore is configured; fall back to debug otherwise.
            val releaseCfg = signingConfigs.getByName("release")
            signingConfig = if (releaseCfg.storeFile != null) releaseCfg
                            else signingConfigs.getByName("debug")

            // Shrink Dart + Kotlin/Java code and resources. Flutter and plugin
            // ProGuard rules are picked up automatically; app-specific keep
            // rules live in proguard-rules.pro.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
