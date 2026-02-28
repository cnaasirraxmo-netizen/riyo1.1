import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef RiyoEventCallbackNative = Void Function(Pointer<Void> playerHandle, Int32 eventType, Pointer<Utf8> data);
typedef RiyoEventCallback = void Function(int eventType, String data);

class RiyoPlayerFFI {
  late DynamicLibrary _lib;

  // Function signatures
  late Pointer<Void> Function(Pointer<Utf8>, Pointer<NativeFunction<RiyoEventCallbackNative>>) _createPlayer;
  late void Function(Pointer<Void>) _play;
  late void Function(Pointer<Void>) _pause;
  late void Function(Pointer<Void>, int) _seek;
  late int Function(Pointer<Void>) _getPosition;
  late int Function(Pointer<Void>) _getDuration;
  late void Function(Pointer<Void>) _destroyPlayer;

  static final Map<int, RiyoEventCallback> _playerCallbacks = {};

  RiyoPlayerFFI() {
    _lib = _loadLibrary();
    _initFunctions();
  }

  DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) return DynamicLibrary.open('libriyo_player.so');
    if (Platform.isIOS || Platform.isMacOS) return DynamicLibrary.process();
    return DynamicLibrary.open('libriyo_player.so');
  }

  void _initFunctions() {
    _createPlayer = _lib.lookupFunction<
        Pointer<Void> Function(Pointer<Utf8>, Pointer<NativeFunction<RiyoEventCallbackNative>>),
        Pointer<Void> Function(Pointer<Utf8>, Pointer<NativeFunction<RiyoEventCallbackNative>>)
    >('riyo_create_player');

    _play = _lib.lookupFunction<void Function(Pointer<Void>), void Function(Pointer<Void>)>('riyo_play');
    _pause = _lib.lookupFunction<void Function(Pointer<Void>), void Function(Pointer<Void>)>('riyo_pause');
    _seek = _lib.lookupFunction<void Function(Pointer<Void>, Int64), void Function(Pointer<Void>, int)>('riyo_seek');
    _getPosition = _lib.lookupFunction<Int64 Function(Pointer<Void>), int Function(Pointer<Void>)>('riyo_get_position');
    _getDuration = _lib.lookupFunction<Int64 Function(Pointer<Void>), int Function(Pointer<Void>)>('riyo_get_duration');
    _destroyPlayer = _lib.lookupFunction<void Function(Pointer<Void>), void Function(Pointer<Void>)>('riyo_destroy_player');
  }

  Pointer<Void> createPlayer(String url, RiyoEventCallback callback) {
    final urlPtr = url.toNativeUtf8();
    final player = _createPlayer(urlPtr, Pointer.fromFunction(_onEventStatic));
    _playerCallbacks[player.address] = callback;
    return player;
  }

  static void _onEventStatic(Pointer<Void> playerHandle, int eventType, Pointer<Utf8> data) {
    final callback = _playerCallbacks[playerHandle.address];
    if (callback != null) {
      callback(eventType, data.toDartString());
    }
  }

  void play(Pointer<Void> player) => _play(player);
  void pause(Pointer<Void> player) => _pause(player);
  void seek(Pointer<Void> player, int ms) => _seek(player, ms);
  int getPosition(Pointer<Void> player) => _getPosition(player);
  int getDuration(Pointer<Void> player) => _getDuration(player);
  void destroy(Pointer<Void> player) {
    _destroyPlayer(player);
    _playerCallbacks.remove(player.address);
  }
}
