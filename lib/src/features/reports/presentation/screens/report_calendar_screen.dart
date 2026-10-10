import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/reports/models/report_calendar_models.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/calendar_grid.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/summary_bar.dart';
import 'package:flutter_money_management/src/features/reports/presentation/widgets/transaction_group_header.dart';
import 'package:flutter_money_management/src/features/reports/providers/report_providers.dart';
import 'package:flutter_money_management/src/features/settings/providers/settings_preferences_providers.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:flutter_money_management/src/theme/app_motion.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';
import 'package:flutter_money_management/src/ui/widgets/app_snack_bar.dart';
import 'package:flutter_money_management/src/ui/widgets/confirm_delete_dialog.dart';
import 'package:flutter_money_management/src/ui/widgets/empty_state.dart';
import 'package:flutter_money_management/src/ui/widgets/load_error_state.dart';
import 'package:flutter_money_management/src/ui/widgets/shimmer_loading.dart';
import 'package:flutter_money_management/src/utils/cycle_utils.dart';
import 'package:flutter_money_management/src/utils/localized_formatters.dart';

/// Check if two dates are the same day
bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class ReportCalendarScreen extends HookConsumerWidget {
  const ReportCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedMonth = ref.watch(selectedMonthProvider);
    final monthStartDay = ref.watch(monthStartDayProvider);
    final calendarData = ref.watch(calendarDataProvider(selectedMonth));
    final monthlySummary = ref.watch(monthlySummaryProvider(selectedMonth));
    final transactionGroups =
        ref.watch(transactionGroupsProvider(selectedMonth));
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
              duration: AppMotion.of(key.currentContext!, AppMotion.normal),
              curve: AppMotion.standard,
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
        title: Text(l10n.calendar),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: l10n.search,
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
          _buildCalendarSection(
            context,
            _CalendarHeader(
              selectedMonth: selectedMonth,
              monthStartDay: monthStartDay,
              selectedDate: selectedDate,
              calendarData: calendarData,
              monthlySummary: monthlySummary,
              monthSelector: _buildMonthSelector(context, ref, selectedMonth),
              onDateSelected: onDateSelected,
            ),
          ),

          // ========== TRANSACTION LIST (SCROLLABLE) ==========
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(transactionListNotifierProvider.notifier)
                    .refresh();
              },
              child: _CalendarTransactionList(
                groups: groups,
                groupKeys: groupKeysRef.value,
                selectedDate: selectedDate,
                onLongPress: (txnWithCat) {
                  _showTransactionActions(context, ref, txnWithCat);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection(BuildContext context, Widget child) {
    if (MediaQuery.orientationOf(context) == Orientation.landscape) {
      return Flexible(child: SingleChildScrollView(child: child));
    }
    return child;
  }

  Widget _buildMonthSelector(
      BuildContext context, WidgetRef ref, DateTime month) {
    final l10n = AppLocalizations.of(context)!;
    final monthLabel = _formatMonthLabel(context, month);
    final monthStartDay = ref.watch(monthStartDayProvider);
    final cycleRange = CycleUtils.getCycleRangeForMonth(month, monthStartDay);
    final cycleLabel =
        CycleUtils.getCycleLabel(cycleRange.start, cycleRange.end);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: l10n.previousMonth,
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              ref
                  .read(transactionListNotifierProvider.notifier)
                  .loadPreviousMonth();
            },
          ),
          Expanded(
            child: Center(
              child: InkWell(
                onTap: () => _showMonthYearPicker(context, ref, month),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            monthLabel,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
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
                      if (monthStartDay != 1) ...[
                        const SizedBox(height: 2),
                        Text(
                          cycleLabel,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.nextMonth,
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              ref
                  .read(transactionListNotifierProvider.notifier)
                  .loadNextMonth();
            },
          ),
        ],
      ),
    );
  }

  void _showMonthYearPicker(
      BuildContext context, WidgetRef ref, DateTime currentMonth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusSheet),
        ),
      ),
      builder: (context) => _MonthYearPickerSheet(
        initialMonth: currentMonth,
        onMonthSelected: (selectedMonth) {
          ref
              .read(transactionListNotifierProvider.notifier)
              .goToMonth(selectedMonth);
          Navigator.pop(context);
        },
      ),
    );
  }

  String _formatMonthLabel(BuildContext context, DateTime month) {
    return AppLocalizations.of(context)!.monthFormat(
      month.month.toString().padLeft(2, '0'),
      month.year,
    );
  }

  void _showTransactionActions(
      BuildContext context, WidgetRef ref, TransactionWithCategory txnWithCat) {
    final txn = txnWithCat.transaction;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(AppLocalizations.of(context)!.edit),
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
              leading:
                  Icon(Icons.delete, color: context.semanticColors.expense),
              title: Text(
                AppLocalizations.of(context)!.delete,
                style: TextStyle(color: context.semanticColors.expense),
              ),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => const ConfirmDeleteDialog(),
                );
                if (confirmed == true) {
                  await ref
                      .read(transactionListNotifierProvider.notifier)
                      .deleteTransaction(txn.id);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(AppLocalizations.of(context)!.share),
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

class _CalendarHeader extends ConsumerWidget {
  final DateTime selectedMonth;
  final int monthStartDay;
  final DateTime? selectedDate;
  final AsyncValue<Map<DateTime, List<AmountBadge>>> calendarData;
  final AsyncValue<Map<String, int>> monthlySummary;
  final Widget monthSelector;
  final ValueChanged<DateTime> onDateSelected;

  const _CalendarHeader({
    required this.selectedMonth,
    required this.monthStartDay,
    required this.selectedDate,
    required this.calendarData,
    required this.monthlySummary,
    required this.monthSelector,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          monthSelector,
          const SizedBox(height: 4),
          calendarData.when(
            data: (data) => CalendarGrid(
              month: selectedMonth,
              cellData: data,
              selectedDate: selectedDate,
              monthStartDay: monthStartDay,
              onDateSelected: onDateSelected,
            ),
            loading: () => const SectionSkeleton(height: 280, lineCount: 6),
            error: (e, s) => SizedBox(
              height: 280,
              child: InlineLoadErrorState(
                onRetry: () =>
                    ref.invalidate(calendarDataProvider(selectedMonth)),
              ),
            ),
          ),
          const SizedBox(height: 4),
          monthlySummary.when(
            data: (summary) => SummaryBar(
              totalIncome: summary['income'] ?? 0,
              totalExpense: summary['expense'] ?? 0,
              net: summary['net'] ?? 0,
            ),
            loading: () => const SectionSkeleton(height: 70, lineCount: 2),
            error: (e, s) => SizedBox(
              height: 70,
              child: InlineLoadErrorState(
                onRetry: () => ref.invalidate(
                  monthlySummaryProvider(selectedMonth),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _CalendarTransactionList extends StatelessWidget {
  final List<TransactionGroup> groups;
  final List<GlobalKey> groupKeys;
  final DateTime? selectedDate;
  final ValueChanged<TransactionWithCategory> onLongPress;

  const _CalendarTransactionList({
    required this.groups,
    required this.groupKeys,
    required this.selectedDate,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedDate = this.selectedDate;
    return groups.isEmpty
        ? ListView(
            // Empty ListView để RefreshIndicator hoạt động
            children: [
              const SizedBox(height: 80),
              EmptyState.compact(
                icon: Icons.event_busy_outlined,
                title: l10n.noTransactionsThisMonth,
                message: '',
                actionLabel: l10n.addTransaction,
                onAction: () {
                  Navigator.pushNamed(context, '/add-transaction');
                },
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
                  key: groupKeys[index],
                  child: Column(
                    children: [
                      TransactionGroupHeader(
                        date: group.date,
                        totalIncome: group.totalIncome,
                        totalExpense: group.totalExpense,
                        isHighlighted: isHighlighted,
                      ),
                      ...group.transactions
                          .map((txnWithCat) => TransactionListItem(
                                transactionWithCategory: txnWithCat,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/transaction-detail',
                                    arguments: txnWithCat.transaction.id,
                                  );
                                },
                                onLongPress: () {
                                  onLongPress(txnWithCat);
                                },
                              )),
                      if (index < groups.length - 1) const Divider(height: 1),
                    ],
                  ),
                );
              }),
            ),
          );
  }
}

void _showNoTransactionsMessage(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context).clearSnackBars();
  showAppSnackBar(
    context,
    l10n.noTransactions,
    duration: const Duration(seconds: 2),
  );
}

void _showScrollingToNearestMessage(
    BuildContext context, DateTime nearestDate) {
  final l10n = AppLocalizations.of(context)!;
  final dateStr = formatLocalizedMonthDay(context, nearestDate);
  ScaffoldMessenger.of(context).clearSnackBars();
  showAppSnackBar(
    context,
    l10n.noTransactionsNearestDate(dateStr),
    duration: const Duration(seconds: 2),
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
    final months = List.generate(
      12,
      (i) => DateFormat.MMMM(l10n.localeName).format(DateTime(2000, i + 1)),
    );
    final scrollController = useScrollController();

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentYearIndex = years.indexOf(selectedYear.value);
        if (currentYearIndex != -1 && scrollController.hasClients) {
          const itemWidth = 80.0;
          final screenWidth = MediaQuery.of(context).size.width;
          final offset = (currentYearIndex * itemWidth) -
              (screenWidth / 2) +
              (itemWidth / 2);
          scrollController.animateTo(
            offset.clamp(0.0, scrollController.position.maxScrollExtent),
            duration: AppMotion.normal,
            curve: AppMotion.standard,
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
                tooltip: l10n.close,
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
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
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
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  child: InkWell(
                    onTap: () =>
                        onMonthSelected(DateTime(selectedYear.value, monthNum)),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    child: Center(
                      child: Text(
                        months[index],
                        style: TextStyle(
                          color: isCurrentSelection
                              ? Theme.of(context).colorScheme.onPrimary
                              : (isCurrentMonth
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color),
                          fontWeight: isCurrentSelection || isCurrentMonth
                              ? FontWeight.bold
                              : null,
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
