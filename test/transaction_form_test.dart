import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/transaction_form_fields.dart';

Widget _app(Widget home) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('vi'), Locale('ja')],
    home: home,
  );
}

class _Launcher extends StatelessWidget {
  final bool isDirty;

  const _Launcher({required this.isDirty});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<Object?>(
              builder: (_) => TransactionDiscardGuard(
                isDirty: isDirty,
                child: Scaffold(
                  appBar: AppBar(title: const Text('Form')),
                  body: Builder(
                    builder: (context) => TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Save'),
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    );
  }
}

void main() {
  group('validateTransactionAmount', () {
    late AppLocalizations l10n;

    setUp(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('rejects empty input', () {
      expect(validateTransactionAmount('', l10n), l10n.amountRequiredError);
    });

    test('rejects zero', () {
      expect(validateTransactionAmount('0', l10n), l10n.invalidAmount);
    });

    test('accepts positive amount', () {
      expect(validateTransactionAmount('50.000', l10n), isNull);
    });
  });

  testWidgets('dirty form asks before discarding on back', (tester) async {
    await tester.pumpWidget(_app(const _Launcher(isDirty: true)));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Form'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Form'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('saving a dirty form pops without confirmation', (tester) async {
    await tester.pumpWidget(_app(const _Launcher(isDirty: true)));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('clean form pops without confirmation', (tester) async {
    await tester.pumpWidget(_app(const _Launcher(isDirty: false)));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('invalid amount shows an inline error', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Builder(
            builder: (context) => Form(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: TextFormField(
                controller: controller,
                validator: (value) => validateTransactionAmount(
                  value,
                  AppLocalizations.of(context)!,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '0');
    await tester.pump();
    expect(find.text('Invalid amount'), findsOneWidget);
  });
}
