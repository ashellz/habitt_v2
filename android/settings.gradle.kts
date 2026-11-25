pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.3.15") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.3.0" apply false
    // :habitt-core, the snapshot model shared by the widgets and the Wear OS app
    id("org.jetbrains.kotlin.jvm") version "2.3.0" apply false
    // Compose compiler for the Jetpack Glance home screen widgets
    id("org.jetbrains.kotlin.plugin.compose") version "2.3.0" apply false
}

include(":app")
// shared snapshot model and watch contract (docs/watch_app.md)
include(":habitt-core")
// the Wear OS app (docs/watch_app.md)
include(":wear")
