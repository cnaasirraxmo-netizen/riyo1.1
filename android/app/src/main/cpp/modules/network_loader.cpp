#include "network_loader.h"
#include <android/log.h>

namespace riyo {

NetworkLoader::NetworkLoader() {}
NetworkLoader::~NetworkLoader() {}

bool NetworkLoader::open(const std::string& url) {
    m_url = url;
    __android_log_print(ANDROID_LOG_INFO, "NetworkLoader", "Opening URL: %s", url.c_str());
    return true;
}

size_t NetworkLoader::read(uint8_t* buffer, size_t size) {
    // Return mock data for now
    return 0;
}

void NetworkLoader::close() {
    __android_log_print(ANDROID_LOG_INFO, "NetworkLoader", "Closing loader");
}

} // namespace riyo
