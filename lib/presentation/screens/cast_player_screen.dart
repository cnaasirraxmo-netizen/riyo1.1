import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:riyobox/services/cast_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CastPlayerScreen extends StatelessWidget {
  const CastPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final castService = context.watch<CastService>();
    final mediaStatus = castService.mediaStatus;
    final metadata = mediaStatus?.mediaInformation?.metadata;

    String title = 'Unknown Title';
    String subtitle = 'RIYOBOX';
    if (metadata is GoogleCastMovieMediaMetadata) {
      title = metadata.title ?? title;
      subtitle = metadata.subtitle ?? subtitle;
    } else if (metadata is GoogleCastTvShowMediaMetadata) {
      title = metadata.seriesTitle ?? title;
      if (metadata.season != null && metadata.episode != null) {
        subtitle = 'Season ${metadata.season}, Episode ${metadata.episode}';
      } else {
        subtitle = metadata.seriesTitle ?? subtitle;
      }
    }

    final imageUrl = (metadata?.images?.isNotEmpty ?? false) ? metadata?.images?.first.url.toString() : null;

    if (!castService.isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return const Scaffold(backgroundColor: Colors.black);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cast_connected, color: Colors.deepPurpleAccent),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          const Spacer(),
          // Poster Image
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurpleAccent.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.white10),
                        errorWidget: (context, url, error) => const Icon(Icons.movie, size: 100, color: Colors.white10),
                      )
                    : Container(
                        color: Colors.white10,
                        child: const Icon(Icons.movie, size: 100, color: Colors.white10),
                      ),
              ),
            ),
          ),
          const Spacer(),
          // Title & Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Progress Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    activeTrackColor: Colors.deepPurpleAccent,
                    inactiveTrackColor: Colors.white.withOpacity(0.1),
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: castService.duration.inSeconds > 0
                        ? castService.position.inSeconds.toDouble().clamp(0, castService.duration.inSeconds.toDouble())
                        : 0,
                    max: castService.duration.inSeconds > 0 ? castService.duration.inSeconds.toDouble() : 1,
                    onChanged: (value) {
                      castService.seek(Duration(seconds: value.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(castService.position),
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                      ),
                      Text(
                        _formatDuration(castService.duration),
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                onPressed: () {
                  final newPos = castService.position - const Duration(seconds: 10);
                  castService.seek(newPos < Duration.zero ? Duration.zero : newPos);
                },
              ),
              const SizedBox(width: 30),
              GestureDetector(
                onTap: () {
                  if (castService.isPlaying) {
                    castService.pause();
                  } else {
                    castService.play();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    castService.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.black,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(width: 30),
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                onPressed: () {
                  final newPos = castService.position + const Duration(seconds: 10);
                  castService.seek(newPos > castService.duration ? castService.duration : newPos);
                },
              ),
            ],
          ),
          const Spacer(),
          // Bottom Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.white70),
                  onPressed: () => _showVolumeSlider(context, castService),
                ),
                Text(
                  'Casting to ${castService.selectedDevice?.friendlyName}',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                ),
                IconButton(
                  icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
                  onPressed: () {
                    castService.stop();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  void _showVolumeSlider(BuildContext context, CastService castService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Volume', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.volume_down, color: Colors.grey),
                      Expanded(
                        child: Slider(
                          value: 0.5, // Default/Placeholder as we might not have current volume
                          onChanged: (value) {
                            castService.setVolume(value);
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }
}
