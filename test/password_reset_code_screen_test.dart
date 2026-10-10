import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/presentation/screens/password_reset_code_screen.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/auth/services/supabase_auth_service.dart';

class _MockAuthService extends Mock implements SupabaseAuthService {}

void main() {
  late _MockAuthService service;

  setUp(() => service = _MockAuthService());

  Future<void> showScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [supabaseAuthServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PasswordResetCodeScreen(email: 'test@example.com'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('rejects short codes without verifying', (tester) async {
    await showScreen(tester);
    await tester.enterText(find.byType(TextFormField), '123');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(
        find.text('Enter the numeric code from your email.'), findsOneWidget);
    verifyNever(() => service.verifyPasswordResetCode(
          email: any(named: 'email'),
          code: any(named: 'code'),
        ));
  });

  testWidgets('shows verification failure and permits another attempt',
      (tester) async {
    when(() => service.verifyPasswordResetCode(
          email: 'test@example.com',
          code: '123456',
        )).thenThrow(Exception('expired'));
    await showScreen(tester);
    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not verify the code. Check it or request a new one.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    verify(() => service.verifyPasswordResetCode(
          email: 'test@example.com',
          code: '123456',
        )).called(2);
  });

  testWidgets('resends to the same email and clears the old code',
      (tester) async {
    when(() => service.resetPassword('test@example.com'))
        .thenAnswer((_) async {});
    await showScreen(tester);
    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text('Send a new code'));
    await tester.pumpAndSettle();
    verify(() => service.resetPassword('test@example.com')).called(1);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        isEmpty);
  });
}
