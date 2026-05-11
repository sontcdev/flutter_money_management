import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_money_management/src/models/error_report.dart';

class ErrorReportService {
  ErrorReportService(this._supabase);

  final SupabaseClient _supabase;

  /// Gửi báo cáo lỗi lên Supabase
  Future<String> submitErrorReport(ErrorReport report) async {
    final response = await _supabase.rpc(
      'create_error_report',
      params: {
        'p_error_type': report.errorType,
        'p_error_message': report.errorMessage,
        'p_stack_trace': report.stackTrace,
        'p_device_info': report.deviceInfo,
        'p_app_version': report.appVersion,
        'p_platform': report.platform,
        'p_context': report.context,
      },
    );

    return response as String;
  }

  /// Tạo và gửi báo cáo lỗi từ error object
  Future<String> reportError({
    required Object error,
    StackTrace? stackTrace,
    String? errorType,
    Map<String, dynamic>? context,
  }) async {
    final report = await ErrorReport.fromError(
      error: error,
      stackTrace: stackTrace,
      errorType: errorType,
      context: context,
    );

    return submitErrorReport(report);
  }
}
