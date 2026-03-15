
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:go_router/go_router.dart';
import 'package:riyo/core/design_system.dart';
import 'package:provider/provider.dart';
import 'package:riyo/providers/settings_provider.dart';
import 'package:riyo/providers/playback_provider.dart';
import 'package:riyo/providers/download_provider.dart';
import 'package:riyo/providers/auth_provider.dart';
import 'package:riyo/providers/home_provider.dart';
import 'package:riyo/providers/system_config_provider.dart';
import 'package:riyo/presentation/screens/splash_screen.dart';
import 'package:riyo/presentation/screens/onboarding_screen.dart';
import 'package:riyo/presentation/screens/auth/login_screen.dart';
import 'package:riyo/presentation/screens/auth/signup_screen.dart';
import 'package:riyo/presentation/screens/auth/forgot_password_screen.dart';
import 'package:riyo/presentation/screens/home_screen.dart';
import 'package:riyo/presentation/screens/movie_details_screen.dart';
import 'package:riyo/presentation/screens/video_player_screen.dart';
import 'package:riyo/presentation/screens/settings_screen.dart';
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
import 'package:riyo/presentation/screens/settings/appearance_settings_screen.dart';
import 'package:riyo/presentation/screens/settings/account_settings_screen.dart';
import 'package:riyo/presentation/screens/settings/notification_settings_screen.dart';
import 'package:riyo/presentation/screens/settings/playback_settings_screen.dart';
import 'package:riyo/presentation/screens/settings/download_settings_screen.dart' as ds;
import 'package:riyo/presentation/screens/settings/data_saver_settings_screen.dart';
import 'package:riyo/presentation/screens/settings/language_settings_screen.dart';
import 'package:riyo/presentation/screens/settings/privacy_settings_screen.dart';
import 'package:riyo/presentation/screens/settings/preferences_settings_screen.dart';
import 'package:riyo/presentation/screens/settings/storage_settings_screen.dart';
import 'package:riyo/presentation/screens/settings/support_settings_screen.dart';
import 'package:riyo/presentation/screens/settings/about_settings_screen.dart' as about;
import 'package:riyo/presentation/screens/settings/developer_settings_screen.dart';
import 'package:riyo/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Firebase/Notification Init Error: $e');
  }
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('so'), Locale('ar'), Locale('es')],
      path: 'assets/lang',
      fallbackLocale: const Locale('en'),
      child: const rp.ProviderScope(child: MyApp()),
    ),
  );
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
  }

  void _initRouter(AuthProvider authProvider) {
    _router ??= GoRouter(
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
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
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
            final url = state.uri.queryParameters['url'];
            final s = state.uri.queryParameters['s'];
            final e = state.uri.queryParameters['e'];
            return VideoPlayerScreen(
              movieId: id,
              videoUrl: url,
              season: s != null ? int.tryParse(s) : null,
              episode: e != null ? int.tryParse(e) : null,
            );
          },
        ),
        GoRoute(
          path: '/settings',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const SettingsScreen(),
          routes: [
            GoRoute(path: 'appearance', builder: (context, state) => const AppearanceSettingsScreen()),
            GoRoute(path: 'account', builder: (context, state) => const AccountSettingsScreen()),
            GoRoute(path: 'notifications', builder: (context, state) => const NotificationSettingsScreen()),
            GoRoute(path: 'playback', builder: (context, state) => const PlaybackSettingsScreen()),
            GoRoute(path: 'downloads', builder: (context, state) => const ds.DownloadSettingsScreen()),
            GoRoute(path: 'data-saver', builder: (context, state) => const DataSaverSettingsScreen()),
            GoRoute(path: 'language', builder: (context, state) => const LanguageSettingsScreen()),
            GoRoute(path: 'privacy', builder: (context, state) => const PrivacySettingsScreen()),
            GoRoute(path: 'preferences', builder: (context, state) => const PreferencesSettingsScreen()),
            GoRoute(path: 'storage', builder: (context, state) => const StorageSettingsScreen()),
            GoRoute(path: 'support', builder: (context, state) => const SupportSettingsScreen()),
            GoRoute(path: 'about', builder: (context, state) => const about.AboutSettingsScreen()),
            GoRoute(path: 'developer', builder: (context, state) => const DeveloperSettingsScreen()),
          ],
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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => PlaybackProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => SystemConfigProvider()),
      ],
      child: DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          return Consumer2<SettingsProvider, AuthProvider>(
            builder: (context, settings, auth, child) {
              _initRouter(auth);

              final lightTheme = AppTheme.getLightTheme(
                settings.dynamicColor ? lightDynamic : null,
              );

              final darkTheme = AppTheme.getDarkTheme(
                settings.dynamicColor ? darkDynamic : null,
                isAmoled: settings.amoledMode,
              );

              return MaterialApp.router(
                routerConfig: _router!,
                title: 'RIYO',
                themeMode: settings.themeMode,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                builder: (context, child) {
                  return child!;
                },
                theme: lightTheme,
                darkTheme: darkTheme,
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _checkAndShowWelcomeNotification();
    }
  }

  Future<void> _checkAndShowWelcomeNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasShownWelcome = prefs.getBool('has_shown_welcome_notification') ?? false;

    if (!hasShownWelcome) {
      await NotificationService.showWelcomeNotification();
      await prefs.setBool('has_shown_welcome_notification', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SystemConfigProvider>(
      builder: (context, systemConfig, child) {
        final bool downloadsEnabled = systemConfig.config.downloadsEnabled;

        final List<BottomNavigationBarItem> items = [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: 'home'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view_outlined),
            activeIcon: const Icon(Icons.grid_view),
            label: 'categories'.tr(),
          ),
          if (downloadsEnabled)
            BottomNavigationBarItem(
              icon: const Icon(Icons.download_outlined),
              activeIcon: const Icon(Icons.download),
              label: 'downloads'.tr(),
            ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search_outlined),
            activeIcon: const Icon(Icons.search),
            label: 'search'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: 'profile_title'.tr(),
          ),
        ];

        return Scaffold(
          body: widget.child,
          bottomNavigationBar: BottomNavigationBar(
            items: items,
            currentIndex: _calculateSelectedIndex(context, downloadsEnabled),
            onTap: (index) => _onItemTapped(index, context, downloadsEnabled),
            type: BottomNavigationBarType.fixed,
          ),
        );
      },
    );
  }

  int _calculateSelectedIndex(BuildContext context, bool downloadsEnabled) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/category')) return 1;
    if (location.startsWith('/downloads')) return downloadsEnabled ? 2 : 0;
    if (location.startsWith('/search')) return downloadsEnabled ? 3 : 2;
    if (location.startsWith('/my-riyo')) return downloadsEnabled ? 4 : 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, bool downloadsEnabled) {
    int targetIndex = index;
    if (!downloadsEnabled && index >= 2) {
      targetIndex = index + 1;
    }

    switch (targetIndex) {
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
}
