#include "riyo_player.h"
#include <iostream>
#include <string>
#include <thread>
#include <atomic>
#include <chrono>

class RiyoPlayerInstance {
public:
    std::string url;
    RiyoEventCallback event_callback;
    std::atomic<bool> is_playing;
    std::atomic<long> position;
    long duration;
    void* surface;

    RiyoPlayerInstance(const char* u, RiyoEventCallback cb)
        : url(u), event_callback(cb), is_playing(false), position(0), duration(120000), surface(nullptr) {
        std::cout << "RiyoPlayer created for URL: " << url << std::endl;
        // In real implementation, this would initialize FFmpeg demuxer, decoders, etc.
    }

    void play() {
        if (!is_playing) {
            is_playing = true;
            if (event_callback) {
                event_callback(RIYO_EVENT_PLAYING, "{\"status\": \"playing\"}");
            }
            std::cout << "RiyoPlayer playing..." << std::endl;
            // Spawn internal playback/decode threads here
        }
    }

    void pause() {
        if (is_playing) {
            is_playing = false;
            if (event_callback) {
                event_callback(RIYO_EVENT_PAUSED, "{\"status\": \"paused\"}");
            }
            std::cout << "RiyoPlayer paused." << std::endl;
        }
    }

    void seek(long ms) {
        position = ms;
        std::cout << "RiyoPlayer seeking to " << ms << "ms" << std::endl;
    }

    ~RiyoPlayerInstance() {
        std::cout << "RiyoPlayer destroyed." << std::endl;
    }
};

extern "C" {

void* riyo_create_player(const char* url, RiyoEventCallback callback) {
    return new RiyoPlayerInstance(url, callback);
}

void riyo_play(void* player) {
    if (player) {
        static_cast<RiyoPlayerInstance*>(player)->play();
    }
}

void riyo_pause(void* player) {
    if (player) {
        static_cast<RiyoPlayerInstance*>(player)->pause();
    }
}

void riyo_seek(void* player, long ms) {
    if (player) {
        static_cast<RiyoPlayerInstance*>(player)->seek(ms);
    }
}

long riyo_get_position(void* player) {
    if (player) {
        return static_cast<RiyoPlayerInstance*>(player)->position;
    }
    return 0;
}

long riyo_get_duration(void* player) {
    if (player) {
        return static_cast<RiyoPlayerInstance*>(player)->duration;
    }
    return 0;
}

void riyo_set_surface(void* player, void* surface_handle) {
    if (player) {
        static_cast<RiyoPlayerInstance*>(player)->surface = surface_handle;
        std::cout << "Surface handle set to: " << surface_handle << std::endl;
    }
}

void riyo_destroy_player(void* player) {
    if (player) {
        delete static_cast<RiyoPlayerInstance*>(player);
    }
}

}
