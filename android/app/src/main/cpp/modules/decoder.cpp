#include "decoder.h"
#include <android/log.h>
#include <cstring>

namespace riyo {

Decoder::Decoder() : m_codec(nullptr) {}
Decoder::~Decoder() { release(); }

bool Decoder::init(const char* mime) {
    m_codec = AMediaCodec_createDecoderByType(mime);
    if (!m_codec) return false;

    AMediaFormat* format = AMediaFormat_new();
    AMediaFormat_setString(format, AMEDIAFORMAT_KEY_MIME, mime);
    // Add more format settings

    AMediaCodec_configure(m_codec, format, nullptr, nullptr, 0);
    AMediaFormat_delete(format);

    AMediaCodec_start(m_codec);
    return true;
}

void Decoder::decode(uint8_t* data, size_t size, double pts) {
    if (!m_codec) return;

    ssize_t bufidx = AMediaCodec_dequeueInputBuffer(m_codec, 2000);
    if (bufidx >= 0) {
        size_t outsize;
        uint8_t* buf = AMediaCodec_getInputBuffer(m_codec, bufidx, &outsize);
        if (buf && size <= outsize) {
            memcpy(buf, data, size);
            AMediaCodec_queueInputBuffer(m_codec, bufidx, 0, size, (uint64_t)(pts * 1000000), 0);
        }
    }
}

void Decoder::release() {
    if (m_codec) {
        AMediaCodec_stop(m_codec);
        AMediaCodec_delete(m_codec);
        m_codec = nullptr;
    }
}

} // namespace riyo
