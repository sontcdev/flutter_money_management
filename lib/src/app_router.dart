// path: lib/src/app_router.dart

import 'package:flutter/material.dart';
import 'models/category.dart';
import 'models/budget.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/transactions_screen.dart';
import 'ui/screens/edit_transaction_screen.dart';
import 'ui/screens/transaction_detail_screen.dart';
import 'ui/screens/budgets_screen.dart';
import 'ui/screens/budget_detail_screen.dart';
import 'ui/screens/budget_edit_screen.dart';
import 'ui/screens/categories_screen.dart';
import 'ui/screens/category_edit_screen.dart';
import 'ui/screens/reports_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/report_calendar_screen.dart';
import 'ui/screens/import_export_screen.dart';
import 'ui/screens/icon_management_screen.dart';
import 'ui/screens/transaction_management_screen.dart';
import 'utils/animations.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case '/home':
        return AppAnimations.fadeRoute(const HomeScreen());
      case '/transactions':
        return AppAnimations.slideRoute(const TransactionsScreen());
      case '/edit-transaction':
        final transactionId = settings.arguments as int;
        return AppAnimations.slideRoute(
          EditTransactionScreen(transactionId: transactionId),
        );
      case '/transaction-detail':
        final transactionId = settings.arguments as int;
        return AppAnimations.slideRoute(
          TransactionDetailScreen(transactionId: transactionId),
        );
      case '/budgets':
        return AppAnimations.slideRoute(const BudgetsScreen());
      case '/budget-detail':
        final budgetId = settings.arguments as int;
        return AppAnimations.slideRoute(
          BudgetDetailScreen(budgetId: budgetId),
        );
      case '/budget-edit':
        final budget = settings.arguments as Budget?;
        return AppAnimations.slideRoute(
          BudgetEditScreen(budget: budget),
        );
      case '/categories':
        return AppAnimations.slideRoute(const CategoriesScreen());
      case '/category-edit':
        final args = settings.arguments;
        Category? category;
        CategoryType? initialType;
        if (args is Category) {
          category = args;
        } else if (args is Map<String, dynamic>) {
          category = args['category'] as Category?;
          initialType = args['initialType'] as CategoryType?;
        }
        return AppAnimations.slideRoute(
          CategoryEditScreen(category: category, initialType: initialType),
        );
      case '/reports':
        return AppAnimations.slideRoute(const ReportsScreen());
      case '/report-calendar':
        return AppAnimations.slideRoute(const ReportCalendarScreen());
      case '/settings':
        return AppAnimations.slideRoute(const SettingsScreen());
      case '/import-export':
        return AppAnimations.slideRoute(const ImportExportScreen());
      case '/icon-management':
        return AppAnimations.slideRoute(const IconManagementScreen());
      case '/transaction-management':
        return AppAnimations.slideRoute(const TransactionManagementScreen());
      default:
        return AppAnimations.fadeRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}

