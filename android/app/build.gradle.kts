plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.myapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.myapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    // ===== Signing Configs =====
    signingConfigs {
        create("release") {
            val keystoreFile = file("../release.keystore")
            if (keystoreFile.exists()) {
                storeFile = keystoreFile
                storePassword = System.getenv("KEYSTORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Saxiix APK-ga la sameeyay hase yeeshee iska dhaaf haddii aan keystore la helin
            if (signingConfigs.getByName("release").storeFile?.exists() == true) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = null
            }

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            // Haddii aad rabto debug signing, default debug key
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.android.gms:play-services-cast-framework:21.4.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}

// Disable validation tasks when keystore is missing (for CI)
tasks.whenTaskAdded {
    if (name.startsWith("validateSigning")) {
        enabled = false
    }
}
