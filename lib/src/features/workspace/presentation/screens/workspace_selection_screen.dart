import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/workspace/presentation/widgets/workspace_invite_notification_section.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
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
      body: workspacesAsync.when(
        data: (workspaces) {
          if (workspaces.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 72,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.workspaceSetupIncomplete,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.workspaceSetupIncompleteDesc,
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showJoinInviteDialog(context, ref),
                            icon: const Icon(Icons.key_outlined),
                            label: Text(l10n.joinByInviteCode),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              ref.invalidate(workspaceListProvider);
                              ref.invalidate(
                                myWorkspaceInviteNotificationsProvider,
                              );
                            },
                            child: Text(l10n.retry),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed('/workspace-create');
                            },
                            child: const Text('Create workspace'),
                          ),
                          FilledButton(
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
                            child: Text(l10n.signOutTitle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
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
            padding: const EdgeInsets.all(16),
            itemCount: workspaces.length,
            itemBuilder: (context, index) {
              final workspace = workspaces[index];
              final isOwner = workspace.ownerId == currentUser?.id;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(workspace.name[0].toUpperCase()),
                  ),
                  title: Text(workspace.name),
                  subtitle: Text(
                    isOwner ? l10n.ownerRole : l10n.roleValue(workspace.role),
                    style: TextStyle(
                      fontSize: 12,
                      color: isOwner ? Colors.green : Colors.blue,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Set active workspace and navigate to home
                    ref.read(activeWorkspaceIdProvider.notifier).state =
                        workspace.id;
                    Navigator.of(context).pushReplacementNamed(
                      '/workspace-detail',
                      arguments: workspace.id,
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(l10n.errorLoadingWorkspaces('$error')),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(workspaceListProvider);
                },
                child: Text(l10n.retry),
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
