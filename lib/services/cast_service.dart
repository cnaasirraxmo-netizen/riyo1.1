import 'package:flutter/foundation.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'dart:async';
import 'dart:io';

class CastService extends ChangeNotifier {
  List<GoogleCastDevice> _devices = [];
  GoogleCastDevice? _selectedDevice;
  bool _isScanning = false;
  bool _isConnected = false;
  bool _isDiscovered = false;
  String? _currentTitle;
  String? _currentPoster;
  bool _isPlaying = false;
  double _volume = 0.5;

  StreamSubscription? _discoverySubscription;
  StreamSubscription? _sessionSubscription;
  Timer? _discoveryTimer;

  List<GoogleCastDevice> get devices => _devices;
  GoogleCastDevice? get selectedDevice => _selectedDevice;
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  bool get hasDevices => _devices.isNotEmpty;
  String? get currentTitle => _currentTitle;
  String? get currentPoster => _currentPoster;
  bool get isPlaying => _isPlaying;
  double get volume => _volume;

  CastService() {
    _init();
  }

  Future<void> _init() async {
    await initContext();
    _sessionSubscription = GoogleCastSessionManager.instance.currentSessionStream.listen((session) {
      _isConnected = GoogleCastSessionManager.instance.connectionState == GoogleCastConnectState.connected;
      if (!_isConnected) {
         _selectedDevice = null;
      }
      notifyListeners();
    });

    // Start passive discovery
    _startPassiveDiscovery();
  }

  void _startPassiveDiscovery() {
    _discoveryTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (!_isScanning && !_isConnected) {
        startScanning();
        Future.delayed(const Duration(seconds: 10), () => stopScanning());
      }
    });
    // Initial scan
    startScanning();
    Future.delayed(const Duration(seconds: 15), () => stopScanning());
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
    notifyListeners();
  }

  Future<void> loadMedia(String url, {String? title, String? subtitle, String? posterUrl}) async {
    if (!_isConnected) {
      print('Not connected to a cast device');
      return;
    }

    _currentTitle = title;
    _currentPoster = posterUrl;
    _isPlaying = true;
    notifyListeners();

    print('Loading media: $url');
    final media = GoogleCastMediaInformation(
      contentId: url,
      contentType: 'video/mp4',
      streamType: CastMediaStreamType.buffered,
      metadata: GoogleCastMovieMediaMetadata(
        title: title ?? 'Video',
        subtitle: subtitle ?? 'RIYO',
        images: posterUrl != null ? [GoogleCastImage(url: Uri.parse(posterUrl))] : [],
      ),
    );

    try {
      await GoogleCastRemoteMediaClient.instance.loadMedia(media);
      print('Media loaded successfully');
    } catch (e) {
      print('Error loading media: $e');
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> play() async {
    await GoogleCastRemoteMediaClient.instance.play();
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> pause() async {
    await GoogleCastRemoteMediaClient.instance.pause();
    _isPlaying = false;
    notifyListeners();
  }
  Future<void> stop() async {
    await GoogleCastRemoteMediaClient.instance.stop();
    _isPlaying = false;
    _currentTitle = null;
    notifyListeners();
  }

  Future<void> seek(Duration position) async => await GoogleCastRemoteMediaClient.instance.seek(GoogleCastMediaSeekOption(position: position));

  Future<void> setVolume(double vol) async {
    GoogleCastSessionManager.instance.setDeviceVolume(vol);
    _volume = vol;
    notifyListeners();
  }

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    _sessionSubscription?.cancel();
    _discoveryTimer?.cancel();
    super.dispose();
  }
}
