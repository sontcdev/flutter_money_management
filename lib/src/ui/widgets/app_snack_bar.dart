import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_spacing.dart';

enum AppSnackBarType { info, success, error }

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackBarType type = AppSnackBarType.info,
  VoidCallback? onUndo,
  SnackBarAction? action,
  Duration? duration,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context);
  final (Color? background, Color? foreground) = switch (type) {
    AppSnackBarType.info => (null, null),
    AppSnackBarType.success => (
        context.semanticColors.income,
        colorScheme.onPrimary,
      ),
    AppSnackBarType.error => (colorScheme.error, colorScheme.onError),
  };
  final resolvedAction = action ??
      (onUndo == null
          ? null
          : SnackBarAction(
              label: AppLocalizations.of(context)!.undo,
              textColor: foreground,
              onPressed: onUndo,
            ));

  messenger.hideCurrentSnackBar();
  return messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: foreground == null ? null : TextStyle(color: foreground),
      ),
      backgroundColor: background,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      action: resolvedAction,
      persist: false,
      duration: duration ??
          (resolvedAction != null
              ? const Duration(seconds: 6)
              : const Duration(seconds: 4)),
    ),
  );
}
