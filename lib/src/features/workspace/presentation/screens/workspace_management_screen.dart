import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace_management_models.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_snack_bar.dart';
import 'package:flutter_money_management/src/ui/widgets/app_status_chip.dart';
import 'package:flutter_money_management/src/ui/widgets/confirm_delete_dialog.dart';
import 'package:flutter_money_management/src/ui/widgets/empty_state.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';

part 'workspace_management_screen_sections.dart';
part 'workspace_management_screen_sections_2.dart';

final _inviteEmailPattern = RegExp(
  r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$',
  caseSensitive: false,
);

class WorkspaceManagementScreen extends HookConsumerWidget {
  const WorkspaceManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeWorkspace = ref.watch(activeWorkspaceProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isOwner = ref.watch(isWorkspaceOwnerProvider);
    final canManageMembers = ref.watch(canManageWorkspaceMembersProvider);
    final canLeaveWorkspace = ref.watch(canLeaveWorkspaceProvider);
    final membersAsync = ref.watch(workspaceMembersProvider);
    final invitesAsync = ref.watch(workspacePendingInvitesProvider);
    final emailController = useTextEditingController();
    final isSubmitting = useState(false);
    final draftEmail = useState('');
    final normalizedEmail = draftEmail.value.trim().toLowerCase();
    final invalidEmail = normalizedEmail.isNotEmpty &&
        !_inviteEmailPattern.hasMatch(normalizedEmail);
    final duplicateMember = membersAsync.maybeWhen(
      data: (members) =>
          normalizedEmail.isNotEmpty &&
          members.any(
            (member) => member.email?.trim().toLowerCase() == normalizedEmail,
          ),
      orElse: () => false,
    );
    final duplicateInvite = invitesAsync.maybeWhen(
      data: (invites) =>
          normalizedEmail.isNotEmpty &&
          invites.any(
            (invite) =>
                invite.status == 'pending' &&
                invite.email.trim().toLowerCase() == normalizedEmail,
          ),
      orElse: () => false,
    );
    final existingInvite = invitesAsync.maybeWhen(
      data: (invites) {
        for (final invite in invites) {
          if (invite.status == 'pending' &&
              invite.email.trim().toLowerCase() == normalizedEmail) {
            return invite;
          }
        }
        return null;
      },
      orElse: () => null,
    );
    final inviteErrorText = duplicateMember
        ? l10n.workspaceInviteAlreadyMember
        : invalidEmail
            ? l10n.workspaceInviteInvalidEmail
            : duplicateInvite
                ? l10n.workspaceInviteAlreadyPending
                : null;

    Future<void> submitInvite() => _submitInvite(
          context: context,
          ref: ref,
          l10n: l10n,
          activeWorkspace: activeWorkspace,
          emailController: emailController,
          draftEmail: draftEmail,
          isSubmitting: isSubmitting,
          invalidEmail: invalidEmail,
          duplicateMember: duplicateMember,
          duplicateInvite: duplicateInvite,
        );

    Future<void> refreshInvite(WorkspaceInviteSummary invite) =>
        _refreshInvite(context, ref, l10n, isSubmitting, invite);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.workspaceManagement),
      ),
      body: activeWorkspace == null
          ? Center(
              child: Text(l10n.noActiveWorkspaceSelected),
            )
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(workspaceMembersProvider);
                ref.invalidate(workspacePendingInvitesProvider);
                await Future.wait([
                  ref.read(workspaceMembersProvider.future),
                  ref.read(workspacePendingInvitesProvider.future),
                ]);
              },
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  _WorkspaceSummaryCard(
                    activeWorkspace: activeWorkspace,
                    isOwner: isOwner,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (canManageMembers) ...[
                    _InviteMemberCard(
                      emailController: emailController,
                      draftEmail: draftEmail,
                      isSubmitting: isSubmitting,
                      inviteErrorText: inviteErrorText,
                      existingInvite: existingInvite,
                      duplicateMember: duplicateMember,
                      submitInvite: submitInvite,
                      refreshInvite: refreshInvite,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _InviteSection(invitesAsync: invitesAsync),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _MemberSection(
                    workspaceId: activeWorkspace.id,
                    canManageMembers: canManageMembers,
                    membersAsync: membersAsync,
                    currentUserId: currentUser?.id,
                    ownerId: activeWorkspace.ownerId,
                    isOwner: isOwner,
                  ),
                  if (canLeaveWorkspace) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _DangerZoneCard(
                      onLeaveWorkspace: () => _leaveWorkspace(
                        context,
                        ref,
                        l10n,
                        activeWorkspace,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _submitInvite({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required Workspace? activeWorkspace,
    required TextEditingController emailController,
    required ValueNotifier<String> draftEmail,
    required ValueNotifier<bool> isSubmitting,
    required bool invalidEmail,
    required bool duplicateMember,
    required bool duplicateInvite,
  }) async {
    final workspace = activeWorkspace;
    final email = emailController.text.trim();
    if (workspace == null ||
        email.isEmpty ||
        isSubmitting.value ||
        invalidEmail ||
        duplicateMember ||
        duplicateInvite) {
      return;
    }

    isSubmitting.value = true;
    try {
      final invite =
          await ref.read(workspaceManagementServiceProvider).createInvite(
                workspaceId: workspace.id,
                email: email,
              );
      emailController.clear();
      draftEmail.value = '';
      ref.invalidate(workspacePendingInvitesProvider);

      if (!context.mounted) {
        return;
      }

      await _showInviteCodeDialog(
        context: context,
        invite: invite,
        title: l10n.inviteCreated,
        message: l10n.shareInviteCodeWith(invite.email),
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
        action: 'create_invite',
        screen: 'workspace_management_screen',
        extraContext: {
          'workspace_id': workspace.id,
          'email_masked': ErrorReportHelper.maskEmail(email),
        },
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> _refreshInvite(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ValueNotifier<bool> isSubmitting,
    WorkspaceInviteSummary invite,
  ) async {
    if (isSubmitting.value) {
      return;
    }

    isSubmitting.value = true;
    try {
      final refreshedInvite = await ref
          .read(workspaceManagementServiceProvider)
          .refreshInvite(invite.id);
      ref.invalidate(workspacePendingInvitesProvider);

      if (!context.mounted) {
        return;
      }

      await _showInviteCodeDialog(
        context: context,
        invite: refreshedInvite,
        title: l10n.inviteRefreshed,
        message: l10n.shareNewInviteCodeWith(refreshedInvite.email),
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
        action: 'refresh_invite',
        screen: 'workspace_management_screen',
        extraContext: {
          'invite_id': invite.id,
        },
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> _leaveWorkspace(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Workspace activeWorkspace,
  ) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: l10n.leaveWorkspace,
      message: l10n.leaveWorkspaceConfirm,
      consequence: l10n.leaveWorkspaceDesc,
      confirmLabel: l10n.leave,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(workspaceManagementServiceProvider)
          .leaveWorkspace(activeWorkspace.id);
      ref.invalidate(workspaceListProvider);
      clearActiveWorkspace(ref);
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/workspace-selection',
          (route) => false,
        );
      }
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
        action: 'leave_workspace',
        screen: 'workspace_management_screen',
      );
    }
  }
}
