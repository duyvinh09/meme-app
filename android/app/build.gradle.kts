import java.util.Base64
import java.nio.charset.StandardCharsets

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.duyvinh09.memeapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    var googleMapsApiKey = ""
    val dartDefines = project.findProperty("dart-defines") as? String
    if (dartDefines != null) {
        dartDefines.split(",").forEach { encoded ->
            try {
                val decoded = String(Base64.getDecoder().decode(encoded), StandardCharsets.UTF_8)
                val parts = decoded.split("=", limit = 2)
                if (parts.size == 2 && parts[0] == "GOOGLE_MAPS_API_KEY") {
                    googleMapsApiKey = parts[1]
                }
            } catch (_: Exception) {}
        }
    }
    if (googleMapsApiKey.isEmpty()) {
        val envFile = rootProject.file("../.env.json")
        if (envFile.exists()) {
            try {
                val content = envFile.readText()
                val regex = Regex(""""GOOGLE_MAPS_API_KEY"\s*:\s*"([^"]+)"""")
                val match = regex.find(content)
                if (match != null) {
                    googleMapsApiKey = match.groupValues[1]
                }
            } catch (_: Exception) {}
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.duyvinh09.memeapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKey
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
