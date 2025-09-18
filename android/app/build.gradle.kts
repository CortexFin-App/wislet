plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.vlad.wislet"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // ВАЖЛИВО: має бути увімкнено для desugaring
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.vlad.wislet"
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            // Тимчасово використовуємо debug-сертифікат для релізу
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // (агп 8.x все ще розуміє цей синтаксис; якщо схочеш — можна
    // замінити на packaging { resources { excludes += "..." } })
    packagingOptions {
        resources.excludes.add("META-INF/com/android/build/gradle/global-synthetics/build-attribution.txt")
        resources.excludes.add("META-INF/gradle/incremental.annotation.processors")
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("androidx.window:window:1.3.0")
    implementation("androidx.core:core-splashscreen:1.0.1")

    // ОНОВЛЕНО: було 2.0.4 → потрібно 2.1.4 або вище
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

configurations.all {
    resolutionStrategy {
        // Зафіксували Material 1.12.0, щоб уникнути конфліктів
        force("com.google.android.material:material:1.12.0")
    }
}
