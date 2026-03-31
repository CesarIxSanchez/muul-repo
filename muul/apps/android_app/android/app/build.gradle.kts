plugins {
    id("com.android.application")
    id("kotlin-android")
<<<<<<< HEAD
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
=======
>>>>>>> 8dfdbb967fa7a81e178b5567ad9faa96d1be0d74
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.android_app"
    compileSdk = flutter.compileSdkVersion
<<<<<<< HEAD
    ndkVersion = flutter.ndkVersion
=======
    ndkVersion = "28.2.13676358"
>>>>>>> 8dfdbb967fa7a81e178b5567ad9faa96d1be0d74

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

<<<<<<< HEAD
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.android_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
=======
    // ✅ Nueva forma con compilerOptions DSL (reemplaza kotlinOptions)
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.android_app"
        minSdk = flutter.minSdkVersion  // ✅ Sintaxis Kotlin DSL correcta
>>>>>>> 8dfdbb967fa7a81e178b5567ad9faa96d1be0d74
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
<<<<<<< HEAD
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
=======
>>>>>>> 8dfdbb967fa7a81e178b5567ad9faa96d1be0d74
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

<<<<<<< HEAD
=======


>>>>>>> 8dfdbb967fa7a81e178b5567ad9faa96d1be0d74
flutter {
    source = "../.."
}
