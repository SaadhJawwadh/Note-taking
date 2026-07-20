import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load release signing config from key.properties if it exists and is valid
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
var hasValidReleaseKey = false

if (keyPropertiesFile.exists()) {
    try {
        keyProperties.load(FileInputStream(keyPropertiesFile))
        val storePath = keyProperties.getProperty("storeFile")
        if (!storePath.isNullOrEmpty()) {
            val keystoreFile = file(storePath)
            if (keystoreFile.exists() && keystoreFile.length() > 0) {
                hasValidReleaseKey = true
            }
        }
    } catch (e: Exception) {
        hasValidReleaseKey = false
    }
}

android {
    namespace = "com.saadhjawwadh.notebook"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.saadhjawwadh.notebook"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasValidReleaseKey) {
            create("release") {
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasValidReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // Temporarily disable shrinking to fix plugin stripping issues
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            isMinifyEnabled = false
        }
    }

    splits {
        abi {
            isEnable = false
        }
    }

    packaging {
        jniLibs {
            pickFirsts += listOf(
                "lib/**/libc++_shared.so",
                "lib/**/libsqlite3.so"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
