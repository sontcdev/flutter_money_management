import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ErrorReport {
  const ErrorReport({
    required this.errorType,
    required this.errorMessage,
    this.stackTrace,
    this.deviceInfo,
    this.appVersion,
    this.platform,
    this.context,
  });

  final String errorType;
  final String errorMessage;
  final String? stackTrace;
  final Map<String, dynamic>? deviceInfo;
  final String? appVersion;
  final String? platform;
  final Map<String, dynamic>? context;

  Map<String, dynamic> toMap() {
    return {
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'device_info': deviceInfo,
      'app_version': appVersion,
      'platform': platform,
      'context': context,
    };
  }

  static Future<ErrorReport> fromError({
    required Object error,
    StackTrace? stackTrace,
    String? errorType,
    Map<String, dynamic>? context,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();
    
    return ErrorReport(
      errorType: errorType ?? error.runtimeType.toString(),
      errorMessage: error.toString(),
      stackTrace: stackTrace?.toString(),
      deviceInfo: await _getDeviceInfo(),
      appVersion: packageInfo.version,
      platform: _getPlatform(),
      context: context,
    );
  }

  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    return {
      'os': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
    };
  }

  static String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}
