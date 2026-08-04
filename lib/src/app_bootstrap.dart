import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
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
  ThemeMode _themeMode = ThemeMode.light; // Default light mode

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    AppLogger.info('App bootstrap started', name: 'MM.App');

    // Initialize Supabase if configured
    if (SupabaseConfig.isConfigured) {
      try {
        AppLogger.info('Supabase initialization started', name: 'MM.App');
        await Supabase.initialize(
          url: SupabaseConfig.supabaseUrl,
          anonKey: SupabaseConfig.supabaseAnonKey,
          httpClient: SupabaseLoggingHttpClient(),
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
          ),
          debug: true, // Enable debug logging for API calls
        );
        AppLogger.info('Supabase initialization succeeded', name: 'MM.App');
      } catch (e, stackTrace) {
        // Log error but continue - app can work in local-only mode
        AppLogger.warn(
          'Supabase initialization failed, continuing in local-only mode',
          name: 'MM.App',
          error: e,
          stackTrace: stackTrace,
        );
      }
    } else {
      AppLogger.warn('Supabase is not configured', name: 'MM.App');
    }

    final prefs = await SharedPreferences.getInstance();
    AppLogger.debug('SharedPreferences loaded', name: 'MM.App');

    if (mounted) {
      // Load theme mode from preferences
      final themeModeIndex = prefs.getInt('theme_mode');

      setState(() {
        _sharedPreferences = prefs;
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
