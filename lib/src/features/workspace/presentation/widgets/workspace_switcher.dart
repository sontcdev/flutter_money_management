import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';

/// Widget to display current workspace and allow switching
class WorkspaceSwitcher extends ConsumerWidget {
  const WorkspaceSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeWorkspace = ref.watch(activeWorkspaceProvider);
    final workspacesAsync = ref.watch(workspaceListProvider);

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
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  activeWorkspace?.name ?? l10n.selectWorkspace,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 20),
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
                      size: 20,
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
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
                            workspace.role,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
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
                  const Icon(Icons.settings, size: 20),
                  const SizedBox(width: 12),
                  Text(l10n.manageWorkspaces),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'manage') {
              Navigator.of(context).pushNamed('/workspace-management');
            } else {
              // Switch to selected workspace
              ref.read(activeWorkspaceIdProvider.notifier).state = value;

              // Refresh data after switching
              ref.invalidate(workspaceListProvider);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.switchedWorkspace(
                    workspaces.firstWhere((w) => w.id == value).name,
                  )),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
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
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
