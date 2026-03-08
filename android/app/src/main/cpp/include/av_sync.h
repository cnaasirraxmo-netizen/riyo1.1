#ifndef AV_SYNC_H
#define AV_SYNC_H

namespace riyo {

class AVSync {
public:
    AVSync();
    ~AVSync();

    void updateAudioTime(double time);
    void updateVideoTime(double time);
    double getDrift();

private:
    double m_audioTime;
    double m_videoTime;
};

} // namespace riyo

#endif // AV_SYNC_H
