plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

group = "com.example.glance_widget_android"
version = "1.0"

android {
    namespace = "com.example.glance_widget_android"
    compileSdk = 36

    defaultConfig {
        minSdk = 26
        consumerProguardFiles("consumer-rules.pro")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    buildFeatures {
        compose = true
    }
}

dependencies {
    // Compose BOM and Runtime
    implementation(platform("androidx.compose:compose-bom:2025.01.01"))
    implementation("androidx.compose.runtime:runtime")

    // Glance for App Widgets
    implementation("androidx.glance:glance-appwidget:1.1.1")
    implementation("androidx.glance:glance-material3:1.1.1")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")

    // DataStore for widget state
    implementation("androidx.datastore:datastore-preferences:1.1.3")

    // Gson for JSON serialization
    implementation("com.google.code.gson:gson:2.10.1")

    // WorkManager for background updates
    implementation("androidx.work:work-runtime-ktx:2.10.0")
}
