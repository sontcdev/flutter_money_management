import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace_management_models.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/ui/widgets/app_status_chip.dart';
import 'package:flutter_money_management/src/ui/widgets/empty_state.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';

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

    Future<void> submitInvite() async {
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

    Future<void> refreshInvite(WorkspaceInviteSummary invite) async {
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
                  AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            activeWorkspace.name.substring(0, 1).toUpperCase(),
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeWorkspace.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  AppStatusChip.info(
                                    label: isOwner
                                        ? l10n.ownerRole
                                        : l10n.roleValue(activeWorkspace.role),
                                  ),
                                  AppStatusChip(
                                    label: l10n.workspaceTypeValue(
                                      activeWorkspace.type,
                                    ),
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (canManageMembers) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.inviteMember,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(l10n.inviteMemberDesc),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            onChanged: (value) {
                              draftEmail.value = value;
                            },
                            decoration: InputDecoration(
                              labelText: l10n.memberEmail,
                              hintText: l10n.emailExample,
                              errorText: inviteErrorText,
                            ),
                            onSubmitted: (_) => submitInvite(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              spacing: AppSpacing.md,
                              runSpacing: AppSpacing.md,
                              alignment: WrapAlignment.end,
                              children: [
                                if (existingInvite != null && !duplicateMember)
                                  OutlinedButton.icon(
                                    onPressed: isSubmitting.value
                                        ? null
                                        : () => refreshInvite(existingInvite),
                                    icon: const Icon(Icons.refresh),
                                    label: Text(l10n.refreshInvite),
                                  ),
                                FilledButton.icon(
                                  onPressed: isSubmitting.value ||
                                          inviteErrorText != null
                                      ? null
                                      : submitInvite,
                                  icon: isSubmitting.value
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.person_add_alt_1),
                                  label: Text(l10n.createInvite),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                      onLeaveWorkspace: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.leaveWorkspace),
                            content: Text(l10n.leaveWorkspaceConfirm),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text(l10n.cancel),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                ),
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text(l10n.leave),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true || !context.mounted) {
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
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _DangerZoneCard extends StatelessWidget {
  const _DangerZoneCard({required this.onLeaveWorkspace});

  final VoidCallback onLeaveWorkspace;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      color: AppColors.expenseContainer.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dangerZone,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.leaveWorkspaceDesc),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            onPressed: onLeaveWorkspace,
            icon: const Icon(Icons.logout),
            label: Text(l10n.leaveWorkspace),
          ),
        ],
      ),
    );
  }
}

class _MemberSection extends ConsumerWidget {
  const _MemberSection({
    required this.workspaceId,
    required this.canManageMembers,
    required this.isOwner,
    required this.membersAsync,
    required this.currentUserId,
    required this.ownerId,
  });

