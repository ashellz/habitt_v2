// The Wear OS app (docs/watch_app.md). A separate APK/AAB with the phone
// app's application id and signing key, which the Wear OS Data Layer needs to
// connect the two. Built from android/:
//
//   ./gradlew :wear:assembleDebug        (then adb -s <watch> install; not
//                                         :wear:installDebug with a phone connected)
//   ./gradlew :wear:bundleRelease
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("org.jetbrains.kotlin.plugin.compose")
}

// Same signing as :app (android/key.properties, gitignored); store paths in it
// are relative to android/app.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
fun keystore(key: String) = rootProject.file("app").resolve(keystoreProperties[key] as String)

// Version from pubspec.yaml like the phone app. Play needs a unique version
// code per artifact under one package: the watch uses 1_000_000 + the build
// number (2.6.0+117 → 1000117).
val pubspecVersion = rootProject.file("../pubspec.yaml").readLines()
    .first { it.startsWith("version:") }.substringAfter(":").trim()
val wearVersionName = pubspecVersion.substringBefore("+")
val wearBuildNumber = pubspecVersion.substringAfter("+", "1").toInt()

android {
    namespace = "com.shellz.habitt.wear"
    compileSdk = 36

    defaultConfig {
        // must match the phone app (Data Layer)
        applicationId = "com.shellz.habitt"
        minSdk = 30
        targetSdk = 36
        versionCode = 1_000_000 + wearBuildNumber
        versionName = wearVersionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
    }

    val hasKeyProperties = keystorePropertiesFile.exists()
    signingConfigs {
        if (hasKeyProperties) {
            getByName("debug") {
                storeFile = keystore("debugStoreFile")
                storePassword = keystoreProperties["debugStorePassword"] as String
                keyAlias = keystoreProperties["debugKeyAlias"] as String
                keyPassword = keystoreProperties["debugKeyPassword"] as String
            }
            create("release") {
                storeFile = keystore("storeFile")
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
        }
        if (hasKeyProperties) {
            getByName("debug") {
                signingConfig = signingConfigs.getByName("debug")
            }
            getByName("release") {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    implementation(project(":habitt-core"))

    implementation("androidx.activity:activity-compose:1.10.1")
    implementation("androidx.wear.compose:compose-material3:1.5.0")
    implementation("androidx.wear.compose:compose-foundation:1.5.0")
    implementation("androidx.wear.compose:compose-navigation:1.5.0")

    implementation("com.google.android.gms:play-services-wearable:19.0.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.10.2")
}
