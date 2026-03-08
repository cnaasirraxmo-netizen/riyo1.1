#include "demuxer.h"
#include <android/log.h>

namespace riyo {

Demuxer::Demuxer() {}
Demuxer::~Demuxer() {}

bool Demuxer::open(const std::string& url) {
    m_url = url;
    __android_log_print(ANDROID_LOG_INFO, "Demuxer", "Opening URL: %s", url.c_str());
    return true;
}

Packet Demuxer::readPacket() {
    // Return empty packet for now
    return {nullptr, 0, 0.0, false};
}

void Demuxer::close() {
    __android_log_print(ANDROID_LOG_INFO, "Demuxer", "Closing Demuxer");
}

} // namespace riyo
