import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riyo/core/casting/domain/entities/cast_device.dart';
import 'package:riyo/core/casting/domain/entities/cast_media.dart';
import 'package:riyo/core/casting/domain/repositories/casting_repository.dart';
import 'package:riyo/core/casting/data/repositories/casting_repository_impl.dart';

final castingRepositoryProvider = Provider<CastingRepository>((ref) {
  return CastingRepositoryImpl();
});

class CastingState {
  final List<CastDevice> devices;
  final CastDevice? connectedDevice;
  final bool isScanning;
  final CastMedia? currentMedia;
  final bool isPlaying;
  final List<CastMedia> queue;

  CastingState({
    this.devices = const [],
    this.connectedDevice,
    this.isScanning = false,
    this.currentMedia,
    this.isPlaying = false,
    this.queue = const [],
  });

  CastingState copyWith({
    List<CastDevice>? devices,
    CastDevice? connectedDevice,
    bool? isScanning,
    CastMedia? currentMedia,
    bool? isPlaying,
    List<CastMedia>? queue,
  }) {
    return CastingState(
      devices: devices ?? this.devices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      isScanning: isScanning ?? this.isScanning,
      currentMedia: currentMedia ?? this.currentMedia,
      isPlaying: isPlaying ?? this.isPlaying,
      queue: queue ?? this.queue,
    );
  }
}

class CastingNotifier extends Notifier<CastingState> {
  CastingRepository get _repository => ref.watch(castingRepositoryProvider);

  @override
  CastingState build() {
    return CastingState();
  }

  void startDiscovery() {
    state = state.copyWith(isScanning: true);
    _repository.startDiscovery();
    _repository.devicesStream.listen((devices) {
      state = state.copyWith(devices: devices);
    });
  }

  void stopDiscovery() {
    _repository.stopDiscovery();
    state = state.copyWith(isScanning: false);
  }

  Future<void> connect(CastDevice device) async {
    await _repository.connect(device);
    state = state.copyWith(connectedDevice: device);
  }

  Future<void> disconnect() async {
    await _repository.disconnect();
    state = state.copyWith(connectedDevice: null);
  }

  Future<void> castMedia(CastMedia media) async {
    await _repository.castMedia(media);
    state = state.copyWith(currentMedia: media, isPlaying: true);
  }

  Future<void> togglePlay() async {
    if (state.isPlaying) {
      await _repository.pause();
    } else {
      await _repository.play();
    }
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  Future<void> stop() async {
    await _repository.stop();
    state = state.copyWith(isPlaying: false, currentMedia: null);
  }

  Future<void> seek(Duration position) async {
    await _repository.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _repository.setVolume(volume);
  }
}

final castingProvider = NotifierProvider<CastingNotifier, CastingState>(CastingNotifier.new);
