import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/presentation/screens/category_edit_screen.dart';
import 'package:flutter_money_management/src/features/settings/providers/settings_preferences_providers.dart';
import 'package:flutter_money_management/src/features/workspace/presentation/screens/create_workspace_screen.dart';
import 'package:flutter_money_management/src/shared/providers/preferences_provider.dart';

Widget _app(Locale locale, Widget home, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

void main() {
  late List<Override> overrides;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    overrides = [
      sharedPreferencesProvider.overrideWithValue(prefs),
      monthStartDayProvider.overrideWith((ref) => MonthStartDayNotifier(prefs)),
    ];
  });

  for (final code in ['vi', 'ja']) {
    final locale = Locale(code);

    testWidgets('CreateWorkspaceScreen is localized ($code)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await tester
          .pumpWidget(_app(locale, const CreateWorkspaceScreen(), overrides));
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(locale);

      expect(l10n.createWorkspaceTitle, l10n.createWorkspaceAction);
      expect(find.text(l10n.createWorkspaceTitle), findsNWidgets(2));
      expect(find.text(l10n.createWorkspaceDescription), findsOneWidget);
      expect(find.text(l10n.workspaceNameLabel), findsOneWidget);
      for (final english in [
        'Create Workspace',
        'Create workspace',
        'Workspace name',
        'Description',
        'Create a shared workspace for your household or group.',
      ]) {
        expect(find.text(english), findsNothing);
      }

      await tester
          .tap(find.widgetWithText(ElevatedButton, l10n.createWorkspaceAction));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(l10n.workspaceNameRequired), findsOneWidget);
      expect(find.text('Workspace name is required'), findsNothing);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('CategoryEditScreen budget options localized ($code)',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await tester
          .pumpWidget(_app(locale, const CategoryEditScreen(), overrides));
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(locale);

      expect(find.text(l10n.createBudgetForCategory), findsOneWidget);
      expect(find.text(l10n.budgetOnlyForExpense), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text(l10n.period), findsOneWidget);
      expect(find.text(l10n.monthly), findsWidgets);
      expect(find.text(l10n.amount), findsOneWidget);
      for (final english in [
        'Create budget for this category',
        'Only available for expense categories',
        'Budget period',
        'Budget amount',
        'Monthly',
      ]) {
        expect(find.text(english), findsNothing);
      }
    });
  }
}
