import 'package:flutter/material.dart';
import 'package:riyo/core/video_engine/riyo_video_engine.dart';
import 'package:riyo/core/video_engine/texture_bridge.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'dart:async';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:riyo/providers/playback_provider.dart';
import 'package:riyo/providers/auth_provider.dart';
import 'package:riyo/providers/download_provider.dart';
import 'package:riyo/services/api_service.dart';
import 'package:riyo/models/movie.dart';
import 'package:riyo/core/casting/presentation/widgets/cast_button.dart';
import 'package:riyo/core/casting/presentation/providers/casting_provider.dart';
import 'package:riyo/core/casting/domain/entities/cast_media.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:webview_flutter/webview_flutter.dart';

class VideoPlayerScreen extends rp.ConsumerStatefulWidget {
  final String? movieId;
  final String? videoUrl;
  final int? season;
  final int? episode;

  const VideoPlayerScreen({super.key, this.movieId, this.videoUrl, this.season, this.episode});

  @override
  rp.ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends rp.ConsumerState<VideoPlayerScreen> {
  RiyoVideoEngine? _engine;
  int? _textureId;
  WebViewController? _webController;
  bool _isControlsVisible = true;
  Timer? _hideControlsTimer;
  double _currentVolume = 0.5;
  double _currentBrightness = 0.5;
  double _playbackSpeed = 1.0;
  String _selectedQuality = 'Auto';
  String _selectedAudio = 'English';
  String _selectedSubtitle = 'Off';
  bool _isBuffering = false;

  Movie? _movie;
  List<Map<String, dynamic>> _sources = [];
  Map<String, dynamic>? _selectedSource;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _fetchData();
    _initVolume();
    _initBrightness();
    _initCastListener();
  }

  Future<void> _fetchData() async {
    final apiService = ApiService();
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (widget.movieId != null) {
      try {
        _movie = await apiService.getMovieDetails(widget.movieId!, token: auth.token);
        final response = await apiService.getSources(widget.movieId!, season: widget.season, episode: widget.episode);
        _sources = List<Map<String, dynamic>>.from(response['sources']);

        if (_sources.isNotEmpty) {
           _selectedSource = _sources.first;
        }

        if (mounted) {
          _initPlayer();
        }
      } catch (e) {
        debugPrint('Error fetching player data: $e');
      }
    } else if (widget.videoUrl != null) {
       _initPlayer();
    }
  }

