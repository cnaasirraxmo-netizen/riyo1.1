import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// Native C++ Struct
base class VideoMetadata extends Struct {
  @Int32()
  external int width;
  @Int32()
  external int height;
  @Double()
  external double frameRate;
  @Int64()
  external int duration;
  external Pointer<Utf8> codec;
}

typedef AnalyzeFrameBrightnessNative = Double Function(Pointer<Uint8> frameData, Int32 size);
typedef AnalyzeFrameBrightness = double Function(Pointer<Uint8> frameData, int size);

typedef ProcessVideoMetadataNative = VideoMetadata Function(Pointer<Utf8> url);
typedef ProcessVideoMetadata = VideoMetadata Function(Pointer<Utf8> url);

class NativeVideoEngine {
  static final DynamicLibrary _lib = _loadLibrary();

  static DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) return DynamicLibrary.open('libvideo_engine.so');
    if (Platform.isIOS) return DynamicLibrary.process();
    throw UnsupportedError('Unsupported platform');
  }

  static final AnalyzeFrameBrightness analyzeFrameBrightness = _lib
      .lookup<NativeFunction<AnalyzeFrameBrightnessNative>>('analyzeFrameBrightness')
      .asFunction();

  static final ProcessVideoMetadata processVideoMetadata = _lib
      .lookup<NativeFunction<ProcessVideoMetadataNative>>('processVideoMetadata')
      .asFunction();

  // Helper method to get metadata
  static Map<String, dynamic> getVideoInfo(String url) {
    final urlPtr = url.toNativeUtf8();
    try {
      final meta = processVideoMetadata(urlPtr);
      return {
        'width': meta.width,
        'height': meta.height,
        'fps': meta.frameRate,
        'duration': meta.duration,
        'codec': meta.codec.toDartString(),
      };
    } finally {
      malloc.free(urlPtr);
    }
  }
}
