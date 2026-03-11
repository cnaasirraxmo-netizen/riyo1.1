#include "demuxer.h"
#include <android/log.h>

namespace riyo {

Demuxer::Demuxer() {}
Demuxer::~Demuxer() {}

bool Demuxer::open(const std::string& url) {
    m_url = url;
    __android_log_print(ANDROID_LOG_INFO, "Demuxer", "Attempting to open URL: %s", url.c_str());
    if (url.empty()) {
        __android_log_print(ANDROID_LOG_ERROR, "Demuxer", "Failed to open: URL is empty");
        return false;
    }
    __android_log_print(ANDROID_LOG_INFO, "Demuxer", "Demuxer successfully initialized for: %s", url.c_str());
    return true;
}

Packet Demuxer::readPacket() {
    // In the final engine, this would call FFmpeg's av_read_frame
    // For now, we simulate a lack of packets to avoid infinite loops in skeleton decoders
    return {nullptr, 0, 0.0, true}; // true indicates EOF
}

void Demuxer::close() {
    __android_log_print(ANDROID_LOG_INFO, "Demuxer", "Closing Demuxer");
}

} // namespace riyo
