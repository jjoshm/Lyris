# Flutter-specific ProGuard rules

# Suppress missing Play Core classes (Flutter references them for deferred
# components, which we don't use — R8 treats unresolved refs as errors).
-dontwarn com.google.android.play.core.**

# Keep Flutter engine JNI bindings
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# flutter_secure_storage uses platform channels — keep plugin class
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Bonsoir (mDNS) uses platform channels
-keep class fr.levavasseur.bonsoir.** { *; }

# flutter_foreground_task
-keep class com.pravera.flutter_foreground_task.** { *; }

# Keep native crypto implementations (cryptography package)
-keep class app.cryptography.** { *; }

# General: keep all plugin registrants
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
