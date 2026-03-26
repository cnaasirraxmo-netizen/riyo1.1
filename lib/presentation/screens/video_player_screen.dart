import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riyo/core/player/base_player.dart';
import 'package:riyo/core/player/player_factory.dart';
import 'package:riyo/presentation/widgets/player/unified_controls.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:riyo/providers/auth_provider.dart';
import 'package:riyo/providers/download_provider.dart';
import 'package:riyo/providers/playback_provider.dart';
import 'package:riyo/providers/settings_provider.dart';
import 'package:riyo/services/api_service.dart';
import 'package:riyo/models/movie.dart';
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

        List<Map<String, dynamic>> availableSubtitles = [];

        // Always add official server if it exists
        String? directUrl = _movie!.directUrl ?? _movie!.videoUrl;
        if (_movie!.isTvShow && widget.season != null && widget.episode != null && _movie!.seasons != null && _movie!.seasons!.isNotEmpty) {
          final season = _movie!.seasons?.firstWhere((s) => s.number == widget.season, orElse: () => _movie!.seasons![0]);
          if (season != null && season.episodes.isNotEmpty) {
            final ep = season.episodes.firstWhere((e) => e.number == widget.episode, orElse: () => season.episodes[0]);
            if (ep.videoUrl != null) {
              directUrl = ep.videoUrl;
            }
          }
        }

        if (directUrl != null && directUrl.isNotEmpty) {
          _sources.add(StreamSource(
            label: 'Official Server',
            url: directUrl,
            type: directUrl.contains('.m3u8') ? 'hls' : 'direct',
            provider: 'admin',
            quality: _movie!.quality ?? 'HD',
          ));
        }

        // Always fetch scraped sources as well
        final response = await apiService.getSources(widget.movieId!, season: widget.season, episode: widget.episode);
        final List<dynamic> sourceData = response['sources'] ?? [];
        _sources.addAll(sourceData.map((s) => StreamSource.fromJson(s)).toList());

        final List<dynamic> subtitleData = response['subtitles'] ?? [];
        availableSubtitles = List<Map<String, dynamic>>.from(subtitleData);

        // Deduplicate sources (Official vs Scraped)
        final seenUrls = <String>{};
        _sources = _sources.where((s) => seenUrls.add(s.url)).toList();

        if (_sources.isNotEmpty) {
          _currentSourceIndex = 0;
          if (widget.videoUrl != null) {
            final idx = _sources.indexWhere((s) => s.url == widget.videoUrl);
            if (idx != -1) _currentSourceIndex = idx;
          }
          _selectedSource = _sources[_currentSourceIndex];
          _initPlayer(availableSubtitles: availableSubtitles);
        } else if (widget.videoUrl != null) {
          _initPlayer(availableSubtitles: availableSubtitles);
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

  Future<void> _initPlayer({List<Map<String, dynamic>> availableSubtitles = const []}) async {
    setState(() => _isLoadingSource = true);
    String? url = _selectedSource?.url ?? widget.videoUrl;
    if (url == null) return;

    final settings = Provider.of<SettingsProvider>(context, listen: false);

    await _player?.dispose();
    _player = PlayerFactory.create(_movie ?? Movie(id: 0, title: 'Video', overview: '', posterPath: '', releaseDate: '', sourceType: 'scraped'), provider: _selectedSource?.provider ?? widget.provider);

    _player?.addListener(_onPlayerStateChanged);
    await _player?.initialize(url);

    // Set subtitles data
    await _player?.setSubtitlesData(availableSubtitles);

    // Apply settings
    _player?.setSpeed(settings.defaultPlaybackSpeed);
    if (settings.defaultVideoQuality != 'Auto') {
       _player?.setQuality(settings.defaultVideoQuality);
    }

    // Resume progress
    if (widget.movieId != null) {
      final savedPos = Provider.of<PlaybackProvider>(context, listen: false).getProgress(widget.movieId!);
      if (savedPos > Duration.zero) {
        await _player?.seek(savedPos);
      }
    }

    _player?.play();
    AnalyticsService.logVideoStart(_movie?.title ?? "Unknown", widget.movieId);

    // Auto-cache (download) watched video for future offline access
    if (_movie != null && !kIsWeb) {
       final downloads = Provider.of<DownloadProvider>(context, listen: false);
       if (!downloads.isDownloaded(_movie!.id) && !downloads.isDownloading(_movie!.id)) {
          // Pass the specific source URL to the download provider if possible,
          // but DownloadProvider currently uses movie.directUrl or movie.videoUrl.
          // We trigger download in background.
          unawaited(downloads.startDownload(_movie!));
       }
    }

    setState(() => _isLoadingSource = false);
  }

  void _onPlayerStateChanged() {
    if (_player == null) return;
    final state = _player!.state;

    if (state.status == PlayerStatus.error) {
      _handleSourceError();
    }

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
      body: Stack(
        children: <Widget>[
          Center(child: _player?.buildPlayer(context) ?? const CircularProgressIndicator(color: Colors.purple)),
          if (_isLoadingSource || (_player?.state.status == PlayerStatus.buffering))
            Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator(color: Colors.purple))),
          if (_player != null)
            UnifiedPlayerControls(
              player: _player!,
              title: _movie?.title ?? 'Loading...',
              subtitle: widget.season != null ? 'Season ${widget.season} • Episode ${widget.episode}' : null,
              onBack: () => Navigator.pop(context),
              onCast: _startCasting,
              onPip: () => _player?.enterPip(),
              isAdmin: _movie?.sourceType == 'admin',
            ),
        ],
      ),
    );
  }
}
