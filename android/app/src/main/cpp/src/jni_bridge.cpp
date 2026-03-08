#include "video_engine.h"
#include <android/native_window_jni.h>
#include <jni.h>

extern "C" {

JNIEXPORT void JNICALL
Java_com_riyo_app_NativeBridge_setSurface(JNIEnv *env, jobject thiz, jlong player_ptr, jobject surface) {
    if (surface != nullptr) {
        ANativeWindow *window = ANativeWindow_fromSurface(env, surface);
        // Set window to C++ engine
    }
}

}
