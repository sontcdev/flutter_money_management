// path: lib/src/app_router.dart

import 'package:flutter/material.dart';
import 'models/category.dart';
import 'models/budget.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/transactions_screen.dart';
import 'ui/screens/add_transaction_screen.dart';
import 'ui/screens/transaction_detail_screen.dart';
import 'ui/screens/budgets_screen.dart';
import 'ui/screens/budget_detail_screen.dart';
import 'ui/screens/budget_edit_screen.dart';
import 'ui/screens/categories_screen.dart';
import 'ui/screens/category_edit_screen.dart';
import 'ui/screens/reports_screen.dart';
import 'ui/screens/settings_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/transactions':
        return MaterialPageRoute(builder: (_) => const TransactionsScreen());
      case '/add-transaction':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AddTransactionScreen(
            transactionId: args?['transactionId'] as int?,
          ),
        );
      case '/transaction-detail':
        final transactionId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(transactionId: transactionId),
        );
      case '/budgets':
        return MaterialPageRoute(builder: (_) => const BudgetsScreen());
      case '/budget-detail':
        final budgetId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => BudgetDetailScreen(budgetId: budgetId),
        );
      case '/budget-edit':
        final budget = settings.arguments as Budget?;
        return MaterialPageRoute(
          builder: (_) => BudgetEditScreen(budget: budget),
        );
      case '/categories':
        return MaterialPageRoute(builder: (_) => const CategoriesScreen());
      case '/category-edit':
        final category = settings.arguments as Category?;
        return MaterialPageRoute(
          builder: (_) => CategoryEditScreen(category: category),
        );
      case '/reports':
        return MaterialPageRoute(builder: (_) => const ReportsScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}

