#ifndef TEXTURE_RENDERER_H
#define TEXTURE_RENDERER_H

#include <android/native_window.h>
#include <EGL/egl.h>
#include <GLES3/gl3.h>
#include <mutex>

namespace riyo {

class TextureRenderer {
public:
    TextureRenderer();
    ~TextureRenderer();

    bool init(ANativeWindow* window);
    void renderFrame(const void* data, int width, int height);
    void release();

private:
    ANativeWindow* m_window;
    EGLDisplay m_display;
    EGLSurface m_surface;
    EGLContext m_context;

    GLuint m_textureId;
    std::mutex m_mutex;
};

} // namespace riyo

#endif // TEXTURE_RENDERER_H
