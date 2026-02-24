import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/services/cast_service.dart';
import 'package:permission_handler/permission_handler.dart';
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
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.nearbyWifiDevices,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      debugPrint('Permission statuses: $statuses');
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
            _buildCastController(castService),
        ],
      ),
    );
  }

  Widget _buildCastController(CastService castService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
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
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: castService.currentPoster != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(castService.currentPoster!, fit: BoxFit.cover),
                      )
                    : const Icon(Icons.movie, color: Colors.deepPurpleAccent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        castService.currentTitle ?? 'Ready to Cast',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Casting to ${castService.selectedDevice?.friendlyName}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => castService.disconnect(),
                  icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                  onPressed: () {}, // Implement seek relative in cast service if needed
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () {
                    if (castService.isPlaying) {
                      castService.pause();
                    } else {
                      castService.play();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(
                      castService.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.black,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.volume_down, color: Colors.grey, size: 20),
                Expanded(
                  child: Slider(
                    value: castService.volume,
                    activeColor: Colors.deepPurpleAccent,
                    onChanged: (val) => castService.setVolume(val),
                  ),
                ),
                const Icon(Icons.volume_up, color: Colors.grey, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
