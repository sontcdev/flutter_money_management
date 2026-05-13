import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/src/data/repositories/supabase_error_mapper.dart';
import 'package:flutter_money_management/src/shared/providers/app_service_providers.dart';
import 'package:flutter_money_management/src/ui/widgets/error_report_dialog.dart';
import 'package:flutter_money_management/src/utils/app_logger.dart';

/// Helper class để xử lý và báo cáo lỗi API
class ErrorReportHelper {
  const ErrorReportHelper._();

  /// Kiểm tra xem lỗi có phải là API error không
  static bool isApiError(Object error) {
    if (SupabaseErrorMapper.isSupabaseException(error)) return true;

    // Exception wrapper có message chứa dấu hiệu remote
    if (error is Exception) {
      final message = error.toString().toLowerCase();
      return message.contains('failed to fetch') ||
          message.contains('failed to sync') ||
          message.contains('failed to load') ||
          message.contains('rpc') ||
          message.contains('supabase') ||
          message.contains('network') ||
          message.contains('connection');
    }

    return false;
  }

  /// Xử lý lỗi API và hiển thị dialog báo cáo
  static Future<void> handleApiError({
    required BuildContext context,
    required WidgetRef ref,
    required Object error,
    StackTrace? stackTrace,
    required String feature,
    required String action,
    String? screen,
    String? userMessage,
    Map<String, dynamic>? extraContext,
  }) async {
    // Log lỗi
    AppLogger.error(
      'API error in $feature.$action',
      name: 'MM.ErrorReport',
      error: error,
      stackTrace: stackTrace,
    );

    // Chỉ show dialog nếu là API error và context còn mounted
    if (!isApiError(error)) {
      debugPrint('Not an API error, skipping dialog: $error');
      return;
    }

    if (!context.mounted) {
      debugPrint('Context not mounted, skipping dialog');
      return;
    }

    // Build error context
    final errorContext = _buildErrorContext(
      feature: feature,
      action: action,
      screen: screen,
      extraContext: extraContext,
    );

    // Show error report dialog
    final errorReportService = ref.read(errorReportServiceProvider);

    await ErrorReportDialog.show(
      context: context,
      error: SupabaseErrorMapper.map(error),
      stackTrace: stackTrace,
      errorType: '$feature.$action',
      errorContext: errorContext,
      errorReportService: errorReportService,
    );
  }

  /// Build error context với metadata
  static Map<String, dynamic> _buildErrorContext({
    required String feature,
    required String action,
    String? screen,
    Map<String, dynamic>? extraContext,
  }) {
    final context = <String, dynamic>{
      'feature': feature,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (screen != null) {
      context['screen'] = screen;
    }

    if (extraContext != null) {
      // Sanitize sensitive data
      final sanitized = Map<String, dynamic>.from(extraContext);

      // Remove sensitive keys
      sanitized.remove('password');
      sanitized.remove('token');
      sanitized.remove('access_token');
      sanitized.remove('refresh_token');
      sanitized.remove('authorization');

      context.addAll(sanitized);
    }

    return context;
  }

  /// Mask email để không lộ thông tin đầy đủ
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) {
      return 'masked-email';
    }

    final localPart = parts.first;
    final domain = parts.last;

    if (localPart.isEmpty) {
      return '***@$domain';
    }

    final maskedLocal = localPart.length == 1
        ? '${localPart[0]}***'
        : '${localPart[0]}***${localPart[localPart.length - 1]}';

    return '$maskedLocal@$domain';
  }

  /// Hiển thị error report dialog (legacy method, prefer handleApiError)
  @Deprecated('Use handleApiError instead')
  static Future<bool?> showErrorDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Object error,
    StackTrace? stackTrace,
    String? errorType,
    Map<String, dynamic>? errorContext,
  }) {
    final errorReportService = ref.read(errorReportServiceProvider);

    return ErrorReportDialog.show(
      context: context,
      error: error,
      stackTrace: stackTrace,
      errorType: errorType,
      errorContext: errorContext,
      errorReportService: errorReportService,
    );
  }

  /// Xử lý lỗi và hiển thị dialog nếu cần (legacy method)
  @Deprecated('Use handleApiError instead')
  static Future<void> handleError({
    required BuildContext context,
    required WidgetRef ref,
    required Object error,
    StackTrace? stackTrace,
    String? errorType,
    Map<String, dynamic>? errorContext,
    bool showDialog = true,
  }) async {
    // Log lỗi ra console
    debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }

    // Hiển thị dialog nếu được yêu cầu
    if (showDialog && context.mounted) {
      await showErrorDialog(
        context: context,
        ref: ref,
        error: error,
        stackTrace: stackTrace,
        errorType: errorType,
        errorContext: errorContext,
      );
    }
  }
}
