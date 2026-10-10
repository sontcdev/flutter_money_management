import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/models/account_deletion_exception.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';

class AccountDeletionDialog extends HookWidget {
  const AccountDeletionDialog({
    super.key,
    required this.onDelete,
    required this.onWebRequest,
  });

  final Future<void> Function() onDelete;
  final Future<void> Function() onWebRequest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = useTextEditingController();
    useListenable(controller);
    final busy = useState(false);
    final failed = useState(false);
    return PopScope(
      canPop: !busy.value,
      child: AlertDialog(
        title: Text(l10n.deleteAccount),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.deleteAccountConfirm),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: controller,
                enabled: !busy.value,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.deleteAccountTypeConfirmation,
                ),
              ),
              if (failed.value) ...[
                const SizedBox(height: AppSpacing.md),
                Text(l10n.deleteAccountFailed,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              if (busy.value) ...[
                const SizedBox(height: AppSpacing.lg),
                const LinearProgressIndicator(),
              ],
              TextButton(
                onPressed: busy.value ? null : onWebRequest,
                child: Text(l10n.deleteAccountWebRequest),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy.value ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: busy.value || controller.text != 'DELETE'
                ? null
                : () async {
                    busy.value = true;
                    failed.value = false;
                    try {
                      await onDelete();
                      if (context.mounted) Navigator.of(context).pop(true);
                    } on SharedWorkspaceMembershipException catch (e) {
                      if (context.mounted) Navigator.of(context).pop(e);
                    } catch (_) {
                      if (context.mounted) {
                        busy.value = false;
                        failed.value = true;
                      }
                    }
                  },
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
  }
}
