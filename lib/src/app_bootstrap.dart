import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'providers/providers.dart';
import 'i18n/locale_provider.dart';
import 'i18n/theme_provider.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  SharedPreferences? _sharedPreferences;
  bool _minDurationPassed = false;
  Color _themeColor = const Color(0xFF4CAF50); // Default green
  ThemeMode _themeMode = ThemeMode.light; // Default light mode

  @override
  void initState() {
    super.initState();
    _init();
    _enforceMinimumSplashDuration();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      // Load theme color from preferences
      final colorValue = prefs.getInt('theme_color');
      // Load theme mode from preferences
      final themeModeIndex = prefs.getInt('theme_mode');
      
      setState(() {
        _sharedPreferences = prefs;
        if (colorValue != null) {
          _themeColor = Color(colorValue);
        }
        if (themeModeIndex != null) {
          _themeMode = ThemeMode.values[themeModeIndex];
        }
      });
    }
  }

  Future<void> _enforceMinimumSplashDuration() async {
    // Ensure splash screen is shown for at least 1.5 seconds
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _minDurationPassed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen until both initialization is complete AND minimum duration has passed
    if (_sharedPreferences == null || !_minDurationPassed) {
      // Determine background color based on theme mode
      final backgroundColor = _themeMode == ThemeMode.dark 
          ? const Color(0xFF121212) // Dark background
          : Colors.white; // Light background
      
      // Determine loading indicator and text color based on theme mode
      final accentColor = _themeMode == ThemeMode.dark 
          ? Colors.white // White for dark mode
          : const Color(0xFFE91E63); // Pink for light mode
      
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: backgroundColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon
                Image.asset(
                  'assets/icon/icon.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 32),
                // Loading Indicator
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
                const SizedBox(height: 16),
                Text(
                  'MoneyWise',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(_sharedPreferences!),
        localeProvider.overrideWith((ref) => LocaleNotifier(_sharedPreferences!)),
        themeModeProvider.overrideWith((ref) => ThemeNotifier(_sharedPreferences!)),
        themeColorProvider.overrideWith((ref) => ThemeColorNotifier(_sharedPreferences!)),
      ],
      child: const MoneyManagementApp(),
    );
  }
}
