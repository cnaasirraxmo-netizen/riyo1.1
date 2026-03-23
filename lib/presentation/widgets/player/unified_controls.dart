import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riyo/core/player/base_player.dart';
import 'package:riyo/core/design_system.dart';
import 'package:riyo/core/video_engine/srt_parser.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:http/http.dart' as http;

class UnifiedPlayerControls extends StatefulWidget {
  final BaseVideoPlayer player;
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final VoidCallback onCast;
  final VoidCallback onPip;
  final bool isAdmin;

  const UnifiedPlayerControls({
    super.key,
    required this.player,
    required this.title,
    this.subtitle,
    required this.onBack,
    required this.onCast,
    required this.onPip,
    this.isAdmin = false,
  });

  @override
  State<UnifiedPlayerControls> createState() => _UnifiedPlayerControlsState();
}

class _UnifiedPlayerControlsState extends State<UnifiedPlayerControls> {
  bool _isVisible = true;
  Timer? _hideTimer;
  double _volume = 0.5;
  double _brightness = 0.5;

  List<SubtitleEntry> _subtitleEntries = [];
  String _currentSubtitleText = '';
  Timer? _subtitleTimer;

  @override
  void initState() {
    super.initState();
    _initVolume();
    _initBrightness();
    _startHideTimer();
    widget.player.addListener(_onPlayerUpdate);
    _startSubtitleTimer();
  }

