plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // FlutterFire
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.felagi"
    compileSdk = 36 // or flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.example.felagi"
        minSdk = flutter.minSdkVersion // or flutter.minSdkVersion
        targetSdk = 34 // or flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.0")
    testImplementation("junit:junit:4.13.2") // For unit tests
    testImplementation("org.mockito:mockito-core:4.11.0") // Stable Mockito
    testImplementation("io.mockk:mockk:1.13.5") // Stable MockK
}
