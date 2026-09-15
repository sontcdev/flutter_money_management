// path: lib/src/ui/widgets/confirm_delete_dialog.dart

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_spacing.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String? title;
  final String? message;

  const ConfirmDeleteDialog({
    super.key,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(title ?? l10n.confirmDelete),
      content: Text(message ?? l10n.confirmDeleteTransaction),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            l10n.cancel,
            style: TextStyle(
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: Text(l10n.delete),
        ),
      ],
    );
  }
}