  void _initCastListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(castingProvider, (previous, next) {
        if (next.connectedDevice != null && _engine != null && _engine!.getState() == 2) {
           _startCasting();
        }
      });
    });
  }

  Future<void> _startCasting() async {
    final castingNotifier = ref.read(castingProvider.notifier);
    String? url = _selectedSource?['url'] ?? widget.videoUrl;
    String? title = _movie?.title ?? "Video";
    String? poster = _movie != null ? (_movie!.posterPath.startsWith('http') ? _movie!.posterPath : 'https://image.tmdb.org/t/p/w500${_movie!.posterPath}') : null;

    if (url != null) {
      _engine?.pause();
      await castingNotifier.castMedia(CastMedia(
        url: url,
        title: title,
        posterUrl: poster,
      ));
    }
  }

  Future<void> _initPlayer() async {
    String? url = _selectedSource?['url'] ?? widget.videoUrl;

    if (_selectedSource?['type'] == 'embed') {
      _engine?.dispose();
      _engine = null;
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..loadRequest(Uri.parse(url!));
      if (mounted) setState(() {});
      return;
    }

    url ??= 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

    _engine = RiyoVideoEngine();
    _textureId = await TextureRegistryBridge.createTexture();
    _engine!.load(url);
    _engine!.setEventCallback();
    _engine!.play();

    if (mounted) {
      setState(() {});
      _startHideControlsTimer();
    }
  }

  Future<void> _initVolume() async {
    _currentVolume = await FlutterVolumeController.getVolume() ?? 0.5;
    if (mounted) setState(() {});
  }

  Future<void> _initBrightness() async {
    try {
      _currentBrightness = await ScreenBrightness().application;
    } catch (e) {
      _currentBrightness = 0.5;
    }
    if (mounted) setState(() {});
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });
    if (_isControlsVisible) {
      _startHideControlsTimer();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _engine != null && _engine!.getState() == 2) {
        setState(() {
          _isControlsVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _engine?.dispose();
    if (_textureId != null) {
      TextureRegistryBridge.releaseTexture(_textureId!);
    }
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _seekRelative(Duration duration) {
    if (_engine == null) return;
    _engine!.seek(duration.inSeconds.toDouble());
    _startHideControlsTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: <Widget>[
            Center(
              child: _selectedSource?['type'] == 'embed'
                  ? (_webController != null
                      ? WebViewWidget(controller: _webController!)
                      : const CircularProgressIndicator(color: Colors.yellow))
                  : (_textureId != null)
                      ? Texture(textureId: _textureId!)
                      : const CircularProgressIndicator(color: Colors.yellow),
            ),
            if (_isControlsVisible) _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black45,
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const Spacer(),
            if (_selectedSource?['type'] != 'embed') _buildPlaybackControls(),
            const Spacer(),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              _movie?.title ?? 'Loading...',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const CastingButton(),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () => _showSettingsMenu()),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    if (_engine == null) return const SizedBox();
    final isPlaying = _engine!.getState() == 2;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10, color: Colors.white, size: 40),
          onPressed: () => _seekRelative(const Duration(seconds: -10)),
        ),
        const SizedBox(width: 40),
        IconButton(
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: Colors.yellow,
            size: 80,
          ),
          onPressed: () {
            setState(() {
              isPlaying ? _engine!.pause() : _engine!.play();
              _startHideControlsTimer();
            });
          },
        ),
        const SizedBox(width: 40),
        IconButton(
          icon: const Icon(Icons.forward_10, color: Colors.white, size: 40),
          onPressed: () => _seekRelative(const Duration(seconds: 10)),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (_selectedSource?['type'] != 'embed')
            Slider(
              value: 0.2,
              onChanged: (val) {},
              activeColor: Colors.yellow,
              inactiveColor: Colors.white24,
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedSource?['type'] == 'embed' ? 'External Source' : '00:20 / 05:00',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Row(
                children: [
                  _buildControlItem(Icons.monitor, _selectedSource?['label'] ?? 'Source', _showSourceMenu),
                  if (_selectedSource?['type'] != 'embed')
                    _buildControlItem(Icons.speed, '${_playbackSpeed}x', _showSpeedMenu),
                  _buildControlItem(Icons.high_quality, _selectedQuality, _showQualityMenu),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlItem(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _showSourceMenu() {
    _showBottomDialog('Select Server', _sources.map((s) => s['label'].toString()).toList(), (val) {
      final source = _sources.firstWhere((s) => s['label'] == val);
      setState(() {
        _selectedSource = source;
        _initPlayer();
      });
    });
  }

  void _showSpeedMenu() {
    _showBottomDialog('Playback Speed', ['0.5x', '1.0x', '1.5x', '2.0x'], (val) {
      setState(() {
        _playbackSpeed = double.parse(val.replaceAll('x', ''));
      });
    });
  }

  void _showQualityMenu() {
    _showBottomDialog('Video Quality', ['Auto', '720p', '1080p'], (val) {
      setState(() => _selectedQuality = val);
    });
  }

  void _showSettingsMenu() {
    _showBottomDialog('Settings', ['Auto-play next', 'Skip Intro'], (val) {});
  }

  void _showBottomDialog(String title, List<String> options, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A3A),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ...options.map((opt) => ListTile(
              title: Text(opt, style: const TextStyle(color: Colors.white)),
              onTap: () {
                onSelect(opt);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
}
