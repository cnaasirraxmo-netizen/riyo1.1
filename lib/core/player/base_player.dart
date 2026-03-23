import 'package:flutter/widgets.dart';

enum PlayerStatus {
  idle,
  loading,
  playing,
  paused,
  buffering,
  error,
  completed
}

class PlayerState {
  final PlayerStatus status;
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final String? error;
  final List<String> availableQualities;
  final String? currentQuality;
  final List<String> availableAudioTracks;
  final String? currentAudioTrack;
  final List<Map<String, dynamic>> availableSubtitles;
  final String? currentSubtitle;
  final double playbackSpeed;
  final double volume;

  PlayerState({
    this.status = PlayerStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffered = Duration.zero,
    this.error,
    this.availableQualities = const [],
    this.currentQuality,
    this.availableAudioTracks = const [],
    this.currentAudioTrack,
    this.availableSubtitles = const [],
    this.currentSubtitle,
    this.playbackSpeed = 1.0,
    this.volume = 1.0,
  });

  PlayerState copyWith({
    PlayerStatus? status,
    Duration? position,
    Duration? duration,
    Duration? buffered,
    String? error,
    List<String>? availableQualities,
    String? currentQuality,
    List<String>? availableAudioTracks,
    String? currentAudioTrack,
    List<Map<String, dynamic>>? availableSubtitles,
    String? currentSubtitle,
    double? playbackSpeed,
    double? volume,
  }) {
    return PlayerState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffered: buffered ?? this.buffered,
      error: error ?? this.error,
      availableQualities: availableQualities ?? this.availableQualities,
      currentQuality: currentQuality ?? this.currentQuality,
      availableAudioTracks: availableAudioTracks ?? this.availableAudioTracks,
      currentAudioTrack: currentAudioTrack ?? this.currentAudioTrack,
      availableSubtitles: availableSubtitles ?? this.availableSubtitles,
      currentSubtitle: currentSubtitle ?? this.currentSubtitle,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      volume: volume ?? this.volume,
    );
  }
}

abstract class BaseVideoPlayer extends ChangeNotifier {
  PlayerState get state;
  Widget buildPlayer(BuildContext context);

  Future<void> initialize(String url);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> setSpeed(double speed);
  Future<void> setQuality(String quality);
  Future<void> setAudioTrack(String track);
  Future<void> setSubtitle(String subtitle);
  Future<void> setSubtitlesData(List<Map<String, dynamic>> subtitles);
  Future<void> enterPip();
  Future<void> dispose();
}
