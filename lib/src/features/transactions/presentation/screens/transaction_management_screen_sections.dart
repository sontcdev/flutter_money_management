part of 'transaction_management_screen.dart';

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.onSelectAll,
    required this.onDeselectAll,
  });

  final int count;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          Text(
            l10n.selectedCount(count),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.select_all),
            label: Text(l10n.selectAll),
            onPressed: onSelectAll,
          ),
          TextButton.icon(
            icon: const Icon(Icons.deselect),
            label: Text(l10n.deselectAll),
            onPressed: onDeselectAll,
          ),
        ],
      ),
    );
  }
}

class _ManagementEmptyState extends StatelessWidget {
  const _ManagementEmptyState({
    required this.hasFilter,
    required this.onClearFilter,
  });

  final bool hasFilter;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final emptyState = hasFilter
        ? EmptyState.noSearchResult(
            icon: Icons.search_off,
            title: l10n.noTransactionsMatch,
            message: l10n.adjustSearchTerms,
            actionLabel: l10n.clearFilter,
            actionIcon: Icons.filter_alt_off,
            onAction: onClearFilter,
            compact: true,
          )
        : EmptyState(
            icon: Icons.receipt_long,
            title: l10n.noTransactions,
            message: l10n.onboardingSubtitle,
            actionLabel: l10n.addTransaction,
            onAction: () {
              Navigator.pushNamed(context, '/add-transaction');
            },
            compact: true,
          );
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: emptyState,
        ),
      ],
    );
  }
}

class _TransactionRowsList extends StatelessWidget {
  const _TransactionRowsList({
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.md,
      ),
      children: [
        AppCard(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              for (var i = 0; i < itemCount; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: Theme.of(context).dividerColor,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                itemBuilder(i),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectionModeToggle extends StatelessWidget {
  const _SelectionModeToggle({
    required this.isSelectionMode,
    required this.onPressed,
  });

  final bool isSelectionMode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      icon: Icon(isSelectionMode ? Icons.close : Icons.checklist),
      onPressed: onPressed,
      tooltip: isSelectionMode ? l10n.cancel : l10n.selectAll,
    );
  }
}
