import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// Native function signatures
typedef PlayerCreateNative = Pointer<Void> Function();
typedef PlayerCreate = Pointer<Void> Function();

typedef PlayerDestroyNative = Void Function(Pointer<Void>);
typedef PlayerDestroy = void Function(Pointer<Void>);

typedef PlayerLoadNative = Void Function(Pointer<Void>, Pointer<Utf8>);
typedef PlayerLoad = void Function(Pointer<Void>, Pointer<Utf8>);

typedef PlayerPlayNative = Void Function(Pointer<Void>);
typedef PlayerPlay = void Function(Pointer<Void>);

typedef PlayerPauseNative = Void Function(Pointer<Void>);
typedef PlayerPause = void Function(Pointer<Void>);

typedef PlayerStopNative = Void Function(Pointer<Void>);
typedef PlayerStop = void Function(Pointer<Void>);

typedef PlayerSeekNative = Void Function(Pointer<Void>, Double);
typedef PlayerSeek = void Function(Pointer<Void>, double);

typedef PlayerSetQualityNative = Void Function(Pointer<Void>, Int32);
typedef PlayerSetQuality = void Function(Pointer<Void>, int);

typedef PlayerSetVolumeNative = Void Function(Pointer<Void>, Float);
typedef PlayerSetVolume = void Function(Pointer<Void>, double);

typedef PlayerSetSpeedNative = Void Function(Pointer<Void>, Float);
typedef PlayerSetSpeed = void Function(Pointer<Void>, double);

typedef PlayerSetAspectRatioNative = Void Function(Pointer<Void>, Int32);
typedef PlayerSetAspectRatio = void Function(Pointer<Void>, int);

typedef PlayerGetStateNative = Int32 Function(Pointer<Void>);
typedef PlayerGetState = int Function(Pointer<Void>);

typedef PlayerGetPositionNative = Double Function(Pointer<Void>);
typedef PlayerGetPosition = double Function(Pointer<Void>);

typedef PlayerGetDurationNative = Double Function(Pointer<Void>);
typedef PlayerGetDuration = double Function(Pointer<Void>);

typedef PlayerGetBufferingProgressNative = Double Function(Pointer<Void>);
typedef PlayerGetBufferingProgress = double Function(Pointer<Void>);

typedef NativeEventCallback = Void Function(Int32, Pointer<Utf8>);
typedef PlayerSetEventCallbackNative = Void Function(Pointer<Void>, Pointer<NativeFunction<NativeEventCallback>>);
typedef PlayerSetEventCallback = void Function(Pointer<Void>, Pointer<NativeFunction<NativeEventCallback>>);

class RiyoVideoEngine {
  late DynamicLibrary _lib;
  late Pointer<Void> _playerHandle;

  Pointer<Void> get handle => _playerHandle;

  late PlayerCreate _playerCreate;
  late PlayerDestroy _playerDestroy;
  late PlayerLoad _playerLoad;
  late PlayerPlay _playerPlay;
  late PlayerPause _playerPause;
  late PlayerStop _playerStop;
  late PlayerSeek _playerSeek;
  late PlayerSetQuality _playerSetQuality;
  late PlayerSetVolume _playerSetVolume;
  late PlayerSetSpeed _playerSetSpeed;
  late PlayerSetAspectRatio _playerSetAspectRatio;
  late PlayerGetState _playerGetState;
  late PlayerGetPosition _playerGetPosition;
  late PlayerGetDuration _playerGetDuration;
  late PlayerGetBufferingProgress _playerGetBufferingProgress;
  late PlayerSetEventCallback _playerSetEventCallback;

  RiyoVideoEngine() {
    _lib = Platform.isAndroid
        ? DynamicLibrary.open('libriyo_video_engine.so')
        : DynamicLibrary.process();

    _playerCreate = _lib.lookupFunction<PlayerCreateNative, PlayerCreate>('player_create');
    _playerDestroy = _lib.lookupFunction<PlayerDestroyNative, PlayerDestroy>('player_destroy');
    _playerLoad = _lib.lookupFunction<PlayerLoadNative, PlayerLoad>('player_load');
    _playerPlay = _lib.lookupFunction<PlayerPlayNative, PlayerPlay>('player_play');
    _playerPause = _lib.lookupFunction<PlayerPauseNative, PlayerPause>('player_pause');
    _playerStop = _lib.lookupFunction<PlayerStopNative, PlayerStop>('player_stop');
    _playerSeek = _lib.lookupFunction<PlayerSeekNative, PlayerSeek>('player_seek');
    _playerSetQuality = _lib.lookupFunction<PlayerSetQualityNative, PlayerSetQuality>('player_set_quality');
    _playerSetVolume = _lib.lookupFunction<PlayerSetVolumeNative, PlayerSetVolume>('player_set_volume');
    _playerSetSpeed = _lib.lookupFunction<PlayerSetSpeedNative, PlayerSetSpeed>('player_set_speed');
    _playerSetAspectRatio = _lib.lookupFunction<PlayerSetAspectRatioNative, PlayerSetAspectRatio>('player_set_aspect_ratio');
    _playerGetState = _lib.lookupFunction<PlayerGetStateNative, PlayerGetState>('player_get_state');
    _playerGetPosition = _lib.lookupFunction<PlayerGetPositionNative, PlayerGetPosition>('player_get_position');
    _playerGetDuration = _lib.lookupFunction<PlayerGetDurationNative, PlayerGetDuration>('player_get_duration');
    _playerGetBufferingProgress = _lib.lookupFunction<PlayerGetBufferingProgressNative, PlayerGetBufferingProgress>('player_get_buffering_progress');
    _playerSetEventCallback = _lib.lookupFunction<PlayerSetEventCallbackNative, PlayerSetEventCallback>('player_set_event_callback');

    _playerHandle = _playerCreate();
  }

  void dispose() {
    _playerDestroy(_playerHandle);
  }

  void load(String url) {
    final nativeUrl = url.toNativeUtf8();
    _playerLoad(_playerHandle, nativeUrl);
    malloc.free(nativeUrl);
  }

  void play() => _playerPlay(_playerHandle);
  void pause() => _playerPause(_playerHandle);
  void stop() => _playerStop(_playerHandle);
  void seek(double seconds) => _playerSeek(_playerHandle, seconds);
  void setQuality(int level) => _playerSetQuality(_playerHandle, level);
  void setVolume(double volume) => _playerSetVolume(_playerHandle, volume);
  void setSpeed(double speed) => _playerSetSpeed(_playerHandle, speed);
  void setAspectRatio(int mode) => _playerSetAspectRatio(_playerHandle, mode);
  int getState() => _playerGetState(_playerHandle);
  double getPosition() => _playerGetPosition(_playerHandle);
  double getDuration() => _playerGetDuration(_playerHandle);
  double getBufferingProgress() => _playerGetBufferingProgress(_playerHandle);

  static final _eventStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get eventStream => _eventStreamController.stream;
  NativeCallable<NativeEventCallback>? _nativeCallable;

  void setEventCallback() {
    _nativeCallable = NativeCallable<NativeEventCallback>.listener(_onNativeEvent);
    _playerSetEventCallback(_playerHandle, _nativeCallable!.nativeFunction);
  }

  static void _onNativeEvent(int event, Pointer<Utf8> data) {
    // This is now safe to be called from any C++ thread
    final dataString = data.toDartString();
    _eventStreamController.add({
      'event': event,
      'data': dataString,
    });
    print('Native event: $event, data: $dataString');
  }
}
