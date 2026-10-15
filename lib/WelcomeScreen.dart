import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Color fplPurple = Color(0xFF37003C);
const Color fplGreen = Color(0xFF00FF85);

// Changed from StartScreen to WelcomeScreen
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(Icons.sports_soccer, size: 56, color: fplPurple),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    );
  }
}