import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'colors.dart';
import 'AppBackground.dart';

class WelcomeScreen extends StatelessWidget {
  final String name;
  final String teamName;
  final VoidCallback onToggleTheme;

  const WelcomeScreen({
    super.key,
    required this.name,
    required this.teamName,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fplPurple,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/'); // sign in route
            }
          },
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: fplGreen, width: 3),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/pl_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Welcome, $name!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      teamName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: fplGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Build your dream team. Win your mini-league.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 36),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: fplGreen,
                      foregroundColor: fplPurple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      context.push('/players');
                    },
                    child: const Text(
                      'Pick Your Squad',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onToggleTheme,
                    child: const Text('Toggle light / dark theme'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}