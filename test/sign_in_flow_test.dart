import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/l10n/app_localizations_en.dart';
import 'package:flutter_money_management/src/data/repositories/supabase_error_mapper.dart';
import 'package:flutter_money_management/src/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/auth/services/supabase_auth_service.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/services/email_persistence_service.dart';
import 'package:flutter_money_management/src/services/error_report_service.dart';
import 'package:flutter_money_management/src/shared/providers/app_service_providers.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';

class _MockAuthService extends Mock implements SupabaseAuthService {}

class _MockEmailPersistence extends Mock implements EmailPersistenceService {}

class _MockErrorReportService extends Mock implements ErrorReportService {}

// Fake, non-secret values. No real credentials are used in this file.
const _email = 'reviewer@example.com';
const _password = 'not-a-real-password';

User _user({String? emailConfirmedAt = '2026-01-01T00:00:00Z'}) => User(
      id: 'user-1',
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
      email: _email,
      emailConfirmedAt: emailConfirmedAt,
    );

Session _session(User user) => Session(
      accessToken: 'fake-access-token',
      tokenType: 'bearer',
      user: user,
    );

Workspace _workspace() => Workspace(
      id: 'ws-1',
      name: 'Personal',
      type: 'personal',
      ownerId: 'user-1',
      role: 'owner',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  final l10n = AppLocalizationsEn();
  late _MockAuthService authService;
  late _MockEmailPersistence emailPersistence;
  late _MockErrorReportService errorReportService;

  setUp(() {
    authService = _MockAuthService();
    emailPersistence = _MockEmailPersistence();
    errorReportService = _MockErrorReportService();
    when(emailPersistence.getSavedEmail).thenReturn(null);
    when(() => emailPersistence.saveEmail(any())).thenAnswer((_) async {});
  });

  Future<void> pumpSignIn(
    WidgetTester tester, {
    required Future<List<Workspace>> Function() workspaces,
    List<String>? visited,
  }) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        supabaseAuthServiceProvider.overrideWithValue(authService),
        emailPersistenceServiceProvider.overrideWithValue(emailPersistence),
        errorReportServiceProvider.overrideWithValue(errorReportService),
        workspaceListProvider.overrideWith((ref) => workspaces()),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: (settings) {
          visited?.add(settings.name ?? '');
          if (settings.name == '/home' ||
              settings.name == '/workspace-selection') {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Scaffold(body: Text('route:${settings.name}')),
            );
          }
          return null;
        },
        home: const SignInScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), _email);
    await tester.enterText(fields.at(1), _password);
    await tester.ensureVisible(find.byType(AppButton));
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();
  }

  void stubSignInSuccess() {
    when(() => authService.signIn(email: _email, password: _password))
        .thenAnswer((_) async => AuthResponse(
              user: _user(),
              session: _session(_user()),
            ));
  }

  testWidgets('sign-in success with a workspace navigates to /home',
      (tester) async {
    stubSignInSuccess();
    final visited = <String>[];
    await pumpSignIn(
      tester,
      workspaces: () async => [_workspace()],
      visited: visited,
    );

    await submit(tester);

    expect(find.text('route:/home'), findsOneWidget);
    expect(visited, contains('/home'));
    verify(() => emailPersistence.saveEmail(_email)).called(1);
  });

  testWidgets('sign-in success without a workspace goes to workspace selection',
      (tester) async {
    stubSignInSuccess();
    await pumpSignIn(tester, workspaces: () async => const []);

    await submit(tester);

    expect(find.text('route:/workspace-selection'), findsOneWidget);
    expect(find.text('route:/home'), findsNothing);
  });

  testWidgets(
      'invalid credentials (mapped like production) show a safe localized '
      'error, no raw exception and no error report dialog', (tester) async {
    // SupabaseAuthService.signIn maps AuthException through
    // mapSupabaseException before it reaches the screen. Reproduce that here.
    when(() => authService.signIn(email: _email, password: _password))
        .thenAnswer((_) async => throw mapSupabaseException(
              const AuthException(
                'Invalid login credentials',
                statusCode: '400',
              ),
            ));
    await pumpSignIn(tester, workspaces: () async => [_workspace()]);

    await submit(tester);

    expect(find.text(l10n.invalidEmailOrPassword), findsOneWidget);
    expect(find.textContaining('AuthException'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('route:/home'), findsNothing);
    // The form stays usable for another attempt.
    expect(find.byType(AppButton), findsOneWidget);
    verifyNever(() => emailPersistence.saveEmail(any()));
  });

  testWidgets('unconfirmed email shows the verify-email message',
      (tester) async {
    when(() => authService.signIn(email: _email, password: _password))
        .thenAnswer((_) async => throw mapSupabaseException(
              const AuthException('Email not confirmed', statusCode: '400'),
            ));
    await pumpSignIn(tester, workspaces: () async => [_workspace()]);

    await submit(tester);

    expect(find.text(l10n.verifyEmailBeforeSignIn), findsOneWidget);
    expect(find.text('route:/home'), findsNothing);
  });

  testWidgets('email with a long top-level domain is accepted', (tester) async {
    const longTldEmail = 'reviewer@example.technology';
    when(() => authService.signIn(email: longTldEmail, password: _password))
        .thenAnswer((_) async => AuthResponse(
              user: _user(),
              session: _session(_user()),
            ));
    await pumpSignIn(tester, workspaces: () async => [_workspace()]);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), longTldEmail);
    await tester.enterText(fields.at(1), _password);
    await tester.ensureVisible(find.byType(AppButton));
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.enterValidEmailAddress), findsNothing);
    expect(find.text('route:/home'), findsOneWidget);
  });

  testWidgets('client-side validation blocks empty and invalid input',
      (tester) async {
    await pumpSignIn(tester, workspaces: () async => [_workspace()]);

    await tester.ensureVisible(find.byType(AppButton));
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();
    expect(find.text(l10n.enterEmail), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'not-an-email');
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();
    expect(find.text(l10n.enterValidEmailAddress), findsOneWidget);

    verifyNever(() => authService.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ));
  });

  testWidgets(
      'workspace fetch failure keeps the user on sign-in and a retry '
      'succeeds', (tester) async {
    stubSignInSuccess();
    var failNext = true;
    await pumpSignIn(
      tester,
      workspaces: () async {
        if (failNext) {
          throw StateError('workspace backend unavailable');
        }
        return [_workspace()];
      },
    );

    await submit(tester);

    // Failure is visible, the user is not navigated away, and the button is
    // enabled again.
    expect(find.textContaining('Failed to load workspaces'), findsOneWidget);
    expect(find.text('route:/home'), findsNothing);
    expect(find.byType(AppButton), findsOneWidget);

    failNext = false;
    await tester.ensureVisible(find.byType(AppButton));
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(find.text('route:/home'), findsOneWidget);
  });

  testWidgets(
      'workspace fetch failure that looks like an API error shows the error '
      'report dialog and can be dismissed', (tester) async {
    stubSignInSuccess();
    await pumpSignIn(
      tester,
      workspaces: () async =>
          throw const SupabaseOperationException('Failed to load workspaces'),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), _email);
    await tester.enterText(fields.at(1), _password);
    await tester.ensureVisible(find.byType(AppButton));
    await tester.tap(find.byType(AppButton));
    // The button spinner animates while the dialog is open, so no settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // ErrorReportHelper shows a modal dialog for API-like errors. Nothing is
    // sent unless the user taps the report button.
    expect(find.byType(AlertDialog), findsOneWidget);
    verifyNever(() => errorReportService.reportError(
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
          errorType: any(named: 'errorType'),
          context: any(named: 'context'),
        ));

    await tester.tap(find.text('Đồng ý'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('Failed to load workspaces'), findsWidgets);
    expect(find.text('route:/home'), findsNothing);
  });

  group('session restoration and logout (provider level)', () {
    late StreamController<AuthState> authEvents;

    setUp(() {
      authEvents = StreamController<AuthState>.broadcast();
      addTearDown(authEvents.close);
      when(() => authService.authStateChanges)
          .thenAnswer((_) => authEvents.stream);
    });

    ProviderContainer makeContainer() {
      final container = ProviderContainer(overrides: [
        supabaseAuthServiceProvider.overrideWithValue(authService),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    test('restored confirmed session is valid; sign-out clears it', () async {
      final container = makeContainer();
      final sub = container.listen(authStateProvider, (_, __) {});
      addTearDown(sub.close);

      authEvents
          .add(AuthState(AuthChangeEvent.initialSession, _session(_user())));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(isAuthenticatedProvider), isTrue);
      expect(container.read(hasValidSessionProvider), isTrue);
      expect(container.read(needsEmailVerificationProvider), isFalse);

      authEvents.add(const AuthState(AuthChangeEvent.signedOut, null));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(isAuthenticatedProvider), isFalse);
      expect(container.read(hasValidSessionProvider), isFalse);
      expect(container.read(currentSessionProvider), isNull);

      // Signing in again restores access.
      authEvents.add(AuthState(AuthChangeEvent.signedIn, _session(_user())));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(hasValidSessionProvider), isTrue);
    });

    test('unconfirmed email session is not valid and needs verification',
        () async {
      final container = makeContainer();
      final sub = container.listen(authStateProvider, (_, __) {});
      addTearDown(sub.close);

      final unconfirmed = _user(emailConfirmedAt: null);
      authEvents
          .add(AuthState(AuthChangeEvent.signedIn, _session(unconfirmed)));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(isAuthenticatedProvider), isTrue);
      expect(container.read(hasValidSessionProvider), isFalse);
      expect(container.read(needsEmailVerificationProvider), isTrue);
    });
  });
}
