import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'base_player.dart';

class NativePlayer extends BaseVideoPlayer {
  VideoPlayerController? _controller;
  PlayerState _state = PlayerState();

  @override
  PlayerState get state => _state;

  @override
  Widget buildPlayer(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: VideoPlayer(_controller!),
    );
  }

  @override
  Future<void> initialize(String url) async {
    _state = _state.copyWith(status: PlayerStatus.loading);
    notifyListeners();

    if (url.startsWith('http')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    } else {
      _controller = VideoPlayerController.file(File(url));
    }

    try {
      await _controller!.initialize();
      _controller!.addListener(_updateState);
      _state = _state.copyWith(
        status: PlayerStatus.idle,
        duration: _controller!.value.duration,
      );
    } catch (e) {
      _state = _state.copyWith(status: PlayerStatus.error, error: e.toString());
    }
    notifyListeners();
  }

  void _updateState() {
    if (_controller == null) return;

    PlayerStatus status;
    if (_controller!.value.hasError) {
      status = PlayerStatus.error;
    } else if (_controller!.value.isBuffering) {
      status = PlayerStatus.buffering;
    } else if (_controller!.value.isPlaying) {
      status = PlayerStatus.playing;
    } else if (_controller!.value.isInitialized) {
      if (_controller!.value.position >= _controller!.value.duration) {
        status = PlayerStatus.completed;
      } else {
        status = PlayerStatus.paused;
      }
    } else {
      status = PlayerStatus.loading;
    }

    _state = _state.copyWith(
      status: status,
      position: _controller!.value.position,
      duration: _controller!.value.duration,
      buffered: _controller!.value.buffered.isNotEmpty
          ? _controller!.value.buffered.last.end
          : Duration.zero,
      error: _controller!.value.errorDescription,
    );
    notifyListeners();
  }

  @override
  Future<void> play() async {
    await _controller?.play();
  }

  @override
  Future<void> pause() async {
    await _controller?.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _controller?.seekTo(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _controller?.setVolume(volume);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _controller?.setPlaybackSpeed(speed);
  }

  @override
  Future<void> dispose() async {
    _controller?.removeListener(_updateState);
    await _controller?.dispose();
    super.dispose();
  }
}
