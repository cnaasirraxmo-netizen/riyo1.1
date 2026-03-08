#ifndef DECODER_H
#define DECODER_H

#include <media/NdkMediaCodec.h>
#include <media/NdkMediaFormat.h>

namespace riyo {

class Decoder {
public:
    Decoder();
    ~Decoder();

    bool init(const char* mime);
    void decode(uint8_t* data, size_t size, double pts);
    void release();

private:
    AMediaCodec* m_codec;
};

} // namespace riyo

#endif // DECODER_H
