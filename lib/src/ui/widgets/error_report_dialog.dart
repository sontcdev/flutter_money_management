import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/data/repositories/supabase_error_mapper.dart';
import 'package:flutter_money_management/src/services/error_report_service.dart';
import 'package:flutter_money_management/src/ui/widgets/app_snack_bar.dart';

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
    final l10n = AppLocalizations.of(context)!;
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
        showAppSnackBar(
          context,
          l10n.errorReportSent,
          type: AppSnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        showAppSnackBar(
          context,
          _buildSubmitErrorMessage(l10n, e),
          type: AppSnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayError = SupabaseErrorMapper.map(widget.error);

    return AlertDialog(
      title: Text(l10n.notice),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.errorOccurred),
          const SizedBox(height: 8),
          Text(displayError.toString()),
        ],
      ),
      actions: [
        TextButton(
          onPressed:
              _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.ok),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submitReport,
          child: _isSubmitting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : Text(l10n.reportError),
        ),
      ],
    );
  }

  String _buildSubmitErrorMessage(AppLocalizations l10n, Object error) {
    if (error is SocketException) {
      return l10n.errorReportOffline;
    }

    if (error is http.ClientException) {
      final message = error.message.toLowerCase();
      if (message.contains('failed host lookup') ||
          message.contains('socketexception') ||
          message.contains('no address associated with hostname')) {
        return l10n.errorReportServerUnreachable;
      }
    }

    return l10n.errorReportFailed;
  }
}
