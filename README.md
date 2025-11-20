# Flutter Money Management App

A comprehensive Flutter application for managing personal finances with budgets, transactions, and reports.

## Features

✅ **Authentication** - Local PIN-based authentication
✅ **Categories CRUD** - Create, edit, delete categories with validation
✅ **Transactions** - Create, edit, delete transactions with receipt attachment
✅ **Budgets (Hũ chi tiêu)** - Set monthly/yearly/custom budgets with overdraft control
✅ **Budget Enforcement** - Atomic transactions that respect budget limits
✅ **Accounts/Wallets** - Multiple accounts with balance tracking
✅ **Reports** - Monthly and yearly reports with charts
✅ **Localization** - Support for English and Vietnamese
✅ **Dark Mode** - Light/dark theme support
✅ **Tests** - Unit tests, integration tests, and widget tests

## Tech Stack

- **Flutter SDK**: 3.32.7
- **State Management**: hooks_riverpod
- **Database**: drift (SQLite)
- **Code Generation**: freezed, json_serializable
- **Localization**: flutter_localizations, intl
- **Charts**: fl_chart
- **Testing**: mocktail, flutter_test

## Project Structure

```
lib/
├── main.dart
├── l10n/                          # Localization files
│   ├── app_en.arb
│   └── app_vi.arb
└── src/
    ├── app.dart                   # Main app widget
    ├── app_router.dart            # Route configuration
    ├── data/
    │   ├── local/
    │   │   ├── app_database.dart  # Drift database
    │   │   ├── daos/              # Data access objects
    │   │   └── tables/            # Table definitions
    │   └── repositories/          # Repository layer
    ├── models/                    # Freezed data models
    ├── providers/                 # Riverpod providers
    ├── services/                  # Business logic
    │   ├── auth_service.dart
    │   ├── budget_service.dart    # Budget enforcement logic
    │   └── report_service.dart
    ├── theme/                     # Theme configuration
    ├── i18n/                      # Locale & theme providers
    └── ui/
        ├── screens/               # App screens
        └── widgets/               # Reusable widgets
```

## Setup Instructions

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Generate Code

Generate localization files:
```bash
flutter gen-l10n
```

Generate drift, freezed, and json_serializable code:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Run the App

```bash
flutter run
```

### 4. Run Tests

```bash
flutter test
```

## Key Features Implementation

### Budget System (Hũ chi tiêu)

The budget system is the core feature with the following characteristics:

1. **Budget Model**: Tracks `limitCents`, `consumedCents`, `overdraftCents`
2. **Period Types**: Monthly, Yearly, Custom
3. **Overlap Prevention**: Only one budget per category per period
4. **Budget Enforcement**: 
   - When creating a transaction, `BudgetService.applyTransactionToBudget()` is called
   - If budget would be exceeded and `allowOverdraft=false`, throws `BudgetExceededException`
   - All operations are atomic using `drift.transaction()`
5. **Recalculation**: Budgets can be recalculated from existing transactions

### Transaction-Budget Integration

```dart
// In TransactionRepository.createTransaction()
await database.transaction(() async {
  // 1. Insert transaction
  final id = await transactionDao.insertTransaction(transaction);
  
  // 2. Apply to budget (throws if exceeded)
  await budgetService.applyTransactionToBudget(transaction);
  
  // 3. Update account balance
  await accountDao.updateBalance(accountId, amountDelta);
  
  // If any step fails, entire transaction rolls back
});
```

### Money Handling

All monetary values are stored as **integer cents** to avoid floating-point precision issues:

```dart
// Store: 10000 cents = $100.00
final amountCents = (amountInDollars * 100).round();

// Display:
final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
final displayAmount = formatter.format(amountCents / 100);
```

## Database Schema

### Transactions Table
- id, amountCents, currency, dateTime
- categoryId (FK), accountId (FK)
- type (expense/income), note, receiptPath
- createdAt, updatedAt

### Categories Table
- id, name, iconName, colorValue
- createdAt, updatedAt

### Accounts Table
- id, name, balanceCents, currency
- type (cash/card/bank)
- createdAt, updatedAt

### Budgets Table
- id, categoryId (FK)
- periodType, periodStart, periodEnd
- limitCents, consumedCents, allowOverdraft, overdraftCents
- createdAt, updatedAt

## Testing

### Unit Tests (`test/budget_service_test.dart`)
- Budget application within limit
- Budget exceeded exception
- Overdraft allowed behavior

### Integration Tests (`test/transaction_budget_integration_test.dart`)
- Transaction rollback on budget exceeded
- Atomic transaction + budget + account update

### Widget Tests (`test/add_transaction_widget_test.dart`)
- UI element rendering
- Form validation

## CI/CD

GitHub Actions workflow (`.github/workflows/ci.yml`):
- Run `flutter analyze`
- Run `flutter test --coverage`
- Build APK
- Upload coverage to Codecov
- Upload APK artifact

## Localization

The app supports English and Vietnamese:

```dart
// In your widget:
final l10n = AppLocalizations.of(context)!;
Text(l10n.budgetExceeded);
```

Switch language in Settings screen.

## Theme

Switch between light and dark mode in Settings screen. Theme state is persisted using SharedPreferences.

## Development Guidelines

1. **All money values**: Use integer cents, never double
2. **Database operations**: Use drift transactions for atomicity
3. **Budget enforcement**: Always call `BudgetService.applyTransactionToBudget()` when creating expense transactions
4. **Error handling**: Catch and handle `BudgetExceededException`, `CategoryInUseException`, `BudgetOverlapException`
5. **Testing**: Write tests for all business logic

## Known Limitations

- Authentication is local-only (no backend integration)
- Sync functionality is stubbed (no real implementation)
- Receipt images stored locally only

## Future Enhancements

- Cloud sync with backend API
- Recurring transactions
- Bulk import/export
- Multi-currency support with exchange rates
- Advanced filtering and search
- Budget templates
- Notifications for budget alerts

## License

MIT License

## Contributing

1. Fork the repository
2. Create a feature branch
3. Run tests: `flutter test`
4. Submit a pull request

## Support

For issues or questions, please open an issue on GitHub.

