import 'package:flutter/material.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';

/// The single splash visual used by the whole startup sequence.
///
/// Both [AppBootstrap] (before the theme/providers exist) and [SplashScreen]
/// (the route gate) render this widget, so the user only ever sees one splash
/// even though startup goes through two phases.
class SplashView extends StatelessWidget {
  final bool isDark;

  const SplashView({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isDark ? AppColors.splashBackgroundDark : AppColors.splashBackground;
    final accentColor =
        isDark ? AppColors.splashAccentDark : AppColors.splashAccent;

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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
