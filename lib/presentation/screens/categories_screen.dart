import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riyo/core/design_system.dart';
import 'package:riyo/services/api_service.dart';
import 'package:riyo/core/casting/presentation/widgets/cast_button.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final ApiService _apiService = ApiService();
  List<String> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _apiService.getHeaderCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        if (!_categories.contains('Coming Soon')) {
          _categories.insert(0, 'Coming Soon');
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('Categories', style: AppTypography.titleLarge),
            actions: [
              const CastingButton(),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push('/settings'),
              ),
            ],
            surfaceTintColor: Colors.transparent,
            floating: true,
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildFeaturedCategoryCard(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Text('Explore Genres', style: AppTypography.titleMedium),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = _categories[index];
                    return InkWell(
                      onTap: () {
                        if (category == 'Coming Soon') {
                          context.push('/coming-soon');
                        } else {
                          context.push('/genre/$category');
                        }
                      },
                      child: _buildGenreCard(category, 'https://picsum.photos/seed/${category.hashCode}/400/200'),
                    );
                  },
                  childCount: _categories.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildFeaturedCategoryCard(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        image: const DecorationImage(
          image: NetworkImage('https://picsum.photos/seed/van/800/400'),
          fit: BoxFit.cover,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black87, Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('FEATURED',
                  style: AppTypography.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Anime Hub',
                  style: AppTypography.headlineMedium.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.push('/genre/Anime'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(100, 40),
                    textStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Explore'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGenreCard(String name, String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withAlpha(120), BlendMode.darken),
        ),
      ),
      child: Center(
        child: Text(
          name,
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