  @override
  void didUpdateWidget(UnifiedPlayerControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.player != oldWidget.player) {
      oldWidget.player.removeListener(_onPlayerUpdate);
      widget.player.addListener(_onPlayerUpdate);
    }
  }

  void _onPlayerUpdate() {
    if (mounted) setState(() {});
  }

  void _startSubtitleTimer() {
    _subtitleTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) _updateSubtitles();
    });
  }

  void _updateSubtitles() {
    final state = widget.player.state;
    if (state.currentSubtitle == null || state.currentSubtitle == 'Off' || _subtitleEntries.isEmpty) {
      if (_currentSubtitleText.isNotEmpty) setState(() => _currentSubtitleText = '');
      return;
    }

    final duration = state.position;
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
        setState(() {
          _subtitleEntries = SrtParser.parse(response.body);
        });
      }
    } catch (e) {
      debugPrint('Subtitle error: $e');
    }
  }

  Future<void> _initVolume() async {
    _volume = await FlutterVolumeController.getVolume() ?? 0.5;
    if (mounted) setState(() {});
  }

  Future<void> _initBrightness() async {
    try {
      _brightness = await ScreenBrightness().application;
    } catch (e) {
      _brightness = 0.5;
    }
    if (mounted) setState(() {});
  }

  void _toggleControls() {
    setState(() {
      _isVisible = !_isVisible;
    });
    if (_isVisible) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && widget.player.state.status == PlayerStatus.playing) {
        setState(() => _isVisible = false);
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _subtitleTimer?.cancel();
    widget.player.removeListener(_onPlayerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: _toggleControls,
          onVerticalDragUpdate: (details) {
            if (details.localPosition.dx < MediaQuery.of(context).size.width / 2) {
              _updateBrightness(details.primaryDelta!);
            } else {
              _updateVolume(details.primaryDelta!);
            }
          },
          child: AnimatedOpacity(
            opacity: _isVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              color: Colors.black45,
              child: _isVisible ? _buildControls(context) : const SizedBox.expand(),
            ),
          ),
        ),
        if (_currentSubtitleText.isNotEmpty)
          Positioned(
            bottom: _isVisible ? 120 : 40,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentSubtitleText,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _updateVolume(double delta) async {
    _volume = (_volume - (delta / 200)).clamp(0.0, 1.0);
    await FlutterVolumeController.setVolume(_volume);
    setState(() {});
  }

  void _updateBrightness(double delta) async {
    _brightness = (_brightness - (delta / 200)).clamp(0.0, 1.0);
    try {
      await ScreenBrightness().setScreenBrightness(_brightness);
    } catch (_) {}
    setState(() {});
  }

  Widget _buildControls(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(context),
          const Spacer(),
          _buildCenterControls(),
          const Spacer(),
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.title, style: AppTypography.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                if (widget.subtitle != null) Text(widget.subtitle!, style: AppTypography.labelMedium.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.cast_rounded, color: Colors.white), onPressed: widget.onCast),
          IconButton(icon: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white), onPressed: widget.onPip),
          _buildSettingsMenu(context),
        ],
      ),
    );
  }

  Widget _buildCenterControls() {
    final state = widget.player.state;
    final isPlaying = state.status == PlayerStatus.playing;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircularIconButton(Icons.replay_10_rounded, () => widget.player.seek(state.position - const Duration(seconds: 10))),
        const SizedBox(width: 48),
        _buildCircularIconButton(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          () => isPlaying ? widget.player.pause() : widget.player.play(),
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 48),
        _buildCircularIconButton(Icons.forward_10_rounded, () => widget.player.seek(state.position + const Duration(seconds: 10))),
      ],
    );
  }

  Widget _buildCircularIconButton(IconData icon, VoidCallback onPressed, {double size = 48, Color color = Colors.white}) {
    return IconButton(
      iconSize: size,
      icon: Icon(icon, color: color),
      onPressed: () {
        onPressed();
        _startHideTimer();
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final state = widget.player.state;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildProgressBar(state),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_formatDuration(state.position)} / ${_formatDuration(state.duration)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
              Row(
                children: [
                   _buildBottomAction(Icons.speed_rounded, '${state.playbackSpeed}x', () => _showSpeedDialog(context)),
                   if (state.availableQualities.isNotEmpty)
                    _buildBottomAction(Icons.high_quality_rounded, state.currentQuality ?? 'Auto', () => _showQualityDialog(context)),
                   _buildBottomAction(Icons.subtitles_rounded, state.currentSubtitle ?? 'Off', () => _showSubtitleDialog(context)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(PlayerState state) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: Theme.of(context).colorScheme.primary,
        inactiveTrackColor: Colors.white24,
        thumbColor: Theme.of(context).colorScheme.primary,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      child: Slider(
        value: state.position.inSeconds.toDouble(),
        max: state.duration.inSeconds.toDouble() <= 0 ? 1.0 : state.duration.inSeconds.toDouble(),
        onChanged: (val) {
          widget.player.seek(Duration(seconds: val.toInt()));
          _startHideTimer();
        },
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsMenu(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(Icons.settings_rounded, color: Colors.white),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'audio', child: Text('Audio Tracks')),
        const PopupMenuItem(value: 'playback', child: Text('Playback Settings')),
      ],
      onSelected: (val) {
        if (val == 'audio') _showAudioTrackDialog(context);
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "${d.inHours > 0 ? '${d.inHours}:' : ''}$minutes:$seconds";
  }

  void _showSpeedDialog(BuildContext context) {
    _showOptionsDialog(context, 'Playback Speed', ['0.5x', '1.0x', '1.5x', '2.0x'], (val) {
      final speed = double.parse(val.replaceAll('x', ''));
      widget.player.setSpeed(speed);
    });
  }

  void _showQualityDialog(BuildContext context) {
    _showOptionsDialog(context, 'Video Quality', widget.player.state.availableQualities, (val) {
      widget.player.setQuality(val);
    });
  }

  void _showSubtitleDialog(BuildContext context) {
    final List<String> options = ['Off'];
    options.addAll(widget.player.state.availableSubtitles.map((s) => s['language'] as String));
    _showOptionsDialog(context, 'Subtitles', options, (val) {
      widget.player.setSubtitle(val);
      if (val != 'Off') {
        final sub = widget.player.state.availableSubtitles.firstWhere((s) => s['language'] == val, orElse: () => <String, dynamic>{});
        if (sub.containsKey('url')) {
          _loadSubtitles(sub['url']);
        }
      } else {
        setState(() {
          _subtitleEntries = [];
          _currentSubtitleText = '';
        });
      }
    });
  }

  void _showAudioTrackDialog(BuildContext context) {
    _showOptionsDialog(context, 'Audio Tracks', widget.player.state.availableAudioTracks, (val) {
      widget.player.setAudioTrack(val);
    });
  }

  void _showOptionsDialog(BuildContext context, String title, List<String> options, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white24),
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
