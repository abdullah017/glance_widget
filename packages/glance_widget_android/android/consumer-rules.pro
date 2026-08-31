# Glance Widget Plugin - ProGuard/R8 Consumer Rules
# These rules are automatically applied to apps using this library

# ============================================
# Glance Widget Receivers
# ============================================
# Keep all widget receivers (they are referenced in AndroidManifest.xml)
-keep class com.example.glance_widget_android.templates.**Receiver {
    <init>();
}

# Keep all GlanceAppWidget implementations
-keep class com.example.glance_widget_android.templates.** extends androidx.glance.appwidget.GlanceAppWidget {
    <init>();
}

# ============================================
# Flutter Plugin
# ============================================
# Keep the plugin class
-keep class com.example.glance_widget_android.GlanceWidgetPlugin {
    <init>();
    public *;
}

# Keep the manager object
-keep class com.example.glance_widget_android.GlanceWidgetManager {
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