  final String workspaceId;
  final bool canManageMembers;
  final bool isOwner;
  final AsyncValue<List<WorkspaceMemberSummary>> membersAsync;
  final String? currentUserId;
  final String ownerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: membersAsync.when(
        data: (members) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.membersSection,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (members.isEmpty)
              EmptyState.compact(
                icon: Icons.group_outlined,
                title: l10n.noMembersFound,
                message: l10n.noMembersFoundDesc,
              )
            else
              ...members.map(
                (member) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    foregroundImage: _avatarImage(member),
                    child: Text(_avatarLabel(context, member)),
                  ),
                  title: Text(_memberLabel(context, member)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_memberEmailLine(context, member)),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (member.userId == currentUserId)
                            AppStatusChip.info(label: l10n.youLabel),
                          if (member.userId == ownerId)
                            AppStatusChip.warning(label: l10n.ownerRole),
                          AppStatusChip.info(
                              label: l10n.roleValue(member.role)),
                          AppStatusChip.success(
                            label: l10n.statusValue(member.membershipStatus),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _memberJoinedLabel(context, member),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: _buildMemberActions(context, ref, member),
                ),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text(l10n.failedToLoadMembers('$error')),
      ),
    );
  }

  Widget? _buildMemberActions(
    BuildContext context,
    WidgetRef ref,
    WorkspaceMemberSummary member,
  ) {
    if (!canManageMembers ||
        member.userId == ownerId ||
        member.userId == currentUserId) {
      return null;
    }

    return IconButton(
      tooltip: AppLocalizations.of(context)!.removeMember,
      icon: const Icon(Icons.person_remove_outlined),
      onPressed: () => _confirmRemoveMember(context, ref, member),
    );
  }

  Future<void> _confirmRemoveMember(
    BuildContext context,
    WidgetRef ref,
    WorkspaceMemberSummary member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removeMember),
        content: Text(
          AppLocalizations.of(context)!.removeMemberConfirm(
            _memberLabel(context, member),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.removeMember),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref.read(workspaceManagementServiceProvider).removeMember(
            workspaceId: workspaceId,
            userId: member.userId,
          );
      ref.invalidate(workspaceMembersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.memberRemoved(
                _memberLabel(context, member),
              ),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      if (context.mounted) {
        await ErrorReportHelper.handleApiError(
          context: context,
          ref: ref,
          error: e,
          stackTrace: stackTrace,
          feature: 'workspace',
          action: 'remove_member',
          screen: 'workspace_management_screen',
          extraContext: {
            'workspace_id': workspaceId,
            'member_user_id': member.userId,
          },
        );
      }
    }
  }

  String _memberEmailLine(BuildContext context, WorkspaceMemberSummary member) {
    final l10n = AppLocalizations.of(context)!;
    return member.email?.trim().isNotEmpty == true
        ? member.email!
        : l10n.userIdValue(_shortId(member.userId));
  }

  String _memberJoinedLabel(
      BuildContext context, WorkspaceMemberSummary member) {
    final l10n = AppLocalizations.of(context)!;
    return member.joinedAt == null
        ? l10n.joinTimeUnavailable
        : l10n.joinedAt(
            formatLocalizedDateTime(context, member.joinedAt!.toLocal()),
          );
  }

  String _memberLabel(BuildContext context, WorkspaceMemberSummary member) {
    final displayName = member.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = member.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }

    return AppLocalizations.of(context)!
        .userShortLabel(_shortId(member.userId));
  }

  String _avatarLabel(BuildContext context, WorkspaceMemberSummary member) {
    final label = _memberLabel(context, member);
    return label.substring(0, 1).toUpperCase();
  }

  ImageProvider<Object>? _avatarImage(WorkspaceMemberSummary member) {
    final avatarUrl = member.avatarUrl?.trim();
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return null;
    }

    return NetworkImage(avatarUrl);
  }
}

class _InviteSection extends HookConsumerWidget {
  const _InviteSection({required this.invitesAsync});

  final AsyncValue<List<WorkspaceInviteSummary>> invitesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedStatus = useState('pending');
    final emailFilterController = useTextEditingController();
    final emailFilter = useState('');
    final sortOption = useState('newest');
    return AppCard(
      child: invitesAsync.when(
        data: (invites) {
          final pendingInvites =
              invites.where((invite) => invite.status == 'pending').toList();
          final declinedInvites =
              invites.where((invite) => invite.status == 'declined').toList();
          final revokedInvites =
              invites.where((invite) => invite.status == 'revoked').toList();
          final visibleInvites = switch (selectedStatus.value) {
            'declined' => declinedInvites,
            'revoked' => revokedInvites,
            _ => pendingInvites,
          };
          final normalizedFilter = emailFilter.value.trim().toLowerCase();
          final filteredInvites = visibleInvites.where((invite) {
            if (normalizedFilter.isEmpty) {
              return true;
            }

            return invite.email.toLowerCase().contains(normalizedFilter);
          }).toList()
            ..sort((a, b) {
              switch (sortOption.value) {
                case 'oldest':
                  return a.createdAt.compareTo(b.createdAt);
                case 'email':
                  return a.email.toLowerCase().compareTo(b.email.toLowerCase());
                default:
                  return b.createdAt.compareTo(a.createdAt);
              }
            });
          final sectionTitle = switch (selectedStatus.value) {
            'declined' => l10n.declinedInvites,
            'revoked' => l10n.revokedInvites,
            _ => l10n.pendingInvites,
          };
          final emptyLabel = switch (selectedStatus.value) {
            'declined' => l10n.noDeclinedInvites,
            'revoked' => l10n.noRevokedInvites,
            _ => l10n.noPendingInvites,
          };

          return DefaultTabController(
            length: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TabBar(
                  onTap: (index) {
                    selectedStatus.value = switch (index) {
                      1 => 'declined',
                      2 => 'revoked',
                      _ => 'pending',
                    };
                  },
                  tabs: [
                    Tab(
                      text: '${l10n.pendingInvites} (${pendingInvites.length})',
                    ),
                    Tab(
                      text:
                          '${l10n.declinedInvites} (${declinedInvites.length})',
                    ),
                    Tab(
                      text: '${l10n.revokedInvites} (${revokedInvites.length})',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 560;
                    final filterField = TextField(
                      controller: emailFilterController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        labelText: l10n.filterInvitesByEmail,
                        hintText: l10n.filterInvitesByEmailHint,
                        suffixIcon: emailFilter.value.isEmpty
                            ? null
                            : IconButton(
                                tooltip: l10n.clearFilter,
                                onPressed: () {
                                  emailFilterController.clear();
                                  emailFilter.value = '';
                                },
                                icon: const Icon(Icons.clear),
                              ),
                      ),
                      onChanged: (value) {
                        emailFilter.value = value;
                      },
                    );
                    final sortMenu = DropdownMenu<String>(
                      width: double.infinity,
                      initialSelection: sortOption.value,
                      label: Text(l10n.sortInvites),
                      dropdownMenuEntries: [
                        DropdownMenuEntry(
                          value: 'newest',
                          label: l10n.sortByNewest,
                        ),
                        DropdownMenuEntry(
                          value: 'oldest',
                          label: l10n.sortByOldest,
                        ),
                        DropdownMenuEntry(
                          value: 'email',
                          label: l10n.sortByEmail,
                        ),
                      ],
                      onSelected: (value) {
                        if (value != null) {
                          sortOption.value = value;
                        }
                      },
                    );
                    if (isWide) {
                      return Row(
                        children: [
                          Expanded(child: filterField),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: sortMenu),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        filterField,
                        const SizedBox(height: AppSpacing.md),
                        sortMenu,
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  sectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                if (filteredInvites.isEmpty)
                  EmptyState.compact(
                    icon: Icons.mark_email_unread_outlined,
                    title: emptyLabel,
                    message: l10n.noInvitesForCurrentFilter,
                  )
                else
                  ...filteredInvites.map(
                    (invite) => _InviteListTile(invite: invite),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text(l10n.failedToLoadInvites('$error')),
      ),
    );
  }
}

class _InviteListTile extends ConsumerWidget {
  const _InviteListTile({required this.invite});

  final WorkspaceInviteSummary invite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        foregroundImage: _inviteAvatarImage(invite),
        child: Text(_inviteAvatarLabel(invite)),
      ),
      title: Text(_inviteTitle(invite)),
      subtitle: _InviteSubtitle(invite: invite),
      isThreeLine: true,
      trailing: invite.status != 'pending'
          ? null
          : PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'copy') {
                  await Clipboard.setData(ClipboardData(text: invite.token));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.inviteCodeCopied)),
                    );
                  }
                  return;
                }

