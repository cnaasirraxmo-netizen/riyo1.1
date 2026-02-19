import 'package:flutter/foundation.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'dart:async';
import 'dart:io';

class CastService extends ChangeNotifier {
  List<GoogleCastDevice> _devices = [];
  GoogleCastDevice? _selectedDevice;
  bool _isScanning = false;
  bool _isConnected = false;
  StreamSubscription? _discoverySubscription;
  StreamSubscription? _sessionSubscription;
  StreamSubscription? _mediaStatusSubscription;

  // Typo in version 1.3.0 of flutter_chrome_cast: GoggleCastMediaStatus
  dynamic _mediaStatus;

  List<GoogleCastDevice> get devices => _devices;
  GoogleCastDevice? get selectedDevice => _selectedDevice;
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;

  static bool _contextInitialized = false;

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
         _setupMediaStatusListener();
      }
      notifyListeners();
    });
  }

  void _setupMediaStatusListener() {
    _mediaStatusSubscription?.cancel();
    _mediaStatusSubscription = GoogleCastRemoteMediaClient.instance.mediaStatusStream.listen((status) {
      _mediaStatus = status;
      notifyListeners();
    });
  }

  Future<void> initContext() async {
    if (_contextInitialized) return;

    try {
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
      _contextInitialized = true;
      print('Cast Context Initialized');
    } catch (e) {
      print('Error initializing Cast Context: $e');
    }
  }

  Future<void> reconnect() async {
    final session = GoogleCastSessionManager.instance.currentSession;
    if (session != null && !_isConnected) {
       _isConnected = true;
       _setupMediaStatusListener();
       notifyListeners();
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
    }
  }

  Future<void> disconnect() async {
    await GoogleCastSessionManager.instance.endSessionAndStopCasting();
    _selectedDevice = null;
    _mediaStatus = null;
    _mediaStatusSubscription?.cancel();
    notifyListeners();
  }

  // Playback Controls
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
    try {
      // Trying different ways to call seek as the package documentation is sparse
      await (GoogleCastRemoteMediaClient.instance as dynamic).seek(position.inSeconds.toDouble());
    } catch (e) {
      print('Seek failed: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await (GoogleCastRemoteMediaClient.instance as dynamic).setStreamVolume(volume);
    } catch (e) {
      print('Set Volume failed: $e');
    }
  }

  // Getters for media state
  dynamic get mediaStatus => _mediaStatus;

  bool get isPlaying {
    if (_mediaStatus == null) return false;
    try {
      return _mediaStatus.playerState == CastMediaPlayerState.playing;
    } catch (_) {
      return false;
    }
  }

  Duration get position {
    if (_mediaStatus == null) return Duration.zero;
    try {
      return Duration(seconds: _mediaStatus.streamPosition.toInt());
    } catch (_) {
      return Duration.zero;
    }
  }

  String? get currentContentId {
    if (_mediaStatus == null) return null;
    try {
      return _mediaStatus.mediaInformation.contentId;
    } catch (_) {
      return null;
    }
  }

  Duration get duration {
    if (_mediaStatus == null) return Duration.zero;
    try {
      return Duration(seconds: _mediaStatus.mediaInformation.streamDuration.toInt());
    } catch (_) {
      return Duration.zero;
    }
  }

  Future<void> loadMedia(String url, {String? title, String? subtitle, String? posterUrl}) async {
    if (!_isConnected) {
      print('Not connected to a cast device');
      return;
    }

    print('Loading media: $url');
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
      print('Media loaded successfully');
    } catch (e) {
      print('Error loading media: $e');
    }
  }

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    _sessionSubscription?.cancel();
    _mediaStatusSubscription?.cancel();
    super.dispose();
  }
}
