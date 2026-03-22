import 'base_player.dart';
import 'native_player.dart';
import 'cpp_player.dart';
import '../../models/movie.dart';

class PlayerFactory {
  static BaseVideoPlayer create(Movie movie, {String? provider}) {
    // If source_type is admin, use NativePlayer (ExoPlayer/AVPlayer)
    if (movie.sourceType == 'admin' || provider == 'admin' || provider == 'local') {
      return NativePlayer();
    }

    // If source_type is scraped, use custom CppPlayer
    return CppPlayer();
  }
}
