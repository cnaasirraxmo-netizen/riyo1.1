package com.riyo.app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry

class MainActivity : FlutterFragmentActivity() {
    private val TEXTURE_CHANNEL = "com.riyo.app/texture"
    private val textures = mutableMapOf<Long, TextureRegistry.SurfaceTextureEntry>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TEXTURE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "create" -> {
                    val entry = flutterEngine.renderer.createSurfaceTexture()
                    textures[entry.id()] = entry
                    result.success(entry.id())
                }
                "release" -> {
                    val id = call.arguments as Long
                    textures.remove(id)?.release()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
