import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/casting_provider.dart';
import '../../domain/entities/cast_device.dart';

class CastDialog extends ConsumerWidget {
  const CastDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final castingState = ref.watch(castingProvider);
    final castingNotifier = ref.read(castingProvider.notifier);

    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1C),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Cast to Device', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          if (castingState.isScanning)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurpleAccent))
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.deepPurpleAccent, size: 20),
              onPressed: () => castingNotifier.startDiscovery(),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: castingState.devices.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cast, size: 64, color: Colors.white10),
                  SizedBox(height: 16),
                  Text('Scanning for devices...', style: TextStyle(color: Colors.white54)),
                ],
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: castingState.devices.length,
              itemBuilder: (context, index) {
                final device = castingState.devices[index];
                final isConnected = castingState.connectedDevice?.id == device.id;

                return ListTile(
                  leading: Icon(
                    device.type == CastDeviceType.googleCast ? Icons.cast : Icons.tv,
                    color: isConnected ? Colors.deepPurpleAccent : Colors.white70,
                  ),
                  title: Text(device.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    device.type == CastDeviceType.googleCast ? 'Google Cast' : 'DLNA Device',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: isConnected ? const Icon(Icons.check_circle, color: Colors.deepPurpleAccent) : null,
                  onTap: () {
                    if (isConnected) {
                      castingNotifier.disconnect();
                    } else {
                      castingNotifier.connect(device);
                    }
                    Navigator.pop(context);
                  },
                );
              },
            ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }
}

void showCastDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const CastDialog(),
  );
}
