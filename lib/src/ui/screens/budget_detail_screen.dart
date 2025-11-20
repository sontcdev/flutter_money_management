// path: lib/src/ui/screens/budget_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BudgetDetailScreen extends ConsumerWidget {
  final int budgetId;

  const BudgetDetailScreen({Key? key, required this.budgetId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final budgetRepo = ref.read(budgetRepositoryProvider);

    return FutureBuilder(
      future: budgetRepo.getBudgetById(budgetId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final budget = snapshot.data!;
        final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.budget),
          ),
          body: ListView(
            padding: EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.limit, style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        formatter.format(budget.limitCents / 100),
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Text(l10n.spent, style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        formatter.format(budget.consumedCents / 100),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 16),
                      Text(l10n.remaining, style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        formatter.format(budget.remainingCents / 100),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

