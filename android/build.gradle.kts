import org.gradle.api.tasks.Delete
import org.gradle.api.JavaVersion
import org.gradle.api.tasks.compile.JavaCompile
import org.gradle.api.file.Directory

// 🔥 Firebase Google Services plugin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.3.15")
    }
}

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
    val project = this

    val configureProject = {

        // ✅ Java JVM 11
        project.tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "11"
            targetCompatibility = "11"
        }

        // ✅ Kotlin JVM 11
        project.tasks.configureEach {
            if (this.javaClass.name.contains("KotlinCompile")) {
                try {
                    val getKotlinOptions = this.javaClass.getMethod("getKotlinOptions")
                    val kotlinOptions = getKotlinOptions.invoke(this)
                    val setJvmTarget = kotlinOptions.javaClass
                        .getMethod("setJvmTarget", String::class.java)
                    setJvmTarget.invoke(kotlinOptions, "11")
                } catch (_: Exception) {}
            }
        }

        // ✅ Android compileOptions fix
        if (project.hasProperty("android")) {
            try {
                val android = project.extensions.getByName("android")
                val getCompileOptions = android.javaClass.getMethod("getCompileOptions")
                val compileOptions = getCompileOptions.invoke(android)
                val setSourceCompatibility = compileOptions.javaClass
                    .getMethod("setSourceCompatibility", JavaVersion::class.java)
                val setTargetCompatibility = compileOptions.javaClass
                    .getMethod("setTargetCompatibility", JavaVersion::class.java)

                setSourceCompatibility.invoke(
                    compileOptions,
                    JavaVersion.VERSION_11
                )
                setTargetCompatibility.invoke(
                    compileOptions,
                    JavaVersion.VERSION_11
                )
            } catch (_: Exception) {}
        }
    }

    if (project.state.executed) {
        configureProject()
    } else {
        project.afterEvaluate {
            configureProject()
        }
    }

    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    if (project.name != "app") {
        try {
            project.evaluationDependsOn(":app")
        } catch (_: Exception) {}
    }
}

// ✅ Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
