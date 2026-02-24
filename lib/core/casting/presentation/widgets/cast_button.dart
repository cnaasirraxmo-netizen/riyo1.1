import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/casting_provider.dart';
import 'cast_dialog.dart';

class CastingButton extends ConsumerWidget {
  final Color? color;

  const CastingButton({super.key, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final castingState = ref.watch(castingProvider);
    final isConnected = castingState.connectedDevice != null;

    // We keep discovery running passively in the background if needed
    // or triggered here.

    return IconButton(
      icon: Icon(
        isConnected ? Icons.cast_connected : Icons.cast,
        color: isConnected ? Colors.blue : (color ?? Colors.white),
      ),
      onPressed: () {
        if (!castingState.isScanning && !isConnected) {
           ref.read(castingProvider.notifier).startDiscovery();
        }
        showCastDialog(context);
      },
      tooltip: 'Cast to Device',
    );
  }
}
