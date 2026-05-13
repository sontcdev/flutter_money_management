import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';

class WorkspaceActivityTab extends ConsumerWidget {
  const WorkspaceActivityTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activityAsync = ref.watch(workspaceActivityProvider);

    return activityAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(child: Text('No activity yet'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            final actor =
                item.actorDisplayName ?? item.actorEmail ?? l10n.unknown;
            return ListTile(
              leading: CircleAvatar(
                  child: Text(actor.substring(0, 1).toUpperCase())),
              title: Text(item.summary ?? item.action),
              subtitle: Text('$actor • ${item.createdAt.toLocal()}'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(l10n.errorWithMessage('$error'))),
    );
  }
}
