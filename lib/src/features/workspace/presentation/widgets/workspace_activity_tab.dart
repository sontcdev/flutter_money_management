import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/services/workspace_sync_helper.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/empty_state.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';

class WorkspaceActivityTab extends ConsumerWidget {
  const WorkspaceActivityTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activityAsync = ref.watch(workspaceActivityProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await syncCurrentWorkspaceData(ref);
        ref.invalidate(workspaceActivityProvider);
      },
      child: activityAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: EmptyState.compact(
                    icon: Icons.history_outlined,
                    title: l10n.noActivityYet,
                    message: l10n.noActivityYetDesc,
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = items[index];
              final actor =
                  item.actorDisplayName ?? item.actorEmail ?? l10n.unknown;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(actor.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(item.summary ?? item.action),
                  subtitle: Text(
                    l10n.activityByActorAt(
                      actor,
                      formatLocalizedDateTime(
                        context,
                        item.createdAt.toLocal(),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(l10n.errorWithMessage('$error'))),
      ),
    );
  }
}
