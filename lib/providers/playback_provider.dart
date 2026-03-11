import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riyo/presentation/providers/playback_provider.dart' as riverpod;

class PlaybackProvider extends ChangeNotifier {
  final Ref ref;

  PlaybackProvider(this.ref) {
    ref.listen(riverpod.playbackProvider, (previous, next) {
      notifyListeners();
    });
  }

  Map<String, Duration> get allProgress => ref.read(riverpod.playbackProvider).progress;
  void resetProgress(String id) => ref.read(riverpod.playbackProvider.notifier).resetProgress(id);
  void updateProgress(String id, Duration pos) => ref.read(riverpod.playbackProvider.notifier).updateProgress(id, pos);
}
