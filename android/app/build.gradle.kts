import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.bordersafety.border_safety_alert"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        val storeFilePath = keystoreProperties.getProperty("storeFile")
            ?: System.getenv("BSAS_KEYSTORE_PATH")
        val storePasswordVal = keystoreProperties.getProperty("storePassword")
            ?: System.getenv("BSAS_KEYSTORE_PASSWORD")
        val keyAliasVal = keystoreProperties.getProperty("keyAlias")
            ?: System.getenv("BSAS_KEY_ALIAS")
        val keyPasswordVal = keystoreProperties.getProperty("keyPassword")
            ?: System.getenv("BSAS_KEY_PASSWORD")

        if (!storeFilePath.isNullOrBlank() && file(storeFilePath).exists()) {
            create("release") {
                storeFile = file(storeFilePath)
                storePassword = storePasswordVal
                keyAlias = keyAliasVal
                keyPassword = keyPasswordVal
            }
        }
    }

    defaultConfig {
        applicationId = "com.bordersafety.border_safety_alert"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            val releaseSigningConfig = signingConfigs.findByName("release")
            if (releaseSigningConfig != null) {
                signingConfig = releaseSigningConfig
            } else {
                logger.warn("[BSAS RELEASE SIGNING] key.properties or BSAS_KEYSTORE_PATH not found. Using debug signing for local test artifact.")
                signingConfig = signingConfigs.getByName("debug")
            }
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
            keepDebugSymbols += "**/*.so"
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
