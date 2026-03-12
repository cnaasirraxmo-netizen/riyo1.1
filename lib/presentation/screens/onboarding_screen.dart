import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:riyo/core/design_system.dart';
import 'package:riyo/presentation/widgets/riyo_components.dart';
import 'package:riyo/providers/auth_provider.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 32,
                fit: BoxFit.contain,
                color: isDark ? Colors.white : Colors.black,
              ),
              const Spacer(),
              Text(
                'Unlimited movies, TV shows, and more',
                textAlign: TextAlign.center,
                style: AppTypography.headlineLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Watch anywhere. Cancel anytime.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(
                  color: Theme.of(context).textTheme.labelSmall?.color,
                ),
              ),
              const Spacer(),
              RiyoButton(
                text: 'Get Started',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                ),
              ),
              const SizedBox(height: 16),
              RiyoButton(
                text: 'Sign In',
                isPrimary: false,
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Watch on any device',
      description: 'Stream on your phone, tablet, laptop, and TV without paying more.',
      icon: Icons.devices_rounded,
    ),
    OnboardingData(
      title: 'Download & watch offline',
      description: 'Save your favorites easily and always have something to watch.',
      icon: Icons.download_done_rounded,
    ),
    OnboardingData(
      title: 'No commitments',
      description: 'Join today, cancel anytime. No hidden fees or contracts.',
      icon: Icons.verified_user_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: _finishOnboarding,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _pages[index].icon,
                        size: 100,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 48),
                      Text(
                        _pages[index].title,
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _pages[index].description,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).textTheme.labelSmall?.color,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      height: 6,
                      width: _currentPage == index ? 24 : 6,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primary.withAlpha(50),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                FloatingActionButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutCubic,
                      );
                    } else {
                      _finishOnboarding();
                    }
                  },
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Icon(_currentPage == _pages.length - 1 ? Icons.check_rounded : Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _finishOnboarding() async {
    await Provider.of<AuthProvider>(context, listen: false).completeOnboarding();
    if (mounted) {
      context.go('/login');
    }
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;

  OnboardingData({required this.title, required this.description, required this.icon});
}
