import '../entities/cast_device.dart';
import '../entities/cast_media.dart';

abstract class CastingRepository {
  Stream<List<CastDevice>> get devicesStream;
  Future<void> startDiscovery();
  Future<void> stopDiscovery();
  Future<void> connect(CastDevice device);
  Future<void> disconnect();
  Future<void> castMedia(CastMedia media);

  // Playback controls
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
}
