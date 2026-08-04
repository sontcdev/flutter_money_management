import 'package:flutter/material.dart';

/// The single splash visual used by the whole startup sequence.
///
/// Both [AppBootstrap] (before the theme/providers exist) and [SplashScreen]
/// (the route gate) render this widget, so the user only ever sees one splash
/// even though startup goes through two phases.
class SplashView extends StatelessWidget {
  final bool isDark;

  const SplashView({super.key, required this.isDark});

  static const Color _darkBackground = Color(0xFF121212);
  static const Color _lightAccent = Color(0xFFE91E63);

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark ? _darkBackground : Colors.white;
    final accentColor = isDark ? Colors.white : _lightAccent;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon/icon.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
            const SizedBox(height: 16),
            Text(
              'MyMoney',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
