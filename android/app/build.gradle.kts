plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    signingConfigs {
        create("release") {
            storeFile = file("E:\\Projects\\key storages\\elifba.jks")
            storePassword = "sadokolik1!Q"
            keyAlias = "mrsadiq"
            keyPassword = "sadokolik1!Q"
        }
    }
    namespace = "com.example.elifba"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    signingConfigs {
        create("release") {
            storeFile = file("../../key/elifba.jks")
            storePassword = System.getenv("STORE_PASSWORD") ?: "sadokolik1!Q"
            keyAlias = "mrsadiq"
            keyPassword = System.getenv("KEY_PASSWORD") ?: "sadokolik1!Q"
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mrsadiq.elifba"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }
}

flutter {
    source = "../.."
}
