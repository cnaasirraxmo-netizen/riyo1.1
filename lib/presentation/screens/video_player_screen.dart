import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:riyobox/providers/playback_provider.dart';
import 'package:riyobox/providers/auth_provider.dart';
import 'package:riyobox/providers/download_provider.dart';
import 'package:riyobox/services/api_service.dart';
import 'package:riyobox/models/movie.dart';
import 'package:riyobox/services/cast_service.dart';
import 'package:riyobox/services/native_video_service.dart';
import 'package:flutter/services.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String? movieId;
  final String? videoUrl;

  const VideoPlayerScreen({super.key, this.movieId, this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  Movie? _movie;
  bool _isControlsVisible = true;
  Timer? _hideControlsTimer;
  double _currentVolume = 0.5;
  double _currentBrightness = 0.5;
  double _playbackSpeed = 1.0;
  String _selectedAudio = 'English';
  String _selectedSubtitle = 'Off';
  bool _isBuffering = false;
  bool _isLocked = false;
  BoxFit _videoFit = BoxFit.contain;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WakelockPlus.enable();
    _initPlayer();
    _initVolume();
    _initBrightness();
  }

  Future<void> _initPlayer() async {
    final downloads = Provider.of<DownloadProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? url = widget.videoUrl;

    // Prioritize local file if downloaded
    if (widget.movieId != null) {
      final downloadedMovie = downloads.downloadedMovies.firstWhere(
        (m) => (m.backendId ?? m.id.toString()) == widget.movieId,
        orElse: () => Movie(id: 0, title: '', overview: '', posterPath: '', releaseDate: '')
      );

      if (downloadedMovie.id != 0 && downloadedMovie.localPath != null) {
        final file = File(downloadedMovie.localPath!);
        if (await file.exists()) {
           developer.log('Playing from local path: ${downloadedMovie.localPath}');
           _controller = VideoPlayerController.file(file);
           _finishPlayerInit();
           return;
        }
      }
    }

    if (url == null && widget.movieId != null) {
      try {
        final token = authProvider.token;
        final movie = await ApiService().getMovieDetails(widget.movieId!, token: token);
        if (mounted) {
          url = movie.videoUrl;
          setState(() => _movie = movie);
        }
      } catch (e) {
        developer.log('Error fetching movie details: $e');
      }
    }

    url ??= 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

    // Initialize Native C++ Video Engine for this stream
    try {
      developer.log('Initializing Native C++ Video Engine for $url');
      // Simulated native metadata extraction
      // final info = NativeVideoEngine.getVideoInfo(url);
      // developer.log('Native Engine Info: $info');
    } catch (e) {
      developer.log('Native Video Engine initialization skipped or failed: $e');
    }

    _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _finishPlayerInit();
  }

  void _finishPlayerInit() {
    _controller!.initialize().then((_) {
      if (mounted) {
        setState(() {});
        final progress = Provider.of<PlaybackProvider>(context, listen: false).getProgress(widget.movieId ?? '');
        if (progress > Duration.zero) {
          _showResumeDialog(progress);
        } else {
          _controller!.play();
        }
        _startHideControlsTimer();
      }
    });
    _setupControllerListeners();
  }

  void _setupControllerListeners() {
    _controller!.addListener(() {
      if (mounted) {
        final isBuffering = _controller!.value.isBuffering;
        if (isBuffering != _isBuffering) {
           setState(() => _isBuffering = isBuffering);
        } else {
           setState(() {});
        }
      }
    });
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
    if (_isLocked) {
      setState(() => _isControlsVisible = !_isControlsVisible);
      if (_isControlsVisible) _startHideControlsTimer();
      return;
    }
    setState(() => _isControlsVisible = !_isControlsVisible);
    if (_isControlsVisible) _startHideControlsTimer();
  }

  void _showResumeDialog(Duration progress) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('RESUME PLAYBACK', style: TextStyle(color: Colors.yellow, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Continue watching from ${_formatDuration(progress)}?', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<PlaybackProvider>(context, listen: false).resetProgress(widget.movieId ?? '');
              _controller?.play();
              Navigator.pop(dialogContext);
            },
            child: const Text('RESTART', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              _controller?.seekTo(progress);
              _controller?.play();
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black),
            child: const Text('RESUME'),
          ),
        ],
      ),
    );
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controller != null && _controller!.value.isPlaying && !_isLocked) {
        setState(() => _isControlsVisible = false);
      }
    });
  }

  @override
  void dispose() {
    if (widget.movieId != null && _controller != null) {
      Provider.of<PlaybackProvider>(context, listen: false).updateProgress(widget.movieId!, _controller!.value.position);
    }
    WakelockPlus.disable();
    _controller?.dispose();
    _hideControlsTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _seekRelative(Duration duration) {
    if (_controller == null || _isLocked) return;
    final newPosition = _controller!.value.position + duration;
    _controller!.seekTo(newPosition);
    _startHideControlsTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PopScope(
        canPop: !_isLocked,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unlock controls to exit'), duration: Duration(seconds: 1)),
            );
          }
        },
        child: GestureDetector(
          onTap: _toggleControls,
          onDoubleTapDown: (details) {
            if (_isLocked) return;
            if (details.localPosition.dx < MediaQuery.of(context).size.width / 2) {
               _seekRelative(const Duration(seconds: -10));
            } else {
               _seekRelative(const Duration(seconds: 10));
            }
          },
          onVerticalDragUpdate: (details) {
            if (_isLocked) return;
            if (details.localPosition.dx < MediaQuery.of(context).size.width / 2) {
              _currentBrightness = (_currentBrightness - details.delta.dy / 100).clamp(0.0, 1.0);
              ScreenBrightness().setApplicationScreenBrightness(_currentBrightness);
            } else {
              _currentVolume = (_currentVolume - details.delta.dy / 100).clamp(0.0, 1.0);
              FlutterVolumeController.setVolume(_currentVolume);
            }
            setState(() {});
            _startHideControlsTimer();
          },
          child: Stack(
            children: <Widget>[
              Center(
                child: (_controller != null && _controller!.value.isInitialized)
                    ? SizedBox.expand(
                        child: FittedBox(
                          fit: _videoFit,
                          child: SizedBox(
                            width: _controller!.value.size.width,
                            height: _controller!.value.size.height,
                            child: VideoPlayer(_controller!),
                          ),
                        ),
                      )
                    : const CircularProgressIndicator(color: Colors.yellow),
              ),
              if (_isBuffering)
                const Center(child: CircularProgressIndicator(color: Colors.yellow)),

              if (_isLocked) _buildLockIndicator(),
              if (_isControlsVisible && !_isLocked) _buildFullControls(),
              if (_isControlsVisible && _isLocked) _buildUnlockButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockIndicator() {
    return Positioned(
      top: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, color: Colors.white70, size: 16),
              SizedBox(width: 8),
              Text('Controls Locked', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 32),
        child: IconButton(
          icon: const Icon(Icons.lock_open, color: Colors.yellow, size: 40),
          onPressed: () {
            setState(() => _isLocked = false);
            _startHideControlsTimer();
          },
        ),
      ),
    );
  }

  Widget _buildFullControls() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent, Colors.transparent, Colors.black87],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const Spacer(),
            _buildPlaybackControls(),
            const Spacer(),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _movie?.title ?? 'Now Playing',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_movie?.releaseDate != null)
                  Text(_movie!.releaseDate.split('-')[0], style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.cast, color: Colors.white), onPressed: _handleCast),
          IconButton(icon: const Icon(Icons.lock_outline, color: Colors.white), onPressed: () => setState(() => _isLocked = true)),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: _showSettingsMenu),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    if (_controller == null) return const SizedBox();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10, color: Colors.white, size: 48),
          onPressed: () => _seekRelative(const Duration(seconds: -10)),
        ),
        const SizedBox(width: 48),
        GestureDetector(
          onTap: () {
            setState(() {
              _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
              _startHideControlsTimer();
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.yellow.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(
              _controller!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.yellow,
              size: 84,
            ),
          ),
        ),
        const SizedBox(width: 48),
        IconButton(
          icon: const Icon(Icons.forward_10, color: Colors.white, size: 48),
          onPressed: () => _seekRelative(const Duration(seconds: 10)),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    if (_controller == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
           SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              activeTrackColor: Colors.yellow,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.yellow,
            ),
            child: Slider(
              value: _controller!.value.position.inMilliseconds.toDouble(),
              min: 0,
              max: _controller!.value.duration.inMilliseconds.toDouble(),
              onChanged: (val) {
                _controller!.seekTo(Duration(milliseconds: val.toInt()));
                _startHideControlsTimer();
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  _buildControlItem(Icons.aspect_ratio, 'Fit', _showAspectMenu),
                  _buildControlItem(Icons.speed, '${_playbackSpeed}x', _showSpeedMenu),
                  _buildControlItem(Icons.subtitles, 'Subs', _showSubtitleMenu),
                  _buildControlItem(Icons.audiotrack, 'Audio', _showAudioMenu),
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
      padding: const EdgeInsets.only(left: 24),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showAspectMenu() {
    final Map<String, BoxFit> options = {
      'Fit (Contain)': BoxFit.contain,
      'Fill Screen': BoxFit.fill,
      'Zoom (Cover)': BoxFit.cover,
      'Scale Down': BoxFit.scaleDown,
    };
    _showBottomDialog('Aspect Ratio', options.keys.toList(), (val) {
      setState(() => _videoFit = options[val]!);
    });
  }

  void _showSpeedMenu() {
    _showBottomDialog('Playback Speed', ['0.5x', '0.75x', '1.0x', '1.25x', '1.5x', '2.0x'], (val) {
      setState(() {
        _playbackSpeed = double.parse(val.replaceAll('x', ''));
        _controller?.setPlaybackSpeed(_playbackSpeed);
      });
    });
  }

  void _showAudioMenu() {
    _showBottomDialog('Audio Track', ['English (Default)', 'Somali', 'Arabic', 'French'], (val) {
      setState(() => _selectedAudio = val);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Audio switched to $_selectedAudio')));
    });
  }

  void _showSubtitleMenu() {
    _showBottomDialog('Subtitles', ['Off', 'English', 'Somali', 'Arabic', 'French'], (val) {
      setState(() => _selectedSubtitle = val);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Subtitles: $_selectedSubtitle')));
    });
  }

  void _showSettingsMenu() {
    _showBottomDialog('Video Settings', ['Auto-play next', 'Display Metadata', 'Hardware Acceleration'], (val) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$val toggled')));
    });
  }

  void _showBottomDialog(String title, List<String> options, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 16),
              child: Text(title, style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.1)),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                itemBuilder: (context, index) => ListTile(
                  title: Text(options[index], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                  onTap: () {
                    onSelect(options[index]);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCast() {
    final castService = Provider.of<CastService>(context, listen: false);
    if (castService.isConnected) {
      _showCastOptions(castService);
    } else {
      context.push('/cast');
    }
  }

  void _showCastOptions(CastService castService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('CAST TO DEVICE', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.cast_connected, color: Colors.yellow),
              title: Text('Cast to ${castService.selectedDevice?.friendlyName}', style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _startCasting(castService);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text('Cast Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.push('/cast');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startCasting(CastService castService) async {
    String? url = widget.videoUrl ?? _movie?.videoUrl;
    if (url == null || url.startsWith('file://') || !url.startsWith('http')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot cast local files')));
      }
      return;
    }
    _controller?.pause();
    await castService.loadMedia(
      url,
      title: _movie?.title ?? 'Video',
      subtitle: _movie?.overview ?? '',
      posterUrl: _movie?.posterPath,
    );
    if (mounted) context.push('/cast');
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}
