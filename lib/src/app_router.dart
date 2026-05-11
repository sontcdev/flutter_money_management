// path: lib/src/app_router.dart

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'app/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/auth/presentation/screens/sign_in_screen.dart';
import 'features/auth/presentation/screens/sign_up_screen.dart';
import 'features/budgets/presentation/screens/budget_detail_screen.dart';
import 'features/budgets/presentation/screens/budget_edit_screen.dart';
import 'features/budgets/presentation/screens/budgets_screen.dart';
import 'features/categories/presentation/screens/categories_screen.dart';
import 'features/categories/presentation/screens/category_edit_screen.dart';
import 'features/categories/presentation/screens/icon_management_screen.dart';
import 'features/home/presentation/screens/dashboard_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/reports/presentation/screens/report_calendar_screen.dart';
import 'features/reports/presentation/screens/reports_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/transactions/presentation/screens/add_transaction_screen.dart';
import 'features/transactions/presentation/screens/edit_transaction_screen.dart';
import 'features/transactions/presentation/screens/transaction_detail_screen.dart';
import 'features/transactions/presentation/screens/transaction_management_screen.dart';
import 'features/transactions/presentation/screens/transactions_screen.dart';
import 'features/workspace/presentation/screens/workspace_management_screen.dart';
import 'features/workspace/presentation/screens/workspace_selection_screen.dart';
import 'features/categories/models/category.dart';
import 'features/budgets/models/budget.dart';
import 'features/transactions/models/transaction.dart' as model;
import 'utils/animations.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return AppAnimations.fadeRoute(const SplashScreen());
      case '/sign-in':
        return AppAnimations.fadeRoute(const SignInScreen());
      case '/sign-up':
        return AppAnimations.slideRoute(const SignUpScreen());
      case '/reset-password':
        return AppAnimations.slideRoute(const ResetPasswordScreen());
      case '/workspace-selection':
        return AppAnimations.fadeRoute(const WorkspaceSelectionScreen());
      case '/home':
        return AppAnimations.fadeRoute(const HomeScreen());
      case '/dashboard':
        return AppAnimations.fadeRoute(const DashboardScreen());
      case '/add-transaction':
        final args = settings.arguments as Map<String, dynamic>?;
        final initialType = args?['type'] as model.TransactionType?;
        return AppAnimations.slideRoute(
          AddTransactionScreen(initialType: initialType),
        );
      case '/transactions':
        return AppAnimations.slideRoute(const TransactionsScreen());
      case '/edit-transaction':
        final transactionId = settings.arguments as String;
        return AppAnimations.slideRoute(
          EditTransactionScreen(transactionId: transactionId),
        );
      case '/transaction-detail':
        final transactionId = settings.arguments as String;
        return AppAnimations.slideRoute(
          TransactionDetailScreen(transactionId: transactionId),
        );
      case '/budgets':
        return AppAnimations.slideRoute(const BudgetsScreen());
      case '/budget-detail':
        final budgetId = settings.arguments as String;
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
      case '/workspace-management':
        return AppAnimations.slideRoute(const WorkspaceManagementScreen());
      case '/icon-management':
        return AppAnimations.slideRoute(const IconManagementScreen());
      case '/transaction-management':
        return AppAnimations.slideRoute(const TransactionManagementScreen());
      default:
        return AppAnimations.fadeRoute(
          Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: Text(
                  AppLocalizations.of(context)?.routeNotFound(
                        settings.name ?? '',
                      ) ??
                      'No route defined for ${settings.name}',
                ),
              ),
            ),
          ),
        );
    }
  }
}
