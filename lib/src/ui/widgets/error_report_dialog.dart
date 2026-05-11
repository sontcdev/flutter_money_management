import 'package:flutter/material.dart';
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
            content: Text('Không thể gửi báo cáo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đã xảy ra lỗi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ứng dụng gặp lỗi không mong muốn. Bạn có muốn gửi báo cáo lỗi để giúp chúng tôi cải thiện ứng dụng không?',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.error.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
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

}
