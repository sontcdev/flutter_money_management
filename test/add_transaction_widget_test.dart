// path: test/add_transaction_widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:test3_cursor/src/ui/screens/add_transaction_screen.dart';

void main() {
  testWidgets('AddTransactionScreen - should validate required fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AddTransactionScreen(),
        ),
      ),
    );

    // Find save button
    final saveButton = find.text('Save');
    expect(saveButton, findsOneWidget);

    // Tap save without filling fields
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Should show validation errors
    expect(find.text('This field is required'), findsWidgets);
  });

  testWidgets('AddTransactionScreen - should validate amount format',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AddTransactionScreen(),
        ),
      ),
    );

    // Enter invalid amount
    final amountField = find.byType(TextFormField).first;
    await tester.enterText(amountField, 'invalid');
    await tester.pumpAndSettle();

    // Should show validation error
    expect(find.text('Invalid amount'), findsOneWidget);
  });
}

