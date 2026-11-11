import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 署名情報（キーストアは git 管理外。key.properties があれば release 署名、
// 無ければ従来どおり debug キーで署名する）。
// ベータ継続性のため、これまでのリリースAPKと同じ「このPCのデバッグキー」を
// key.properties + upload.keystore で CI にも渡す（ワークフロー参照）。
val keystoreProperties = Properties()
val keystorePropertiesFile = file("key.properties")
val hasUploadKeystore = keystorePropertiesFile.exists()
if (hasUploadKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

// flutter build の --dart-define を gradle から読む。
// Flutter は「KEY=VALUE」全体をBase64化したものをカンマ区切りで渡す。
fun dartDefines(): Map<String, String> {
    val raw = project.findProperty("dart-defines") as? String ?: return emptyMap()
    if (raw.isEmpty()) return emptyMap()
    return raw.split(",").mapNotNull { entry ->
        try {
            val decoded = String(Base64.getDecoder().decode(entry), Charsets.UTF_8)
            val idx = decoded.indexOf('=')
            if (idx <= 0) {
                null
            } else {
                decoded.substring(0, idx) to decoded.substring(idx + 1)
            }
        } catch (_: Exception) {
            null
        }
    }.toMap()
}

android {
    namespace = "com.inutomo.inutomo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.inutomo.inutomo"
        manifestPlaceholders["MAPS_API_KEY"] =
            dartDefines()["GOOGLE_MAPS_API_KEY"] ?: ""
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("upload") {
            if (hasUploadKeystore) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // key.properties があれば正式なアップロードキー、無ければ従来の
            // デバッグキー（既存ベータユーザーは上書きインストールで継続）
            signingConfig = if (hasUploadKeystore) {
                signingConfigs.getByName("upload")
            } else {
                signingConfigs.getByName("debug")
            }
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
