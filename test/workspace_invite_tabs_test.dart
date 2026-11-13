import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace_management_models.dart';
import 'package:flutter_money_management/src/features/workspace/presentation/screens/workspace_management_screen.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _now = DateTime.now();

WorkspaceInviteSummary _invite(String id, String status) =>
    WorkspaceInviteSummary(
      id: id,
      email: '$id@example.com',
      role: 'member',
      status: status,
      token: 'tok-$id',
      expiresAt: _now.add(const Duration(days: 5)),
      createdAt: _now,
      updatedAt: null,
      matchedUserId: null,
      matchedDisplayName: null,
      matchedAvatarUrl: null,
    );

void main() {
  final workspace = Workspace(
    id: 'w1',
    name: 'Team',
    type: 'shared',
    ownerId: 'owner-1',
    role: 'owner',
    createdAt: _now,
    updatedAt: _now,
  );

  const sizes = {
    'portrait': Size(390, 844),
    'landscape': Size(844, 390),
  };

  for (final lang in ['vi', 'en', 'ja']) {
    for (final scale in [1.0, 1.3]) {
      for (final s in sizes.entries) {
        testWidgets('invite tabs readable $lang x$scale ${s.key}', (t) async {
          t.view.physicalSize = s.value;
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          await t.pumpWidget(ProviderScope(
            overrides: [
              activeWorkspaceProvider.overrideWithValue(workspace),
              workspacePendingInvitesProvider.overrideWith((ref) async => [
                    _invite('a', 'pending'),
                    _invite('b', 'declined'),
                    _invite('c', 'revoked'),
                  ]),
              workspaceMembersProvider
                  .overrideWith((ref) async => <WorkspaceMemberSummary>[]),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme(primaryColor: const Color(0xFF00884B)),
              locale: Locale(lang),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const WorkspaceManagementScreen(),
            ),
          ));
          await t.pumpAndSettle();
          final l10n = await AppLocalizations.delegate.load(Locale(lang));
          final labels = [
            '${l10n.pendingInvites} (1)',
            '${l10n.declinedInvites} (1)',
            '${l10n.revokedInvites} (1)',
          ];
          final tabBar = find.byType(TabBar);
          await t.scrollUntilVisible(tabBar, 300,
              scrollable: find.byType(Scrollable).first);
          for (final label in labels) {
            final f = find.descendant(
                of: tabBar, matching: find.text(label), skipOffstage: false);
            expect(f, findsOneWidget, reason: label);
            // Reachable by scrolling the tab bar, then fully visible text.
            await t.ensureVisible(f);
            await t.pumpAndSettle();
            final text = t.widget<Text>(f);
            expect(text.data, label);
            final box = t.renderObject<RenderBox>(f);
            final painter = TextPainter(
              text: TextSpan(text: label, style: text.style),
              textDirection: TextDirection.ltr,
              textScaler: TextScaler.linear(scale),
              maxLines: 1,
            )..layout();
            expect(box.size.width, greaterThanOrEqualTo(painter.width - 0.5),
                reason: 'clipped: $label');
            // Tap selects it (behavior preserved).
            await t.tap(f);
            await t.pumpAndSettle();
          }
          expect(t.takeException(), isNull);
        });
      }
    }
  }
}
