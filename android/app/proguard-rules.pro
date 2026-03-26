# General Flutter & Plugin Infrastructure
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep all implementations of Flutter interfaces to ensure they are found via reflection
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin
-keep class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler
-keep class * implements io.flutter.plugin.common.EventChannel$StreamHandler

# Pigeon-generated classes (used by shared_preferences, workmanager, etc.)
-keep class **.Messages { *; }
-keep class **.Messages$* { *; }
-keep class dev.flutter.pigeon.** { *; }

# sqflite & SQLCipher
-keep class com.tekartik.sqflite.** { *; }
-keep class net.sqlcipher.** { *; }
-keep class net.sqlcipher.database.** { *; }
-keep class net.sqlcipher.database.SQLiteDatabase { *; }
-dontwarn net.sqlcipher.**

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class dev.flutter.pigeon.shared_preferences_android.** { *; }

# Package Info Plus
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }
-keep class dev.fluttercommunity.plus.packageinfo_platform_interface.** { *; }

# Receive Sharing Intent
-keep class com.kasem.receive_sharing_intent.** { *; }

# File Picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class miguelruivo.flutter.plugins.filepicker.** { *; }

# WorkManager
-keep class be.tramckrijte.workmanager.** { *; }
-keep class androidx.work.** { *; }

# Telephony
-keep class com.shounakmulay.telephony.** { *; }
-dontwarn com.shounakmulay.telephony.**

# Other Plugins
-keep class com.baseflow.permissionhandler.** { *; }
-keep class com.arthenica.ffmpegkit.** { *; }
-keep class androidx.biometric.** { *; }
-keep class io.flutter.plugins.localauth.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class io.flutter.plugins.urllauncher.** { *; }
-keep class dev.fluttercommunity.plus.share.** { *; }
-keep class gal.** { *; }

# General JNI keep
-keepclassmembers class * { native <methods>; }
