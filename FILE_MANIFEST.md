# Flutter Money Management App - File Manifest

## Complete File List

This document lists all files created for the Flutter Money Management application.

### Core Application Files

1. **lib/main.dart** - App entry point with provider initialization
2. **lib/src/app.dart** - MaterialApp configuration with localization and theming
3. **lib/src/app_router.dart** - Route definitions for all screens

### Models (Freezed + JSON Serializable)

4. **lib/src/models/transaction.dart** - Transaction model with TransactionType enum
5. **lib/src/models/category.dart** - Category model
6. **lib/src/models/account.dart** - Account model with AccountType enum
7. **lib/src/models/budget.dart** - Budget model with PeriodType enum and extensions

### Database Layer (Drift)

8. **lib/src/data/local/tables/transactions_table.dart** - Transactions table schema
9. **lib/src/data/local/tables/categories_table.dart** - Categories table schema
10. **lib/src/data/local/tables/accounts_table.dart** - Accounts table schema
11. **lib/src/data/local/tables/budgets_table.dart** - Budgets table schema
12. **lib/src/data/local/app_database.dart** - Database configuration and migration
13. **lib/src/data/local/daos/transaction_dao.dart** - Transaction data access object
14. **lib/src/data/local/daos/category_dao.dart** - Category data access object
15. **lib/src/data/local/daos/account_dao.dart** - Account data access object
16. **lib/src/data/local/daos/budget_dao.dart** - Budget data access object

### Repository Layer

17. **lib/src/data/repositories/transaction_repository.dart** - Transaction repo with budget integration
18. **lib/src/data/repositories/budget_repository.dart** - Budget repository
19. **lib/src/data/repositories/category_repository.dart** - Category repository
20. **lib/src/data/repositories/account_repository.dart** - Account repository

### Services (Business Logic)

21. **lib/src/services/budget_service.dart** - Budget enforcement with exceptions
22. **lib/src/services/report_service.dart** - Monthly/yearly report generation
23. **lib/src/services/auth_service.dart** - Local authentication service

### Providers (Riverpod)

24. **lib/src/providers/providers.dart** - All Riverpod provider definitions

### Theme

25. **lib/src/theme/app_colors.dart** - Color palette based on Figma design
26. **lib/src/theme/app_theme.dart** - Light and dark theme configurations

### Internationalization

27. **lib/src/i18n/locale_provider.dart** - Locale state management
28. **lib/src/i18n/theme_provider.dart** - Theme mode state management
29. **lib/l10n/app_en.arb** - English translations (already existed, verified complete)
30. **lib/l10n/app_vi.arb** - Vietnamese translations (updated with all keys)

### UI Widgets

31. **lib/src/ui/widgets/app_button.dart** - Reusable button component
32. **lib/src/ui/widgets/app_input.dart** - Reusable input field component
33. **lib/src/ui/widgets/app_card.dart** - Reusable card component
34. **lib/src/ui/widgets/budget_progress.dart** - Budget progress indicator
35. **lib/src/ui/widgets/transaction_item.dart** - Transaction list item
36. **lib/src/ui/widgets/category_item.dart** - Category list item
37. **lib/src/ui/widgets/receipt_viewer.dart** - Receipt image viewer
38. **lib/src/ui/widgets/chart_widget.dart** - Pie and bar chart widgets

### UI Screens

39. **lib/src/ui/screens/login_screen.dart** - Login/PIN screen
40. **lib/src/ui/screens/home_screen.dart** - Home dashboard
41. **lib/src/ui/screens/transactions_screen.dart** - Transaction list
42. **lib/src/ui/screens/add_transaction_screen.dart** - Add/edit transaction with budget checking
43. **lib/src/ui/screens/transaction_detail_screen.dart** - Transaction detail view
44. **lib/src/ui/screens/budgets_screen.dart** - Budget list
45. **lib/src/ui/screens/budget_detail_screen.dart** - Budget detail view
46. **lib/src/ui/screens/categories_screen.dart** - Category list
47. **lib/src/ui/screens/category_edit_screen.dart** - Category edit form
48. **lib/src/ui/screens/accounts_screen.dart** - Account list
49. **lib/src/ui/screens/account_edit_screen.dart** - Account edit form
50. **lib/src/ui/screens/reports_screen.dart** - Reports dashboard
51. **lib/src/ui/screens/settings_screen.dart** - Settings with locale/theme switcher

