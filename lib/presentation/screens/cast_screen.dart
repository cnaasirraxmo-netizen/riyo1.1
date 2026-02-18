import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyobox/services/cast_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'dart:io';

class CastScreen extends StatefulWidget {
  const CastScreen({super.key});

  @override
  State<CastScreen> createState() => _CastScreenState();
}

class _CastScreenState extends State<CastScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestPermissions();
      if (!mounted) return;
      final service = context.read<CastService>();
      service.startScanning();
    });
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.location,
        Permission.nearbyWifiDevices,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
    }
  }

  @override
  Widget build(BuildContext context) {
    final castService = context.watch<CastService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'CONNECT TO DEVICE',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!castService.isScanning)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.yellow),
              onPressed: () => castService.startScanning(),
            ),
        ],
      ),
      body: Stack(
        children: [
          _buildDeviceList(castService),
          if (castService.isConnected) _buildNowPlaying(castService),
        ],
      ),
    );
  }

  Widget _buildDeviceList(CastService castService) {
    if (castService.isScanning && castService.devices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.yellow),
            SizedBox(height: 24),
            Text(
              'Searching for devices...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (castService.devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cast, size: 100, color: Colors.white10),
            ),
            const SizedBox(height: 24),
            const Text(
              'No devices found',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Make sure your TV is on the same Wi-Fi network.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => castService.startScanning(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('SEARCH AGAIN', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: castService.devices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final device = castService.devices[index];
        final isConnected = castService.isConnected && castService.selectedDevice == device;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isConnected ? Colors.yellow.withOpacity(0.1) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isConnected ? Colors.yellow : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isConnected ? Colors.yellow : Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.tv,
                color: isConnected ? Colors.black : Colors.white,
              ),
            ),
            title: Text(
              device.friendlyName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              device.modelName ?? 'Cast Device',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: isConnected
                ? const Icon(Icons.check_circle, color: Colors.yellow)
                : const Icon(Icons.chevron_right, color: Colors.white24),
            onTap: () async {
              if (isConnected) {
                _showDisconnectDialog(context, castService);
              } else {
                await castService.connectToDevice(device);
              }
            },
          ),
        );
      },
    );
  }

  void _showDisconnectDialog(BuildContext context, CastService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Disconnect?', style: TextStyle(color: Colors.white)),
        content: const Text('Do you want to stop casting to this device?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              service.disconnect();
              Navigator.pop(context);
            },
            child: const Text('DISCONNECT', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlaying(CastService castService) {
    final status = castService.mediaStatus;
    final info = status?.mediaInformation;
    final metadata = info?.metadata;

    String? title;
    String? subtitle;
    List<GoogleCastImage>? images;

    if (metadata is GoogleCastMovieMediaMetadata) {
      title = metadata.title;
      subtitle = metadata.subtitle;
      images = metadata.images;
    }

    if (status == null) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                const Icon(Icons.cast_connected, color: Colors.yellow),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CONNECTED', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(castService.selectedDevice?.friendlyName ?? 'Device', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => castService.loadMedia(
                    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                    title: 'Big Buck Bunny',
                    subtitle: 'Sample Casting Video',
                  ),
                  child: const Text('TEST CAST', style: TextStyle(color: Colors.yellow)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      image: images != null && images.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(images.first.url.toString()),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (images == null || images.isEmpty) ? const Icon(Icons.movie, color: Colors.white24) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title ?? 'Unknown Title',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle ?? 'RIYOBOX',
                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => castService.stop(),
                    icon: const Icon(Icons.stop_circle_outlined, color: Colors.white54, size: 32),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildProgressBar(castService),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () => castService.seek(castService.currentPosition - const Duration(seconds: 10)),
                    icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                  ),
                  _buildPlayPauseButton(castService),
                  IconButton(
                    onPressed: () => castService.seek(castService.currentPosition + const Duration(seconds: 10)),
                    icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildVolumeSlider(castService),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(CastService castService) {
    final duration = castService.mediaStatus?.mediaInformation?.duration ?? Duration.zero;
    final current = castService.currentPosition.inSeconds.toDouble();
    final total = duration.inSeconds.toDouble();

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: Colors.yellow,
            inactiveTrackColor: Colors.white10,
            thumbColor: Colors.yellow,
          ),
          child: Slider(
            value: total > 0 ? current.clamp(0.0, total) : 0,
            max: total > 0 ? total : 1,
            onChanged: (val) {
              castService.seek(Duration(seconds: val.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(castService.currentPosition), style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Text(_formatDuration(duration), style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton(CastService castService) {
    final state = castService.mediaStatus?.playerState;
    final isPlaying = state == CastMediaPlayerState.playing;
    final isBuffering = state == CastMediaPlayerState.buffering || state == CastMediaPlayerState.loading;

    if (isBuffering) {
      return const SizedBox(
        width: 64,
        height: 64,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: Colors.yellow, strokeWidth: 3),
        ),
      );
    }

    return IconButton(
      onPressed: () => isPlaying ? castService.pause() : castService.play(),
      iconSize: 64,
      icon: Icon(
        isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
        color: Colors.yellow,
      ),
    );
  }

  Widget _buildVolumeSlider(CastService castService) {
    final volume = castService.mediaStatus?.volume ?? 1.0;

    return Row(
      children: [
        const Icon(Icons.volume_down, color: Colors.white54, size: 20),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
              activeTrackColor: Colors.white54,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: volume.toDouble(),
              onChanged: (val) => castService.setVolume(val),
            ),
          ),
        ),
        const Icon(Icons.volume_up, color: Colors.white54, size: 20),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}
