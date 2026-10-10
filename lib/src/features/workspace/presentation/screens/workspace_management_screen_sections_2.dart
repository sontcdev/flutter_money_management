part of 'workspace_management_screen.dart';

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
                    showAppSnackBar(
                      context,
                      l10n.inviteCodeCopied,
                      type: AppSnackBarType.success,
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
                    showAppSnackBar(
                      context,
                      l10n.inviteRevoked,
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
    final mutedColor = isDark
        ? AppColors.textLightSecondary
        : context.semanticColors.textFaint;
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
              showAppSnackBar(
                context,
                l10n.inviteCodeCopied,
                type: AppSnackBarType.success,
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
      color: context.semanticColors.warning,
    );
  }

  if (days <= 3) {
    return _InviteExpiryStatus(
      label: _inviteExpiryLabel(l10n, expiresAt),
      statusLabel: l10n.expiringSoonStatus,
      color: context.semanticColors.warning,
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
