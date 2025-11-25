// path: lib/src/ui/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../models/transaction.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';

class ReportsScreen extends HookConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final transactionsAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedPeriod = useState(0); // 0: Tháng này, 1: Tháng trước, 2: Năm này

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Navigate to Calendar Report
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Báo cáo theo lịch'),
                subtitle: const Text('Xem giao dịch theo từng ngày trong tháng'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pushNamed(context, '/report-calendar');
                },
              ),
            ),

            const SizedBox(height: 16),

            // Period Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: _PeriodButton(
                        label: 'Tháng này',
                        isSelected: selectedPeriod.value == 0,
                        onTap: () => selectedPeriod.value = 0,
                      ),
                    ),
                    Expanded(
                      child: _PeriodButton(
                        label: 'Tháng trước',
                        isSelected: selectedPeriod.value == 1,
                        onTap: () => selectedPeriod.value = 1,
                      ),
                    ),
                    Expanded(
                      child: _PeriodButton(
                        label: 'Năm này',
                        isSelected: selectedPeriod.value == 2,
                        onTap: () => selectedPeriod.value = 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Summary Card
            transactionsAsync.when(
              data: (transactions) {
                final filteredTransactions = _filterTransactions(transactions, selectedPeriod.value);
                
                final totalIncome = filteredTransactions
                    .where((t) => t.type == TransactionType.income)
                    .fold<int>(0, (sum, t) => sum + t.amountCents);
                
                final totalExpense = filteredTransactions
                    .where((t) => t.type == TransactionType.expense)
                    .fold<int>(0, (sum, t) => sum + t.amountCents);
                
                final balance = totalIncome - totalExpense;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Báo cáo tổng quan',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _SummaryRow(
                          label: 'Tổng thu nhập',
                          amount: totalIncome,
                          color: AppColors.income,
                          icon: Icons.arrow_downward,
                        ),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          label: 'Tổng chi tiêu',
                          amount: totalExpense,
                          color: AppColors.expense,
                          icon: Icons.arrow_upward,
                        ),
                        const Divider(height: 24),
                        _SummaryRow(
                          label: 'Số dư',
                          amount: balance,
                          color: balance >= 0 ? AppColors.income : AppColors.expense,
                          icon: balance >= 0 ? Icons.trending_up : Icons.trending_down,
                          isBold: true,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Số giao dịch: ${filteredTransactions.length}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Lỗi: $err'),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Category Breakdown
            Text(
              'Chi tiêu theo danh mục',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            transactionsAsync.when(
              data: (transactions) {
                return categoriesAsync.when(
                  data: (categories) {
                    final filteredTransactions = _filterTransactions(transactions, selectedPeriod.value)
                        .where((t) => t.type == TransactionType.expense)
                        .toList();
                    
                    if (filteredTransactions.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text('Chưa có chi tiêu trong kỳ này'),
                          ),
                        ),
                      );
                    }

                    // Group by category
                    final Map<int, int> categoryTotals = {};
                    for (final t in filteredTransactions) {
                      categoryTotals[t.categoryId] = (categoryTotals[t.categoryId] ?? 0) + t.amountCents;
                    }

                    final totalExpense = filteredTransactions.fold<int>(0, (sum, t) => sum + t.amountCents);

                    final sortedCategories = categoryTotals.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: sortedCategories.map((entry) {
                            final category = categories.firstWhere(
                              (c) => c.id == entry.key,
                              orElse: () => categories.first,
                            );
                            final percentage = totalExpense > 0 
                                ? (entry.value / totalExpense * 100).toStringAsFixed(1)
                                : '0';
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Color(category.colorValue),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        category.iconName,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.name,
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 4),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: totalExpense > 0 ? entry.value / totalExpense : 0,
                                            backgroundColor: Colors.grey[200],
                                            valueColor: AlwaysStoppedAnimation(Color(category.colorValue)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        CurrencyFormatter.formatVNDFromCents(entry.value),
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        '$percentage%',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (err, _) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Lỗi: $err'),
                    ),
                  ),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Lỗi: $err'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions, int period) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (period) {
      case 0: // Tháng này
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 1: // Tháng trước
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 2: // Năm này
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    }

    return transactions.where((t) =>
      t.dateTime.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
      t.dateTime.isBefore(endDate.add(const Duration(seconds: 1)))
    ).toList();
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final IconData icon;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          CurrencyFormatter.formatVNDFromCents(amount),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

