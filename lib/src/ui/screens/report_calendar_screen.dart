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
import 'settings_screen.dart';

/// Check if two dates are the same day
bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class ReportCalendarScreen extends HookConsumerWidget {
  const ReportCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final monthStartDay = ref.watch(monthStartDayProvider);
    final calendarData = ref.watch(calendarDataProvider(selectedMonth));
    final monthlySummary = ref.watch(monthlySummaryProvider(selectedMonth));
    final transactionGroups = ref.watch(transactionGroupsProvider(selectedMonth));
    final selectedDate = ref.watch(selectedDateProvider);

    // Lấy groups hiện tại
    final groups = transactionGroups.valueOrNull ?? [];

    // ========== GLOBAL KEYS CHO MỖI GROUP ==========
    // Dùng useRef để giữ keys stable, không tạo mới mỗi build
    final groupKeysRef = useRef<List<GlobalKey>>([]);
    
    // Đảm bảo có đủ keys cho tất cả groups
    while (groupKeysRef.value.length < groups.length) {
      groupKeysRef.value.add(GlobalKey());
    }

    // ========== SCROLL FUNCTION ==========
    void scrollToDate(DateTime targetDate) {
      if (groups.isEmpty) {
        _showNoTransactionsMessage(context);
        return;
      }

      int targetIndex = -1;
      bool isExactMatch = false;

      // 1. Tìm ngày chính xác
      for (int i = 0; i < groups.length; i++) {
        if (_isSameDay(groups[i].date, targetDate)) {
          targetIndex = i;
          isExactMatch = true;
          break;
        }
      }

      // 2. Nếu không có, tìm ngày gần nhất (groups sorted descending)
      if (targetIndex == -1) {
        for (int i = 0; i < groups.length; i++) {
          if (groups[i].date.isBefore(targetDate)) {
            targetIndex = i;
            break;
          }
        }
        if (targetIndex == -1) {
          targetIndex = groups.length - 1;
        }
      }

      // 3. Scroll đến widget bằng GlobalKey
      if (targetIndex >= 0 && targetIndex < groupKeysRef.value.length) {
        final key = groupKeysRef.value[targetIndex];
        
        // Dùng Future.delayed để đảm bảo widget đã được render
        Future.delayed(const Duration(milliseconds: 100), () {
          if (key.currentContext != null) {
            Scrollable.ensureVisible(
              key.currentContext!,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: 0.0, // Scroll item lên đầu
            );
          }
        });

        if (!isExactMatch) {
          _showScrollingToNearestMessage(context, groups[targetIndex].date);
        }
      }
    }

    // ========== DATE SELECTION HANDLER ==========
    void onDateSelected(DateTime date) {
      ref.read(selectedDateProvider.notifier).state = date;
      scrollToDate(date);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n?.calendar ?? 'Lịch'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      // ========== LAYOUT CỐ ĐỊNH CALENDAR, CHỈ SCROLL TRANSACTION LIST ==========
      body: Column(
        children: [
          // ========== CALENDAR SECTION (CỐ ĐỊNH) ==========
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                _buildMonthSelector(context, ref, selectedMonth),
                const SizedBox(height: 4),
                calendarData.when(
                  data: (data) => CalendarGrid(
                    month: selectedMonth,
                    cellData: data,
                    selectedDate: selectedDate,
                    monthStartDay: monthStartDay,
                    onDateSelected: onDateSelected,
                  ),
                  loading: () => const SizedBox(
                    height: 280,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, s) => SizedBox(
                    height: 280,
                    child: Center(child: Text('Error: $e')),
                  ),
                ),
                const SizedBox(height: 4),
                monthlySummary.when(
                  data: (summary) => SummaryBar(
                    totalIncome: summary['income'] ?? 0,
                    totalExpense: summary['expense'] ?? 0,
                    net: summary['net'] ?? 0,
                  ),
                  loading: () => const SizedBox(height: 70),
                  error: (e, s) => const SizedBox(height: 70),
                ),
                const Divider(height: 1),
              ],
            ),
          ),

          // ========== TRANSACTION LIST (SCROLLABLE) ==========
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(transactionListNotifierProvider.notifier).refresh();
              },
              child: groups.isEmpty
                  ? ListView(
                      // Empty ListView để RefreshIndicator hoạt động
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            'Không có giao dịch trong tháng này',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: List.generate(groups.length, (index) {
                          final group = groups[index];
                          final isHighlighted = selectedDate != null &&
                              _isSameDay(group.date, selectedDate);

                          return Container(
                            key: groupKeysRef.value[index],
                            child: Column(
                              children: [
                                TransactionGroupHeader(
                                  date: group.date,
                                  totalIncome: group.totalIncome,
                                  totalExpense: group.totalExpense,
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
                                if (index < groups.length - 1)
                                  const Divider(height: 1),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
            ),
          ),
        ],
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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

void _showNoTransactionsMessage(BuildContext context) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Không có giao dịch'),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void _showScrollingToNearestMessage(BuildContext context, DateTime nearestDate) {
  final dateStr = '${nearestDate.day}/${nearestDate.month}';
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Không có giao dịch. Hiển thị ngày gần nhất: $dateStr'),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ========== MONTH YEAR PICKER ==========
class _MonthYearPickerSheet extends HookWidget {
  final DateTime initialMonth;
  final Function(DateTime) onMonthSelected;

  const _MonthYearPickerSheet({
    required this.initialMonth,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedYear = useState(initialMonth.year);
    final now = DateTime.now();
    final years = List.generate(10, (i) => now.year - 5 + i);
    final months = List.generate(12, (i) => '${l10n.month} ${i + 1}');
    final scrollController = useScrollController();

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentYearIndex = years.indexOf(selectedYear.value);
        if (currentYearIndex != -1 && scrollController.hasClients) {
          final itemWidth = 80.0;
          final screenWidth = MediaQuery.of(context).size.width;
          final offset = (currentYearIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
          scrollController.animateTo(
            offset.clamp(0.0, scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
      return null;
    }, []);

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
                '${l10n.selectMonth}/${l10n.selectYear}',
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
          SizedBox(
            height: 40,
            child: ListView.builder(
              controller: scrollController,
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
                    selectedYear.value == now.year && monthNum == now.month;

                return Material(
                  color: isCurrentSelection
                      ? Theme.of(context).colorScheme.primary
                      : isCurrentMonth
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => onMonthSelected(DateTime(selectedYear.value, monthNum)),
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: Text(
                        months[index],
                        style: TextStyle(
                          color: isCurrentSelection
                              ? Colors.white
                              : (isCurrentMonth
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).textTheme.bodyLarge?.color),
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
