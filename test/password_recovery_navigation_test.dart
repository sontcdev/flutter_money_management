import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/ui/widgets/auth_callback_feedback_listener.dart';

void main() {
  testWidgets(
      'verified recovery opens password route through the app navigator',
      (tester) async {
    final events = StreamController<AuthState>();
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authStateProvider.overrideWith((ref) => events.stream)],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => AuthCallbackFeedbackListener(
            navigatorKey: navigatorKey,
            child: child!,
          ),
          routes: {
            '/reset-password': (_) =>
                const Scaffold(body: Text('New password')),
          },
          home: const Scaffold(body: Text('Enter OTP')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Enter OTP'), findsOneWidget);
    expect(find.text('New password'), findsNothing);
    events.add(AuthState(
      AuthChangeEvent.passwordRecovery,
      Session(
        accessToken: 'test-recovery-token',
        tokenType: 'bearer',
        user: const User(
          id: 'test-user',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-10-10T00:00:00Z',
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('New password'), findsOneWidget);
    expect(find.text('Enter OTP'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    events.close();
  });
}
