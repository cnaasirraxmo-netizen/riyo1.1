import 'package:flutter/foundation.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;

class CastService extends ChangeNotifier {
  List<GoogleCastDevice> _devices = [];
  GoogleCastDevice? _selectedDevice;
  bool _isScanning = false;
  bool _isConnected = false;
  StreamSubscription? _discoverySubscription;
  StreamSubscription? _sessionSubscription;
  StreamSubscription? _mediaStatusSubscription;
  StreamSubscription? _positionSubscription;

  GoggleCastMediaStatus? _mediaStatus;
  Duration _currentPosition = Duration.zero;

  List<GoogleCastDevice> get devices => _devices;
  GoogleCastDevice? get selectedDevice => _selectedDevice;
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  GoggleCastMediaStatus? get mediaStatus => _mediaStatus;
  Duration get currentPosition => _currentPosition;

  CastService() {
    _init();
    initContext();
  }

  void _init() {
    _sessionSubscription = GoogleCastSessionManager.instance.currentSessionStream.listen((session) {
      _isConnected = GoogleCastSessionManager.instance.connectionState == GoogleCastConnectState.connected;
      if (!_isConnected) {
         _selectedDevice = null;
         _mediaStatus = null;
         _currentPosition = Duration.zero;
         _mediaStatusSubscription?.cancel();
         _positionSubscription?.cancel();
      } else {
        _listenToMediaStatus();
      }
      notifyListeners();
    });
  }

  void _listenToMediaStatus() {
    _mediaStatusSubscription?.cancel();
    _mediaStatusSubscription = GoogleCastRemoteMediaClient.instance.mediaStatusStream.listen((status) {
      _mediaStatus = status;
      notifyListeners();
    });

    _positionSubscription?.cancel();
    _positionSubscription = GoogleCastRemoteMediaClient.instance.playerPositionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
  }

  Future<void> initContext() async {
    const appId = GoogleCastDiscoveryCriteria.kDefaultApplicationId;
    GoogleCastOptions? options;
    if (Platform.isIOS) {
      options = IOSGoogleCastOptions(
        GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(appId),
      );
    } else {
      options = GoogleCastOptionsAndroid(
        appId: appId,
      );
    }
    await GoogleCastContext.instance.setSharedInstanceWithOptions(options);
  }

  void startScanning() {
    if (_isScanning) return;
    _isScanning = true;
    _devices = [];
    notifyListeners();

    GoogleCastDiscoveryManager.instance.startDiscovery();
    _discoverySubscription = GoogleCastDiscoveryManager.instance.devicesStream.listen((devices) {
      _devices = devices;
      notifyListeners();
    });
  }

  void stopScanning() {
    _isScanning = false;
    GoogleCastDiscoveryManager.instance.stopDiscovery();
    _discoverySubscription?.cancel();
    notifyListeners();
  }

  Future<void> connectToDevice(GoogleCastDevice device) async {
    try {
      _selectedDevice = device;
      notifyListeners();
      developer.log('Connecting to device: ${device.friendlyName}');
      await GoogleCastSessionManager.instance.startSessionWithDevice(device);
    } catch (e) {
      developer.log('Error connecting to device', error: e);
      _selectedDevice = null;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await GoogleCastSessionManager.instance.endSessionAndStopCasting();
    _selectedDevice = null;
    notifyListeners();
  }

  Future<void> loadMedia(String url, {String? title, String? subtitle, String? posterUrl}) async {
    if (!_isConnected) {
      developer.log('Not connected to a cast device');
      return;
    }

    developer.log('Loading media: $url');
    final media = GoogleCastMediaInformation(
      contentId: url,
      contentType: 'video/mp4',
      streamType: CastMediaStreamType.buffered,
      metadata: GoogleCastMovieMediaMetadata(
        title: title ?? 'Video',
        subtitle: subtitle ?? 'RIYOBOX',
        images: posterUrl != null ? [GoogleCastImage(url: Uri.parse(posterUrl))] : [],
      ),
    );

    try {
      await GoogleCastRemoteMediaClient.instance.loadMedia(media);
      developer.log('Media loaded successfully');
    } catch (e) {
      developer.log('Error loading media', error: e);
    }
  }

  Future<void> play() async {
    await GoogleCastRemoteMediaClient.instance.play();
  }

  Future<void> pause() async {
    await GoogleCastRemoteMediaClient.instance.pause();
  }

  Future<void> stop() async {
    await GoogleCastRemoteMediaClient.instance.stop();
  }

  Future<void> seek(Duration position) async {
    await GoogleCastRemoteMediaClient.instance.seek(
      GoogleCastMediaSeekOption(
        position: position,
        resumeState: GoogleCastMediaResumeState.play,
      ),
    );
  }

  Future<void> setVolume(double volume) async {
    GoogleCastSessionManager.instance.setDeviceVolume(volume);
  }

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    _sessionSubscription?.cancel();
    _mediaStatusSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}
