import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riyo/core/design_system.dart';
import 'package:riyo/presentation/widgets/movie_card.dart';
import 'package:riyo/models/movie.dart';
import 'package:riyo/services/api_service.dart';
import 'package:riyo/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class MyRiyoScreen extends StatelessWidget {
  const MyRiyoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final apiService = ApiService();

    return Scaffold(
      appBar: AppBar(
        title: Text('My RIYO', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.cast_connected_outlined),
            onPressed: () => context.push('/cast'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            _buildStatsSection(context, auth.token),
            const SizedBox(height: 40),
            _buildSectionHeader(context, 'My Watchlist', onTap: () => context.push('/genre/Watchlist')),
            const SizedBox(height: 16),
            FutureBuilder<List<Movie>>(
              future: auth.token != null ? apiService.getWatchlist(auth.token!) : Future.value([]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return _buildMovieHorizontalList(context, snapshot.data!);
              }
            ),
            const SizedBox(height: 40),
            _buildSectionHeader(context, 'Account Settings', showArrow: false),
            const SizedBox(height: 16),
            _buildAccountSettings(context),
            const SizedBox(height: 48),
            _buildFooter(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, String? token) {
    final apiService = ApiService();
    return FutureBuilder<List<Movie>>(
      future: token != null ? apiService.getWatchlist(token) : Future.value([]),
      builder: (context, snapshot) {
        final watchlistCount = snapshot.data?.length ?? 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(context, watchlistCount.toString(), 'Watchlist', () {}),
            _buildStatItem(context, '0', 'History', () {}),
            _buildStatItem(context, '0', 'Downloads', () => context.go('/downloads')),
          ],
        );
      }
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(value, style: AppTypography.headlineMedium.copyWith(color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 4),
          Text(label, style: AppTypography.labelSmall),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {bool showArrow = true, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.titleMedium),
          if (showArrow)
            const Icon(Icons.chevron_right_rounded, size: 24),
        ],
      ),
    );
  }

  Widget _buildMovieHorizontalList(BuildContext context, List<Movie> movies) {
    if (movies.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text('Your list is empty', style: AppTypography.bodyMedium.copyWith(color: Theme.of(context).textTheme.labelSmall?.color)),
      );
    }

    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            child: MovieCard(movie: movie, height: 210),
          );
        },
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Column(
      children: [
        if (auth.role == 'admin')
           _buildSettingsButton(
            context,
            icon: Icons.admin_panel_settings_outlined,
            text: 'Admin Panel',
            onTap: () => context.push('/admin'),
          ),
        if (auth.role == 'admin')
          const SizedBox(height: 12),
        _buildSettingsButton(
          context,
          icon: Icons.settings_outlined,
          text: 'App Settings',
          onTap: () => context.push('/settings'),
        ),
        const SizedBox(height: 12),
        _buildSettingsButton(
          context,
          icon: Icons.child_care_rounded,
          text: 'Kids Mode',
          onTap: () => context.push('/kids'),
        ),
        const SizedBox(height: 12),
         _buildSettingsButton(
          context,
          icon: Icons.subscriptions_outlined,
          text: 'Subscription Plans',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSettingsButton(BuildContext context, {required IconData icon, required String text, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.buttonBorderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.amoledSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.buttonBorderRadius),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(child: Text(text, style: AppTypography.titleMedium)),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Text('RIYO PREMIUM V3.0.0', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Text('DESIGN SYSTEM V2', style: AppTypography.labelSmall.copyWith(fontSize: 10, color: Theme.of(context).textTheme.labelSmall?.color)),
      ],
    );
  }
}
