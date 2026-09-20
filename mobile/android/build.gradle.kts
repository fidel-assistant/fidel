allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// file_picker 8.x force compileSdk 34 ; flutter_plugin_android_lifecycle exige ≥ 36.
// afterEvaluate : après le bloc android {} du plugin (withPlugin serait trop tôt).
// NDK 30 installé localement — éviter le NDK 28.2.x Flutter (copie locale corrompue).
subprojects {
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.apply {
            if (compileSdk != null && compileSdk!! < 37) {
                compileSdk = 37
            }
            ndkVersion = "30.0.16248370"
        }
        extensions.findByType(com.android.build.gradle.AppExtension::class.java)?.apply {
            ndkVersion = "30.0.16248370"
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