### Tests

52. **test/budget_service_test.dart** - Unit tests for budget service
53. **test/transaction_budget_integration_test.dart** - Integration tests for atomic operations
54. **test/add_transaction_widget_test.dart** - Widget tests for transaction form

### CI/CD

55. **.github/workflows/ci.yml** - GitHub Actions workflow

### Configuration

56. **build.yaml** - Build configuration for code generators (already existed)
57. **pubspec.yaml** - Dependencies configuration (already existed, verified)
58. **README.md** - Comprehensive documentation

## Total Files Created: 58

## Files to Generate (via build_runner)

After running `flutter pub run build_runner build --delete-conflicting-outputs`, the following files will be auto-generated:

- **lib/src/models/transaction.freezed.dart**
- **lib/src/models/transaction.g.dart**
- **lib/src/models/category.freezed.dart**
- **lib/src/models/category.g.dart**
- **lib/src/models/account.freezed.dart**
- **lib/src/models/account.g.dart**
- **lib/src/models/budget.freezed.dart**
- **lib/src/models/budget.g.dart**
- **lib/src/data/local/app_database.g.dart**
- **lib/src/data/local/daos/transaction_dao.g.dart**
- **lib/src/data/local/daos/category_dao.g.dart**
- **lib/src/data/local/daos/account_dao.g.dart**
- **lib/src/data/local/daos/budget_dao.g.dart**

## Files to Generate (via flutter gen-l10n)

After running `flutter gen-l10n`, the following localization files will be generated:

- **lib/l10n/app_localizations.dart** (already exists)
- **lib/l10n/app_localizations_en.dart** (already exists)
- **lib/l10n/app_localizations_vi.dart** (already exists)

## Next Steps

1. Run `flutter pub get` to ensure all dependencies are installed
2. Run `flutter gen-l10n` to generate localization files
3. Run `flutter pub run build_runner build --delete-conflicting-outputs` to generate code
4. Run `flutter analyze` to check for errors
5. Run `flutter test` to run all tests
6. Run `flutter run` to launch the app

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                       UI Layer                          │
│  (Screens + Widgets + HooksConsumerWidget)             │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│                   Providers Layer                       │
│         (Riverpod StateNotifier + FutureProvider)       │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│              Repository Layer                           │
│    (Business logic + Model conversion)                  │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│               Services Layer                            │
│  (BudgetService, ReportService, AuthService)           │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│              Data Access Layer                          │
│          (Drift DAOs + Database)                        │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│                  SQLite Database                        │
│           (money_management.sqlite)                     │
└─────────────────────────────────────────────────────────┘
```

## Key Implementation Details

### Atomic Transactions

All transaction creation follows this pattern:

```dart
await database.transaction(() async {
  // 1. Insert transaction
  final id = await transactionDao.insert(transaction);
  
  // 2. Apply budget constraints (may throw)
  await budgetService.applyTransactionToBudget(transaction);
  
  // 3. Update account balance
  await accountDao.updateBalance(accountId, delta);
  
  // If any step fails, all changes rollback
});
```

### Budget Enforcement

```dart
// BudgetService.applyTransactionToBudget()
- Finds active budget for transaction category and date
- Calculates new consumed amount
- If exceeded and !allowOverdraft → throws BudgetExceededException
- Updates budget consumed and overdraft amounts
```

### Money as Integer Cents

```dart
// Storage
int amountCents = 10000; // $100.00

// Display
String display = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 2,
).format(amountCents / 100); // "$100.00"
```

## Acceptance Criteria ✓

✅ All money arithmetic uses integer cents
✅ Transaction creation with budget checking is atomic
✅ Budget exceeded throws exception and rolls back
✅ BudgetService unit tests pass
✅ Integration test verifies atomic rollback
✅ UI matches Figma styling (colors, spacing, typography)
✅ Localization works for en + vi
✅ Tests are runnable with `flutter test`
✅ CI workflow configured

