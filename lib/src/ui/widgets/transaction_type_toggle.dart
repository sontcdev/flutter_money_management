// path: lib/src/ui/widgets/transaction_type_toggle.dart

import 'package:flutter/material.dart';
import '../../features/transactions/models/transaction.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Pill-shaped expense/income switch on a surface2 track, matching the
/// mockup's "Chi tiêu / Thu nhập" toggle used on the add/edit transaction
/// screens. Passing [transferLabel] adds a third "Chuyển khoản" segment.
class TransactionTypeToggle extends StatelessWidget {
  final TransactionType value;
  final String expenseLabel;
  final String incomeLabel;
  /// Null hides the transfer segment, keeping the original two-way toggle.
  final String? transferLabel;
  final ValueChanged<TransactionType> onChanged;

  const TransactionTypeToggle({
    super.key,
    required this.value,
    required this.expenseLabel,
    required this.incomeLabel,
    this.transferLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: expenseLabel,
              icon: Icons.arrow_upward,
              color: AppColors.expense,
              selected: value == TransactionType.expense,
              onTap: () => onChanged(TransactionType.expense),
            ),
          ),
          Expanded(
            child: _Segment(
              label: incomeLabel,
              icon: Icons.arrow_downward,
              color: AppColors.income,
              selected: value == TransactionType.income,
              onTap: () => onChanged(TransactionType.income),
            ),
          ),
          if (transferLabel != null)
            Expanded(
              child: _Segment(
                label: transferLabel!,
                icon: Icons.swap_horiz,
                color: Theme.of(context).colorScheme.primary,
                selected: value == TransactionType.transfer,
                onTap: () => onChanged(TransactionType.transfer),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.surface : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .shadow
                        .withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppSpacing.iconSizeSm,
              color: selected
                  ? color
                  : Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.5,
                      ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected
                          ? color
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
