#ifndef VIDEO_ENGINE_H
#define VIDEO_ENGINE_H

#include <string>
#include <functional>
#include <memory>
#include <mutex>
#include <thread>
#include <vector>

namespace riyo {

enum class PlayerState {
    IDLE,
    LOADING,
    PLAYING,
    PAUSED,
    BUFFERING,
    ERROR,
    ENDED
};

enum class Event {
    PLAY,
    PAUSE,
    BUFFER_START,
    BUFFER_END,
    ERROR,
    QUALITY_CHANGE,
    SEEK,
    ENDED,
    POSITION_UPDATE,
    DURATION_UPDATE
};

using EventCallback = std::function<void(Event, const std::string&)>;

class VideoEngine {
public:
    VideoEngine();
    ~VideoEngine();

    void load(const std::string& url);
    void play();
    void pause();
    void stop();
    void seek(double time_seconds);
    void setQuality(int level);
    void setVolume(float volume);
    void setSpeed(float speed);
    void setAspectRatio(int mode);
    PlayerState getState() const;
    double getPosition() const;
    double getDuration() const;
    double getBufferingProgress() const;

    void setEventCallback(EventCallback callback);

private:
    void engineThread();
    void updateState(PlayerState newState);
    void emitEvent(Event event, const std::string& data = "");

    std::string m_url;
    PlayerState m_state;
    EventCallback m_eventCallback;
    mutable std::mutex m_stateMutex;

    double m_position;
    double m_duration;
    float m_volume;
    float m_speed;
    int m_aspectRatioMode;
    double m_bufferingProgress;

    bool m_isRunning;
    std::unique_ptr<std::thread> m_engineThread;
};

} // namespace riyo

#endif // VIDEO_ENGINE_H
