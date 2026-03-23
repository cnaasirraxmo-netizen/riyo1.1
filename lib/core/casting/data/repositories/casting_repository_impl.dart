import 'dart:async';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:media_cast_dlna/media_cast_dlna.dart';
import 'package:riyo/core/casting/domain/entities/cast_device.dart';
import 'package:riyo/core/casting/domain/entities/cast_media.dart';
import 'package:riyo/core/casting/domain/repositories/casting_repository.dart';

class CastingRepositoryImpl implements CastingRepository {
  final _devicesController = StreamController<List<CastDevice>>.broadcast();
  final List<CastDevice> _foundDevices = [];

  StreamSubscription? _googleCastSub;
  final _dlnaApi = MediaCastDlnaApi();
  Timer? _dlnaDiscoveryTimer;

  @override
  Stream<List<CastDevice>> get devicesStream => _devicesController.stream;

  @override
  Future<void> startDiscovery() async {
    _foundDevices.clear();
    _devicesController.add([]);

    // 1. Google Cast Discovery
    _googleCastSub?.cancel();
    GoogleCastDiscoveryManager.instance.startDiscovery();
    _googleCastSub = GoogleCastDiscoveryManager.instance.devicesStream.listen(
      (googleDevices) {
        _updateDevices(googleDevices.map((d) => CastDevice(
          id: d.deviceID,
          name: d.friendlyName,
          model: d.modelName,
          type: CastDeviceType.googleCast,
          originalDevice: d,
        )).toList(), CastDeviceType.googleCast);
      },
      onError: (error) {
        _devicesController.addError(error);
      },
    );

    // 2. DLNA Discovery
    await _dlnaApi.initializeUpnpService();
    await _dlnaApi.startDiscovery(DiscoveryOptions(timeout: DiscoveryTimeout(seconds: 10)));

    _dlnaDiscoveryTimer?.cancel();
    _dlnaDiscoveryTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final dlnaDevices = await _dlnaApi.getDiscoveredDevices();
       _updateDevices(dlnaDevices.where((d) => d.deviceType.contains('MediaRenderer')).map((d) => CastDevice(
        id: d.udn.value,
        name: d.friendlyName,
        ip: d.ipAddress.value,
        type: CastDeviceType.dlna,
        originalDevice: d,
      )).toList(), CastDeviceType.dlna);
    });
  }

  void _updateDevices(List<CastDevice> newDevices, CastDeviceType type) {
    _foundDevices.removeWhere((d) => d.type == type);
    _foundDevices.addAll(newDevices);
    _devicesController.add(List.from(_foundDevices));
  }

  @override
  Future<void> stopDiscovery() async {
    GoogleCastDiscoveryManager.instance.stopDiscovery();
    _googleCastSub?.cancel();
    _dlnaDiscoveryTimer?.cancel();
    await _dlnaApi.stopDiscovery();
  }

  CastDevice? _connectedDevice;

  @override
  Future<void> connect(CastDevice device) async {
    _connectedDevice = device;
    if (device.type == CastDeviceType.googleCast) {
      await GoogleCastSessionManager.instance.startSessionWithDevice(device.originalDevice);
    } else if (device.type == CastDeviceType.dlna) {
      // DLNA usually doesn't have a "session" start, just send media to the IP
    }
  }

  @override
  Future<void> disconnect() async {
    if (_connectedDevice?.type == CastDeviceType.googleCast) {
      await GoogleCastSessionManager.instance.endSessionAndStopCasting();
    }
    _connectedDevice = null;
  }

  @override
  Future<void> castMedia(CastMedia media) async {
    if (_connectedDevice == null) return;

    if (_connectedDevice!.type == CastDeviceType.googleCast) {
       final mediaInfo = GoogleCastMediaInformation(
        contentId: media.url,
        contentType: 'video/mp4',
        streamType: media.isLive ? CastMediaStreamType.live : CastMediaStreamType.buffered,
        metadata: GoogleCastMovieMediaMetadata(
          title: media.title,
          subtitle: media.subtitle ?? 'RIYO',
          images: media.posterUrl != null ? [GoogleCastImage(url: Uri.parse(media.posterUrl!))] : [],
        ),
      );
      await GoogleCastRemoteMediaClient.instance.loadMedia(mediaInfo);
    } else if (_connectedDevice!.type == CastDeviceType.dlna) {
       final device = _connectedDevice!.originalDevice as DlnaDevice;
       await _dlnaApi.setMediaUri(
         device.udn,
         Url(value: media.url),
         VideoMetadata(title: media.title),
       );
       await _dlnaApi.play(device.udn);
    }
  }

  @override
  Future<void> pause() async {
     if (_connectedDevice?.type == CastDeviceType.googleCast) {
       await GoogleCastRemoteMediaClient.instance.pause();
     } else if (_connectedDevice?.type == CastDeviceType.dlna) {
       await _dlnaApi.pause((_connectedDevice!.originalDevice as DlnaDevice).udn);
     }
  }

  @override
  Future<void> play() async {
     if (_connectedDevice?.type == CastDeviceType.googleCast) {
       await GoogleCastRemoteMediaClient.instance.play();
     } else if (_connectedDevice?.type == CastDeviceType.dlna) {
       await _dlnaApi.play((_connectedDevice!.originalDevice as DlnaDevice).udn);
     }
  }

  @override
  Future<void> stop() async {
     if (_connectedDevice?.type == CastDeviceType.googleCast) {
       await GoogleCastRemoteMediaClient.instance.stop();
     } else if (_connectedDevice?.type == CastDeviceType.dlna) {
       await _dlnaApi.stop((_connectedDevice!.originalDevice as DlnaDevice).udn);
     }
  }

  @override
  Future<void> seek(Duration position) async {
     if (_connectedDevice?.type == CastDeviceType.googleCast) {
       await GoogleCastRemoteMediaClient.instance.seek(GoogleCastMediaSeekOption(position: position));
     } else if (_connectedDevice?.type == CastDeviceType.dlna) {
       await _dlnaApi.seek((_connectedDevice!.originalDevice as DlnaDevice).udn, TimePosition(seconds: position.inSeconds));
     }
  }

  @override
  Future<void> setVolume(double volume) async {
     if (_connectedDevice?.type == CastDeviceType.googleCast) {
       GoogleCastSessionManager.instance.setDeviceVolume(volume);
     } else if (_connectedDevice?.type == CastDeviceType.dlna) {
       await _dlnaApi.setVolume((_connectedDevice!.originalDevice as DlnaDevice).udn, VolumeLevel(percentage: (volume * 100).toInt()));
     }
  }
}
