import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:riyobox/services/cast_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
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
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'CONNECT TO A DEVICE',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              castService.isScanning ? Icons.stop : Icons.refresh,
              color: Colors.deepPurpleAccent,
            ),
            onPressed: () {
              if (castService.isScanning) {
                castService.stopScanning();
              } else {
                castService.startScanning();
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (castService.isScanning)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              color: Colors.deepPurpleAccent,
              minHeight: 2,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              'AVAILABLE DEVICES',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          if (castService.devices.isEmpty && !castService.isScanning)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.cast_connected_outlined, size: 60, color: Colors.white.withOpacity(0.2)),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No devices found',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Make sure your TV is on the same Wi-Fi network',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => castService.startScanning(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('SEARCH AGAIN'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: castService.devices.length,
                itemBuilder: (context, index) {
                  final device = castService.devices[index];
                  final isConnected = castService.isConnected && castService.selectedDevice?.deviceID == device.deviceID;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isConnected ? Colors.deepPurpleAccent.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isConnected ? Colors.deepPurpleAccent : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isConnected ? Icons.cast_connected : Icons.cast,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        device.friendlyName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        device.modelName ?? 'Cast Device',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                      ),
                      trailing: isConnected
                          ? const Icon(Icons.check_circle, color: Colors.deepPurpleAccent)
                          : Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.1), size: 14),
                      onTap: () async {
                        if (isConnected) {
                          // Already connected
                        } else {
                          await castService.connectToDevice(device);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          if (castService.isConnected) _buildMiniPlayer(castService),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer(CastService castService) {
    final mediaStatus = castService.mediaStatus;
    final metadata = mediaStatus?.mediaInformation?.metadata;

    String title = 'Nothing playing';
    if (metadata is GoogleCastMovieMediaMetadata) {
      title = metadata.title ?? title;
    } else if (metadata is GoogleCastTvShowMediaMetadata) {
      title = metadata.seriesTitle ?? title;
    }

    final subtitle = castService.selectedDevice?.friendlyName ?? 'Connected';

    return GestureDetector(
      onTap: () {
        if (mediaStatus != null) {
          context.push('/cast-player');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, -2),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.white.withOpacity(0.05),
                      child: const Icon(Icons.movie, color: Colors.deepPurpleAccent),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (castService.isPlaying) {
                        castService.pause();
                      } else {
                        castService.play();
                      }
                    },
                    icon: Icon(
                      castService.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => castService.disconnect(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            if (mediaStatus != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: LinearProgressIndicator(
                  value: castService.duration.inSeconds > 0
                      ? castService.position.inSeconds / castService.duration.inSeconds
                      : 0,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  color: Colors.deepPurpleAccent,
                  minHeight: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
