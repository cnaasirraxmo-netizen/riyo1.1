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

  PlayerState({
    this.status = PlayerStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffered = Duration.zero,
    this.error,
  });

  PlayerState copyWith({
    PlayerStatus? status,
    Duration? position,
    Duration? duration,
    Duration? buffered,
    String? error,
  }) {
    return PlayerState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffered: buffered ?? this.buffered,
      error: error ?? this.error,
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
  Future<void> dispose();
}
