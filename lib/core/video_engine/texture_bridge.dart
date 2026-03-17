import 'dart:async';
import 'package:flutter/services.dart';

class TextureRegistryBridge {
  static const MethodChannel _channel = MethodChannel('com.riyo.app/texture');

  static Future<int> createTexture() async {
    final int textureId = await _channel.invokeMethod('create');
    return textureId;
  }

  static Future<void> connectPlayer(int textureId, int playerPtr) async {
    await _channel.invokeMethod('connect', {
      'textureId': textureId,
      'playerPtr': playerPtr,
    });
  }

  static Future<void> releaseTexture(int textureId) async {
    await _channel.invokeMethod('release', textureId);
  }
}
