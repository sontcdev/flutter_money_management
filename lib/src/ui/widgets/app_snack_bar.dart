import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/app_semantic_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_surface_tokens.dart';

enum AppSnackBarType { info, success, error }

/// Foreground (message and undo action) readable on the actual snackbar
/// [fill]. Keeps [preferred] when it reaches 4.5:1; otherwise black or white,
/// whichever contrasts best.
Color snackBarForegroundOn(Color fill, {Color? preferred}) {
  if (preferred != null &&
      AppSurfaceTokens.contrast(preferred, fill) >= 4.5) {
    return preferred;
  }
  return AppSurfaceTokens.contrast(Colors.black, fill) >=
          AppSurfaceTokens.contrast(Colors.white, fill)
      ? Colors.black
      : Colors.white;
}

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
  final income = context.semanticColors.income;
  final (Color? background, Color? foreground) = switch (type) {
    AppSnackBarType.info => (null, null),
    AppSnackBarType.success => (income, snackBarForegroundOn(income)),
    AppSnackBarType.error => (
        colorScheme.error,
        snackBarForegroundOn(colorScheme.error, preferred: colorScheme.onError),
      ),
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
      duration: duration ??
          (resolvedAction != null
              ? const Duration(seconds: 6)
              : const Duration(seconds: 4)),
    ),
  );
}
