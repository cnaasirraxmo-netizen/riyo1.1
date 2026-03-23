import 'dart:async';
import 'package:flutter/material.dart';
import '../video_engine/riyo_video_engine.dart';
import '../video_engine/texture_bridge.dart';
import 'base_player.dart';

class CppPlayer extends BaseVideoPlayer {
  RiyoVideoEngine? _engine;
  int? _textureId;
  PlayerState _state = PlayerState();
  StreamSubscription? _eventSubscription;
  Timer? _statusUpdateTimer;

  @override
  PlayerState get state => _state;

  @override
  Widget buildPlayer(BuildContext context) {
    if (_textureId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Texture(textureId: _textureId!),
    );
  }

  @override
  Future<void> initialize(String url) async {
    _state = _state.copyWith(status: PlayerStatus.loading);
    notifyListeners();

    try {
      _engine = RiyoVideoEngine();
      _textureId = await TextureRegistryBridge.createTexture();
      _engine!.setEventCallback();
      await TextureRegistryBridge.connectPlayer(_textureId!, _engine!.handle.address);

      _eventSubscription = _engine!.eventStream.listen(_onEvent);
      _engine!.load(url);
      _engine!.play();

      _statusUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        _updatePlaybackState();
      });

    } catch (e) {
      _state = _state.copyWith(status: PlayerStatus.error, error: e.toString());
    }
    notifyListeners();
  }

  void _onEvent(Map<String, dynamic> event) {
    final eventType = event['event'] as int;
    final data = event['data'] as String;

    if (eventType == 4) { // ERROR
      _state = _state.copyWith(status: PlayerStatus.error, error: data);
    } else if (eventType == 8) { // POSITION_UPDATE
      final pos = double.tryParse(data) ?? 0.0;
      _state = _state.copyWith(position: Duration(seconds: pos.toInt()));
    } else if (eventType == 9) { // DURATION_UPDATE
      final dur = double.tryParse(data) ?? 0.0;
      _state = _state.copyWith(duration: Duration(seconds: dur.toInt()));
    }
    notifyListeners();
  }

  void _updatePlaybackState() {
    if (_engine == null) return;

    final nativeState = _engine!.getState();
    PlayerStatus status;

    switch (nativeState) {
      case 1: status = PlayerStatus.loading; break;
      case 2: status = PlayerStatus.playing; break;
      case 3: status = PlayerStatus.paused; break;
      case 4: status = PlayerStatus.buffering; break;
      case 5: status = PlayerStatus.completed; break;
      case 6: status = PlayerStatus.error; break;
      default: status = PlayerStatus.idle;
    }

    _state = _state.copyWith(
      status: status,
      position: Duration(seconds: _engine!.getPosition().toInt()),
      duration: Duration(seconds: _engine!.getDuration().toInt()),
      buffered: Duration(seconds: (_engine!.getBufferingProgress() * _engine!.getDuration()).toInt()),
    );
    notifyListeners();
  }

  @override
  Future<void> play() async {
    _engine?.play();
  }

  @override
  Future<void> pause() async {
    _engine?.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    _engine?.seek(position.inSeconds.toDouble());
  }

  @override
  Future<void> setVolume(double volume) async {
    _engine?.setVolume(volume);
  }

  @override
  Future<void> setSpeed(double speed) async {
    _engine?.setSpeed(speed);
  }

  @override
  Future<void> setQuality(String quality) async {
    final levels = {'480p': 1, '720p': 2, '1080p': 3};
    final level = levels[quality] ?? 0;
    _engine?.setQuality(level);
    _state = _state.copyWith(currentQuality: quality);
    notifyListeners();
  }

  @override
  Future<void> setAudioTrack(String track) async {
    _state = _state.copyWith(currentAudioTrack: track);
    notifyListeners();
  }

  @override
  Future<void> setSubtitle(String subtitle) async {
    _state = _state.copyWith(currentSubtitle: subtitle);
    notifyListeners();
  }

  @override
  Future<void> setSubtitlesData(List<Map<String, dynamic>> subtitles) async {
    _state = _state.copyWith(availableSubtitles: subtitles);
    notifyListeners();
  }

  @override
  Future<void> enterPip() async {
    // C++ Engine PiP trigger
  }

  @override
  Future<void> dispose() async {
    _statusUpdateTimer?.cancel();
    _eventSubscription?.cancel();
    _engine?.dispose();
    if (_textureId != null) {
      await TextureRegistryBridge.releaseTexture(_textureId!);
    }
    super.dispose();
  }
}
