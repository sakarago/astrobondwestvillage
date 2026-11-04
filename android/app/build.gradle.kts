import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
}

// Supabase URL + anon key (public by design; RLS protects data). Read from the iOS
// SupabaseCredentials.swift (single source of truth, read-only), overridable via
// local.properties (supabase.url / supabase.anonKey) or env SUPABASE_URL / SUPABASE_ANON_KEY.
val supabaseCreds: Pair<String, String> = run {
    val local = Properties().apply {
        val f = rootProject.file("local.properties")
        if (f.exists()) f.inputStream().use { load(it) }
    }
    val swift = rootProject.file("../AstroBondWestVillage/Infrastructure/Supabase/SupabaseCredentials.swift")
        .takeIf { it.exists() }?.readText().orEmpty()
    fun fromSwift(name: String): String? =
        Regex(name + "\\s*=\\s*\"([^\"]+)\"").find(swift)?.groupValues?.get(1)
    val url = local.getProperty("supabase.url") ?: System.getenv("SUPABASE_URL") ?: fromSwift("urlString") ?: ""
    val key = local.getProperty("supabase.anonKey") ?: System.getenv("SUPABASE_ANON_KEY") ?: fromSwift("anonKey") ?: ""
    url to key
}


android {
    namespace = "com.astrobond.app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.astrobond.app"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "0.1.0"
        buildConfigField("String", "SUPABASE_URL", "\"${supabaseCreds.first}\"")
        buildConfigField("String", "SUPABASE_ANON_KEY", "\"${supabaseCreds.second}\"")
        ndk { abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64") }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            // Signing config intentionally absent: never commit keystores.
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    ndkVersion = "27.0.12077973"
    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.activity.compose)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.material.icons)
    implementation(libs.androidx.navigation.compose)
    implementation(platform(libs.supabase.bom))
    implementation(libs.supabase.auth)
    implementation(libs.supabase.postgrest)
    implementation(libs.supabase.realtime)
    implementation(libs.supabase.storage)
    implementation(libs.ktor.client.okhttp)
    implementation(libs.kotlinx.serialization.json)
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.coil.compose)
    debugImplementation(libs.androidx.compose.ui.tooling)
}
