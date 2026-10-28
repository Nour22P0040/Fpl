import 'package:flutter/material.dart';
import 'colors.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/app_bg.png', fit: BoxFit.cover),
        // Dark purple overlay so white text stays readable
        Container(color: fplPurple.withValues(alpha: 0.55)),
        child,
      ],
    );
  }
}