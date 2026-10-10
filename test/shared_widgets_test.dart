import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/ui/widgets/app_segmented_filter.dart';
import 'package:flutter_money_management/src/ui/widgets/app_snack_bar.dart';
import 'package:flutter_money_management/src/ui/widgets/confirm_delete_dialog.dart';
import 'package:flutter_money_management/src/ui/widgets/empty_state.dart';
import 'package:flutter_money_management/src/ui/widgets/load_error_state.dart';
import 'package:flutter_money_management/src/ui/widgets/shimmer_loading.dart';

Widget _app(Widget home, {bool reduceMotion = false}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('vi'), Locale('ja')],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
    home: Scaffold(body: home),
  );
}

Widget _launcher(Future<void> Function(BuildContext context) onPressed) {
  return Builder(
    builder: (context) => Center(
      child: TextButton(
        onPressed: () => onPressed(context),
        child: const Text('Open'),
      ),
    ),
  );
}

void main() {
  group('InlineLoadErrorState', () {
    testWidgets('shows the default message and retries', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        _app(InlineLoadErrorState(onRetry: () => retries++)),
      );

      expect(find.text("Couldn't load this section."), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });

    testWidgets('shows a custom message', (tester) async {
      await tester.pumpWidget(
        _app(InlineLoadErrorState(onRetry: () {}, message: 'Offline')),
      );

      expect(find.text('Offline'), findsOneWidget);
    });
  });

  group('showAppSnackBar', () {
    testWidgets('shows the message and calls onUndo', (tester) async {
      var undoCount = 0;
      await tester.pumpWidget(
        _app(
          _launcher((context) async {
            showAppSnackBar(
              context,
              'Item deleted',
              onUndo: () => undoCount++,
            );
          }),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Item deleted'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(undoCount, 1);
    });

    testWidgets('has no undo action without onUndo', (tester) async {
      await tester.pumpWidget(
        _app(
          _launcher((context) async {
            showAppSnackBar(context, 'Saved', type: AppSnackBarType.success);
          }),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Undo'), findsNothing);
    });
  });

  group('ConfirmDeleteDialog', () {
    Future<List<bool>> pumpDialog(
      WidgetTester tester, {
      String? itemName,
      String? consequence,
      String? confirmLabel,
    }) async {
      final results = <bool>[];
      await tester.pumpWidget(
        _app(
          _launcher((context) async {
            results.add(
              await ConfirmDeleteDialog.show(
                context,
                itemName: itemName,
                consequence: consequence,
                confirmLabel: confirmLabel,
              ),
            );
          }),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      return results;
    }

    testWidgets('renders item name, message and consequence', (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await pumpDialog(
        tester,
        itemName: 'Groceries',
        consequence: 'All transactions move to Uncategorized.',
      );

      expect(find.text(l10n.deleteItemTitle('Groceries')), findsOneWidget);
      expect(find.text(l10n.deleteCannotBeUndone), findsOneWidget);
      expect(
        find.text('All transactions move to Uncategorized.'),
        findsOneWidget,
      );
    });

    testWidgets('confirm returns true', (tester) async {
      final results = await pumpDialog(tester, itemName: 'Groceries');

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(results, [true]);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('cancel returns false', (tester) async {
      final results = await pumpDialog(tester, itemName: 'Groceries');

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(results, [false]);
    });

    testWidgets('uses a custom confirm label', (tester) async {
      final results = await pumpDialog(tester, confirmLabel: 'Archive');

      expect(find.text('Delete'), findsNothing);
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(results, [true]);
    });
  });

  group('EmptyState', () {
    testWidgets('first run skips the entrance animation with reduced motion',
        (tester) async {
      var actions = 0;
      await tester.pumpWidget(
        _app(
          EmptyState.firstRun(
            icon: Icons.wallet_outlined,
            title: 'No wallets yet',
            message: 'Add your first wallet',
            actionLabel: 'Add wallet',
            onAction: () => actions++,
          ),
          reduceMotion: true,
        ),
      );

      expect(
        find.descendant(
          of: find.byType(EmptyState),
          matching: find.byWidgetPredicate(
            (widget) => widget is TweenAnimationBuilder,
          ),
        ),
        findsNothing,
      );
      expect(find.text('No wallets yet'), findsOneWidget);
      expect(find.text('Add your first wallet'), findsOneWidget);

      await tester.tap(find.text('Add wallet'));
      expect(actions, 1);
    });

    testWidgets('first run animates without reduced motion', (tester) async {
      await tester.pumpWidget(
        _app(
          const EmptyState.firstRun(
            icon: Icons.wallet_outlined,
            title: 'No wallets yet',
            message: 'Add your first wallet',
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(EmptyState),
          matching: find.byWidgetPredicate(
            (widget) => widget is TweenAnimationBuilder,
          ),
        ),
        findsWidgets,
      );
      await tester.pumpAndSettle();
      expect(find.text('No wallets yet'), findsOneWidget);
    });
  });

  group('ShimmerLoading', () {
    testWidgets('stops animating with reduced motion', (tester) async {
      await tester.pumpWidget(
        _app(
          const ShimmerLoading(width: 120, height: 16),
          reduceMotion: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShimmerLoading), findsOneWidget);
      expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);
    });

    testWidgets('keeps animating without reduced motion', (tester) async {
      await tester.pumpWidget(
        _app(const ShimmerLoading(width: 120, height: 16)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(SchedulerBinding.instance.hasScheduledFrame, isTrue);
    });
  });

  group('AppSegmentedFilter', () {
    Widget filter(String selected, ValueChanged<String> onChanged) {
      return Center(
        child: AppSegmentedFilter<String>(
          options: const [
            FilterOption(label: 'All', value: 'all'),
            FilterOption(label: 'Income', value: 'income'),
            FilterOption(label: 'Expense', value: 'expense'),
          ],
          selectedValue: selected,
          onChanged: onChanged,
        ),
      );
    }

    testWidgets('tapping an option reports its value', (tester) async {
      final changes = <String>[];
      await tester.pumpWidget(_app(filter('all', changes.add)));

      await tester.tap(find.text('Expense'));
      await tester.pumpAndSettle();
      expect(changes, ['expense']);
    });

    testWidgets('marks only the selected option as selected', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(filter('income', (_) {})));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.text('Income')),
        matchesSemantics(
          label: 'Income',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.text('All')),
        matchesSemantics(
          label: 'All',
          isButton: true,
          isSelected: false,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });
}
