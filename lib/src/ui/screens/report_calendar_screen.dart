// path: lib/src/ui/screens/report_calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/report_providers.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/summary_bar.dart';
import '../widgets/transaction_group_header.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/confirm_delete_dialog.dart';

class ReportCalendarScreen extends HookConsumerWidget {
  const ReportCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final calendarData = ref.watch(calendarDataProvider(selectedMonth));
    final monthlySummary = ref.watch(monthlySummaryProvider(selectedMonth));
    final transactionGroups = ref.watch(transactionGroupsProvider(selectedMonth));
    final scrollController = useScrollController();
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n?.reports ?? 'Lịch'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(transactionListNotifierProvider.notifier).refresh();
        },
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildMonthSelector(context, ref, selectedMonth),
                  const SizedBox(height: 16),
                  calendarData.when(
                    data: (data) => CalendarGrid(
                      month: selectedMonth,
                      cellData: data,
                      selectedDate: selectedDate,
                      onDateSelected: (date) {
                        ref.read(selectedDateProvider.notifier).state = date;
                      },
                    ),
                    loading: () => const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, s) => SizedBox(
                      height: 300,
                      child: Center(child: Text('Error: $e')),
                    ),
                  ),
                  const SizedBox(height: 16),
                  monthlySummary.when(
                    data: (summary) => SummaryBar(
                      totalIncome: summary['income'] ?? 0,
                      totalExpense: summary['expense'] ?? 0,
                      net: summary['net'] ?? 0,
                    ),
                    loading: () => const SizedBox(height: 80),
                    error: (e, s) => const SizedBox(height: 80),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            transactionGroups.when(
              data: (groups) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= groups.length * 2 - 1) return null;

                    if (index.isOdd) {
                      return const Divider(height: 1);
                    }

                    final groupIndex = index ~/ 2;
                    final group = groups[groupIndex];
                    final isHighlighted = selectedDate != null &&
                        _isSameDay(group.date, selectedDate);

                    return Column(
                      children: [
                        TransactionGroupHeader(
                          date: group.date,
                          netAmount: group.netAmount,
                          isHighlighted: isHighlighted,
                        ),
                        ...group.transactions.map((txnWithCat) => TransactionListItem(
                          transactionWithCategory: txnWithCat,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/transaction-detail',
                              arguments: txnWithCat.transaction.id,
                            );
                          },
                          onLongPress: () {
                            _showTransactionActions(context, ref, txnWithCat);
                          },
                        )),
                      ],
                    );
                  },
                ),
              ),
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => SliverToBoxAdapter(
                child: Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, WidgetRef ref, DateTime month) {
    final monthLabel = _formatMonthLabel(month);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              ref.read(transactionListNotifierProvider.notifier).loadPreviousMonth();
            },
          ),
          Expanded(
            child: Center(
              child: InkWell(
                onTap: () => _showMonthYearPicker(context, ref, month),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        monthLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              ref.read(transactionListNotifierProvider.notifier).loadNextMonth();
            },
          ),
        ],
      ),
    );
  }

  void _showMonthYearPicker(BuildContext context, WidgetRef ref, DateTime currentMonth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MonthYearPickerSheet(
        initialMonth: currentMonth,
        onMonthSelected: (selectedMonth) {
          ref.read(transactionListNotifierProvider.notifier).goToMonth(selectedMonth);
          Navigator.pop(context);
        },
      ),
    );
  }

  String _formatMonthLabel(DateTime month) {
    return 'Tháng ${month.month.toString().padLeft(2, '0')}/${month.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showTransactionActions(BuildContext context, WidgetRef ref, TransactionWithCategory txnWithCat) {
    final txn = txnWithCat.transaction;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/add-transaction',
                  arguments: {'transactionId': txn.id},
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => const ConfirmDeleteDialog(),
                );
                if (confirmed == true) {
                  await ref.read(transactionListNotifierProvider.notifier).deleteTransaction(txn.id);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthYearPickerSheet extends HookWidget {
  final DateTime initialMonth;
  final Function(DateTime) onMonthSelected;

  const _MonthYearPickerSheet({
    required this.initialMonth,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selectedYear = useState(initialMonth.year);
    final now = DateTime.now();
    final years = List.generate(10, (i) => now.year - 5 + i);
    final months = [
      'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
      'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
      'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chọn tháng/năm',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Year selector
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: years.length,
              itemBuilder: (context, index) {
                final year = years[index];
                final isSelected = year == selectedYear.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(year.toString()),
                    selected: isSelected,
                    onSelected: (_) => selectedYear.value = year,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Month grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final monthNum = index + 1;
                final isCurrentSelection = 
                    selectedYear.value == initialMonth.year && 
                    monthNum == initialMonth.month;
                final isCurrentMonth = 
                    selectedYear.value == now.year && 
                    monthNum == now.month;
                
                return Material(
                  color: isCurrentSelection
                      ? Theme.of(context).colorScheme.primary
                      : isCurrentMonth
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => onMonthSelected(DateTime(selectedYear.value, monthNum)),
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: Text(
                        months[index],
                        style: TextStyle(
                          color: isCurrentSelection ? Colors.white : null,
                          fontWeight: isCurrentSelection || isCurrentMonth ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

