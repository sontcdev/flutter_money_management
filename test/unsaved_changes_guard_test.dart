import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/ui/widgets/unsaved_changes_guard.dart';

Future<GlobalKey<NavigatorState>> _pump(
  WidgetTester tester, {
  required bool dirty,
  UnsavedChangesController? controller,
  Locale locale = const Locale('en'),
}) async {
  final key = GlobalKey<NavigatorState>();
  await tester.pumpWidget(MaterialApp(
    navigatorKey: key,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(body: Text('home')),
  ));
  key.currentState!.push(MaterialPageRoute<void>(
    builder: (_) => UnsavedChangesGuard(
      isDirty: dirty,
      controller: controller,
      child: const Scaffold(body: Text('editor')),
    ),
  ));
  await tester.pumpAndSettle();
  return key;
}

void main() {
  testWidgets('clean pop works without dialog', (tester) async {
    final key = await _pump(tester, dirty: false);
    await key.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('editor'), findsNothing);
  });

  testWidgets('dirty -> Keep editing stays', (tester) async {
    final key = await _pump(tester, dirty: true);
    await key.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('editor'), findsOneWidget);
  });

  testWidgets('dirty -> Discard pops', (tester) async {
    final key = await _pump(tester, dirty: true);
    await key.currentState!.maybePop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('editor'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('markSaved bypasses dialog', (tester) async {
    final c = UnsavedChangesController();
    final key = await _pump(tester, dirty: true, controller: c);
    c.markSaved();
    await tester.pump();
    await key.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('editor'), findsNothing);
  });

  testWidgets('dialog is localized (vi)', (tester) async {
    final key = await _pump(tester, dirty: true, locale: const Locale('vi'));
    await key.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Bỏ thay đổi?'), findsOneWidget);
    expect(find.text('Tiếp tục chỉnh sửa'), findsOneWidget);
    expect(find.text('Bỏ'), findsOneWidget);
  });

  testWidgets('second back while dialog open does not stack dialogs',
      (tester) async {
    final key = await _pump(tester, dirty: true);
    await key.currentState!.maybePop();
    await tester.pump();
    // Fire the guard callback again while the dialog is still open.
    final scope = tester.widget<PopScope>(
      find.byWidgetPredicate((w) => w is PopScope).first,
    );
    scope.onPopInvokedWithResult!(false, null);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('editor'), findsOneWidget);
  });

  testWidgets(
      'route removed while awaiting confirmation: no crash, no extra pop',
      (tester) async {
    final key = await _pump(tester, dirty: true);
    await key.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    // Remove the guarded route underneath the open dialog.
    final guarded = ModalRoute.of(tester.element(find.text('editor')))!;
    key.currentState!.removeRoute(guarded);
    await tester.pumpAndSettle();
    expect(find.text('editor'), findsNothing);
    expect(find.text('home'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Home must survive: Discard must not pop an unrelated route.
    expect(find.text('home'), findsOneWidget);
  });
}
