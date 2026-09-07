// The Compose compiler is required to build this module's Glance widgets, but
// no Flutter app template declares `org.jetbrains.kotlin.plugin.compose` in its
// `pluginManagement` block. Declaring it in a versionless `plugins {}` block
// therefore fails in every consumer app with "Plugin [id: ...] was not found".
// Bringing our own classpath here keeps the plugin self-contained.
buildscript {
    // The Compose compiler plugin must be built against the same Kotlin release
    // as the host app's Kotlin Gradle Plugin, and that version is chosen by the
    // app, not by us. `KotlinCompilerVersion` sits on the shared buildscript
    // classloader once KGP has been resolved, so read the version from there and
    // follow whatever the app picked instead of pinning one and drifting.
    //
    // Escape hatches, in order: `glance.kotlinVersion` for apps that need to
    // override the detection, then the app's own `kotlin.version` property, then
    // a pinned fallback for when KGP is not on the classloader at all.
    val detectedKotlinVersion =
        runCatching {
            Class
                .forName("org.jetbrains.kotlin.config.KotlinCompilerVersion")
                .getField("VERSION")
                .get(null) as String
        }.getOrNull()

    val composeCompilerVersion =
        (project.findProperty("glance.kotlinVersion") as String?)
            ?: detectedKotlinVersion
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

    testOptions {
        unitTests {
            // Robolectric needs the merged resources to inflate anything.
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()
            }
        }
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

    // JVM unit tests. The routing and formatting logic is kept free of Android
    // types on purpose, so these run without Robolectric or a device.
    testImplementation("org.junit.jupiter:junit-jupiter:5.14.2")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher:1.14.2")

    // Composes a Glance widget at a chosen slot size and lets the test assert
    // on the resulting tree. The templates' layout decisions cannot be checked
    // any other way without an emulator.
    testImplementation("androidx.glance:glance-appwidget-testing:1.2.0")
    testImplementation("org.robolectric:robolectric:4.16")
    testImplementation("androidx.test:core:1.7.0")
    testImplementation("junit:junit:4.13.2")
    // Glance's test harness and Robolectric are JUnit 4; the rest of this
    // module's tests are JUnit 5, so the platform needs both engines.
    testRuntimeOnly("org.junit.vintage:junit-vintage-engine:6.1.3")
}
