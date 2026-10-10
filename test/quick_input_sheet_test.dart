import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/budgets/services/budget_service.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/categories/providers/category_providers.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/quick_input_review_sheet.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/voice_input_sheet.dart';
import 'package:flutter_money_management/src/features/transactions/providers/transaction_providers.dart';
import 'package:flutter_money_management/src/features/transactions/repositories/transaction_repository.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/presentation/widgets/wallet_field.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/shared/providers/preferences_provider.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_money_management/src/ui/widgets/app_input.dart';
import 'package:flutter_money_management/src/utils/voice_transaction_parser.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

late SharedPreferences _prefs;

final _now = DateTime(2026, 10, 9);
Category _category(String id, String name) => Category(
      id: id,
      name: name,
      type: CategoryType.expense,
      iconName: 'restaurant',
      colorValue: Colors.blue.toARGB32(),
      createdAt: _now,
      updatedAt: _now,
    );
Wallet _wallet(String id, String name, {bool isDefault = false}) => Wallet(
      id: id,
      workspaceId: 'workspace',
      name: name,
      iconName: 'wallet',
      colorValue: Colors.blue.toARGB32(),
      isDefault: isDefault,
      createdAt: _now,
      updatedAt: _now,
    );
final _categories = [
  _category('food', 'Ăn uống'),
  _category('travel', 'Di chuyển')
];
final _wallets = [
  _wallet('cash', 'Cash', isDefault: true),
  _wallet('momo', 'Momo')
];

VoiceParseResult _item(String note) => VoiceParseResult(
      rawText: note,
      note: note,
      amountVnd: 30000,
      date: _now,
      type: TransactionType.expense,
      categoryId: 'food',
      categoryName: 'Ăn uống',
      walletId: 'momo',
      walletName: 'Momo',
    );

Widget _app(Widget home,
        {Brightness brightness = Brightness.light,
        Locale locale = const Locale('en'),
        double textScale = 1}) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(brightness: brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    );

