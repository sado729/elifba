plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.vebstudio.elifba"
    // Target Android 16 (API 36) to meet Google Play's target API level requirement.
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    signingConfigs {
        create("release") {
            storeFile = file("../../key/elifba.jks")
            storePassword = System.getenv("STORE_PASSWORD") ?: "sadokolik1!Q"
            keyAlias = "vebstudio"
            keyPassword = System.getenv("KEY_PASSWORD") ?: "sadokolik1!Q"
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.vebstudio.elifba"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // R8 ilə kod kiçildilməsi və istifadə olunmayan resursların atılması.
            // Flutter, just_audio və media3 öz keep qaydalarını consumer-rules
            // kimi gətirir, ona görə proguard-rules.pro boşdur.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
