#include "renderer.h"
#include <android/log.h>
#include <cstring>

namespace riyo {

Renderer::Renderer() : m_window(nullptr) {}
Renderer::~Renderer() { release(); }

bool Renderer::init(ANativeWindow* window) {
    m_window = window;
    ANativeWindow_acquire(m_window);
    return true;
}

void Renderer::render(uint8_t* frame, size_t size) {
    if (!m_window) return;

    ANativeWindow_Buffer buffer;
    if (ANativeWindow_lock(m_window, &buffer, nullptr) == 0) {
        // Mock rendering by copying pixel data
        // For actual implementation, use OpenGL/Vulkan
        ANativeWindow_unlockAndPost(m_window);
    }
}

void Renderer::release() {
    if (m_window) {
        ANativeWindow_release(m_window);
        m_window = nullptr;
    }
}

} // namespace riyo
