plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mrsadiq.elifba"
    compileSdk = 35

    signingConfigs {
        create("release") {
            storeFile = file("E:\\Projects\\key storages\\elifba.jks")
            storePassword = "sadokolik1!Q"
            keyAlias = "mrsadiq"
            keyPassword = "sadokolik1!Q"
        }
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.mrsadiq.elifba"
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        
        // Build optimizasiyası
        multiDexEnabled = true
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    
    // Build performansı üçün
    dexOptions {
        javaMaxHeapSize = "4g"
        preDexLibraries = false
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
