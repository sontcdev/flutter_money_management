import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/notifications/providers/notification_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/features/workspace/services/workspace_sync_helper.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_snack_bar.dart';

/// Widget to display current workspace and allow switching
class WorkspaceSwitcher extends ConsumerWidget {
  const WorkspaceSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeWorkspace = ref.watch(activeWorkspaceProvider);
    final workspacesAsync = ref.watch(workspaceListProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider).maybeWhen(
          data: (count) => count,
          orElse: () => 0,
        );

    return workspacesAsync.when(
      data: (workspaces) {
        if (workspaces.isEmpty) {
          return const SizedBox.shrink();
        }

        return PopupMenuButton<String>(
          tooltip: l10n.switchWorkspace,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium,
                  size: AppSpacing.iconSizeSm,
                  color: Theme.of(context).colorScheme.primary,
                ),
                if (unreadCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Badge(
                      label: Text('$unreadCount'),
                      child: const SizedBox(width: 1, height: 1),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  activeWorkspace?.name ?? l10n.selectWorkspace,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: AppSpacing.iconSizeSm),
              ],
            ),
          ),
          itemBuilder: (context) => [
            // Current workspaces
            ...workspaces.map((workspace) {
              final isActive = workspace.id == activeWorkspace?.id;
              return PopupMenuItem<String>(
                value: workspace.id,
                child: Row(
                  children: [
                    Icon(
                      isActive ? Icons.check_circle : Icons.circle_outlined,
                      size: AppSpacing.iconSizeSm,
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workspace.name,
                            style: TextStyle(
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          Text(
                            workspace.type == 'personal'
                                ? '${workspace.role} • personal'
                                : workspace.role,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const PopupMenuDivider(),

            // Manage workspaces
            PopupMenuItem<String>(
              value: 'manage',
              child: Row(
                children: [
                  const Icon(Icons.settings, size: AppSpacing.iconSizeSm),
                  const SizedBox(width: 12),
                  Text(l10n.manageWorkspaces),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'detail',
              child: Row(
                children: [
                  const Icon(
                    Icons.dashboard_customize_outlined,
                    size: AppSpacing.iconSizeSm,
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.workspaceDetail),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'create',
              child: Row(
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    size: AppSpacing.iconSizeSm,
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.createWorkspace),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'manage') {
              Navigator.of(context).pushNamed('/workspace-management');
            } else if (value == 'detail') {
              Navigator.of(context).pushNamed('/workspace-detail');
            } else if (value == 'create') {
              Navigator.of(context).pushNamed('/workspace-create');
            } else {
              // Switch to selected workspace
              ref.read(activeWorkspaceIdProvider.notifier).state = value;

              // Refresh data after switching: every core provider is
              // workspace-scoped, so keeping the old cache shows the previous
              // workspace's wallets/categories/transactions.
              ref.invalidate(workspaceListProvider);
              invalidateCoreDataProviders(ref);

              showAppSnackBar(
                context,
                l10n.switchedWorkspace(
                  workspaces.firstWhere((w) => w.id == value).name,
                ),
                duration: const Duration(seconds: 2),
              );
            }
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => IconButton(
        tooltip: l10n.retry,
        icon: Icon(
          Icons.cloud_off_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
        onPressed: () => ref.invalidate(workspaceListProvider),
      ),
    );
  }
}
