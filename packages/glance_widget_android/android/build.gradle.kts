// The Compose compiler is required to build this module's Glance widgets, but
// no Flutter app template declares `org.jetbrains.kotlin.plugin.compose` in its
// `pluginManagement` block. Declaring it in a versionless `plugins {}` block
// therefore fails in every consumer app with "Plugin [id: ...] was not found".
// Bringing our own classpath here keeps the plugin self-contained.
buildscript {
    // The Compose compiler plugin version must equal the Kotlin version the host
    // app resolved. Apps pinned to a different Kotlin version can override this
    // with `glance.kotlinVersion` in their `gradle.properties`.
    val composeCompilerVersion =
        (project.findProperty("glance.kotlinVersion") as String?)
            ?: (project.findProperty("kotlin.version") as String?)
            ?: "2.4.0"

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("org.jetbrains.kotlin:compose-compiler-gradle-plugin:$composeCompilerVersion")
    }
}

plugins {
    id("com.android.library")
    // The Kotlin Gradle Plugin is deliberately NOT applied here. Flutter's own
    // Gradle plugin applies `kotlin-android` to every plugin project whenever
    // AGP's built-in Kotlin is disabled -- which is what both the Flutter app
    // template and the Flutter migrator configure
    // (`android.builtInKotlin=false`). Applying KGP ourselves would additionally
    // trip Flutter 3.47's "plugins applying KGP will fail to build" warning.
}

// Applied imperatively rather than in `plugins {}` because the classpath is
// supplied by the `buildscript` block above. The Compose Gradle plugin attaches
// itself via `pluginManager.withPlugin(...)`, so it does not matter that Flutter
// applies `kotlin-android` after this point.
apply(plugin = "org.jetbrains.kotlin.plugin.compose")

group = "dev.glance.widget.android"
version = "1.0"

android {
    namespace = "dev.glance.widget.android"
    compileSdk = 36

    defaultConfig {
        // Jetpack Glance requires API 23; API 26 is the floor at which app
        // widgets pin reliably and `AppWidgetManager.requestPinAppWidget`
        // exists.
        minSdk = 26
        consumerProguardFiles("consumer-rules.pro")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Compose BOM and runtime — Glance renders through the Compose runtime.
    implementation(platform("androidx.compose:compose-bom:2026.06.01"))
    implementation("androidx.compose.runtime:runtime")

    // Glance for app widgets
    implementation("androidx.glance:glance-appwidget:1.2.0")
    implementation("androidx.glance:glance-material3:1.2.0")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")

    // DataStore for widget state
    implementation("androidx.datastore:datastore-preferences:1.2.1")

    // Gson for JSON serialization
    implementation("com.google.code.gson:gson:2.14.0")

    // WorkManager for background updates
    implementation("androidx.work:work-runtime-ktx:2.11.2")
}
