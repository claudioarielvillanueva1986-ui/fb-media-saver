pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // AGP 9.x hace un hard-error en plugins de terceros (flutter_inappwebview_android)
    // que todavía usan getDefaultProguardFile('proguard-android.txt'). Se fija en la
    // última 8.x (con Gradle 8.14.3 abajo) hasta que el plugin actualice su
    // build.gradle. Ojo: 8.7.3 no alcanza, androidx.browser/core piden AGP >= 8.9.1.
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
