
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:riyo/providers/settings_provider.dart';
import 'package:riyo/providers/playback_provider.dart';
import 'package:riyo/providers/download_provider.dart';
import 'package:riyo/providers/auth_provider.dart';
import 'package:riyo/providers/home_provider.dart';
import 'package:riyo/services/cast_service.dart';
import 'package:riyo/presentation/screens/splash_screen.dart';
import 'package:riyo/presentation/screens/onboarding_screen.dart';
import 'package:riyo/presentation/screens/auth/login_screen.dart';
import 'package:riyo/presentation/screens/auth/signup_screen.dart';
import 'package:riyo/presentation/screens/home_screen.dart';
import 'package:riyo/presentation/screens/movie_details_screen.dart';
import 'package:riyo/presentation/screens/video_player_screen.dart';
import 'package:riyo/presentation/screens/settings_screen.dart';
import 'package:riyo/presentation/screens/cast_screen.dart';
import 'package:riyo/presentation/screens/categories_screen.dart';
import 'package:riyo/presentation/screens/downloads_screen.dart';
import 'package:riyo/presentation/screens/my_riyo_screen.dart';
import 'package:riyo/presentation/screens/search_screen.dart';
import 'package:riyo/presentation/screens/coming_soon_screen.dart';
import 'package:riyo/presentation/screens/genre_movies_screen.dart';
import 'package:riyo/presentation/screens/admin/admin_panel_screen.dart';
import 'package:riyo/presentation/screens/download_settings_screen.dart';
import 'package:riyo/presentation/screens/support/contacts_screen.dart';
import 'package:riyo/presentation/screens/support/terms_screen.dart';
import 'package:riyo/presentation/screens/support/privacy_screen.dart';
import 'package:riyo/presentation/screens/support/about_screen.dart';
import 'package:riyo/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase initialization (requires google-services.json in real apps)
  try {
    await Firebase.initializeApp();
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Firebase/Notification Init Error: $e');
  }
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

GoRouter _createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final bool loggingIn = state.uri.path == '/login';
      final bool signingUp = state.uri.path == '/signup';
      final bool splash = state.uri.path == '/splash';
      final bool welcome = state.uri.path == '/welcome';

      if (splash) return null;

      if (!authProvider.isOnboardingComplete) {
        return welcome ? null : '/welcome';
      }

      if (!authProvider.isAuthenticated) {
        return (loggingIn || signingUp || welcome) ? null : '/login';
      }

      if (loggingIn || signingUp || welcome) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/category',
            builder: (context, state) => const CategoriesScreen(),
          ),
          GoRoute(
            path: '/downloads',
            builder: (context, state) => const DownloadsScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/my-riyo',
            builder: (context, state) => const MyRiyoScreen(),
          ),
          GoRoute(
            path: '/coming-soon',
            builder: (context, state) => const ComingSoonScreen(),
          ),
          GoRoute(
            path: '/genre/:name',
            builder: (context, state) {
              final name = state.pathParameters['name']!;
              return GenreMoviesScreen(genreName: name);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/movie/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MovieDetailsScreen(movieId: id);
        },
      ),
      GoRoute(
        path: '/movie/:id/play',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          return VideoPlayerScreen(movieId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/cast',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CastScreen(),
      ),
      GoRoute(
        path: '/download-settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DownloadSettingsScreen(),
      ),
      GoRoute(
        path: '/contacts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ContactsScreen(),
      ),
      GoRoute(
        path: '/terms',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/about',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
    GoRoute(
      path: '/admin',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AdminPanelScreen(),
    ),
    ],
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => PlaybackProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
        ChangeNotifierProvider(create: (_) => CastService()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          return MaterialApp.router(
            routerConfig: _createRouter(auth),
            title: 'RIYO',
            themeMode: settings.themeMode,
            locale: settings.language == 'Arabic'
                ? const Locale('ar', '')
                : const Locale('en', ''),
            builder: (context, child) {
              return Directionality(
                textDirection: settings.language == 'Arabic'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child!,
              );
            },
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              primaryColor: Colors.deepPurple,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.light,
                secondary: Colors.deepPurpleAccent,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              primaryColor: Colors.deepPurple,
              scaffoldBackgroundColor: const Color(0xFF1C1B1F),
              colorScheme: const ColorScheme.dark(
                primary: Colors.deepPurple,
                secondary: Colors.yellow,
                onPrimary: Colors.white,
                onSecondary: Colors.black,
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: Color(0xFF1C1B1F),
                selectedItemColor: Colors.yellow,
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                showUnselectedLabels: true,
              ),
            ),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/category')) return 1;
    if (location.startsWith('/downloads')) return 2;
    if (location.startsWith('/search')) return 3;
    if (location.startsWith('/my-riyo')) return 4;
    return 0; // Default
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/category');
        break;
      case 2:
        context.go('/downloads');
        break;
      case 3:
        context.go('/search');
        break;
      case 4:
        context.go('/my-riyo');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download_outlined),
            activeIcon: Icon(Icons.download),
            label: 'Downloads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'My RIYO',
          ),
        ],
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }
}
