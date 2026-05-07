import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum AppLogLevel {
  debug(500),
  info(800),
  warn(900),
  error(1000);

  const AppLogLevel(this.value);

  final int value;
}

class AppLogger {
  const AppLogger._();

  static bool get _isVerboseEnabled => kDebugMode || kProfileMode;

  static void debug(
    String message, {
    required String name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_isVerboseEnabled) return;
    _log(
      AppLogLevel.debug,
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void info(
    String message, {
    required String name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_isVerboseEnabled) return;
    _log(
      AppLogLevel.info,
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void warn(
    String message, {
    required String name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      AppLogLevel.warn,
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(
    String message, {
    required String name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      AppLogLevel.error,
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _log(
    AppLogLevel level,
    String message, {
    required String name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name,
      level: level.value,
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }
}
