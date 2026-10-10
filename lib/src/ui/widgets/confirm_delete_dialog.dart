// path: lib/src/ui/widgets/confirm_delete_dialog.dart

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_spacing.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final String? itemName;
  final String? consequence;
  final String? confirmLabel;

  const ConfirmDeleteDialog({
    super.key,
    this.title,
    this.message,
    this.itemName,
    this.consequence,
    this.confirmLabel,
  });

  static Future<bool> show(
    BuildContext context, {
    String? title,
    String? message,
    String? itemName,
    String? consequence,
    String? confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDeleteDialog(
        title: title,
        message: message,
        itemName: itemName,
        consequence: consequence,
        confirmLabel: confirmLabel,
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        title ??
            (itemName != null
                ? l10n.deleteItemTitle(itemName!)
                : l10n.confirmDelete),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message ??
                (itemName != null
                    ? l10n.deleteCannotBeUndone
                    : l10n.confirmDeleteTransaction),
          ),
          if (consequence != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              consequence!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
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
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(confirmLabel ?? l10n.delete),
        ),
      ],
    );
  }
}
