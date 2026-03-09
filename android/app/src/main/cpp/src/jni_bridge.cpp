#include "video_engine.h"
#include <android/native_window_jni.h>
#include <jni.h>

extern "C" {

JNIEXPORT void JNICALL
Java_com_riyo_app_NativeBridge_setSurface(JNIEnv *env, jobject thiz, jlong player_ptr, jobject surface) {
    if (player_ptr == 0) return;
    auto player = reinterpret_cast<riyo::VideoEngine*>(player_ptr);

    if (surface != nullptr) {
        ANativeWindow *window = ANativeWindow_fromSurface(env, surface);
        // player->setWindow(window); // Implement in engine
    }
}

}
