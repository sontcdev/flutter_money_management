import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'data/api/api_client.dart';
import 'utils/app_logger.dart';
import 'utils/supabase_logging_http_client.dart';
import 'providers/providers.dart';
import 'i18n/locale_provider.dart';
import 'i18n/theme_provider.dart';
import 'config/supabase_config.dart';
import 'ui/widgets/app_lifecycle_sync_coordinator.dart';
import 'app/presentation/widgets/splash_view.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  SharedPreferences? _sharedPreferences;
  ApiClient? _apiClient;
  ThemeMode _themeMode = ThemeMode.light; // Default light mode

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    AppLogger.info('App bootstrap started', name: 'MM.App');

    final prefs = await SharedPreferences.getInstance();
    AppLogger.debug('SharedPreferences loaded', name: 'MM.App');
    final apiClient = ApiClient(
      baseUrl: SupabaseConfig.apiBaseUrl,
      prefs: prefs,
      httpClient: SupabaseLoggingHttpClient(),
    );

    if (mounted) {
      // Load theme mode from preferences
      final themeModeIndex = prefs.getInt('theme_mode');

      setState(() {
        _sharedPreferences = prefs;
        _apiClient = apiClient;
        if (themeModeIndex != null) {
          _themeMode = ThemeMode.values[themeModeIndex];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show the splash only while bootstrap is still running; the route gate
    // (SplashScreen) keeps showing the very same visual afterwards.
    if (_sharedPreferences == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashView(isDark: _themeMode == ThemeMode.dark),
      );
    }

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(_sharedPreferences!),
        supabaseClientProvider.overrideWithValue(_apiClient!),
        localeProvider
            .overrideWith((ref) => LocaleNotifier(_sharedPreferences!)),
        themeModeProvider
            .overrideWith((ref) => ThemeNotifier(_sharedPreferences!)),
        themeColorProvider
            .overrideWith((ref) => ThemeColorNotifier(_sharedPreferences!)),
        fontScaleProvider
            .overrideWith((ref) => FontScaleNotifier(_sharedPreferences!)),
      ],
      child: const AppLifecycleSyncCoordinator(
        child: MoneyManagementApp(),
      ),
    );
  }
}
