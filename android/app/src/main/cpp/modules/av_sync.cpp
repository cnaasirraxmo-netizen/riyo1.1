#include "av_sync.h"

namespace riyo {

AVSync::AVSync() : m_audioTime(0.0), m_videoTime(0.0) {}
AVSync::~AVSync() {}

void AVSync::updateAudioTime(double time) {
    m_audioTime = time;
}

void AVSync::updateVideoTime(double time) {
    m_videoTime = time;
}

double AVSync::getDrift() {
    return m_audioTime - m_videoTime;
}

} // namespace riyo
