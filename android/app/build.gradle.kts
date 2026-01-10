plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import org.jetbrains.kotlin.gradle.dsl.JvmTarget

android {
    namespace = "com.shellz.habitt"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Kotlin compiler configuration moved to top-level kotlin { compilerOptions }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.shellz.habitt"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
   
    signingConfigs {
        getByName("debug") {
            storeFile = file("keystore/debug.keystore")
            storePassword = "2005JimsH"
            keyAlias = "androiddebugkey"
            keyPassword = "2005JimsH"
        }

        create("release") {
            storeFile = file("keystore/habitt-release-key.keystore")
            storePassword = "2005JimsH"
            keyAlias = "habitt-key-alias"
            keyPassword = "2005JimsH"
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }

        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    jvmToolchain(17)
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}
