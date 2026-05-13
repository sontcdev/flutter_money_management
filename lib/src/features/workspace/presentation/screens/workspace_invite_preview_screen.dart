import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/notifications/providers/notification_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';

class WorkspaceInvitePreviewScreen extends ConsumerStatefulWidget {
  const WorkspaceInvitePreviewScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<WorkspaceInvitePreviewScreen> createState() =>
      _WorkspaceInvitePreviewScreenState();
}

class _WorkspaceInvitePreviewScreenState
    extends ConsumerState<WorkspaceInvitePreviewScreen> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final previewAsync =
        ref.watch(workspaceInvitePreviewProvider(widget.token));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.joinWorkspace)),
      body: previewAsync.when(
        data: (preview) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  child:
                      Text(preview.workspaceName.substring(0, 1).toUpperCase()),
                ),
                title: Text(preview.workspaceName),
                subtitle: Text(preview.description ?? preview.workspaceType),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Members',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...preview.members.map(
              (member) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(
                    (member.displayName ?? member.email ?? '?')
                        .substring(0, 1)
                        .toUpperCase(),
                  ),
                ),
                title: Text(member.displayName ?? member.email ?? l10n.unknown),
                subtitle: Text(member.role),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSubmitting ? null : () => _acceptInvite(context),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.joinWorkspace),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(l10n.errorWithMessage('$error'))),
      ),
    );
  }

  Future<void> _acceptInvite(BuildContext context) async {
    if (_isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final workspaceId = await ref
          .read(workspaceManagementServiceProvider)
          .acceptInvite(widget.token);
      ref.read(activeWorkspaceIdProvider.notifier).state = workspaceId;
      ref.invalidate(workspaceListProvider);
      ref.invalidate(myNotificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
      ref.invalidate(myWorkspaceInviteNotificationsProvider);

      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/workspace-detail',
        (route) => route.settings.name == '/workspace-selection',
        arguments: workspaceId,
      );
    } catch (e, stackTrace) {
      if (!context.mounted) {
        return;
      }
      await ErrorReportHelper.handleApiError(
        context: context,
        ref: ref,
        error: e,
        stackTrace: stackTrace,
        feature: 'workspace',
        action: 'accept_invite_preview',
        screen: 'workspace_invite_preview_screen',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
