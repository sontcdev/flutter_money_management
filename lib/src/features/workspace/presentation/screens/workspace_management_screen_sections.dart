part of 'workspace_management_screen.dart';

class _WorkspaceSummaryCard extends StatelessWidget {
  const _WorkspaceSummaryCard({
    required this.activeWorkspace,
    required this.isOwner,
  });

  final Workspace activeWorkspace;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusCard),
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
    );
  }
}

class _InviteMemberCard extends StatelessWidget {
  const _InviteMemberCard({
    required this.emailController,
    required this.draftEmail,
    required this.isSubmitting,
    required this.inviteErrorText,
    required this.existingInvite,
    required this.duplicateMember,
    required this.submitInvite,
    required this.refreshInvite,
  });

  final TextEditingController emailController;
  final ValueNotifier<String> draftEmail;
  final ValueNotifier<bool> isSubmitting;
  final String? inviteErrorText;
  final WorkspaceInviteSummary? existingInvite;
  final bool duplicateMember;
  final Future<void> Function() submitInvite;
  final Future<void> Function(WorkspaceInviteSummary invite) refreshInvite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final existingInvite = this.existingInvite;
    return AppCard(
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
    );
  }
}

class _InviteFilterBar extends StatelessWidget {
  const _InviteFilterBar({
    required this.emailFilterController,
    required this.emailFilter,
    required this.sortOption,
  });

  final TextEditingController emailFilterController;
  final ValueNotifier<String> emailFilter;
  final ValueNotifier<String> sortOption;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
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
      color: context.semanticColors.expenseContainer.withValues(alpha: 0.45),
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

  Future<void> _showRolesInfo(BuildContext context, AppLocalizations l10n) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.workspaceRolesTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.workspaceRoleOwnerDesc),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.workspaceRoleAdminDesc),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.workspaceRoleMemberDesc),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: membersAsync.when(
        data: (members) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.membersSection,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.workspaceRolesTitle,
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _showRolesInfo(context, l10n),
                ),
              ],
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: l10n.removeMember,
      message: l10n.removeMemberConfirm(_memberLabel(context, member)),
      confirmLabel: l10n.removeMember,
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      await ref.read(workspaceManagementServiceProvider).removeMember(
            workspaceId: workspaceId,
            userId: member.userId,
          );
      ref.invalidate(workspaceMembersProvider);
      if (context.mounted) {
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.memberRemoved(
            _memberLabel(context, member),
          ),
          type: AppSnackBarType.success,
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
                _InviteFilterBar(
                  emailFilterController: emailFilterController,
                  emailFilter: emailFilter,
                  sortOption: sortOption,
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