Widget _screen(
        {TransactionRepository? repository,
        List<Transaction> history = const [],
        Locale locale = const Locale('en'),
        double textScale = 1}) =>
    ProviderScope(
      overrides: [
        workspaceListProvider.overrideWith((ref) async => [
              Workspace(
                id: 'workspace',
                name: 'Test',
                type: 'personal',
                ownerId: 'user',
                role: 'owner',
                createdAt: _now,
                updatedAt: _now,
              ),
            ]),
        activeWorkspaceIdProvider.overrideWith((ref) => 'workspace'),
        activeWorkspaceProvider.overrideWithValue(Workspace(
          id: 'workspace',
          name: 'Test',
          type: 'personal',
          ownerId: 'user',
          role: 'owner',
          createdAt: _now,
          updatedAt: _now,
        )),
        categoriesForWorkspaceProvider('workspace')
            .overrideWith((ref) async => _categories),
        walletsForWorkspaceProvider('workspace')
            .overrideWith((ref) async => _wallets),
        transactionsProvider.overrideWith((ref) async => history),
        sharedPreferencesProvider.overrideWithValue(_prefs),
        if (repository != null)
          transactionRepositoryProvider.overrideWithValue(repository),
      ],
      child: _app(const AddTransactionScreen(),
          locale: locale, textScale: textScale),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  setUpAll(() {
    registerFallbackValue(Transaction(
      id: '',
      amountCents: 1,
      currency: 'VND',
      dateTime: _now,
      type: TransactionType.expense,
      walletId: 'momo',
      createdAt: _now,
      updatedAt: _now,
    ));
  });

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('extra amount warning updates with commas in $brightness',
        (tester) async {
      await tester.pumpWidget(_app(
          const Scaffold(body: VoiceInputSheet(categories: [])),
          brightness: brightness));
      await tester.enterText(find.byType(TextField), 'cafe 30k và bánh 50k');
      await tester.pumpAndSettle();
      final warning = find
          .text('Several amounts found. Separate transactions with commas.');
      expect(warning, findsOneWidget);
      expect(tester.widget<Text>(warning).style!.color,
          Theme.of(tester.element(warning)).colorScheme.error);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull);
      await tester.enterText(find.byType(TextField), 'cafe 30k, bánh 50k');
      await tester.pumpAndSettle();
      expect(warning, findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('review warning allows saving and clears after confirmed edit',
      (tester) async {
    final item = VoiceParseResult(
      rawText: 'cafe 30k và bánh 50k',
      note: 'Cafe và bánh 50k',
      amountVnd: 30000,
      date: _now,
      type: TransactionType.expense,
      categoryId: 'food',
      categoryName: 'Ăn uống',
      walletId: 'momo',
      walletName: 'Momo',
      hasExtraAmounts: true,
    );
    final saved = <VoiceParseResult>[];
    await tester.pumpWidget(_app(Scaffold(
        body: QuickInputReviewSheet(
      results: [item],
      categories: _categories,
      wallets: _wallets,
      onSave: (value) async {
        saved.add(value);
        return false;
      },
    ))));
    final warning =
        find.text('Several amounts found. Separate transactions with commas.');
    expect(warning, findsOneWidget);
    await tester.tap(find.text('Save remaining transactions'));
    await tester.pumpAndSettle();
    expect(saved.single.hasExtraAmounts, isTrue);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();
    expect(warning, findsNothing);
    await tester.tap(find.text('Save remaining transactions'));
    await tester.pumpAndSettle();
    expect(saved.last.hasExtraAmounts, isFalse);
  });

  testWidgets('typed input fills amount, cleaned note, category and wallet',
      (tester) async {
    await tester.pumpWidget(_screen());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Type or speak a transaction'));
    await tester.pumpAndSettle();
    expect(tester.widget<VoiceInputSheet>(find.byType(VoiceInputSheet)).wallets,
        hasLength(2));
    expect(
        tester.widget<VoiceInputSheet>(find.byType(VoiceInputSheet)).categories,
        hasLength(2));
    await tester.enterText(
        find.descendant(
            of: find.byType(VoiceInputSheet), matching: find.byType(TextField)),
        'cafe 30k hom qua vi momo');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Chip, 'Wallet: Momo'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(ExpansionTile));
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();
    final inputs = tester.widgetList<AppInput>(find.byType(AppInput));
    expect(
        inputs.firstWhere((input) => input.label == 'Amount').controller!.text,
        '30.000');
    expect(
        inputs
            .firstWhere((input) => input.label.startsWith('Note'))
            .controller!
            .text,
        'Cafe');
    expect(tester.widget<WalletField>(find.byType(WalletField)).wallet!.id,
        'momo');
    await tester.pumpWidget(const SizedBox());
  });

  for (final sameWorkspace in [true, false]) {
    testWidgets(
        'history suggestions ${sameWorkspace ? "stay in active" : "do not cross"} workspace',
        (tester) async {
      final history = List.generate(
          3,
          (index) => Transaction(
                id: '$index',
                amountCents: 3000000,
                currency: 'VND',
                dateTime: _now,
                type: TransactionType.expense,
                categoryId: 'food',
                walletId: 'momo',
                note: 'quán quen',
                createdAt: _now,
                updatedAt: _now,
              ));
      await tester.pumpWidget(_screen(history: history));
      await tester.pumpAndSettle();
      if (!sameWorkspace) {
        final container = ProviderScope.containerOf(
            tester.element(find.byType(AddTransactionScreen)));
        container.read(activeWorkspaceIdProvider.notifier).state = 'other';
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byTooltip('Type or speak a transaction'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.descendant(
              of: find.byType(VoiceInputSheet),
              matching: find.byType(TextField)),
          'quan quen 30k');
      await tester.pumpAndSettle();
      expect(find.textContaining('Suggested from history'),
          sameWorkspace ? findsOneWidget : findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
      'review preserves unsaved items and never repeats confirmed saves',
      (tester) async {
    final calls = <String>[];
    var fail = true;
    await tester.pumpWidget(_app(Scaffold(
        body: QuickInputReviewSheet(
      results: [_item('First'), _item('Second'), _item('Third')],
      categories: _categories,
      wallets: _wallets,
      onSave: (item) async {
        calls.add(item.note!);
        return item.note != 'Second' || !fail;
      },
    ))));
    await tester.tap(find.text('Save remaining transactions'));
    await tester.pumpAndSettle();
    expect(calls, ['First', 'Second']);
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Save remaining transactions'));
    await tester.pumpAndSettle();
    expect(calls, ['First', 'Second', 'Second', 'Third']);
  });

  testWidgets('review edits and removes items; controls lock while saving',
      (tester) async {
    final completion = Completer<bool>();
    final saved = <VoiceParseResult>[];
    await tester.pumpWidget(_app(Scaffold(
        body: QuickInputReviewSheet(
      results: [_item('First'), _item('Second')],
      categories: _categories,
      wallets: _wallets,
      onSave: (item) {
        saved.add(item);
        return completion.future;
      },
    ))));
    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '45000');
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsNothing);
    await tester.tap(find.text('Save remaining transactions'));
    await tester.pump();
    expect(saved.single.amountVnd, 45000);
    expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Close'))
            .onPressed,
        isNull);
    completion.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);
  });

  for (final proceed in [false, true]) {
    testWidgets(
        'batch budget ${proceed ? "override" : "decline"} preserves save contract',
        (tester) async {
      final repository = _MockTransactionRepository();
      final calls = <bool>[];
      when(() => repository.createTransaction(any(),
              allowOverdraft: any(named: 'allowOverdraft'),
              workspaceIdOverride: any(named: 'workspaceIdOverride')))
          .thenAnswer((invocation) async {
        final allow =
            invocation.namedArguments[#allowOverdraft] as bool? ?? false;
        calls.add(allow);
        expect(invocation.namedArguments[#workspaceIdOverride], 'workspace');
        if (!allow) {
          throw BudgetExceededException(
              message: 'Test budget', remainingCents: 0, limitCents: 1);
        }
        return invocation.positionalArguments.first as Transaction;
      });
      await tester.pumpWidget(_screen(repository: repository));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Type or speak a transaction'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.descendant(
              of: find.byType(VoiceInputSheet),
              matching: find.byType(TextField)),
          'cafe 30k, grab 45k vi momo');
      await tester.pumpAndSettle();
      await tester
          .tap(find.widgetWithText(FilledButton, 'Review transactions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save remaining transactions'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Test budget'), findsOneWidget);
      await tester.tap(find.text(proceed ? 'Proceed' : 'Cancel').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      if (proceed) {
        expect(calls, [false, true, false]);
        await tester.tap(find.text('Cancel').last);
        await tester.pumpAndSettle();
        expect(find.text('Cafe'), findsNothing);
        expect(find.text('Grab'), findsOneWidget);
      } else {
        expect(calls, [false]);
        expect(find.text('Cafe'), findsOneWidget);
        expect(find.text('Grab'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets(
        'quick input fits compact ${brightness.name} layout with keyboard and large text',
        (tester) async {
      tester.view.physicalSize = const Size(375, 600);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(
          Builder(
              builder: (context) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: const TextScaler.linear(1.6)),
                    child:
                        const Scaffold(body: VoiceInputSheet(categories: [])),
                  )),
          brightness: brightness));
      await tester.enterText(find.byType(TextField), 'cafe 30k, grab 45k');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Review transactions'));
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), 'cafe 30k và bánh 50k');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find
          .text('Several amounts found. Separate transactions with commas.'));
      await tester.ensureVisible(find.text('Apply'));
      expect(tester.takeException(), isNull);
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('quick input review stays usable in ${brightness.name} landscape',
        (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showQuickInputReviewSheet(
                context,
                results: [_item('Cafe'), _item('Lunch')],
                categories: _categories,
                wallets: _wallets,
                onSave: (_) async => false,
              ),
              child: const Text('Open review'),
            ),
          ),
        ),
        brightness: brightness,
      ));
      await tester.tap(find.text('Open review'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final save = find.text('Save remaining transactions');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(QuickInputReviewSheet), findsOneWidget);
      await tester.ensureVisible(find.text('Edit').first);
      await tester.tap(find.text('Edit').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Apply'));
      await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('dismissing review with pending items asks to discard',
      (tester) async {
    await tester.pumpWidget(_app(
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showQuickInputReviewSheet(
              context,
              results: [_item('Cafe')],
              categories: _categories,
              wallets: _wallets,
              onSave: (_) async => true,
            ),
            child: const Text('Open review'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open review'));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickInputReviewSheet), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(QuickInputReviewSheet), findsNothing);
  });

  testWidgets('transaction entry opens quick input in phone landscape',
      (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_screen());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Type or speak a transaction'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    await tester.enterText(
      find.descendant(
        of: find.byType(VoiceInputSheet),
        matching: find.byType(TextField),
      ),
      'cafe 30k hom qua vi momo',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final apply = find.widgetWithText(FilledButton, 'Apply');
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(find.byType(VoiceInputSheet), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final locale in ['en', 'vi', 'ja']) {
    for (final size in [const Size(844, 390), const Size(1366, 1024)]) {
      testWidgets('add transaction form fits $locale $size', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 180);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_screen(
          locale: Locale(locale),
          textScale: 1.3,
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final details = find.byType(ExpansionTile);
        await tester.ensureVisible(details);
        await tester.tap(details);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final context = tester.element(find.byType(AddTransactionScreen));
        final l10n = AppLocalizations.of(context)!;
        final note = find.byWidgetPredicate(
          (widget) => widget is AppInput && widget.label == l10n.note,
        );
        await tester.ensureVisible(note);
        await tester.enterText(
          find.descendant(of: note, matching: find.byType(TextField)),
          'Lunch with friends',
        );
        await tester.pumpAndSettle();
        expect(find.text('Lunch with friends'), findsOneWidget);
        final dismissKeyboard = find.widgetWithText(TextButton, l10n.skip);
        expect(dismissKeyboard.hitTestable(), findsOneWidget);
        await tester.tap(dismissKeyboard);
        tester.view.viewInsets = const FakeViewPadding();
        await tester.pumpAndSettle();
        final save = find.byType(AppButton);
        await Scrollable.ensureVisible(
          tester.element(save),
          alignment: 1,
        );
        await tester.pumpAndSettle();
        expect(save.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
