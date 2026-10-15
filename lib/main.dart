import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'SignupScreen.dart';
import 'WelcomeScreen.dart';
import 'players_screen.dart';

void main() {
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
      GoRoute(
        path: '/',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) {
          // 1. Extract the passed map values from SignupScreen
          final data = state.extra as Map<String, String>?;
          final managerName = data?['name'] ?? 'Manager';
          final team = data?['team'] ?? 'My Team';

          // 2. Pass them into the WelcomeScreen
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