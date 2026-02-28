# RIYO Core C++ Playback Engine Architecture

## 1. Engine Core Modules

```text
[ Network Layer ] ──▶ [ Buffer Manager ] ──▶ [ Demuxer ]
                              │                 │
                              ▼                 ▼
                       [ ABR Controller ]    [ Decoders ] (H.264/H.265/AV1)
                              │                 │
                              ▼                 ▼
                       [ Clock Sync ] ◀──▶ [ Renderer ] (GPU Texture Sharing)
                              │                 │
                              ▼                 ▼
                       [ Audio Sink ]      [ UI Interface ] (Dart FFI)
```

### A. Demuxer (HLS/DASH)
- **Role:** Parses master playlist, handles variant switching logic, extracts ES (Elementary Streams).
- **Libraries:** Libavformat (FFmpeg) or custom implementation for low-latency.

### B. Hardware Decoders
- **Android:** JNI calls to `MediaCodec` for zero-copy surface rendering.
- **iOS:** `VideoToolbox` (Objective-C++ bridge).
- **Desktop/Linux:** `DXVA` (Windows), `VAAPI` (Linux).
- **Fallback:** Software decoding via `libavcodec`.

### C. ABR Controller (Adaptive Bitrate)
- **Strategy:** Throughput-based + Buffer-occupancy-based (BBA).
- **Switching:** Seamless switching at segment boundaries (2s/6s keyframe intervals).

## 2. Threading Model

1. **Main Thread (Event Loop):** Handles Public API calls and Event callbacks to Dart.
2. **Network Thread:** Asynchronous I/O using `libcurl` or `Boost.Asio`.
3. **Decode Thread:** Dedicated per-stream decoding to prevent UI/Network blocking.
4. **Render Thread:** Synchronized with VSync for smooth playback.
5. **Sync Thread:** High-precision clock for A-V synchronization.

## 3. Memory & Resource Management

- **Zero-Copy Architecture:** Decoding directly into GPU textures/surfaces to avoid CPU ↔ GPU data transfers.
- **Frame Pooling:** Pre-allocating video frames to minimize memory fragmentation.
- **RAII:** Strict usage of `std::unique_ptr` and `std::shared_ptr`.
- **Circular Buffers:** For audio and packet buffering to manage jitter.

## 4. Flutter ↔ C++ Integration (FFI Bridge)

### Communication: Dart FFI vs Platform Channels
- **Decision:** **Dart FFI** for low-latency controls and high-frequency metrics (e.g., current playback time, buffer status). **Platform Channels** for high-level UI commands (e.g., `play`, `pause`, `setQuality`).
- **Rendering:** **Texture Sharing (External Textures)**.
    - C++ engine writes decoded frames to a texture (e.g., OpenGL/Vulkan/Metal).
    - Flutter renders the texture via `Texture` widget.

### Event Flow (C++ → Dart)
```text
C++ (Event Thread) ──▶ Dart Native Callback (FFI) ──▶ Dart Isolate ──▶ Flutter UI (State)
```

## 5. Public API (C-Compatible)

```cpp
extern "C" {
    typedef void (*EventCallback)(int event_type, const char* data);

    void* create_player(const char* url, EventCallback cb);
    void player_play(void* player);
    void player_pause(void* player);
    void player_seek(void* player, long ms);
    void player_set_surface(void* player, void* surface_handle);
    void player_destroy(void* player);

    // Metrics
    long player_get_buffered_ms(void* player);
    double player_get_current_bitrate(void* player);
}
```

## 6. Performance Optimization
- **Predictive Prefetching:** Pre-fetching next 2 segments of current quality + 1 segment of next-higher quality.
- **Low-Latency Mode:** Disabling ABR and minimizing buffer size for live events.
- **GPU Texture Sharing:** Avoiding readback to CPU for UI overlays.
