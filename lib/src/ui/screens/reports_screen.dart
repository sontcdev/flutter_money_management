// path: lib/src/ui/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:test3_cursor/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../providers/providers.dart';
import '../../services/report_service.dart';
import '../widgets/chart_widget.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _isMonthly = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reportService = ref.watch(reportServiceProvider);
    final format = NumberFormat.currency(symbol: '');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reports)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: true, label: Text(l10n.month)),
                      ButtonSegment(value: false, label: Text(l10n.year)),
                    ],
                    selected: {_isMonthly},
                    onSelectionChanged: (Set<bool> selected) {
                      setState(() => _isMonthly = selected.first);
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isMonthly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<int>(
                      value: _selectedMonth,
                      isExpanded: true,
                      items: List.generate(12, (index) {
                        return DropdownMenuItem(
                          value: index + 1,
                          child: Text('${index + 1}'),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedMonth = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      isExpanded: true,
                      items: List.generate(10, (index) {
                        final year = DateTime.now().year - 5 + index;
                        return DropdownMenuItem(
                          value: year,
                          child: Text('$year'),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedYear = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<int>(
                value: _selectedYear,
                isExpanded: true,
                items: List.generate(10, (index) {
                  final year = DateTime.now().year - 5 + index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text('$year'),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedYear = value);
                  }
                },
              ),
            ),
          Expanded(
            child: FutureBuilder(
              future: _isMonthly
                  ? reportService.monthlyReport(_selectedYear, _selectedMonth)
                  : reportService.yearlyReport(_selectedYear),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return Center(child: Text('No data'));
                }

                final report = snapshot.data! as dynamic;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.total,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                format.format(report.totalCents / 100),
                                style: Theme.of(context).textTheme.displayMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.byCategory,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      ChartWidget(
                        breakdown: report.breakdown as List<CategoryBreakdown>,
                        type: ChartType.donut,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.topCategories,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      ...(report.breakdown as List<CategoryBreakdown>).take(5).map((item) {
                        return Card(
                          child: ListTile(
                            title: Text(item.categoryName),
                            trailing: Text(
                              '${format.format(item.amountCents / 100)} (${item.percentage.toStringAsFixed(1)}%)',
                            ),
                          ),
                        );
                      }),
                    ],
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

