#include "decoder.h"
#include <android/log.h>
#include <cstring>

namespace riyo {

Decoder::Decoder() : m_codec(nullptr) {}
Decoder::~Decoder() { release(); }

bool Decoder::init(const char* mime) {
    if (mime == nullptr) {
        __android_log_print(ANDROID_LOG_ERROR, "Decoder", "Failed to init: MIME type is null");
        return false;
    }

    __android_log_print(ANDROID_LOG_INFO, "Decoder", "Initializing decoder for MIME: %s", mime);
    m_codec = AMediaCodec_createDecoderByType(mime);
    if (!m_codec) {
        __android_log_print(ANDROID_LOG_ERROR, "Decoder", "Failed to create decoder for MIME: %s", mime);
        return false;
    }

    AMediaFormat* format = AMediaFormat_new();
    AMediaFormat_setString(format, AMEDIAFORMAT_KEY_MIME, mime);
    // Example: set video size if known, or handle in format change callback
    // AMediaFormat_setInt32(format, AMEDIAFORMAT_KEY_WIDTH, 1280);
    // AMediaFormat_setInt32(format, AMEDIAFORMAT_KEY_HEIGHT, 720);

    media_status_t status = AMediaCodec_configure(m_codec, format, nullptr, nullptr, 0);
    if (status != AMEDIA_OK) {
        __android_log_print(ANDROID_LOG_ERROR, "Decoder", "Failed to configure codec: %d", status);
        AMediaFormat_delete(format);
        return false;
    }

    AMediaFormat_delete(format);

    status = AMediaCodec_start(m_codec);
    if (status != AMEDIA_OK) {
        __android_log_print(ANDROID_LOG_ERROR, "Decoder", "Failed to start codec: %d", status);
        return false;
    }

    __android_log_print(ANDROID_LOG_INFO, "Decoder", "Decoder started successfully");
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
