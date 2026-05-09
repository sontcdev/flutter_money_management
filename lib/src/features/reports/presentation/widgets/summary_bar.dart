import 'package:flutter/material.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/utils/currency_formatter.dart';

class SummaryBar extends StatelessWidget {
  final int totalIncome;
  final int totalExpense;
  final int net;

  const SummaryBar({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final incomeAmount = CurrencyFormatter.formatVNDFromCents(
      totalIncome,
      locale: l10n.localeName,
    );
    final expenseAmount = CurrencyFormatter.formatVNDFromCents(
      totalExpense,
      locale: l10n.localeName,
    );
    final netAmount = CurrencyFormatter.formatVNDFromCents(
      net.abs(),
      locale: l10n.localeName,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              context,
              l10n.income,
              incomeAmount,
              AppColors.income, // Green for income
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          Expanded(
            child: _buildSummaryItem(
              context,
              l10n.expense,
              expenseAmount,
              AppColors.expense, // Red for expense
            ),
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          Expanded(
            child: _buildSummaryItem(
              context,
              l10n.net,
              '${net >= 0 ? '+' : '-'}$netAmount',
              net >= 0 ? AppColors.income : AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      BuildContext context, String label, String amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 12,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
