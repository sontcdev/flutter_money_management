// path: lib/src/utils/api_logger.dart

import 'package:flutter/foundation.dart';

/// API Logger utility for debugging
/// Provides formatted logging for API calls, responses, and errors
class ApiLogger {
  static const bool _enableLogging = kDebugMode; // Only log in debug mode

  /// Log API request
  static void logRequest(String method, String endpoint, {Map<String, dynamic>? data}) {
    if (!_enableLogging) return;
    
    debugPrint('');
    debugPrint('🔵 API REQUEST ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📍 $method $endpoint');
    if (data != null && data.isNotEmpty) {
      debugPrint('📦 Data: $data');
    }
    debugPrint('⏰ ${DateTime.now().toIso8601String()}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Log API response
  static void logResponse(String method, String endpoint, dynamic response, {int? statusCode}) {
    if (!_enableLogging) return;
    
    debugPrint('');
    debugPrint('🟢 API RESPONSE ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📍 $method $endpoint');
    if (statusCode != null) {
      debugPrint('📊 Status: $statusCode');
    }
    debugPrint('📦 Response: $response');
    debugPrint('⏰ ${DateTime.now().toIso8601String()}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Log API error
  static void logError(String method, String endpoint, dynamic error, {StackTrace? stackTrace}) {
    if (!_enableLogging) return;
    
    debugPrint('');
    debugPrint('🔴 API ERROR ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📍 $method $endpoint');
    debugPrint('❌ Error: $error');
    if (stackTrace != null) {
      debugPrint('📚 Stack trace:');
      debugPrint(stackTrace.toString());
    }
    debugPrint('⏰ ${DateTime.now().toIso8601String()}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Log general info
  static void logInfo(String message) {
    if (!_enableLogging) return;
    debugPrint('ℹ️  $message');
  }

  /// Log warning
  static void logWarning(String message) {
    if (!_enableLogging) return;
    debugPrint('⚠️  $message');
  }

  /// Log success
  static void logSuccess(String message) {
    if (!_enableLogging) return;
    debugPrint('✅ $message');
  }
}
