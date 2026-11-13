import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/workspace/presentation/screens/create_workspace_screen.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/features/workspace/services/workspace_management_service.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class _FakeService implements WorkspaceManagementService {
  final calls = <String>[];
  final completer = Completer<String>();

  @override
  Future<String> createWorkspace({
    required String name,
    String? description,
    String? avatarPath,
  }) {
    calls.add(name);
    return completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Future<ProviderContainer> _pump(WidgetTester t, _FakeService service) async {
  final container = ProviderContainer(
    overrides: [
      workspaceManagementServiceProvider.overrideWithValue(service),
    ],
  );
  addTearDown(container.dispose);
  await t.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => settings.name == '/workspace-detail'
            ? const Scaffold(body: Text('detail-page'))
            : const CreateWorkspaceScreen(),
      ),
      initialRoute: '/',
    ),
  ));
  await t.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('blank and whitespace name shows inline error, no service call',
      (t) async {
    final service = _FakeService();
    await _pump(t, service);
    final l = AppLocalizations.of(t.element(find.byType(Scaffold)))!;

    await t.tap(find.byType(AppButton));
    await t.pump();
    expect(find.text(l.workspaceNameRequired), findsOneWidget);

    await t.enterText(find.byType(TextFormField).first, '   ');
    await t.tap(find.byType(AppButton));
    await t.pump();
    expect(find.text(l.workspaceNameRequired), findsOneWidget);
    expect(service.calls, isEmpty);
    await t.pump(const Duration(milliseconds: 200));
  });

  testWidgets('name field uses next action; description stays multiline',
      (t) async {
    await _pump(t, _FakeService());
    final fields = t
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].textInputAction, TextInputAction.next);
    expect(fields[1].maxLines, 3);
    expect(fields[1].textInputAction, isNot(TextInputAction.next));
  });

  testWidgets('valid create calls service once, guards duplicate, navigates',
      (t) async {
    final service = _FakeService();
    final container = await _pump(t, service);
    final l = AppLocalizations.of(t.element(find.byType(Scaffold)))!;

    await t.enterText(find.byType(TextFormField).first, ' Home ');
    await t.tap(find.byType(AppButton));
    await t.pump();
    await t.tap(find.byType(AppButton), warnIfMissed: false);
    await t.pump();
    expect(service.calls, [' Home ']);
    expect(find.text(l.workspaceNameRequired), findsNothing);

    service.completer.complete('ws-1');
    await t.pumpAndSettle();
    expect(container.read(activeWorkspaceIdProvider), 'ws-1');
    expect(find.text('detail-page'), findsOneWidget);
  });
}
