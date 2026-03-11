import 'package:hive_ce/hive.dart';
import 'package:riyo/data/cache/schemas.dart';

extension HiveRegistrar on HiveInterface {
  void registerAdapters() {
    registerAdapter(MovieCacheAdapter());
    registerAdapter(PlaybackProgressCacheAdapter());
    registerAdapter(CategoryCacheAdapter());
    registerAdapter(HomeSectionCacheAdapter());
  }
}
