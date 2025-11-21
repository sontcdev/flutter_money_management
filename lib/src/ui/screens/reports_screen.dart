// path: lib/src/ui/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/ui/widgets/chart_widget.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';

class ReportsScreen extends HookConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedYear = useState(DateTime.now().year);
    final selectedMonth = useState(DateTime.now().month);
    final reportService = ref.read(reportServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: selectedMonth.value,
                    decoration: const InputDecoration(labelText: 'Month'),
                    items: List.generate(12, (i) => i + 1).map((month) {
                      return DropdownMenuItem(
                        value: month,
                        child: Text(DateFormat.MMMM().format(DateTime(2000, month))),
                      );
                    }).toList(),
                    onChanged: (value) => selectedMonth.value = value!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: selectedYear.value,
                    decoration: const InputDecoration(labelText: 'Year'),
                    items: List.generate(5, (i) => DateTime.now().year - i).map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }).toList(),
                    onChanged: (value) => selectedYear.value = value!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              future: reportService.monthlyReport(selectedYear.value, selectedMonth.value),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final report = snapshot.data!;
                final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

                return Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _SummaryRow(
                              l10n.totalIncome,
                              formatter.format(report.totalIncomeCents / 100),
                              Colors.green,
                            ),
                            const SizedBox(height: 8),
                            _SummaryRow(
                              l10n.totalExpense,
                              formatter.format(report.totalExpenseCents / 100),
                              Colors.red,
                            ),
                            const Divider(),
                            _SummaryRow(
                              l10n.net,
                              formatter.format(report.netCents / 100),
                              report.netCents >= 0 ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (report.expenseBreakdown.isNotEmpty)
                      PieChartWidget(
                        title: '${l10n.expense} ${l10n.breakdown}',
                        data: report.expenseBreakdown.take(5)
                            .map((item) => ChartData(
                                  label: item.categoryName,
                                  value: item.percentage,
                                ))
                            .toList(),
                      ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.topCategories,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 16),
                            ...report.expenseBreakdown.take(5).map((item) {
                              return ListTile(
                                title: Text(item.categoryName),
                                trailing: Text(
                                  formatter.format(item.amountCents / 100),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text('${item.percentage.toStringAsFixed(1)}%'),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

