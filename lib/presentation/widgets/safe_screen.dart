import 'package:flutter/material.dart';
import 'package:riyo/services/local_cache_service.dart';

class SafeScreen extends StatelessWidget {
  final Widget child;
  final Widget? errorWidget;

  const SafeScreen({
    super.key,
    required this.child,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildContent(context),
        _buildConnectivityBanner(),
      ],
    );
  }

  Widget _buildConnectivityBanner() {
    return StreamBuilder<bool>(
      stream: LocalCacheService().connectivityStream,
      initialData: LocalCacheService().isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        if (isOnline) return const SizedBox.shrink();

        return Positioned(
          top: MediaQuery.of(context).padding.top,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: Container(
              color: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 8),
                  Text(
                    'Offline Mode - Using Cached Content',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return _SafeErrorBoundary(
      errorWidget: errorWidget,
      child: child,
    );
  }
}

class _SafeErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? errorWidget;

  const _SafeErrorBoundary({
    required this.child,
    this.errorWidget,
  });

  @override
  State<_SafeErrorBoundary> createState() => _SafeErrorBoundaryState();
}

class _SafeErrorBoundaryState extends State<_SafeErrorBoundary> {
  bool _hasError = false;
  Object? _error;

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ??
          Scaffold(
            backgroundColor: const Color(0xFF121212),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Screen Failed to Load',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error?.toString() ?? 'An unexpected error occurred.',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _error = null;
                        });
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          );
    }

    // Capture errors from child widgets
    return Builder(
      builder: (context) {
        try {
          return widget.child;
        } catch (e) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _hasError = true;
                _error = e;
              });
            }
          });
          return const SizedBox.shrink();
        }
      },
    );
  }
}
