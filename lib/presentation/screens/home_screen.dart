
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:riyo/core/design_system.dart';
import 'package:riyo/providers/auth_provider.dart';
import 'package:riyo/providers/home_provider.dart';
import 'package:riyo/providers/playback_provider.dart';
import 'package:riyo/providers/settings_provider.dart';
import 'package:riyo/providers/system_config_provider.dart';
import 'package:riyo/models/movie.dart';
import 'package:riyo/services/api_service.dart';
import 'package:riyo/presentation/widgets/movie_card.dart';
import 'package:riyo/presentation/widgets/shimmer_loading.dart';
import 'package:riyo/presentation/widgets/state_widgets.dart';
import 'package:riyo/core/casting/presentation/widgets/cast_button.dart';
import 'package:riyo/services/analytics_service.dart';
import 'package:riyo/core/localization.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      await homeProvider.loadConfig(token: auth.token);
      if (mounted) {
        _precacheHomeImages();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      // Auto refresh stale data on resume
      homeProvider.loadConfig(token: auth.token, forceRefresh: true);
    }
  }

  void _precacheHomeImages() {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    // Precache first few images from each section
    for (var entry in homeProvider.sections) {
      final title = entry['title'] as String;
      homeProvider.getSectionFuture(title, '').then((movies) {
        if (!mounted) return;
        for (var movie in movies.take(5)) {
          if (movie.posterPath.isNotEmpty) {
            final url = movie.posterPath.startsWith('http')
                ? movie.posterPath
                : 'https://image.tmdb.org/t/p/w500${movie.posterPath}';
            precacheImage(CachedNetworkImageProvider(url), context);
          }
        }
      });
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          homeProvider.refresh();
          await homeProvider.loadConfig(token: auth.token);
        },
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                title: Image.asset(
                  'assets/images/logo.png',
                  height: 28,
                  fit: BoxFit.contain,
                  color: isDark ? Colors.white : Colors.black,
                ),
                actions: [
                  Selector<SettingsProvider, bool>(
                    selector: (_, s) => s.isOffline,
                    builder: (context, isOffline, child) {
                      if (!isOffline) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Chip(
                          label: Text('offline_badge'.tr(context),
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          padding: EdgeInsets.zero,
                          side: BorderSide.none,
                        ),
                      );
                    },
                  ),
                  Selector<SystemConfigProvider, bool>(
                    selector: (_, sc) => sc.config.castingEnabled,
                    builder: (context, enabled, child) {
                      return enabled ? const CastingButton() : const SizedBox.shrink();
                    }
                  ),
                  IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () {
                        AnalyticsService.logButtonClick('home_settings_button');
                        context.push('/settings');
                      }),
                ],
                pinned: true,
                floating: true,
                forceElevated: innerBoxIsScrolled,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60.0),
                  child: Container(
                    height: 60.0,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Selector<HomeProvider, List<String>>(
                      selector: (_, h) => h.categories,
                      builder: (context, categories, child) {
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Selector<HomeProvider, String>(
                                selector: (_, h) => h.selectedCategory,
                                builder: (context, selectedCategory, child) {
                                  final category = categories[index];
                                  final isSelected = selectedCategory == category;
                                  return ChoiceChip(
                                    label: Text(category),
                                    selected: isSelected,
                                    onSelected: (bool selected) {
                                      homeProvider.setSelectedCategory(category);
                                    },
                                    showCheckmark: false,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: isSelected
                                          ? Colors.transparent
                                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                      ),
                                    ),
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Theme.of(context).textTheme.bodyMedium?.color,
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                    child: CircularProgressIndicator());
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
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                                    child: Text('downloads'.tr(context),
                                        style: AppTypography.headlineMedium),
                                  ),
                                  _buildMovieCategory(
                                      'available_offline'.tr(context),
                                      Future.value(snapshot.data ?? [])),
                                  const SizedBox(height: 100),
                                ]
                              : [
                                  RepaintBoundary(
                                      child: _buildCarouselSlider(
                                          auth.token, home)),
                                  const SizedBox(height: 24),
                                  _buildContinueWatchingSection(auth.token),
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
          return const ShimmerLoading.rectangular(height: 450);
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildTrendingCarousel(token);
        }

        final movies = snapshot.data!;

        return Column(
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: 500.0,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 8),
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
                            height: 500.0,
                            width: double.infinity,
                            placeholder: (context, url) => const ShimmerLoading.rectangular(height: 500),
                            errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
                          ),
                        Container(
                          height: 500.0,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Theme.of(context).scaffoldBackgroundColor,
                                Theme.of(context).scaffoldBackgroundColor.withAlpha(0),
                              ],
                              stops: const [0.0, 0.5],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 40,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                movie.title,
                                textAlign: TextAlign.center,
                                style: AppTypography.headlineLarge.copyWith(
                                  color: Colors.white,
                                  shadows: [const Shadow(color: Colors.black, blurRadius: 12)],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      final id = movie.backendId ?? movie.id.toString();
                                      context.push('/movie/$id/play');
                                    },
                                    icon: const Icon(Icons.play_arrow_rounded),
                                    label: Text('play_now'.tr(context)),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(140, 48),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton.filledTonal(
                                    onPressed: () {
                                      final id = movie.backendId ?? movie.id.toString();
                                      context.push('/movie/$id');
                                    },
                                    icon: const Icon(Icons.info_outline_rounded),
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
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: movies.asMap().entries.map((entry) {
                return Container(
                  width: _currentCarouselIndex == entry.key ? 16.0 : 6.0,
                  height: 6.0,
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: Theme.of(context).colorScheme.primary.withAlpha(
                        _currentCarouselIndex == entry.key ? 255 : 100),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Text('continue_watching'.tr(context), style: AppTypography.titleLarge),
                ),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: moviesWithProgress.length,
                    itemBuilder: (context, index) {
                      final movie = moviesWithProgress[index];
                      return Container(
                        width: 260,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                             final id = movie.backendId ?? movie.id.toString();
                             context.push('/movie/$id/play');
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
                                    child: CachedNetworkImage(
                                      imageUrl: (movie.backdropPath ?? movie.posterPath).startsWith('http')
                                          ? (movie.backdropPath ?? movie.posterPath)
                                          : 'https://image.tmdb.org/t/p/w500${movie.backdropPath ?? movie.posterPath}',
                                      fit: BoxFit.cover,
                                      width: 260,
                                      height: 146,
                                      placeholder: (context, url) => const ShimmerLoading.rectangular(height: 146, width: 260),
                                      errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.white24,
                                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTheme.cardBorderRadius)),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    child: Container(
                                      width: 130, // Mock progress
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(AppTheme.cardBorderRadius)),
                                      ),
                                    ),
                                  ),
                                  const Center(
                                    child: Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 40),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  movie.title,
                                  style: AppTypography.labelMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
     return const ShimmerLoading.rectangular(height: 450);
  }

  Widget _buildMovieCategory(String title, Future<List<Movie>> future) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.titleLarge,
              ),
              IconButton(
                onPressed: () => context.push('/genre/$title'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: FutureBuilder<List<Movie>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildMovieShimmerList();
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('no_movies_found'.tr(context)));
              }
              final movies = snapshot.data!;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  return SizedBox(
                    width: 150,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MovieCard(movie: movie, height: 210),
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

  Widget _buildMovieShimmerList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const SizedBox(
          width: 150,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: ShimmerLoading.rectangular(height: 210),
          ),
        );
      },
    );
  }
}
