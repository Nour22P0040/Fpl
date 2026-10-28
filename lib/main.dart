import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'SigninScreen.dart';
import 'SignupScreen.dart';
import 'WelcomeScreen.dart';
import 'players_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FplApp());
}

class FplApp extends StatefulWidget {
  const FplApp({super.key});

  @override
  State<FplApp> createState() => _FplAppState();
}

class _FplAppState extends State<FplApp> {
  ThemeMode _themeMode = ThemeMode.light;

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
      // Start screen is Sign In
      GoRoute(
        path: '/',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) {
          final data = state.extra as Map<String, String>?;
          final managerName = data?['name'] ?? 'Manager';
          final team = data?['team'] ?? 'My Team';

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
    );
  }
}