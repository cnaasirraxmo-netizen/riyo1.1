import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riyo/core/player/base_player.dart';
import 'package:riyo/core/player/player_factory.dart';
import 'package:riyo/core/video_engine/srt_parser.dart';
import 'package:http/http.dart' as http;
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:riyo/providers/auth_provider.dart';
import 'package:riyo/providers/playback_provider.dart';
import 'package:riyo/services/api_service.dart';
import 'package:riyo/models/movie.dart';
import 'package:riyo/core/casting/presentation/widgets/cast_button.dart';
import 'package:riyo/core/casting/presentation/providers/casting_provider.dart';
import 'package:riyo/core/casting/domain/entities/cast_media.dart';
import 'package:riyo/services/analytics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;

class VideoPlayerScreen extends rp.ConsumerStatefulWidget {
  final String? movieId;
  final String? videoUrl;
  final int? season;
  final int? episode;
  final String? provider;

  const VideoPlayerScreen({super.key, this.movieId, this.videoUrl, this.season, this.episode, this.provider});

  @override
  rp.ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends rp.ConsumerState<VideoPlayerScreen> {
  BaseVideoPlayer? _player;
  bool _isControlsVisible = true;
  Timer? _hideControlsTimer;
  double _currentVolume = 0.5;
  double _currentBrightness = 0.5;
  double _playbackSpeed = 1.0;
  String _selectedQuality = 'Auto';
  String _selectedSubtitle = 'Off';
  List<Map<String, dynamic>> _availableSubtitles = [];
  List<SubtitleEntry> _subtitleEntries = [];
  String _currentSubtitleText = '';

  Movie? _movie;
  List<StreamSource> _sources = [];
  StreamSource? _selectedSource;
  int _currentSourceIndex = 0;
  bool _isError = false;
  bool _isLoadingSource = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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

        // Check for local download first
        if (_movie?.localPath != null) {
          final file = File(_movie!.localPath!);
          if (await file.exists()) {
            _sources.insert(
              0,
              StreamSource(
                label: 'Offline (Downloaded)',
                url: _movie!.localPath!,
                type: _movie!.localPath!.contains('.m3u8') ? 'hls' : 'direct',
                provider: 'local',
                quality: 'Original',
              ),
            );
          }
        }

        final response = await apiService.getSources(widget.movieId!, season: widget.season, episode: widget.episode);
        final List<dynamic> sourceData = response['sources'] ?? [];
        _sources.addAll(sourceData.map((s) => StreamSource.fromJson(s)).toList());

        final List<dynamic> subtitleData = response['subtitles'] ?? [];
        _availableSubtitles = List<Map<String, dynamic>>.from(subtitleData);

        if (_sources.isNotEmpty) {
          _currentSourceIndex = 0;
          if (widget.videoUrl != null) {
            final idx = _sources.indexWhere((s) => s.url == widget.videoUrl);
            if (idx != -1) _currentSourceIndex = idx;
          }
          _selectedSource = _sources[_currentSourceIndex];
          _initPlayer();
        } else if (widget.videoUrl != null) {
          _initPlayer();
        } else {
          setState(() { _isError = true; _isLoadingSource = false; });
        }
      } catch (e) {
        setState(() { _isError = true; _isLoadingSource = false; });
      }
    } else if (widget.videoUrl != null) {
      _initPlayer();
    }
  }

  Future<void> _initPlayer() async {
    setState(() => _isLoadingSource = true);
    String? url = _selectedSource?.url ?? widget.videoUrl;
    if (url == null) return;

    await _player?.dispose();
    _player = PlayerFactory.create(_movie ?? Movie(id: 0, title: 'Video', overview: '', posterPath: '', releaseDate: '', sourceType: 'scraped'), provider: _selectedSource?.provider ?? widget.provider);

    _player!.addListener(_onPlayerStateChanged);
    await _player!.initialize(url);

    // Resume progress
    if (widget.movieId != null) {
      final savedPos = Provider.of<PlaybackProvider>(context, listen: false).getProgress(widget.movieId!);
      if (savedPos > Duration.zero) {
        await _player!.seek(savedPos);
      }
    }

    _player!.play();
    AnalyticsService.logVideoStart(_movie?.title ?? "Unknown", widget.movieId);

    setState(() => _isLoadingSource = false);
    _startHideControlsTimer();
  }

  void _onPlayerStateChanged() {
    if (_player == null) return;
    final state = _player!.state;

    if (state.status == PlayerStatus.error) {
      _handleSourceError();
    }

    _updateSubtitles(state.position.inSeconds.toDouble());

    // Save progress periodically
    if (state.status == PlayerStatus.playing && widget.movieId != null && state.position.inSeconds % 5 == 0) {
      Provider.of<PlaybackProvider>(context, listen: false).updateProgress(widget.movieId!, state.position);
    }

    if (mounted) setState(() {});
  }

  void _handleSourceError() {
    if (_currentSourceIndex + 1 < _sources.length) {
      _currentSourceIndex++;
      _selectedSource = _sources[_currentSourceIndex];
      _initPlayer();
    } else {
      setState(() { _isError = true; _isLoadingSource = false; });
    }
  }

  void _updateSubtitles(double positionSeconds) {
    if (_selectedSubtitle == 'Off' || _subtitleEntries.isEmpty) {
      if (_currentSubtitleText.isNotEmpty) setState(() => _currentSubtitleText = '');
      return;
    }
    final duration = Duration(milliseconds: (positionSeconds * 1000).toInt());
    final currentEntry = _subtitleEntries.firstWhere(
      (entry) => duration >= entry.start && duration <= entry.end,
      orElse: () => SubtitleEntry(start: Duration.zero, end: Duration.zero, text: ''),
    );
    if (_currentSubtitleText != currentEntry.text) {
      setState(() => _currentSubtitleText = currentEntry.text);
    }
  }

  Future<void> _loadSubtitles(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() { _subtitleEntries = SrtParser.parse(response.body); });
      }
    } catch (e) { debugPrint('Subtitle error: $e'); }
  }

  void _initCastListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(castingProvider, (previous, next) {
        if (next.connectedDevice != null && _player?.state.status == PlayerStatus.playing) {
           _startCasting();
        }
      });
    });
  }

  Future<void> _startCasting() async {
    final castingNotifier = ref.read(castingProvider.notifier);
    String? url = _selectedSource?.url ?? widget.videoUrl;
    if (url != null) {
      _player?.pause();
      await castingNotifier.castMedia(CastMedia(
        url: url,
        title: _movie?.title ?? "Video",
        posterUrl: _movie?.posterPath,
      ));
    }
  }

  Future<void> _initVolume() async {
    _currentVolume = await FlutterVolumeController.getVolume() ?? 0.5;
    if (mounted) setState(() {});
  }

  Future<void> _initBrightness() async {
    try { _currentBrightness = await ScreenBrightness().application; } catch (e) { _currentBrightness = 0.5; }
    if (mounted) setState(() {});
  }

  void _toggleControls() {
    setState(() { _isControlsVisible = !_isControlsVisible; });
    if (_isControlsVisible) _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _player?.state.status == PlayerStatus.playing) {
        setState(() { _isControlsVisible = false; });
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable();
    _player?.removeListener(_onPlayerStateChanged);
    _player?.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text('Playback failed. Check your connection.', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: <Widget>[
            Center(child: _player?.buildPlayer(context) ?? const CircularProgressIndicator(color: Colors.purple)),
            if (_selectedSubtitle != 'Off' && _currentSubtitleText.isNotEmpty)
              Positioned(
                bottom: _isControlsVisible ? 100 : 40,
                left: 20, right: 20,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                    child: Text(_currentSubtitleText, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
              ),
            if (_isLoadingSource || (_player?.state.status == PlayerStatus.buffering))
              Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator(color: Colors.purple))),
            if (_isControlsVisible) _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.7), Colors.transparent, Colors.black.withOpacity(0.7)],
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
          IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_movie?.title ?? 'Loading...', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                if (widget.season != null) Text('Season ${widget.season} • Episode ${widget.episode}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const CastingButton(),
          IconButton(icon: const Icon(Icons.more_vert_rounded, color: Colors.white), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    if (_player == null) return const SizedBox();
    final isPlaying = _player!.state.status == PlayerStatus.playing;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 48), onPressed: () => _player!.seek(_player!.state.position - const Duration(seconds: 10))),
        const SizedBox(width: 48),
        IconButton(
          icon: Icon(isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, color: Colors.purple, size: 96),
          onPressed: () => isPlaying ? _player!.pause() : _player!.play(),
        ),
        const SizedBox(width: 48),
        IconButton(icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 48), onPressed: () => _player!.seek(_player!.state.position + const Duration(seconds: 10))),
      ],
    );
  }

  Widget _buildBottomBar() {
    if (_player == null) return const SizedBox();
    final state = _player!.state;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Slider(
            value: state.position.inSeconds.toDouble(),
            max: state.duration.inSeconds.toDouble() <= 0 ? 1.0 : state.duration.inSeconds.toDouble(),
            onChanged: (val) => _player!.seek(Duration(seconds: val.toInt())),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_formatDuration(state.position)} / ${_formatDuration(state.duration)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
              Row(
                children: [
                  _buildControlItem(Icons.subtitles_rounded, _selectedSubtitle, _showSubtitleMenu),
                  _buildControlItem(Icons.speed_rounded, '${_playbackSpeed}x', _showSpeedMenu),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "${d.inHours > 0 ? '${d.inHours}:' : ''}$minutes:$seconds";
  }

  Widget _buildControlItem(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: InkWell(
        onTap: onTap,
        child: Column(children: [Icon(icon, color: Colors.white), Text(label, style: const TextStyle(color: Colors.white, fontSize: 10))]),
      ),
    );
  }

  void _showSubtitleMenu() {
    final List<String> options = ['Off'];
    options.addAll(_availableSubtitles.map((s) => s['language'] as String));
    _showBottomDialog('SUBTITLES', options, (val) {
      setState(() { _selectedSubtitle = val; _currentSubtitleText = ''; _subtitleEntries = []; });
      if (val != 'Off') {
        final sub = _availableSubtitles.firstWhere((s) => s['language'] == val);
        _loadSubtitles(sub['url']);
      }
    });
  }

  void _showSpeedMenu() {
    _showBottomDialog('SPEED', ['0.5x', '1.0x', '1.5x', '2.0x'], (val) {
      final speed = double.parse(val.replaceAll('x', ''));
      setState(() => _playbackSpeed = speed);
      _player?.setSpeed(speed);
    });
  }

  void _showBottomDialog(String title, List<String> options, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: options.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(options[index], style: const TextStyle(color: Colors.white)),
          onTap: () { onSelect(options[index]); Navigator.pop(context); },
        ),
      ),
    );
  }
}
