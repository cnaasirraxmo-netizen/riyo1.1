#include "video_engine.h"
#include <android/log.h>

#define LOG_TAG "RiyoVideoEngine"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

namespace riyo {

VideoEngine::VideoEngine() : m_state(PlayerState::IDLE), m_isRunning(false), m_position(0.0), m_duration(0.0), m_volume(1.0f), m_speed(1.0f), m_aspectRatioMode(0), m_bufferingProgress(0.0) {
    LOGI("VideoEngine initialized");
}

VideoEngine::~VideoEngine() {
    m_isRunning = false;
    if (m_engineThread && m_engineThread->joinable()) {
        m_engineThread->join();
    }
}

void VideoEngine::load(const std::string& url) {
    std::lock_guard<std::mutex> lock(m_stateMutex);
    m_url = url;
    m_position = 0.0;

    // Improved detection for external links
    bool isM3U8 = url.find(".m3u8") != std::string::npos;
    bool isMP4 = url.find(".mp4") != std::string::npos;

    LOGI("Loading URL: %s (Format: %s)", url.c_str(), isM3U8 ? "HLS" : (isMP4 ? "MP4" : "Unknown"));

    m_duration = 0.0; // Reset duration until metadata is parsed
    updateState(PlayerState::LOADING);

    if (m_isRunning) {
        m_isRunning = false;
        if (m_engineThread && m_engineThread->joinable()) m_engineThread->join();
    }

    m_isRunning = true;
    m_engineThread = std::make_unique<std::thread>(&VideoEngine::engineThread, this);
}

void VideoEngine::play() {
    std::lock_guard<std::mutex> lock(m_stateMutex);
    if (m_state == PlayerState::PAUSED || m_state == PlayerState::LOADING) {
        updateState(PlayerState::PLAYING);
        emitEvent(Event::PLAY);
    }
}

void VideoEngine::pause() {
    std::lock_guard<std::mutex> lock(m_stateMutex);
    if (m_state == PlayerState::PLAYING) {
        updateState(PlayerState::PAUSED);
        emitEvent(Event::PAUSE);
    }
}

void VideoEngine::stop() {
    std::lock_guard<std::mutex> lock(m_stateMutex);
    updateState(PlayerState::IDLE);
    m_position = 0.0;
}

void VideoEngine::seek(double time_seconds) {
    std::lock_guard<std::mutex> lock(m_stateMutex);
    m_position = time_seconds;
    LOGI("Seeking to: %f", time_seconds);
    emitEvent(Event::SEEK, std::to_string(time_seconds));
}

void VideoEngine::setQuality(int level) {
    LOGI("Setting quality to: %d", level);
    emitEvent(Event::QUALITY_CHANGE, std::to_string(level));
}

void VideoEngine::setVolume(float volume) {
    std::lock_guard<std::mutex> lock(m_stateMutex);
    m_volume = volume;
    LOGI("Setting volume: %f", volume);
}

void VideoEngine::setSpeed(float speed) {
    std::lock_guard<std::mutex> lock(m_stateMutex);
    m_speed = speed;
    LOGI("Setting speed: %f", speed);
}

void VideoEngine::setAspectRatio(int mode) {
    std::lock_guard<std::mutex> lock(m_stateMutex);
    m_aspectRatioMode = mode;
    LOGI("Setting aspect ratio mode: %d", mode);
}

PlayerState VideoEngine::getState() const {
    std::lock_guard<std::mutex> lock(m_stateMutex);
    return m_state;
}

double VideoEngine::getPosition() const {
    std::lock_guard<std::mutex> lock(m_stateMutex);
    return m_position;
}

double VideoEngine::getDuration() const {
    std::lock_guard<std::mutex> lock(m_stateMutex);
    return m_duration;
}

double VideoEngine::getBufferingProgress() const {
    std::lock_guard<std::mutex> lock(m_stateMutex);
    return m_bufferingProgress;
}

void VideoEngine::setEventCallback(EventCallback callback) {
    m_eventCallback = callback;
}

void VideoEngine::engineThread() {
    LOGI("Engine thread started");
    while (m_isRunning) {
        {
            std::lock_guard<std::mutex> lock(m_stateMutex);
            if (m_state == PlayerState::PLAYING) {
                m_position += 0.1 * m_speed;

                // Simulate metadata arrival
                if (m_duration <= 0.0) {
                    m_duration = 3600.0; // Mock 1 hour duration
                    emitEvent(Event::DURATION_UPDATE, std::to_string(m_duration));
                }

                if (m_position >= m_duration) {
                    m_position = m_duration;
                    updateState(PlayerState::ENDED);
                }

                // Regular position update events
                emitEvent(Event::POSITION_UPDATE, std::to_string(m_position));
            }
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    LOGI("Engine thread stopped");
}

void VideoEngine::updateState(PlayerState newState) {
    if (m_state != newState) {
        m_state = newState;
        LOGI("State changed to: %d", static_cast<int>(m_state));

        switch (newState) {
            case PlayerState::BUFFERING: emitEvent(Event::BUFFER_START); break;
            case PlayerState::PLAYING: emitEvent(Event::BUFFER_END); break;
            case PlayerState::ENDED: emitEvent(Event::ENDED); break;
            default: break;
        }
    }
}

void VideoEngine::emitEvent(Event event, const std::string& data) {
    if (m_eventCallback) {
        m_eventCallback(event, data);
    }
}

} // namespace riyo
