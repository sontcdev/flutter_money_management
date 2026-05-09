// path: lib/src/utils/api_logger.dart

import 'package:flutter/foundation.dart';

import 'app_logger.dart';

/// API Logger utility for debugging
/// Provides formatted logging for API calls, responses, and errors
class ApiLogger {
  static const bool _enableLogging = kDebugMode; // Only log in debug mode

  /// Log API request
  static void logRequest(String method, String endpoint,
      {Map<String, dynamic>? data}) {
    if (!_enableLogging) return;

    final hasData = data != null && data.isNotEmpty;
    AppLogger.debug(
      'Request $method $endpoint${hasData ? ' with payload' : ''}',
      name: 'MM.Api',
    );
  }

  /// Log API response
  static void logResponse(String method, String endpoint, dynamic response,
      {int? statusCode}) {
    if (!_enableLogging) return;

    final statusSuffix = statusCode != null ? ' status=$statusCode' : '';
    final responseSuffix = response == null ? '' : ' response received';
    AppLogger.debug(
      'Response $method $endpoint$statusSuffix$responseSuffix',
      name: 'MM.Api',
    );
  }

  /// Log API error
  static void logError(String method, String endpoint, dynamic error,
      {StackTrace? stackTrace}) {
    if (!_enableLogging) return;

    AppLogger.error(
      'Request failed $method $endpoint',
      name: 'MM.Api',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log general info
  static void logInfo(String message) {
    if (!_enableLogging) return;
    AppLogger.info(message, name: 'MM.Api');
  }

  /// Log warning
  static void logWarning(String message) {
    if (!_enableLogging) return;
    AppLogger.warn(message, name: 'MM.Api');
  }

  /// Log success
  static void logSuccess(String message) {
    if (!_enableLogging) return;
    AppLogger.info(message, name: 'MM.Api');
  }
}
