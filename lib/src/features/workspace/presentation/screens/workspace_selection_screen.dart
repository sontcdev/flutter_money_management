import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/workspace/presentation/widgets/workspace_invite_notification_section.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/utils/error_report_helper.dart';

/// Screen to select or create a workspace after authentication
class WorkspaceSelectionScreen extends ConsumerWidget {
  const WorkspaceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final workspacesAsync = ref.watch(workspaceListProvider);
    final currentUser = ref.watch(currentUserProvider);
    final inviteCount = ref.watch(myWorkspaceInviteCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectWorkspace),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create workspace',
            onPressed: () =>
                Navigator.of(context).pushNamed('/workspace-create'),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: inviteCount > 0,
              label: Text('$inviteCount'),
              child: const Icon(Icons.key_outlined),
            ),
            tooltip: l10n.joinByInviteCode,
            onPressed: () => _showJoinInviteDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final supabaseAuth = ref.read(supabaseAuthServiceProvider);
              await supabaseAuth.signOut();
              // Clear active workspace
              clearActiveWorkspace(ref);
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/sign-in');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(workspaceListProvider);
          ref.invalidate(myWorkspaceInviteNotificationsProvider);
          await ref.read(workspaceListProvider.future);
        },
        child: workspacesAsync.when(
          data: (workspaces) {
            final colorScheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final secondaryText = isDark
                ? AppColors.textLightSecondary
                : AppColors.textSecondary;
            final faintText =
                isDark ? AppColors.textLightFaint : AppColors.textFaint;

            if (workspaces.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            size: 36,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.workspaceSetupIncomplete,
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.workspaceSetupIncompleteDesc,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: secondaryText),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          alignment: WrapAlignment.center,
                          children: [
                            AppButton.outlined(
                              text: l10n.joinByInviteCode,
                              icon: Icons.key_outlined,
                              onPressed: () =>
                                  _showJoinInviteDialog(context, ref),
                            ),
                            AppButton.outlined(
                              text: l10n.retry,
                              onPressed: () {
                                ref.invalidate(workspaceListProvider);
                                ref.invalidate(
                                  myWorkspaceInviteNotificationsProvider,
                                );
                              },
                            ),
                            AppButton(
                              text: 'Create workspace',
                              onPressed: () {
                                Navigator.of(context)
                                    .pushNamed('/workspace-create');
                              },
                            ),
                            AppButton(
                              text: l10n.signOutTitle,
                              onPressed: () async {
                                final supabaseAuth =
                                    ref.read(supabaseAuthServiceProvider);
                                await supabaseAuth.signOut();
                                clearActiveWorkspace(ref);
                                if (context.mounted) {
                                  Navigator.of(context)
                                      .pushReplacementNamed('/sign-in');
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        const WorkspaceInviteNotificationSection(
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: workspaces.length,
              itemBuilder: (context, index) {
                final workspace = workspaces[index];
                final isOwner = workspace.ownerId == currentUser?.id;
                final initials = workspace.name.isNotEmpty
                    ? workspace.name[0].toUpperCase()
                    : '?';

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                      onTap: () {
                        // Set active workspace and navigate to home
                        ref.read(activeWorkspaceIdProvider.notifier).state =
                            workspace.id;
                        Navigator.of(context).pushReplacementNamed(
                          '/workspace-detail',
                          arguments: workspace.id,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initials,
                                style: textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    workspace.name,
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs / 2),
                                  Text(
                                    isOwner
                                        ? l10n.ownerRole
                                        : l10n.roleValue(workspace.role),
                                    style: textTheme.bodySmall
                                        ?.copyWith(color: faintText),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: faintText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.errorDark
                            : AppColors.error,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Text(
                          l10n.errorLoadingWorkspaces('$error'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        text: l10n.retry,
                        onPressed: () {
                          ref.invalidate(workspaceListProvider);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: null,
    );
  }

  Future<void> _showJoinInviteDialog(
      BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final parentContext = context;
    final controller = TextEditingController();
    var isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(l10n.joinWorkspace),
            content: TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.inviteCode,
                hintText: l10n.pasteWorkspaceInviteCode,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) async {
                await _acceptInvite(
                  dialogContext: context,
                  parentContext: parentContext,
                  ref: ref,
                  controller: controller,
                  isSubmitting: isSubmitting,
                  setSubmitting: (value) =>
                      setState(() => isSubmitting = value),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () => _acceptInvite(
                          dialogContext: context,
                          parentContext: parentContext,
                          ref: ref,
                          controller: controller,
                          isSubmitting: isSubmitting,
                          setSubmitting: (value) =>
                              setState(() => isSubmitting = value),
                        ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.join),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();
  }

  Future<void> _acceptInvite({
    required BuildContext dialogContext,
    required BuildContext parentContext,
    required WidgetRef ref,
    required TextEditingController controller,
    required bool isSubmitting,
    required void Function(bool value) setSubmitting,
  }) async {
    final token = controller.text.trim();
    if (token.isEmpty || isSubmitting) {
      return;
    }

    setSubmitting(true);
    try {
      if (!dialogContext.mounted || !parentContext.mounted) {
        return;
      }

      Navigator.of(dialogContext).pop();
      Navigator.of(parentContext).pushReplacementNamed(
        '/workspace-invite-preview',
        arguments: token,
      );
    } catch (e, stackTrace) {
      if (!dialogContext.mounted) {
        return;
      }

      await ErrorReportHelper.handleApiError(
        context: dialogContext,
        ref: ref,
        error: e,
        stackTrace: stackTrace,
        feature: 'workspace',
        action: 'accept_invite',
        screen: 'workspace_selection_screen',
        extraContext: {
          'token_length': token.length,
        },
      );
    } finally {
      setSubmitting(false);
    }
  }
}
