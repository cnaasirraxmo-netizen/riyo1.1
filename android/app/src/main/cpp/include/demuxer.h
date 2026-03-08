#ifndef DEMUXER_H
#define DEMUXER_H

#include <string>
#include <vector>
#include <cstdint>

namespace riyo {

struct Packet {
    uint8_t* data;
    size_t size;
    double pts;
    bool is_audio;
};

class Demuxer {
public:
    Demuxer();
    ~Demuxer();

    bool open(const std::string& url);
    Packet readPacket();
    void close();

private:
    std::string m_url;
};

} // namespace riyo

#endif // DEMUXER_H
