import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace_management_models.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_section_header.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';

class WorkspaceInviteNotificationSection extends ConsumerWidget {
  const WorkspaceInviteNotificationSection({
    super.key,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.screenPadding,
    ),
    this.showWhenEmpty = false,
  });

  final EdgeInsets padding;
  final bool showWhenEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final invitesAsync = ref.watch(myWorkspaceInviteNotificationsProvider);

    return Padding(
      padding: padding,
      child: invitesAsync.when(
        data: (invites) {
          if (invites.isEmpty && !showWhenEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                title: l10n.notification,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.md),
              if (invites.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Text(l10n.noWorkspaceInviteNotifications),
                  ),
                )
              else
                ...invites.map(
                  (invite) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _InviteNotificationCard(invite: invite),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Text(l10n.errorWithMessage('$error')),
          ),
        ),
      ),
    );
  }
}

class _InviteNotificationCard extends ConsumerStatefulWidget {
  const _InviteNotificationCard({required this.invite});

  final WorkspaceInviteNotification invite;

  @override
  ConsumerState<_InviteNotificationCard> createState() =>
      _InviteNotificationCardState();
}

class _InviteNotificationCardState
    extends ConsumerState<_InviteNotificationCard> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final invite = widget.invite;
    final invitedBy = invite.invitedByDisplayName ?? invite.invitedByEmail;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    Icons.group_add_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.workspaceInviteMessage(invite.workspaceName),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (invitedBy != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.workspaceInviteFrom(invitedBy),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _acceptInvite,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.join),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : _declineInvite,
                      child: Text(l10n.declineInvite),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptInvite() async {
    if (_isSubmitting) {
      return;
    }

    final context = this.context;
    try {
      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pushNamed(
        '/workspace-invite-preview',
        arguments: widget.invite.token,
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
        action: 'accept_invite_notification',
        screen: 'workspace_invite_notification_section',
        extraContext: {
          'invite_id': widget.invite.id,
          'workspace_id': widget.invite.workspaceId,
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _declineInvite() async {
    if (_isSubmitting) {
      return;
    }

    final context = this.context;
    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(workspaceManagementServiceProvider)
          .declineInvite(widget.invite.token);
      ref.invalidate(myWorkspaceInviteNotificationsProvider);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.inviteDeclined),
        ),
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
        action: 'decline_invite_notification',
        screen: 'workspace_invite_notification_section',
        extraContext: {
          'invite_id': widget.invite.id,
          'workspace_id': widget.invite.workspaceId,
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
