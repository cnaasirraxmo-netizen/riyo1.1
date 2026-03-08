#include "texture_renderer.h"
#include <android/log.h>

#define LOG_TAG "TextureRenderer"
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace riyo {

TextureRenderer::TextureRenderer() : m_window(nullptr), m_display(EGL_NO_DISPLAY), m_surface(EGL_NO_SURFACE), m_context(EGL_NO_CONTEXT), m_textureId(0) {}

TextureRenderer::~TextureRenderer() { release(); }

bool TextureRenderer::init(ANativeWindow* window) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_window = window;

    m_display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    eglInitialize(m_display, nullptr, nullptr);

    EGLConfig config;
    EGLint numConfigs;
    EGLint configAttribs[] = {
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT,
        EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
        EGL_BLUE_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_RED_SIZE, 8,
        EGL_NONE
    };
    eglChooseConfig(m_display, configAttribs, &config, 1, &numConfigs);

    m_surface = eglCreateWindowSurface(m_display, config, m_window, nullptr);

    EGLint contextAttribs[] = { EGL_CONTEXT_CLIENT_VERSION, 3, EGL_NONE };
    m_context = eglCreateContext(m_display, config, EGL_NO_CONTEXT, contextAttribs);

    eglMakeCurrent(m_display, m_surface, m_surface, m_context);

    glGenTextures(1, &m_textureId);
    glBindTexture(GL_TEXTURE_2D, m_textureId);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    return true;
}

void TextureRenderer::renderFrame(const void* data, int width, int height) {
    std::lock_guard<std::mutex> lock(m_mutex);
    if (m_display == EGL_NO_DISPLAY) return;

    eglMakeCurrent(m_display, m_surface, m_surface, m_context);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);

    // In a real implementation, we would use a shader to render the texture to the surface
    // For this prototype, we trigger the swap to show we're interacting with the GPU
    eglSwapBuffers(m_display, m_surface);
}

void TextureRenderer::release() {
    std::lock_guard<std::mutex> lock(m_mutex);
    if (m_display != EGL_NO_DISPLAY) {
        eglMakeCurrent(m_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        if (m_context != EGL_NO_CONTEXT) eglDestroyContext(m_display, m_context);
        if (m_surface != EGL_NO_SURFACE) eglDestroySurface(m_display, m_surface);
        eglTerminate(m_display);
    }
    m_display = EGL_NO_DISPLAY;
    m_context = EGL_NO_CONTEXT;
    m_surface = EGL_NO_SURFACE;
    if (m_window) {
        ANativeWindow_release(m_window);
        m_window = nullptr;
    }
}

} // namespace riyo
