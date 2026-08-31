# Glance Widget Plugin - ProGuard/R8 Consumer Rules
# These rules are automatically applied to apps using this library

# ============================================
# Glance Widget Receivers
# ============================================
# Keep all widget receivers (they are referenced in AndroidManifest.xml)
-keep class dev.glance.widget.android.templates.**Receiver {
    <init>();
}

# Keep all GlanceAppWidget implementations
-keep class dev.glance.widget.android.templates.** extends androidx.glance.appwidget.GlanceAppWidget {
    <init>();
}

# ============================================
# Gson-serialized models
# ============================================
# These two are written to disk as JSON and read back later, so their field
# names are a storage format, not an implementation detail. Left to R8 they
# become a, b, c, d -- and the letters are not stable across builds, so an app
# update makes everything the previous version wrote unreadable. Both readers
# swallow the parse failure and return null, so the symptom is silent: widgets
# stop updating in the background, queued taps never arrive, and only in
# release. Verified in build/app/outputs/mapping/release/mapping.txt.
#
# ActionCallback implementations need no rule here -- glance-appwidget's own
# proguard.txt already keeps them.
-keepclassmembers class dev.glance.widget.android.BackgroundUpdateConfig {
    <fields>;
}
-keepclassmembers class dev.glance.widget.android.PendingAction {
    <fields>;
}

# ============================================
# Flutter Plugin
# ============================================
# Keep the plugin class
-keep class dev.glance.widget.android.GlanceWidgetPlugin {
    <init>();
    public *;
}

# Keep the manager object
-keep class dev.glance.widget.android.GlanceWidgetManager {
    public *;
}

# ============================================
# Jetpack Glance
# ============================================
# Keep Glance state definitions
-keep class androidx.glance.state.** { *; }

# Keep GlanceAppWidgetManager
-keep class androidx.glance.appwidget.GlanceAppWidgetManager { *; }

# ============================================
# DataStore Preferences
# ============================================
# Keep DataStore classes
-keep class androidx.datastore.** { *; }
-keepclassmembers class * {
    @androidx.datastore.preferences.core.Preferences$Key <fields>;
}

# ============================================
# Gson Serialization
# ============================================
# Keep Gson classes
-keepattributes Signature
-keepattributes *Annotation*

# Keep generic type info for Gson
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep TypeToken for Gson
-keepclassmembers class * extends com.google.gson.reflect.TypeToken { *; }

# ============================================
# Kotlin Coroutines
# ============================================
# Keep coroutine intrinsics
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# ============================================
# General Android
# ============================================
# Keep native method names
-keepclasseswithmembernames class * {
    native <methods>;
}
