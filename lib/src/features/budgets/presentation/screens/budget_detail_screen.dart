import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_icon_widget.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_card.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';

class BudgetDetailScreen extends ConsumerWidget {
  final String budgetId;

  const BudgetDetailScreen({super.key, required this.budgetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final budgetRepo = ref.read(budgetRepositoryProvider);
    final theme = Theme.of(context);

    return FutureBuilder(
      future: budgetRepo.getBudgetById(budgetId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.budget)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final budget = snapshot.data!;
        final categoryAsync = ref.watch(categoryProvider(budget.categoryId));

        final isExceeded = budget.isExceeded;
        final progress = budget.limitCents > 0
            ? budget.consumedCents / budget.limitCents
            : 0.0;
        final nearLimit = !isExceeded && progress >= 0.8;

        final statusColor = isExceeded
            ? AppColors.error
            : nearLimit
                ? AppColors.warning
                : AppColors.primary;

        final periodLabel = switch (budget.periodType) {
          PeriodType.monthly => l10n.monthly,
          PeriodType.yearly => l10n.yearly,
          PeriodType.custom => l10n.custom,
        };

        return Scaffold(
          appBar: AppBar(title: Text(l10n.budget)),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Hero: icon + category name + amount + status subtitle
              Center(
                child: Column(
                  children: [
                    categoryAsync.when(
                      data: (category) => Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Center(
                          child: category != null
                              ? CategoryIconWidget(
                                  iconName: category.iconName,
                                  size: 28,
                                  color: statusColor,
                                )
                              : Icon(Icons.category_outlined,
                                  size: 28, color: statusColor),
                        ),
                      ),
                      loading: () => Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      error: (_, __) => Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Icon(Icons.category_outlined,
                            size: 28, color: statusColor),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    categoryAsync.when(
                      data: (category) => Text(
                        category?.name ?? l10n.unknown,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      loading: () => Text(l10n.loading),
                      error: (_, __) => Text(l10n.unknown),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      CurrencyFormatter.formatVNDFromCents(
                        budget.consumedCents,
                        locale: l10n.localeName,
                      ),
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isExceeded
                          ? '${l10n.limit}: ${CurrencyFormatter.formatVNDFromCents(budget.limitCents, locale: l10n.localeName)} · ${l10n.exceeded} ${CurrencyFormatter.formatVNDFromCents(budget.consumedCents - budget.limitCents, locale: l10n.localeName)}'
                          : '${l10n.limit}: ${CurrencyFormatter.formatVNDFromCents(budget.limitCents, locale: l10n.localeName)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(statusColor),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Info card: period / start / remaining
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _InfoRow(label: l10n.period, value: periodLabel),
                    Divider(height: 1, color: theme.dividerColor),
                    _InfoRow(
                      label: l10n.startDate,
                      value: formatLocalizedDate(context, budget.periodStart),
                    ),
                    Divider(height: 1, color: theme.dividerColor),
                    _InfoRow(
                      label: l10n.remaining,
                      value: CurrencyFormatter.formatVNDFromCents(
                        budget.remainingCents,
                        locale: l10n.localeName,
                      ),
                      valueColor: isExceeded
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
