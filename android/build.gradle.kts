allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Suppress "source value 8 is obsolete" warnings from plugins/modules
    tasks.withType<JavaCompile> {
        options.compilerArgs.add("-Xlint:-options")
        options.compilerArgs.add("-Xlint:-unchecked")
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    project.evaluationDependsOn(":app")

    // บังคับให้ปลั๊กอินทุกตัว (เช่น :printing) ใช้ compileSdk 36
    // ข้าม :app เพราะถูก evaluate ไปแล้วและตั้งค่าถูกต้องอยู่แล้ว
    if (project.name != "app") {
        afterEvaluate {
            extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
                compileSdkVersion(36)
            }
        }
    }
}
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
