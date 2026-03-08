package com.riyo.app

import android.view.Surface

class NativeBridge {
    external fun setSurface(playerPtr: Long, surface: Surface)

    companion object {
        init {
            System.loadLibrary("riyo_video_engine")
        }
    }
}
