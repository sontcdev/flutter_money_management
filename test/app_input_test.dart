import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/ui/widgets/app_input.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Form(child: child)),
    );

void main() {
  testWidgets('forwards textInputAction and autovalidateMode', (tester) async {
    await tester.pumpWidget(_wrap(const AppInput(
      label: 'L',
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.always,
      validator: _alwaysError,
    )));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.textInputAction, TextInputAction.next);
    expect(find.text('bad'), findsOneWidget);
  });

  testWidgets('onFieldSubmitted fires', (tester) async {
    String? submitted;
    await tester.pumpWidget(_wrap(AppInput(
      label: 'L',
      showKeyboardToolbar: false,
      onFieldSubmitted: (v) => submitted = v,
    )));
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(submitted, 'abc');
  });

  testWidgets('external focusNode is used and not disposed', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(_wrap(AppInput(
      label: 'L',
      focusNode: node,
      showKeyboardToolbar: false,
    )));
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode, node);
    node.requestFocus();
    await tester.pump();
    expect(node.hasFocus, isTrue);

    await tester.pumpWidget(_wrap(const SizedBox()));
    // Would throw if the node had been disposed.
    node.addListener(() {});
    node.requestFocus();
  });

  testWidgets('toolbar overlay follows external node and is removed',
      (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(_wrap(AppInput(label: 'L', focusNode: node)));
    node.requestFocus();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(TextButton), findsNWidgets(2));
    node.unfocus();
    await tester.pump();
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('defaults keep current behaviour', (tester) async {
    await tester.pumpWidget(_wrap(const AppInput(label: 'L')));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.textInputAction, isNull);
    expect(field.focusNode, isNotNull);
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(TextButton), findsNWidgets(2));
    await tester.pumpWidget(_wrap(const SizedBox()));
    expect(tester.takeException(), isNull);
  });
}

String? _alwaysError(String? _) => 'bad';
