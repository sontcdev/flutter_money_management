part of 'transactions_screen.dart';

class _TransactionGroup extends StatelessWidget {
  final DateTime date;
  final List<Transaction> transactions;
  final Map<String, Category> categoryMap;
  final Map<String, Wallet> walletMap;
  final Future<bool> Function(Transaction, DismissDirection) confirmSwipe;
  final ValueChanged<Transaction> onDelete;

  const _TransactionGroup({
    required this.date,
    required this.transactions,
    required this.categoryMap,
    required this.walletMap,
    required this.confirmSwipe,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String dateLabel;
    if (date == today) {
      dateLabel = l10n.today;
    } else if (date == yesterday) {
      dateLabel = l10n.yesterday;
    } else {
      dateLabel = formatLocalizedFullDate(context, date);
    }

    // Calculate net total for the day (matches mockup's single net-amount label)
    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold<int>(0, (sum, t) => sum + t.amountCents);

    final totalExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<int>(0, (sum, t) => sum + t.amountCents);

    final net = totalIncome - totalExpense;
    final netColor = net < 0
        ? context.semanticColors.expense
        : net > 0
            ? context.semanticColors.income
            : null;
    final netLabel = net == 0
        ? ''
        : ' · ${net > 0 ? '+' : ''}${CurrencyFormatter.formatVNDFromCents(net, locale: l10n.localeName)}';

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date label with income/expense summary chips
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.sm,
            ),
            child: Text.rich(
              TextSpan(
                text: dateLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
                children: [
                  if (netLabel.isNotEmpty)
                    TextSpan(
                      text: netLabel,
                      style: TextStyle(color: netColor),
                    ),
                ],
              ),
            ),
          ),

          // Transactions grouped in a rounded, bordered card (matches design)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            child: AppCard(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (var i = 0; i < transactions.length; i++) ...[
                    Builder(builder: (context) {
                      final transaction = transactions[i];
                      final category = categoryMap[transaction.categoryId];
                      final isTransfer =
                          transaction.type == TransactionType.transfer;
                      // Transfers have no category: label them "from -> to".
                      final fromWallet = walletMap[transaction.walletId];
                      final toWallet = walletMap[transaction.toWalletId];

                      final item = TransactionItem(
                        transaction: transaction,
                        categoryName: isTransfer
                            ? '${fromWallet?.name ?? l10n.unknown} → '
                                '${toWallet?.name ?? l10n.unknown}'
                            : category?.name ?? l10n.unknown,
                        categoryIconName:
                            isTransfer ? null : category?.iconName,
                        categoryIcon: isTransfer ? Icons.swap_horiz : null,
                        categoryColor: isTransfer
                            ? Theme.of(context).colorScheme.primary
                            : category != null
                                ? getCategoryColor(category.colorValue)
                                : null,
                        showDate: true, // Show date in subtitle
                        showChevron: true,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/transaction-detail',
                            arguments: transaction.id,
                          );
                        },
                      );
                      return Dismissible(
                        key: ValueKey(transaction.id),
                        background: _SwipeBackground(
                          icon: Icons.edit_outlined,
                          label: l10n.edit,
                          color: theme.colorScheme.primary,
                          foreground: theme.colorScheme.onPrimary,
                          alignment: Alignment.centerLeft,
                        ),
                        secondaryBackground: _SwipeBackground(
                          icon: Icons.delete_outline,
                          label: l10n.delete,
                          color: theme.colorScheme.error,
                          foreground: theme.colorScheme.onError,
                          alignment: Alignment.centerRight,
                        ),
                        confirmDismiss: (direction) =>
                            confirmSwipe(transaction, direction),
                        onDismissed: (_) => onDelete(transaction),
                        child: item,
                      );
                    }),
                    if (i != transactions.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        child: Divider(
                          height: 1,
                          color: theme.dividerColor,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color foreground;
  final Alignment alignment;

  const _SwipeBackground({
    required this.icon,
    required this.label,
    required this.color,
    required this.foreground,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      autofocus: true,
      decoration: InputDecoration(
        hintText: l10n.search,
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      onChanged: onChanged,
    );
  }
}

class _SearchToggleButton extends StatelessWidget {
  const _SearchToggleButton({
    required this.showSearch,
    required this.onPressed,
  });

  final bool showSearch;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          tooltip: showSearch ? l10n.close : l10n.search,
          icon: Icon(showSearch ? Icons.close : Icons.search),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _TransactionFilterBar extends StatelessWidget {
  const _TransactionFilterBar({
    required this.selectedValue,
    required this.onChanged,
  });

  final TransactionFilter selectedValue;
  final ValueChanged<TransactionFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.md,
      ),
      child: AppSegmentedFilter<TransactionFilter>(
        options: [
          FilterOption(
            label: l10n.all,
            value: TransactionFilter.all,
            icon: Icons.list,
          ),
          FilterOption(
            label: l10n.expense,
            value: TransactionFilter.expense,
            icon: Icons.arrow_upward,
            color: context.semanticColors.expense,
          ),
          FilterOption(
            label: l10n.income,
            value: TransactionFilter.income,
            icon: Icons.arrow_downward,
            color: context.semanticColors.income,
          ),
          FilterOption(
            label: l10n.transfer,
            value: TransactionFilter.transfer,
            icon: Icons.swap_horiz,
          ),
        ],
        selectedValue: selectedValue,
        onChanged: onChanged,
      ),
    );
  }
}

class _TransactionsEmptyView extends StatelessWidget {
  const _TransactionsEmptyView({
    required this.hasSearchQuery,
    required this.filter,
    required this.onRefresh,
    required this.onClearSearch,
    required this.onClearFilter,
  });

  final bool hasSearchQuery;
  final TransactionFilter filter;
  final Future<void> Function() onRefresh;
  final VoidCallback onClearSearch;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget emptyState;
    if (hasSearchQuery) {
      emptyState = EmptyState.noSearchResult(
        icon: Icons.search_off,
        title: l10n.noTransactionsMatch,
        message: l10n.adjustSearchTerms,
        actionLabel: l10n.clearFilter,
        actionIcon: Icons.filter_alt_off,
        onAction: onClearSearch,
        compact: true,
      );
    } else if (filter != TransactionFilter.all) {
      final (icon, title, message) = switch (filter) {
        TransactionFilter.expense => (
            Icons.arrow_upward,
            l10n.noExpenseTitle,
            l10n.noExpenseTransactionsFound,
          ),
        TransactionFilter.transfer => (
            Icons.swap_horiz,
            l10n.noTransferTitle,
            l10n.noTransferTransactionsFound,
          ),
        _ => (
            Icons.arrow_downward,
            l10n.noIncomeTitle,
            l10n.noIncomeTransactionsFound,
          ),
      };
      emptyState = EmptyState(
        icon: icon,
        title: title,
        message: message,
        actionLabel: l10n.addTransaction,
        onAction: () {
          Navigator.pushNamed(context, '/add-transaction');
        },
        secondaryActionLabel: l10n.clearFilter,
        onSecondaryAction: onClearFilter,
        compact: true,
        type: EmptyStateType.noFilterResult,
      );
    } else {
      emptyState = EmptyState.firstRun(
        icon: Icons.receipt_long,
        title: l10n.startTracking,
        message: l10n.onboardingSubtitle,
        actionLabel: l10n.addTransaction,
        onAction: () {
          Navigator.pushNamed(context, '/add-transaction');
        },
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: emptyState,
          ),
        ],
      ),
    );
  }
}
