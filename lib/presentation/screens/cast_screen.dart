import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyobox/services/cast_service.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class CastScreen extends StatefulWidget {
  const CastScreen({super.key});

  @override
  State<CastScreen> createState() => _CastScreenState();
}

class _CastScreenState extends State<CastScreen> {
  final String _sampleVideoUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestPermissions();
      final service = context.read<CastService>();
      service.startScanning();
    });
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.nearbyWifiDevices,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      print('Permission statuses: $statuses');
    }
  }

  @override
  Widget build(BuildContext context) {
    final castService = context.watch<CastService>();

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text('CAST TO DEVICE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!castService.isScanning)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.deepPurpleAccent),
              onPressed: () => castService.startScanning(),
            ),
        ],
      ),
      body: Column(
        children: [
          if (castService.isScanning && castService.devices.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)))
          else if (castService.devices.isEmpty)
             Expanded(
               child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cast, size: 80, color: Colors.white10),
                    const SizedBox(height: 16),
                    const Text('No devices found', style: TextStyle(color: Colors.white70)),
                    TextButton(onPressed: () => castService.startScanning(), child: const Text('SEARCH AGAIN')),
                  ],
                ),
            ),
             )
          else
            Expanded(
              child: ListView.builder(
                itemCount: castService.devices.length,
                itemBuilder: (context, index) {
                  final device = castService.devices[index];
                  final isConnected = castService.isConnected && castService.selectedDevice == device;

                  return ListTile(
                    leading: Icon(Icons.cast, color: isConnected ? Colors.deepPurpleAccent : Colors.white70),
                    title: Text(device.friendlyName, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(device.modelName ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    trailing: isConnected
                      ? const Icon(Icons.check_circle, color: Colors.deepPurpleAccent)
                      : null,
                    onTap: () async {
                      if (isConnected) {
                        await castService.disconnect();
                      } else {
                        await castService.connectToDevice(device);
                      }
                    },
                  );
                },
              ),
            ),
          if (castService.isConnected)
            _buildCastControls(castService),
        ],
      ),
    );
  }

  Widget _buildCastControls(CastService castService) {
    final status = castService.mediaStatus;
    final isCasting = status != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.cast_connected, color: Colors.deepPurpleAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Casting to ${castService.selectedDevice?.friendlyName}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      if (isCasting)
                        Text('Now Playing', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => castService.disconnect(), icon: const Icon(Icons.power_settings_new, color: Colors.redAccent)),
              ],
            ),
            if (isCasting) ...[
              const SizedBox(height: 20),
              _buildProgressBar(castService),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10, color: Colors.white, size: 30),
                    onPressed: () => castService.seek(castService.position - const Duration(seconds: 10)),
                  ),
                  IconButton(
                    icon: Icon(
                      castService.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 60,
                    ),
                    onPressed: () => castService.isPlaying ? castService.pause() : castService.play(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10, color: Colors.white, size: 30),
                    onPressed: () => castService.seek(castService.position + const Duration(seconds: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildVolumeSlider(castService),
            ] else ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => castService.loadMedia(_sampleVideoUrl, title: 'Big Buck Bunny', subtitle: 'Sample Video'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('CAST SAMPLE VIDEO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(CastService castService) {
    final position = castService.position;
    final duration = castService.duration;
    final progress = duration.inSeconds > 0 ? position.inSeconds / duration.inSeconds : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: Colors.deepPurpleAccent,
            inactiveTrackColor: Colors.white10,
            thumbColor: Colors.deepPurpleAccent,
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (value) {
              final newPos = Duration(seconds: (value * duration.inSeconds).toInt());
              castService.seek(newPos);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(_formatDuration(duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeSlider(CastService castService) {
    return Row(
      children: [
        const Icon(Icons.volume_down, color: Colors.white70, size: 20),
        Expanded(
          child: Slider(
            value: 0.5, // We don't have current volume yet, so let's default to 0.5
            activeColor: Colors.white70,
            onChanged: (value) => castService.setVolume(value),
          ),
        ),
        const Icon(Icons.volume_up, color: Colors.white70, size: 20),
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
