
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:riyo/presentation/providers/auth_provider.dart';
import 'package:riyo/presentation/providers/home_provider.dart';
import 'package:riyo/presentation/providers/playback_provider.dart';
import 'package:riyo/models/movie.dart';
import 'package:riyo/presentation/widgets/movie_card.dart';
import 'package:riyo/presentation/widgets/shimmer_loading.dart';
import 'package:riyo/core/casting/presentation/widgets/cast_button.dart';
import 'package:riyo/main.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentCarouselIndex = 0;

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final homeNotifier = ref.read(homeProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: RefreshIndicator(
        onRefresh: () async {
          await homeNotifier.loadConfig(forceRefresh: true);
        },
        color: Colors.deepPurpleAccent,
        backgroundColor: const Color(0xFF1C1C1C),
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                backgroundColor: const Color(0xFF141414),
                title: Image.asset(
                  'assets/images/logo.png',
                  height: 32,
                  fit: BoxFit.contain,
                ),
                actions: [
                  const CastingButton(),
                  IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () => context.push('/settings')),
                ],
                pinned: true,
                floating: true,
                forceElevated: innerBoxIsScrolled,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(50.0),
                  child: SizedBox(
                    height: 50.0,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: homeState.categories.length,
                      itemBuilder: (context, index) {
                        final category = homeState.categories[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: homeState.selectedCategory == category,
                            onSelected: (bool selected) {
                              homeNotifier.setSelectedCategory(category);
                            },
                            backgroundColor: const Color(0xFF262626),
                            selectedColor: Colors.deepPurpleAccent,
                            labelStyle: TextStyle(
                              color: homeState.selectedCategory == category
                                  ? Colors.white
                                  : Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ];
          },
          body: homeState.isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RepaintBoundary(
                        child: _buildCarouselSlider(homeState.featuredMovies),
                      ),
                      const SizedBox(height: 10),
                      _buildContinueWatching(),
                      const SizedBox(height: 20),
                      ...homeState.sections.map((sec) {
                        final future = homeNotifier.getSectionMovies(
                          sec['title'],
                          sec['type'],
                          genre: sec['genre'],
                        );
                        return _buildMovieCategory(sec['title'], future);
                      }),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCarouselSlider(List<Movie> movies) {
    if (movies.isEmpty) return const SizedBox.shrink();

    return Column(
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: 450.0,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration: const Duration(milliseconds: 1000),
                autoPlayCurve: Curves.fastOutSlowIn,
                viewportFraction: 1.0,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentCarouselIndex = index;
                  });
                },
              ),
              items: movies.map((movie) {
                return Builder(
                  builder: (BuildContext context) {
                    return GestureDetector(
                      onTap: () {
                        final id = movie.backendId ?? movie.id.toString();
                        context.push('/movie/$id');
                      },
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: (movie.posterPath).startsWith('http')
                                ? (movie.posterPath)
                                : 'https://image.tmdb.org/t/p/w780${movie.posterPath}',
                            fit: BoxFit.cover,
                            height: 450.0,
                            width: double.infinity,
                            placeholder: (context, url) => const ShimmerLoading.rectangular(height: 450),
                            errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
                          ),
                        Container(
                          height: 450.0,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withAlpha(204), Colors.transparent],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 30,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                movie.title.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                                ),
                              ),
                              const SizedBox(height: 15),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      final id = movie.backendId ?? movie.id.toString();
                                      context.push('/movie/$id/play');
                                    },
                                    icon: const Icon(Icons.play_arrow, color: Colors.black),
                                    label: const Text('PLAY', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      final id = movie.backendId ?? movie.id.toString();
                                      context.push('/movie/$id');
                                    },
                                    icon: const Icon(Icons.info_outline, color: Colors.white),
                                    label: const Text('DETAILS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.white, width: 2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                  },
                );
              }).toList(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: movies.asMap().entries.map((entry) {
                return GestureDetector(
                  onTap: () => setState(() => _currentCarouselIndex = entry.key),
                  child: Container(
                    width: 6.0,
                    height: 6.0,
                    margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white
                          .withAlpha(_currentCarouselIndex == entry.key ? 230 : 102),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
  }

  Widget _buildContinueWatching() {
    ref.watch(playbackProvider); // Rebuild when progress changes
    final cache = ref.read(cacheServiceProvider);

    final recentActivity = cache.getAllRecentActivity().where((p) => p.positionSeconds > 0).take(10).toList();
    if (recentActivity.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Continue Watching',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recentActivity.length,
            itemBuilder: (context, index) {
              final activity = recentActivity[index];
              final movie = cache.getCachedMovies([activity.movieId]).firstOrNull;

              if (movie == null) return const SizedBox.shrink();

              return Container(
                width: 240,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => context.push('/movie/${movie.backendId}/play'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: CachedNetworkImage(
                                imageUrl: movie.backdropPath != null && movie.backdropPath!.isNotEmpty
                                    ? (movie.backdropPath!.startsWith('http') ? movie.backdropPath! : 'https://image.tmdb.org/t/p/w500${movie.backdropPath}')
                                    : (movie.posterPath.startsWith('http') ? movie.posterPath : 'https://image.tmdb.org/t/p/w500${movie.posterPath}'),
                                fit: BoxFit.cover,
                                memCacheHeight: 135,
                                memCacheWidth: 240,
                                placeholder: (context, url) => Container(color: Colors.white10),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: LinearProgressIndicator(
                              value: activity.durationSeconds > 0 ? activity.positionSeconds / activity.durationSeconds : 0.5,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.yellow),
                              minHeight: 3,
                            ),
                          ),
                          const Positioned.fill(
                            child: Center(
                              child: Icon(Icons.play_arrow, color: Colors.white, size: 40),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        movie.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMovieCategory(String title, Future<List<Movie>> future) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => context.push('/genre/$title'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: FutureBuilder<List<Movie>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildMovieShimmerList();
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Cilad ayaa ka dhacday soo rarida filimada.', style: TextStyle(color: Colors.white)));
              }
              final movies = snapshot.data!;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  return SizedBox(
                    width: 140,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MovieCard(movie: movie, height: 160),
                          const SizedBox(height: 8),
                          Text(
                            movie.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${movie.releaseDate.split('-')[0]}${movie.runtime != null ? " | ${_formatDuration(movie.runtime!)}" : ""}',
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDuration(int minutes) {
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m';
  }

  Widget _buildMovieShimmerList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      itemBuilder: (context, index) {
        return const SizedBox(
          width: 140,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading.rectangular(height: 160),
                SizedBox(height: 8),
                ShimmerLoading.rectangular(height: 14, width: 100),
                SizedBox(height: 4),
                ShimmerLoading.rectangular(height: 12, width: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
