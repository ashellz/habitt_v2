// The widget snapshot model and the watch ↔ phone contract (docs/home_widgets.md,
// docs/watch_app.md), shared by the phone's home screen widgets (:app) and the
// Wear OS app (:wear). Pure Kotlin + org.json, so it is unit tested on the JVM:
//
//   ./gradlew :habitt-core:test
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("org.jetbrains.kotlin.jvm")
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    // Android ships org.json; on the JVM (tests) it comes from Maven
    compileOnly("org.json:json:20240303")
    testImplementation("org.json:json:20240303")
    testImplementation("junit:junit:4.13.2")
}
