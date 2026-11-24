import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'SignupScreen.dart';
import 'WelcomeScreen.dart';
import 'players_screen.dart';
import 'favorite_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/buddies_screen.dart';
import 'screens/chat_screen.dart';
import 'services/presence_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    // Already initialized natively (e.g. after a hot restart): reuse it
    // instead of crashing before runApp().
    if (e.code != 'duplicate-app') rethrow;
  }

  // Returning (already signed-in) managers are online at launch
  if (FirebaseAuth.instance.currentUser != null) {
    PresenceService.start();
  }

  runApp(const FplApp());
}

class FplApp extends StatefulWidget {
  const FplApp({super.key});

  @override
  State<FplApp> createState() => _FplAppState();
}

class _FplAppState extends State<FplApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.light;

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

  /// Normal cases (user presses Home / comes back). Crashes and lost
  /// signal are covered by onDisconnect in PresenceService.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('App lifecycle: $state');
    if (state == AppLifecycleState.resumed) {
      PresenceService.setOnline();
    } else if (state == AppLifecycleState.paused) {
      PresenceService.setOffline();
    }
  }

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
    });
  }

  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      // App opens on Sign In; its "Sign up" link opens /signup
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) {
          final data = state.extra as Map<String, String>? ?? const {};
          final managerName = data['name'] ?? 'Manager';
          final team = data['team'] ?? 'My Team';

          return WelcomeScreen(
            name: managerName,
            teamName: team,
            onToggleTheme: _toggleTheme,
          );
        },
      ),
      GoRoute(
        path: '/players',
        builder: (context, state) => const PlayersScreen(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoriteScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/buddies',
        builder: (context, state) => const BuddiesScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final peer = state.extra as Map<String, String>;
          return ChatScreen(
            peerId: peer['peerId']!,
            peerName: peer['peerName']!,
          );
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF37003C)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF37003C),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
      // Make Android's bottom navigation bar follow the app theme,
      // otherwise it stays white in dark mode.
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            systemNavigationBarColor:
                isDark ? const Color(0xFF121212) : Colors.grey[100],
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
          child: child!,
        );
      },
    );
  }
}