plugins {
    id("com.android.application")

    // Firebase
    id("com.google.gms.google-services")

    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {

    namespace = "com.medivoice.medic"

    compileSdk = 36

    ndkVersion = "28.2.13676358"

    defaultConfig {

        applicationId = "com.medivoice.medic"

        minSdk = flutter.minSdkVersion

        targetSdk = 36

        versionCode = 1

        versionName = "1.0"
    }

    compileOptions {

        sourceCompatibility =
            JavaVersion.VERSION_17

        targetCompatibility =
            JavaVersion.VERSION_17

        isCoreLibraryDesugaringEnabled = true
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(
                org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            )
        }
    }

    buildTypes {

        release {

            signingConfig =
                signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-analytics")
}

flutter {

    source = "../.."
}