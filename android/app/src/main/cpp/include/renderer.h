#ifndef RENDERER_H
#define RENDERER_H

#include <android/native_window.h>

namespace riyo {

class Renderer {
public:
    Renderer();
    ~Renderer();

    bool init(ANativeWindow* window);
    void render(uint8_t* frame, size_t size);
    void release();

private:
    ANativeWindow* m_window;
};

} // namespace riyo

#endif // RENDERER_H