                if (value == 'refresh') {
                  try {
                    final refreshedInvite = await ref
                        .read(workspaceManagementServiceProvider)
                        .refreshInvite(invite.id);
                    ref.invalidate(workspacePendingInvitesProvider);
                    if (context.mounted) {
                      await _showInviteCodeDialog(
                        context: context,
                        invite: refreshedInvite,
                        title: l10n.inviteRefreshed,
                        message: l10n.shareNewInviteCodeWith(
                          refreshedInvite.email,
                        ),
                      );
                    }
                  } catch (e, stackTrace) {
                    if (context.mounted) {
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
                    }
                  }
                  return;
                }

                try {
                  await ref
                      .read(workspaceManagementServiceProvider)
                      .revokeInvite(invite.id);
                  ref.invalidate(workspacePendingInvitesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.inviteRevoked)),
                    );
                  }
                } catch (e, stackTrace) {
                  if (context.mounted) {
                    await ErrorReportHelper.handleApiError(
                      context: context,
                      ref: ref,
                      error: e,
                      stackTrace: stackTrace,
                      feature: 'workspace',
                      action: 'revoke_invite',
                      screen: 'workspace_management_screen',
                      extraContext: {
                        'invite_id': invite.id,
                      },
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'copy',
                  child: Text(l10n.copyCode),
                ),
                PopupMenuItem<String>(
                  value: 'refresh',
                  child: Text(l10n.refreshInvite),
                ),
                PopupMenuItem<String>(
                  value: 'revoke',
                  child: Text(l10n.revoke),
                ),
              ],
            ),
    );
  }
}

class _InviteSubtitle extends StatelessWidget {
  const _InviteSubtitle({required this.invite});

  final WorkspaceInviteSummary invite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor =
        isDark ? AppColors.textLightSecondary : AppColors.textFaint;
    if (invite.status == 'declined') {
      final declinedAt = invite.updatedAt ?? invite.createdAt;
      return _InviteStatusSubtitle(
        email: invite.email,
        statusLabel: l10n.declinedStatus,
        detailLabel: l10n.declinedAt(_formatInviteDateTime(declinedAt)),
        color: mutedColor,
      );
    }

    if (invite.status == 'revoked') {
      final revokedAt = invite.updatedAt ?? invite.createdAt;
      return _InviteStatusSubtitle(
        email: invite.email,
        statusLabel: l10n.revokedStatus,
        detailLabel: l10n.revokedAt(_formatInviteDateTime(revokedAt)),
        color: mutedColor,
      );
    }

