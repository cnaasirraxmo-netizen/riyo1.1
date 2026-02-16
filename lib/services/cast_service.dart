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

  List<GoogleCastDevice> get devices => _devices;
  GoogleCastDevice? get selectedDevice => _selectedDevice;
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;

  CastService() {
    _init();
    initContext();
  }

  void _init() {
    _sessionSubscription = GoogleCastSessionManager.instance.currentSessionStream.listen((session) {
      _isConnected = GoogleCastSessionManager.instance.connectionState == GoogleCastConnectState.connected;
      if (!_isConnected) {
         _selectedDevice = null;
      }
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
    super.dispose();
  }
}
