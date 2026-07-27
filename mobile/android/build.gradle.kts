allprojects {
    repositories {
        google()
        mavenCentral()
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

    // Some bundled Flutter plugins (geocoding_android, connectivity_plus, ...) hardcode
    // an older compileSdk (33) that newer androidx transitive deps reject. Force every
    // Android library subproject up to 36 so AAR-metadata checks pass without patching
    // each plugin. Uses the stable api.dsl interface (AGP 8/9 compatible). This hook is
    // registered here, before the evaluationDependsOn block below triggers evaluation.
    afterEvaluate {
        extensions.findByType(com.android.build.api.dsl.LibraryExtension::class.java)
            ?.let { it.compileSdk = 36 }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
