# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Telephony plugin
# Keep the entire telephony plugin namespace (BroadcastReceiver, Service, MethodHandler, etc.)
-keep class com.shounakmulay.telephony.** { *; }
-keepnames class com.shounakmulay.telephony.** { *; }
# BroadcastReceiver must survive shrinking — Android instantiates it by name
-keep class com.shounakmulay.telephony.sms.IncomingSmsReceiver { *; }

# permission_handler plugin
-keep class com.baseflow.permissionhandler.** { *; }

# Dart background isolate entry-points are called by name; keep them
# (The @pragma('vm:entry-point') annotation handles this at the Dart level,
#  but keep the top-level JNI bridge just in case.)
-keep class * extends io.flutter.embedding.engine.plugins.FlutterPlugin
-keep class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler

# sqflite — keeps sqlite JNI helpers
-keep class com.tekartik.sqflite.** { *; }

# SQLCipher — keep all native classes
-keep class net.sqlcipher.** { *; }

# Suppress warnings for libraries that reference missing classes
-dontwarn com.shounakmulay.telephony.**

# WorkManager (background task scheduling)
-keep class androidx.work.** { *; }
-keep class be.tramckrijte.workmanager.** { *; }
