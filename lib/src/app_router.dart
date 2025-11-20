// path: lib/src/app_router.dart
import 'package:flutter/material.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/transactions_screen.dart';
import 'ui/screens/add_transaction_screen.dart';
import 'ui/screens/transaction_detail_screen.dart';
import 'ui/screens/budgets_screen.dart';
import 'ui/screens/budget_detail_screen.dart';
import 'ui/screens/categories_screen.dart';
import 'ui/screens/category_edit_screen.dart';
import 'ui/screens/reports_screen.dart';
import 'ui/screens/settings_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/transactions':
        return MaterialPageRoute(builder: (_) => const TransactionsScreen());
      case '/add-transaction':
        return MaterialPageRoute(
            builder: (_) => AddTransactionScreen(transactionId: null));
      case '/edit-transaction':
        final transactionId = settings.arguments as String?;
        return MaterialPageRoute(
            builder: (_) => AddTransactionScreen(transactionId: transactionId));
      case '/transaction-detail':
        final transactionId = settings.arguments as String;
        return MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(transactionId: transactionId));
      case '/budgets':
        return MaterialPageRoute(builder: (_) => const BudgetsScreen());
      case '/budget-detail':
        final budgetId = settings.arguments as String;
        return MaterialPageRoute(
            builder: (_) => BudgetDetailScreen(budgetId: budgetId));
      case '/categories':
        return MaterialPageRoute(builder: (_) => const CategoriesScreen());
      case '/add-category':
        return MaterialPageRoute(
            builder: (_) => CategoryEditScreen(categoryId: null));
      case '/edit-category':
        final categoryId = settings.arguments as String;
        return MaterialPageRoute(
            builder: (_) => CategoryEditScreen(categoryId: categoryId));
      case '/reports':
        return MaterialPageRoute(builder: (_) => const ReportsScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
            builder: (_) => const Scaffold(
                  body: Center(child: Text('Page not found')),
                ));
    }
  }
}

