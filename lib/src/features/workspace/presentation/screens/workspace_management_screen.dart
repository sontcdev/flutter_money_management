import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace_management_models.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';

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
            (invite) => invite.email.trim().toLowerCase() == normalizedEmail,
          ),
      orElse: () => false,
    );
    final existingInvite = invitesAsync.maybeWhen(
      data: (invites) {
        for (final invite in invites) {
          if (invite.email.trim().toLowerCase() == normalizedEmail) {
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
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.workspace_premium_outlined),
                      title: Text(activeWorkspace.name),
                      subtitle: Text(
                        isOwner
                            ? l10n.workspaceOwnerDescription
                            : l10n.roleValue(activeWorkspace.role),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isOwner) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.inviteMember,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.inviteMemberDesc,
                            ),
                            const SizedBox(height: 12),
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
                                border: const OutlineInputBorder(),
                                errorText: inviteErrorText,
                              ),
                              onSubmitted: (_) => submitInvite(),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                alignment: WrapAlignment.end,
                                children: [
                                  if (existingInvite != null &&
                                      !duplicateMember)
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
                    ),
                    const SizedBox(height: 16),
                    _InviteSection(invitesAsync: invitesAsync),
                    const SizedBox(height: 16),
                  ],
                  _MemberSection(
                    workspaceId: activeWorkspace.id,
                    isOwner: isOwner,
                    membersAsync: membersAsync,
                    currentUserId: currentUser?.id,
                    ownerId: activeWorkspace.ownerId,
                  ),
                ],
              ),
            ),
    );
  }
}

class _MemberSection extends ConsumerWidget {
  const _MemberSection({
    required this.workspaceId,
    required this.isOwner,
    required this.membersAsync,
    required this.currentUserId,
    required this.ownerId,
  });

  final String workspaceId;
  final bool isOwner;
  final AsyncValue<List<WorkspaceMemberSummary>> membersAsync;
  final String? currentUserId;
  final String ownerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: membersAsync.when(
          data: (members) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.membersSection,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (members.isEmpty)
                Text(l10n.noMembersFound)
              else
                ...members.map(
                  (member) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      foregroundImage: _avatarImage(member),
                      child: Text(_avatarLabel(context, member)),
                    ),
                    title: Text(
                        _memberTitle(context, member, ownerId, currentUserId)),
                    subtitle: Text(_memberSubtitle(context, member)),
                    isThreeLine: true,
                    trailing: member.userId == currentUserId
                        ? Chip(label: Text(l10n.youLabel))
                        : _buildMemberActions(context, ref, member),
                  ),
                ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(l10n.failedToLoadMembers('$error')),
        ),
      ),
    );
  }

  Widget? _buildMemberActions(
    BuildContext context,
    WidgetRef ref,
    WorkspaceMemberSummary member,
  ) {
    if (!isOwner ||
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

  String _memberTitle(
    BuildContext context,
    WorkspaceMemberSummary member,
    String ownerId,
    String? currentUserId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final label = _memberLabel(context, member);
    if (member.userId == currentUserId) {
      return member.userId == ownerId
          ? l10n.memberOwnerYouLabel(label)
          : l10n.memberYouLabel(label);
    }
    return member.userId == ownerId ? l10n.memberOwnerLabel(label) : label;
  }

  String _memberSubtitle(BuildContext context, WorkspaceMemberSummary member) {
    final l10n = AppLocalizations.of(context)!;
    final joinedLabel = member.joinedAt == null
        ? l10n.joinTimeUnavailable
        : l10n.joinedAt(member.joinedAt!.toLocal().toString());
    final emailLine = member.email?.trim().isNotEmpty == true
        ? member.email!
        : l10n.userIdValue(_shortId(member.userId));
    return '$emailLine\n${l10n.roleValue(member.role)} • ${l10n.statusValue(member.membershipStatus)}\n$joinedLabel';
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

class _InviteSection extends ConsumerWidget {
  const _InviteSection({required this.invitesAsync});

  final AsyncValue<List<WorkspaceInviteSummary>> invitesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: invitesAsync.when(
          data: (invites) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.pendingInvites,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (invites.isEmpty)
                Text(l10n.noPendingInvites)
              else
                ...invites.map(
                  (invite) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      foregroundImage: _inviteAvatarImage(invite),
                      child: Text(_inviteAvatarLabel(invite)),
                    ),
                    title: Text(_inviteTitle(invite)),
                    subtitle: _InviteSubtitle(invite: invite),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'copy') {
                          await Clipboard.setData(
                              ClipboardData(text: invite.token));
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
                  ),
                ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(l10n.failedToLoadInvites('$error')),
        ),
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
    final expiryStatus = _inviteExpiryStatus(l10n, invite.expiresAt);

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
    AppLocalizations l10n, DateTime expiresAt) {
  final now = DateTime.now();
  final localExpiry = expiresAt.toLocal();
  final difference = localExpiry.difference(now);

  if (difference.isNegative) {
    return _InviteExpiryStatus(
      label: _inviteExpiryLabel(l10n, expiresAt),
      statusLabel: l10n.expiredStatus,
      color: Colors.red,
    );
  }

  final days = difference.inDays;
  if (days <= 1) {
    return _InviteExpiryStatus(
      label: _inviteExpiryLabel(l10n, expiresAt),
      statusLabel: l10n.urgentStatus,
      color: Colors.orange,
    );
  }

  if (days <= 3) {
    return _InviteExpiryStatus(
      label: _inviteExpiryLabel(l10n, expiresAt),
      statusLabel: l10n.expiringSoonStatus,
      color: Colors.amber.shade800,
    );
  }

  return _InviteExpiryStatus(
    label: _inviteExpiryLabel(l10n, expiresAt),
    statusLabel: l10n.activeStatus,
    color: Colors.green,
  );
}

String _shortId(String value) {
  if (value.length <= 8) {
    return value;
  }
  return '${value.substring(0, 8)}...';
}
