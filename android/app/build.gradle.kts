plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.gallery_triage_app"
    // 4.1.3 — igual ao targetSdk, não ao que a instalação local do
    // Flutter trouxer por padrão.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.gallery_triage_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        //
        // 4.1.1 — minSdk 30 (Android 11): createDeleteRequest,
        // createTrashRequest, colunas de geração do MediaStore e
        // QUERY_ARG_MATCH_TRASHED, sem o caminho legado de API 29.
        // 4.1.2 — targetSdk 36 (Android 16): exigido pela Play Store
        // para apps novos/atualizados a partir de 31/08/2026. Nenhum
        // dos dois vem de `flutter.*Version` porque esses valores
        // seguem a instalação local do Flutter, não a spec.
        minSdk = 30
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
