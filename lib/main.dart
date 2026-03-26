
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
import 'package:riyo/presentation/widgets/safe_screen.dart';
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
import 'package:riyo/presentation/screens/kids/kids_home_screen.dart';
import 'package:riyo/presentation/widgets/state_widgets.dart';
import 'package:riyo/presentation/screens/admin/admin_panel_screen.dart';
import 'package:riyo/presentation/screens/download_settings_screen.dart';
import 'package:riyo/presentation/screens/support/contacts_screen.dart';
import 'package:riyo/presentation/screens/support/terms_screen.dart';
import 'package:riyo/presentation/screens/support/privacy_screen.dart';
import 'package:riyo/presentation/screens/support/about_screen.dart';
import 'package:riyo/presentation/screens/settings/appearance_settings_screen.dart';
import 'package:riyo/presentation/screens/settings/account_settings_screen.dart';
import 'package:riyo/presentation/screens/settings/edit_profile_screen.dart';
import 'package:riyo/presentation/screens/settings/change_password_screen.dart';
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
import 'package:riyo/presentation/screens/settings/parental_control_screen.dart';
import 'package:riyo/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riyo/services/local_cache_service.dart';
import 'package:riyo/core/localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:riyo/core/constants.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  try {
    await Hive.initFlutter();
    await LocalCacheService().init();
    debugPrint('Hive initialized successfully.');
  } catch (e) {
    debugPrint('Hive initialization error: $e');
  }

  // Global Error Handler for UI errors
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF121212),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                details.exception.toString(),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => main(), // Simple retry
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  };

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('GLOBAL FLUTTER ERROR: ${details.exception}');
  };

  try {
    debugPrint('Starting Firebase initialization...');
    try {
      await Firebase.initializeApp().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Firebase initialization timed out after 10 seconds');
          return Firebase.app(); // Return default app if already initialized, or throw
        },
      );
    } catch (e) {
      debugPrint('Firebase initialization error (might already be initialized): $e');
    }

    debugPrint('Starting NotificationService initialization...');
    try {
      await NotificationService.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('NotificationService initialization timed out after 10 seconds');
        },
      );
      await NotificationService.setupInteractedMessage();
    } catch (e) {
      debugPrint('NotificationService initialization error: $e');
    }
    debugPrint('All critical initializations complete.');
  } catch (e) {
    debugPrint('CRITICAL APP INIT ERROR: $e');
  }

  runApp(
    const rp.ProviderScope(child: MyApp()),
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
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle initial link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('Deep link error: $e');
    }

    // Handle incoming links
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Deep link stream error: $err');
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.pathSegments.contains('movie')) {
      final movieId = uri.pathSegments.last;
      _router?.push('/movie/$movieId');
    }
  }

  void _initRouter(AuthProvider authProvider) {
    _router ??= GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      refreshListenable: authProvider,
      observers: [
        _AnalyticsObserver(authProvider),
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      errorBuilder: (context, state) {
        return Scaffold(
          body: StateWidget(
            icon: Icons.error_outline_rounded,
            title: 'Page not found',
            description: 'The page you are looking for does not exist or has been moved.',
            primaryActionText: 'Go Home',
            onPrimaryAction: () => context.go('/home'),
          ),
        );
      },
      redirect: (context, state) {
        try {
          final bool loggingIn = state.uri.path == '/login';
          final bool signingUp = state.uri.path == '/signup';
          final bool splash = state.uri.path == '/splash';
          final bool welcome = state.uri.path == '/welcome';

          if (splash) return null;

          // Ensure state is loaded before making redirection decisions
          if (!authProvider.isInitialized) {
            return null; // Stay on splash while initializing
          }

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
        } catch (e) {
          debugPrint('Redirect Error: $e. Defaulting to /splash');
          return '/splash';
        }
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SafeScreen(child: SplashScreen()),
        ),
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const SafeScreen(child: WelcomeScreen()),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const SafeScreen(child: LoginScreen()),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SafeScreen(child: SignUpScreen()),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const SafeScreen(child: ForgotPasswordScreen()),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainScreen(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  name: 'home',
                  builder: (context, state) => const HomeScreen(),
                  routes: [
                    GoRoute(
                      path: 'genre/:name',
                      builder: (context, state) {
                        final name = state.pathParameters['name']!;
                        return GenreMoviesScreen(genreName: name);
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/category',
                  name: 'categories',
                  builder: (context, state) => const CategoriesScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/downloads',
                  name: 'downloads',
                  builder: (context, state) => const DownloadsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/search',
                  name: 'search',
                  builder: (context, state) => const SearchScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/my-riyo',
                  name: 'profile',
                  builder: (context, state) => const MyRiyoScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/coming-soon',
          builder: (context, state) => const ComingSoonScreen(),
        ),
        GoRoute(
          path: '/kids',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const KidsHomeScreen(),
        ),
        GoRoute(
          path: '/movie/:id',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final id = state.pathParameters['id'];
            if (id == null || id == 'null' || id.isEmpty) {
               return Scaffold(
                 body: StateWidget(
                   icon: Icons.movie_filter_outlined,
                   title: 'Invalid navigation request',
                   description: 'Movie details cannot be loaded without a valid ID.',
                   primaryActionText: 'Go Back',
                   onPrimaryAction: () => context.pop(),
                 ),
               );
            }
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
            final p = state.uri.queryParameters['provider'];
            return VideoPlayerScreen(
              movieId: id == 'external' ? null : id,
              videoUrl: url,
              season: s != null ? int.tryParse(s) : null,
              episode: e != null ? int.tryParse(e) : null,
              provider: p,
            );
          },
        ),
        GoRoute(
          path: '/settings',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const SettingsScreen(),
          routes: [
            GoRoute(path: 'appearance', builder: (context, state) => const AppearanceSettingsScreen()),
            GoRoute(
              path: 'account',
              builder: (context, state) => const AccountSettingsScreen(),
              routes: [
                GoRoute(path: 'edit-profile', builder: (context, state) => const EditProfileScreen()),
                GoRoute(path: 'change-password', builder: (context, state) => const ChangePasswordScreen()),
              ]
            ),
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
            GoRoute(path: 'parental-control', builder: (context, state) => const ParentalControlSettingsScreen()),
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
                localizationsDelegates: [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en', ''),
                  Locale('so', ''),
                ],
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

class _AnalyticsObserver extends NavigatorObserver {
  final AuthProvider auth;
  _AnalyticsObserver(this.auth);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logScreen(route);
  }

  void _logScreen(Route<dynamic> route) {
    if (route.settings.name != null) {
      _sendAnalytics(route.settings.name!);
    } else if (route is PageRoute) {
      // Try to get path from state if possible, or just use route type for now
      // This is a bit limited with GoRouter without a custom observer that has access to state
    }
  }

  Future<void> _sendAnalytics(String screenName) async {
    if (!auth.isAuthenticated || auth.token == null) return;
    try {
      await http.post(
        Uri.parse('${Constants.apiBaseUrl}/api/v1/analytics/usage'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
        body: jsonEncode({
          'screen': screenName,
          'feature': 'navigation',
        }),
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }
}

class MainScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

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
    // Removed redundant welcome notification check as it's now handled instantly in NotificationService
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
            label: 'home'.tr(context),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view_outlined),
            activeIcon: const Icon(Icons.grid_view),
            label: 'categories'.tr(context),
          ),
          if (downloadsEnabled)
            BottomNavigationBarItem(
              icon: const Icon(Icons.download_outlined),
              activeIcon: const Icon(Icons.download),
              label: 'downloads'.tr(context),
            ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search_outlined),
            activeIcon: const Icon(Icons.search),
            label: 'search'.tr(context),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: 'profile_title'.tr(context),
          ),
        ];

        return Scaffold(
          body: widget.navigationShell,
          bottomNavigationBar: BottomNavigationBar(
            items: items,
            currentIndex: _calculateSelectedIndex(downloadsEnabled),
            onTap: (index) => _onItemTapped(index, downloadsEnabled),
            type: BottomNavigationBarType.fixed,
          ),
        );
      },
    );
  }

  int _calculateSelectedIndex(bool downloadsEnabled) {
    int index = widget.navigationShell.currentIndex;
    if (!downloadsEnabled && index >= 2) {
      return index - 1;
    }
    return index;
  }

  void _onItemTapped(int index, bool downloadsEnabled) {
    int targetIndex = index;
    if (!downloadsEnabled && index >= 2) {
      targetIndex = index + 1;
    }

    // If the user clicks the current tab or home, force navigation to the branch root
    final bool isRootRequested = targetIndex == 0 || targetIndex == widget.navigationShell.currentIndex;

    widget.navigationShell.goBranch(targetIndex, initialLocation: isRootRequested);
  }
}
