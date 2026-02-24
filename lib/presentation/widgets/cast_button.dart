import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riyo/services/cast_service.dart';
import 'package:go_router/go_router.dart';

class CastButton extends StatelessWidget {
  final Color? color;

  const CastButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Consumer<CastService>(
      builder: (context, castService, child) {
        // Only show if devices are found or already connected
        if (!castService.hasDevices && !castService.isConnected) {
          return const SizedBox.shrink();
        }

        return IconButton(
          icon: Icon(
            castService.isConnected ? Icons.cast_connected : Icons.cast,
            color: castService.isConnected ? Colors.blue : (color ?? Colors.white),
          ),
          onPressed: () => context.push('/cast'),
          tooltip: 'Cast to Device',
        );
      },
    );
  }
}
