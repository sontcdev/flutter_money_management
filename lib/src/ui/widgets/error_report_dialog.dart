import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_money_management/src/data/repositories/supabase_error_mapper.dart';
import 'package:flutter_money_management/src/services/error_report_service.dart';

class ErrorReportDialog extends StatefulWidget {
  const ErrorReportDialog({
    super.key,
    required this.error,
    this.stackTrace,
    this.errorType,
    this.context,
    required this.errorReportService,
  });

  final Object error;
  final StackTrace? stackTrace;
  final String? errorType;
  final Map<String, dynamic>? context;
  final ErrorReportService errorReportService;

  static Future<bool?> show({
    required BuildContext context,
    required Object error,
    StackTrace? stackTrace,
    String? errorType,
    Map<String, dynamic>? errorContext,
    required ErrorReportService errorReportService,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorReportDialog(
        error: error,
        stackTrace: stackTrace,
        errorType: errorType,
        context: errorContext,
        errorReportService: errorReportService,
      ),
    );
  }

  @override
  State<ErrorReportDialog> createState() => _ErrorReportDialogState();
}

class _ErrorReportDialogState extends State<ErrorReportDialog> {
  bool _isSubmitting = false;

  Future<void> _submitReport() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.errorReportService.reportError(
        error: widget.error,
        stackTrace: widget.stackTrace,
        errorType: widget.errorType,
        context: widget.context,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi báo cáo lỗi thành công. Cảm ơn bạn!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_buildSubmitErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayError = SupabaseErrorMapper.map(widget.error);

    return AlertDialog(
      title: const Text('Thông báo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Đã có lỗi xảy ra'),
          const SizedBox(height: 8),
          Text(displayError.toString()),
        ],
      ),
      actions: [
        TextButton(
          onPressed:
              _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Đồng ý'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submitReport,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Phản ánh'),
        ),
      ],
    );
  }

  String _buildSubmitErrorMessage(Object error) {
    if (error is SocketException) {
      return 'Không thể gửi báo cáo vì thiết bị chưa kết nối mạng hoặc DNS không phân giải được máy chủ.';
    }

    if (error is http.ClientException) {
      final message = error.message.toLowerCase();
      if (message.contains('failed host lookup') ||
          message.contains('socketexception') ||
          message.contains('no address associated with hostname')) {
        return 'Không thể gửi báo cáo vì không kết nối được tới máy chủ Supabase. Hãy kiểm tra mạng hoặc cấu hình máy chủ.';
      }
    }

    return 'Không thể gửi báo cáo lúc này. Vui lòng thử lại sau.';
  }
}
