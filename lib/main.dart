import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'src/app_bootstrap.dart';
import 'src/utils/app_logger.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        AppLogger.error(
          'Flutter framework error',
          name: 'MM.App',
          error: details.exception,
          stackTrace: details.stack,
        );
        FlutterError.presentError(details);
      };

      PlatformDispatcher.instance.onError = (error, stackTrace) {
        AppLogger.error(
          'Unhandled platform error',
          name: 'MM.App',
          error: error,
          stackTrace: stackTrace,
        );
        return true;
      };

      AppLogger.info('Application startup', name: 'MM.App');

      runApp(const AppBootstrap());
    },
    (error, stackTrace) {
      AppLogger.error(
        'Uncaught zone exception',
        name: 'MM.App',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
