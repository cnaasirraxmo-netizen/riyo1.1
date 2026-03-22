#include "video_engine.h"
#include <cstring>

extern "C" {

using namespace riyo;

VideoEngine* g_player = nullptr;

void* player_create() {
    g_player = new VideoEngine();
    return g_player;
}

void player_destroy(void* handle) {
    auto player = static_cast<VideoEngine*>(handle);
    delete player;
    if (g_player == player) g_player = nullptr;
}

void player_load(void* handle, const char* url) {
    auto player = static_cast<VideoEngine*>(handle);
    player->load(url);
}

void player_play(void* handle) {
    auto player = static_cast<VideoEngine*>(handle);
    player->play();
}

void player_pause(void* handle) {
    auto player = static_cast<VideoEngine*>(handle);
    player->pause();
}

void player_stop(void* handle) {
    auto player = static_cast<VideoEngine*>(handle);
    player->stop();
}

void player_seek(void* handle, double time) {
    auto player = static_cast<VideoEngine*>(handle);
    player->seek(time);
}

void player_set_quality(void* handle, int level) {
    auto player = static_cast<VideoEngine*>(handle);
    player->setQuality(level);
}

void player_set_volume(void* handle, float volume) {
    auto player = static_cast<VideoEngine*>(handle);
    player->setVolume(volume);
}

void player_set_speed(void* handle, float speed) {
    auto player = static_cast<VideoEngine*>(handle);
    player->setSpeed(speed);
}

void player_set_aspect_ratio(void* handle, int mode) {
    auto player = static_cast<VideoEngine*>(handle);
    player->setAspectRatio(mode);
}

int player_get_state(void* handle) {
    auto player = static_cast<VideoEngine*>(handle);
    return static_cast<int>(player->getState());
}

double player_get_position(void* handle) {
    auto player = static_cast<VideoEngine*>(handle);
    return player->getPosition();
}

double player_get_duration(void* handle) {
    auto player = static_cast<VideoEngine*>(handle);
    return player->getDuration();
}

double player_get_buffering_progress(void* handle) {
    auto player = static_cast<VideoEngine*>(handle);
    return player->getBufferingProgress();
}

typedef void (*NativeEventCallback)(int event, const char* data);

void player_set_event_callback(void* handle, NativeEventCallback callback) {
    auto player = static_cast<VideoEngine*>(handle);
    player->setEventCallback([callback](Event event, const std::string& data) {
        callback(static_cast<int>(event), data.c_str());
    });
}

}
