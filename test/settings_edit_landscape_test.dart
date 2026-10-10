import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart'
    as model;
import 'package:flutter_money_management/src/features/transactions/presentation/screens/edit_transaction_screen.dart';
import 'package:flutter_money_management/src/features/transactions/repositories/transaction_attachment_repository.dart';
import 'package:flutter_money_management/src/features/transactions/repositories/transaction_repository.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/features/wallets/providers/wallet_providers.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/i18n/locale_provider.dart';
import 'package:flutter_money_management/src/i18n/theme_provider.dart';
import 'package:flutter_money_management/src/ui/widgets/app_button.dart';

class _TransactionRepository extends Mock implements TransactionRepository {}

class _AttachmentRepository extends Mock
    implements TransactionAttachmentRepository {}

void main() {
  for (final locale in ['en', 'vi', 'ja']) {
    for (final size in [const Size(844, 390), const Size(1366, 1024)]) {
      for (final editing in [false, true]) {
        testWidgets(
            '${editing ? 'Edit transaction' : 'Settings'} fits $locale $size',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          if (editing) {
            tester.view.viewInsets = const FakeViewPadding(bottom: 180);
          }
          addTearDown(tester.view.reset);
          SharedPreferences.setMockInitialValues({'app_locale': locale});
          final prefs = await SharedPreferences.getInstance();
          PackageInfo.setMockInitialValues(
            appName: 'My Money',
            packageName: 'com.sontc.mymoney',
            version: '1.2.0',
            buildNumber: '7',
            buildSignature: '',
          );
          final now = DateTime(2026, 10, 10);
          final repository = _TransactionRepository();
          final attachments = _AttachmentRepository();
          when(() => repository.getTransactionById('transaction')).thenAnswer(
            (_) async => model.Transaction(
              id: 'transaction',
              amountCents: 3000000,
              currency: 'VND',
              dateTime: now,
              type: model.TransactionType.expense,
              categoryId: 'food',
              walletId: 'cash',
              note: 'Lunch with friends',
              createdAt: now,
              updatedAt: now,
            ),
          );
          when(() => attachments.getLatestReceiptAttachmentByTransactionId(
              'transaction')).thenAnswer((_) async => null);
          await tester.pumpWidget(ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              localeProvider.overrideWith((ref) => LocaleNotifier(prefs)),
              themeModeProvider.overrideWith((ref) => ThemeNotifier(prefs)),
              themeColorProvider
                  .overrideWith((ref) => ThemeColorNotifier(prefs)),
              fontScaleProvider.overrideWith((ref) => FontScaleNotifier(prefs)),
              currentUserProvider.overrideWithValue(User(
                id: 'user',
                appMetadata: {},
                userMetadata: {'display_name': 'Landscape Review'},
                aud: 'authenticated',
                email: 'review@example.test',
                createdAt: now.toIso8601String(),
              )),
              activeWorkspaceProvider.overrideWithValue(Workspace(
                id: 'workspace',
                name: 'Shared household workspace',
                type: 'shared',
                ownerId: 'other-user',
                role: 'member',
                memberCount: 2,
                createdAt: now,
                updatedAt: now,
              )),
              canLeaveWorkspaceProvider.overrideWith((ref) => true),
              transactionRepositoryProvider.overrideWithValue(repository),
              transactionAttachmentRepositoryProvider
                  .overrideWithValue(attachments),
              transactionCanManageProvider('transaction')
                  .overrideWith((ref) async => true),
              transactionReceiptImageUrlProvider('transaction')
                  .overrideWith((ref) async => null),
              categoriesProvider.overrideWith((ref) async => [
                    Category(
                      id: 'food',
                      name: 'Food and dining',
                      iconName: 'restaurant',
                      colorValue: Colors.blue.toARGB32(),
                      createdAt: now,
                      updatedAt: now,
                    )
                  ]),
              walletsProvider.overrideWith((ref) async => [
                    Wallet(
                      id: 'cash',
                      workspaceId: 'workspace',
                      name: 'Household cash',
                      iconName: 'wallet',
                      colorValue: Colors.blue.toARGB32(),
                      createdAt: now,
                      updatedAt: now,
                    )
                  ]),
            ],
            child: MaterialApp(
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: editing
                  ? const EditTransactionScreen(transactionId: 'transaction')
                  : const SettingsScreen(),
            ),
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final context = tester.element(find.byType(Scaffold).first);
          final l10n = AppLocalizations.of(context)!;
          final action =
              editing ? find.byType(AppButton) : find.text(l10n.deleteAccount);
          if (editing) {
            await tester.ensureVisible(action);
          } else {
            await tester.scrollUntilVisible(action, 200);
          }
          await tester.pumpAndSettle();
          expect(action.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
          if (editing) {
            expect(find.text('Lunch with friends'), findsOneWidget);
            verify(() => repository.getTransactionById('transaction'))
                .called(1);
          }
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
