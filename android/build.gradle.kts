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
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Fix for older Flutter plugins (e.g. telephony) that pre-date the AGP namespace requirement.
subprojects {
    plugins.withId("com.android.library") {
        val android =
            extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
        if (android != null && android.namespace.isNullOrEmpty()) {
            android.namespace = project.group.toString().ifEmpty { project.name }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
