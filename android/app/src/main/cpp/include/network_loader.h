#ifndef NETWORK_LOADER_H
#define NETWORK_LOADER_H

#include <string>
#include <vector>
#include <cstdint>

namespace riyo {

class NetworkLoader {
public:
    NetworkLoader();
    ~NetworkLoader();

    bool open(const std::string& url);
    size_t read(uint8_t* buffer, size_t size);
    void close();

private:
    std::string m_url;
};

} // namespace riyo

#endif // NETWORK_LOADER_H
