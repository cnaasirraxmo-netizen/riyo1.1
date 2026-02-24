
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:riyo/providers/auth_provider.dart';
import 'package:riyo/providers/home_provider.dart';
import 'package:riyo/providers/playback_provider.dart';
import 'package:riyo/providers/settings_provider.dart';
import 'package:riyo/models/movie.dart';
import 'package:riyo/services/api_service.dart';
import 'package:riyo/presentation/widgets/movie_card.dart';
import 'package:riyo/presentation/widgets/shimmer_loading.dart';
import 'package:riyo/presentation/widgets/state_widgets.dart';
import 'package:riyo/presentation/widgets/cast_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<HomeProvider>(context, listen: false)
          .loadConfig(token: auth.token);
    });
  }

  Future<List<Movie>> _getFilteredMovies(
      String category, String? token, bool isOffline) async {
    List<Movie> movies;

    if (category == "My List") {
      movies = await _apiService.getWatchlist(token ?? "");
    } else if (category == "All") {
      movies = await _apiService.getTrendingMovies(token: token);
    } else if (category == "Movies") {
      movies = await _apiService.getTrendingMovies(token: token);
      movies = movies.where((m) => !m.isTvShow).toList();
    } else if (category == "TV Shows") {
      movies = await _apiService.getTrendingMovies(token: token);
      movies = movies.where((m) => m.isTvShow).toList();
    } else {
      // Treat as Genre
      movies = await _apiService.getTrendingMovies(token: token, genre: category);
    }

    if (isOffline) {
      movies = movies.where((m) => m.isDownloaded).toList();
    }

    return movies;
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: RefreshIndicator(
        onRefresh: () async {
          homeProvider.refresh();
          await homeProvider.loadConfig(token: auth.token);
        },
        color: Colors.deepPurpleAccent,
        backgroundColor: const Color(0xFF1C1C1C),
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                backgroundColor: const Color(0xFF141414),
                title: const Text('RIYO',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white)),
                actions: [
                  Selector<SettingsProvider, bool>(
                    selector: (_, s) => s.isOffline,
                    builder: (context, isOffline, child) {
                      if (!isOffline) return const SizedBox.shrink();
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Chip(
                          label: Text('OFFLINE MODE',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    },
                  ),
                  const CastButton(),
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
                    child: Selector<HomeProvider, List<String>>(
                      selector: (_, h) => h.categories,
                      builder: (context, categories, child) {
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Selector<HomeProvider, String>(
                                selector: (_, h) => h.selectedCategory,
                                builder: (context, selectedCategory, child) {
                                  final category = categories[index];
                                  return ChoiceChip(
                                    label: Text(category),
                                    selected: selectedCategory == category,
                                    onSelected: (bool selected) {
                                      homeProvider.setSelectedCategory(category);
                                    },
                                    backgroundColor: const Color(0xFF262626),
                                    selectedColor: Colors.deepPurpleAccent,
                                    labelStyle: TextStyle(
                                      color: selectedCategory == category
                                          ? Colors.white
                                          : Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Selector<HomeProvider, bool>(
            selector: (_, h) => h.isLoadingConfig,
            builder: (context, isLoading, child) {
              if (isLoading) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Colors.deepPurpleAccent));
              }
              return Consumer2<SettingsProvider, HomeProvider>(
                builder: (context, settings, home, child) {
                  return FutureBuilder<List<Movie>>(
                    future: _getFilteredMovies(
                        home.selectedCategory, auth.token, settings.isOffline),
                    builder: (context, snapshot) {
                      if (settings.isOffline &&
                          snapshot.hasData &&
                          snapshot.data!.isEmpty) {
                        return NoInternetState(
                          onRetry: () => settings.setOfflineMode(false),
                          onGoOffline: () => context.push('/downloads'),
                        );
                      }

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: settings.isOffline
                              ? [
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                                    child: Text('MY DOWNLOADS',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  _buildMovieCategory(
                                      "Available Offline",
                                      Future.value(snapshot.data ?? [])),
                                  const SizedBox(height: 400),
                                ]
                              : [
                                  RepaintBoundary(
                                      child: _buildCarouselSlider(
                                          auth.token, home)),
                                  _buildContinueWatchingSection(auth.token),
                                  const SizedBox(height: 20),
                                  ...home.sections.map((sec) {
                                    if (sec['type'] == 'continue_watching') {
                                      return _buildContinueWatchingSection(
                                          auth.token);
                                    }
                                    final future = home.getSectionFuture(
                                        sec['title'], sec['type'],
                                        genre: sec['genre'], token: auth.token);
                                    return _buildMovieCategory(
                                        sec['title'], future);
                                  }),
                                  const SizedBox(height: 40),
                                ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselSlider(String? token, HomeProvider home) {
    return FutureBuilder<List<Movie>>(
      future: home.featuredFuture ??
          _apiService.getTrendingMovies(token: token, isFeatured: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerLoading.rectangular(height: 400);
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          // Fallback to trending if no featured movies
          return _buildTrendingCarousel(token);
        }

        final movies = snapshot.data!;

        return Column(
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: 450.0, // Large poster height
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
      },
    );
  }

  Widget _buildContinueWatchingSection(String? token) {
    return Selector<PlaybackProvider, Map<String, Duration>>(
      selector: (_, p) => p.allProgress,
      builder: (context, allProgress, child) {
        if (allProgress.isEmpty) return const SizedBox.shrink();

        return FutureBuilder<List<Movie>>(
          future: _apiService.getTrendingMovies(token: token),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }
            final moviesWithProgress = snapshot.data!
                .where((m) =>
                    (allProgress[m.id.toString()] ?? Duration.zero) >
                    Duration.zero)
                .toList();
            if (moviesWithProgress.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text('CONTINUE WATCHING', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: moviesWithProgress.length,
                    itemBuilder: (context, index) {
                      final movie = moviesWithProgress[index];
                      return Container(
                        width: 240,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: GestureDetector(
                          onTap: () {
                             final id = movie.backendId ?? movie.id.toString();
                             context.push('/movie/$id/play');
                          },
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: (movie.backdropPath ?? movie.posterPath).startsWith('http')
                                      ? (movie.backdropPath ?? movie.posterPath)
                                      : 'https://image.tmdb.org/t/p/w500${movie.backdropPath ?? movie.posterPath}',
                                  fit: BoxFit.cover,
                                  width: 240,
                                  height: 135,
                                  placeholder: (context, url) => const ShimmerLoading.rectangular(height: 135, width: 240),
                                  errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
                                ),
                              ),
                              Container(
                                width: 240,
                                height: 4,
                                color: Colors.white24,
                              ),
                              Positioned(
                                left: 0,
                                child: Container(
                                  width: 120, // Mock progress
                                  height: 4,
                                  color: Colors.deepPurpleAccent,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Icon(Icons.play_circle_fill, color: Colors.white.withAlpha(204), size: 48),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Text(movie.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
          },
        );
      },
    );
  }

  Widget _buildTrendingCarousel(String? token) {
    return FutureBuilder<List<Movie>>(
      future: _apiService.getTrendingMovies(token: token),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerLoading.rectangular(height: 400);
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('Cilad ayaa dhacday.', style: TextStyle(color: Colors.white))),
          );
        }

        final movies = snapshot.data!;

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
              items: movies.take(5).map((movie) {
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
          ],
        );
      },
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