    final expiryStatus = _inviteExpiryStatus(context, l10n, invite.expiresAt);

    return Text.rich(
      TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          TextSpan(text: '${invite.email}\n'),
          TextSpan(text: '${l10n.status}: '),
          TextSpan(
            text: '${expiryStatus.statusLabel}\n',
            style: TextStyle(
              color: expiryStatus.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: '${expiryStatus.label}\n',
            style: TextStyle(
              color: expiryStatus.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: '${l10n.inviteCode}: ${invite.token}'),
        ],
      ),
    );
  }
}

class _InviteStatusSubtitle extends StatelessWidget {
  const _InviteStatusSubtitle({
    required this.email,
    required this.statusLabel,
    required this.detailLabel,
    required this.color,
  });

  final String email;
  final String statusLabel;
  final String detailLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Text.rich(
      TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          TextSpan(text: '$email\n'),
          TextSpan(text: '${l10n.status}: '),
          TextSpan(
            text: '$statusLabel\n',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: detailLabel,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatInviteDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}

class _InviteExpiryStatus {
  const _InviteExpiryStatus({
    required this.label,
    required this.statusLabel,
    required this.color,
  });

  final String label;
  final String statusLabel;
  final Color color;
}

Future<void> _showInviteCodeDialog({
  required BuildContext context,
  required WorkspaceInviteSummary invite,
  required String title,
  required String message,
}) async {
  final l10n = AppLocalizations.of(context)!;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 12),
          SelectableText(
            invite.token,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
          ),
          const SizedBox(height: 12),
          Text(l10n.invitedUserJoinHint),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: invite.token));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.inviteCodeCopied)),
              );
            }
          },
          child: Text(l10n.copyCode),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    ),
  );
}

String _inviteTitle(WorkspaceInviteSummary invite) {
  final displayName = invite.matchedDisplayName?.trim();
  if (displayName != null && displayName.isNotEmpty) {
    return displayName;
  }

  return invite.email;
}

String _inviteAvatarLabel(WorkspaceInviteSummary invite) {
  final label = _inviteTitle(invite);
  return label.substring(0, 1).toUpperCase();
}

ImageProvider<Object>? _inviteAvatarImage(WorkspaceInviteSummary invite) {
  final avatarUrl = invite.matchedAvatarUrl?.trim();
  if (avatarUrl == null || avatarUrl.isEmpty) {
    return null;
  }

  return NetworkImage(avatarUrl);
}

String _inviteExpiryLabel(AppLocalizations l10n, DateTime expiresAt) {
  final now = DateTime.now();
  final localExpiry = expiresAt.toLocal();
  final difference = localExpiry.difference(now);

  if (difference.isNegative) {
    final days = difference.inDays.abs();
    if (days == 0) {
      return l10n.expiredToday;
    }
    if (days == 1) {
      return l10n.expiredOneDayAgo;
    }
    return l10n.expiredDaysAgo(days);
  }

  final days = difference.inDays;
  if (days == 0) {
    return l10n.expiresToday;
  }
  if (days == 1) {
    return l10n.expiresInOneDay;
  }
  return l10n.expiresInDays(days);
}

_InviteExpiryStatus _inviteExpiryStatus(
    BuildContext context, AppLocalizations l10n, DateTime expiresAt) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final now = DateTime.now();
  final localExpiry = expiresAt.toLocal();
  final difference = localExpiry.difference(now);

  if (difference.isNegative) {
    return _InviteExpiryStatus(
      label: _inviteExpiryLabel(l10n, expiresAt),
      statusLabel: l10n.expiredStatus,
      color: isDark ? AppColors.errorDark : AppColors.error,
    );
  }

  final days = difference.inDays;
  if (days <= 1) {
    return _InviteExpiryStatus(
      label: _inviteExpiryLabel(l10n, expiresAt),
      statusLabel: l10n.urgentStatus,
      color: isDark ? AppColors.warningDark : AppColors.warning,
    );
  }

  if (days <= 3) {
    return _InviteExpiryStatus(
      label: _inviteExpiryLabel(l10n, expiresAt),
      statusLabel: l10n.expiringSoonStatus,
      color: isDark ? AppColors.warningDark : AppColors.warning,
    );
  }

  return _InviteExpiryStatus(
    label: _inviteExpiryLabel(l10n, expiresAt),
    statusLabel: l10n.activeStatus,
    color: isDark ? AppColors.successDark : AppColors.success,
  );
}

String _shortId(String value) {
  if (value.length <= 8) {
    return value;
  }
  return '${value.substring(0, 8)}...';
}
