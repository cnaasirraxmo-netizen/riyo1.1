import 'package:flutter/foundation.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'dart:async';
import 'dart:io';

class CastService extends ChangeNotifier {
  List<GoogleCastDevice> _devices = [];
  GoogleCastDevice? _selectedDevice;
  bool _isScanning = false;
  bool _isConnected = false;
  GoggleCastMediaStatus? _mediaStatus;
  StreamSubscription? _discoverySubscription;
  StreamSubscription? _sessionSubscription;
  StreamSubscription? _mediaStatusSubscription;
  Timer? _ticker;

  List<GoogleCastDevice> get devices => _devices;
  GoogleCastDevice? get selectedDevice => _selectedDevice;
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  GoggleCastMediaStatus? get mediaStatus => _mediaStatus;

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
        _mediaStatusSubscription?.cancel();
      } else {
        _subscribeToMediaStatus();
      }
      notifyListeners();
    });
  }

  void _subscribeToMediaStatus() {
    _mediaStatusSubscription?.cancel();
    _mediaStatusSubscription = GoogleCastRemoteMediaClient.instance.mediaStatusStream.listen((status) {
      _mediaStatus = status;
      _startTicker();
      notifyListeners();
    });
  }

  void _startTicker() {
    _ticker?.cancel();
    if (isPlaying) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
        notifyListeners();
      });
    }
  }

  void _stopTicker() {
    _ticker?.cancel();
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
    if (options != null) {
      await GoogleCastContext.instance.setSharedInstanceWithOptions(options);
    }
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
      print('Connecting to device: ${device.friendlyName}');
      await GoogleCastSessionManager.instance.startSessionWithDevice(device);
    } catch (e) {
      print('Error connecting to device: $e');
      _selectedDevice = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await GoogleCastSessionManager.instance.endSessionAndStopCasting();
    _selectedDevice = null;
    notifyListeners();
  }

  Future<void> loadMedia(String url, {String? title, String? subtitle, String? posterUrl}) async {
    if (!_isConnected) {
      print('Not connected to a cast device');
      return;
    }

    print('Loading media: $url');

    // Determine content type based on URL or default to video/mp4
    String contentType = 'video/mp4';
    if (url.toLowerCase().endsWith('.m3u8')) {
      contentType = 'application/x-mpegurl';
    } else if (url.toLowerCase().endsWith('.mp3')) {
      contentType = 'audio/mpeg';
    }

    final media = GoogleCastMediaInformation(
      contentId: url,
      contentType: contentType,
      streamType: CastMediaStreamType.buffered,
      metadata: GoogleCastMovieMediaMetadata(
        title: title ?? 'Video',
        subtitle: subtitle ?? 'RIYOBOX',
        images: posterUrl != null ? [GoogleCastImage(url: Uri.parse(posterUrl))] : [],
      ),
    );

    try {
      await GoogleCastRemoteMediaClient.instance.loadMedia(media);
      print('Media loaded successfully');
    } catch (e) {
      print('Error loading media: $e');
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
      GoogleCastMediaSeekOption(position: position),
    );
  }

  void setVolume(double volume) {
    GoogleCastSessionManager.instance.setDeviceVolume(volume);
  }

  bool get isPlaying => _mediaStatus?.playerState == CastMediaPlayerState.playing;
  bool get isPaused => _mediaStatus?.playerState == CastMediaPlayerState.paused;
  bool get isBuffering => _mediaStatus?.playerState == CastMediaPlayerState.buffering;

  Duration get position => GoogleCastRemoteMediaClient.instance.playerPosition;
  Duration get duration => _mediaStatus?.mediaInformation?.duration ?? Duration.zero;

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    _sessionSubscription?.cancel();
    _mediaStatusSubscription?.cancel();
    _ticker?.cancel();
    super.dispose();
  }
}
