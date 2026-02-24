import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
        // Ensure "Coming Soon" is prominent or present
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
      backgroundColor: const Color(0xFF141414),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF141414),
            title: const Text('RIYO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
            actions: [
              const CastingButton(),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => context.push('/settings'),
              ),
            ],
            floating: true,
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildFeaturedCategoryCard(context),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Text('EXPLORE CATEGORIES', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
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
        ],
      ),
    );
  }

  Widget _buildFeaturedCategoryCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Image.network(
            'https://picsum.photos/seed/van/800/400',
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Container(
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black87, Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('FEATURED CATEGORY', style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('ANIME HUB', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.push('/genre/Anime'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('EXPLORE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        borderRadius: BorderRadius.circular(4),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withAlpha(100), BlendMode.darken),
        ),
      ),
      child: Center(
        child: Text(
          name.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
    );
  }
}
