// path: test/add_transaction_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_money_management/src/ui/screens/add_transaction_screen.dart';
import 'package:flutter_money_management/src/data/local/app_database.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.withQueryExecutor(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('AddTransactionScreen displays validation error for empty amount', (WidgetTester tester) async {
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          home: AddTransactionScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Try to save without entering amount
    final saveButton = find.text('Save');
    expect(saveButton, findsOneWidget);

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Should show error
    expect(find.text('Please enter valid amount'), findsOneWidget);
  });

  testWidgets('AddTransactionScreen requires category and account selection', (WidgetTester tester) async {
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          home: AddTransactionScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Enter amount but don't select category/account
    final amountField = find.byType(TextFormField).first;
    await tester.enterText(amountField, '100.00');
    await tester.pumpAndSettle();

    // Try to save
    final saveButton = find.text('Save');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Should show error
    expect(find.text('Please select category and account'), findsOneWidget);
  });

  testWidgets('AddTransactionScreen switches between expense and income', (WidgetTester tester) async {
    final sharedPreferences = await SharedPreferences.getInstance();

    // Create test categories
    await database.categoryDao.insertCategory(
      CategoriesCompanion.insert(
        name: 'Food',
        iconName: '🍔',
        colorValue: 0xFFFF0000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    await database.categoryDao.insertCategory(
      CategoriesCompanion.insert(
        name: 'Salary',
        iconName: '💰',
        colorValue: 0xFF00FF00,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          home: AddTransactionScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initially should be on expense
    expect(find.text('Expense'), findsOneWidget);

    // Switch to income
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();

    // Categories should update
    expect(find.text('Salary'), findsOneWidget);
  });
}

