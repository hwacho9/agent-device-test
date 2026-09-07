plugins {
    alias(libs.plugins.kotlin.multiplatform)
    alias(libs.plugins.android.kmp)
}
kotlin {
    android {
        namespace = "com.example.agentdevicee2edemo.shared"
        compileSdk = 35
        minSdk = 26
        withHostTestBuilder {}.configure {}
        compilerOptions { jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17) }
    }
    iosArm64 { binaries.framework { baseName = "Shared"; isStatic = false } }
    iosSimulatorArm64 { binaries.framework { baseName = "Shared"; isStatic = false } }
    sourceSets {
        commonTest.dependencies { implementation(kotlin("test")) }
    }
}
