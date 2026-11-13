import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace_management_models.dart';
import 'package:flutter_money_management/src/features/workspace/presentation/screens/workspace_management_screen.dart';
import 'package:flutter_money_management/src/features/workspace/presentation/screens/workspace_selection_screen.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_providers.dart';
import 'package:flutter_money_management/src/theme/app_surface_tokens.dart';
import 'package:flutter_money_management/src/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _now = DateTime.now();

Widget _app(ThemeData theme, List<Override> overrides, Widget home) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('vi')],
        home: home,
      ),
    );

WorkspaceInviteSummary _invite(String id, Duration expiresIn) =>
    WorkspaceInviteSummary(
      id: id,
      email: '$id@example.com',
      role: 'member',
      status: 'pending',
      token: 'tok-$id',
      expiresAt: _now.add(expiresIn),
      createdAt: _now,
      updatedAt: null,
      matchedUserId: null,
      matchedDisplayName: null,
      matchedAvatarUrl: null,
    );

void main() {
  final themes = {
    'light': AppTheme.lightTheme(primaryColor: const Color(0xFF00884B)),
    'dark': AppTheme.darkTheme(primaryColor: const Color(0xFF00884B)),
  };

  for (final e in themes.entries) {
    testWidgets('empty workspace warning icon >= 3:1 (${e.key})', (t) async {
      await t.pumpWidget(_app(
        e.value,
        [
          workspaceListProvider.overrideWith((ref) async => <Workspace>[]),
          myWorkspaceInviteNotificationsProvider
              .overrideWith((ref) async => <WorkspaceInviteNotification>[]),
          currentUserProvider.overrideWithValue(null),
        ],
        const WorkspaceSelectionScreen(),
      ));
      await t.pumpAndSettle();
      final icon = t.widget<Icon>(find.byIcon(Icons.error_outline));
      final page = e.value.scaffoldBackgroundColor;
      final container = t.widget<Container>(find
          .ancestor(
              of: find.byIcon(Icons.error_outline),
              matching: find.byType(Container))
          .first);
      final fill = Color.alphaBlend(
          (container.decoration as BoxDecoration).color!, page);
      expect(AppSurfaceTokens.contrast(icon.color!, fill),
          greaterThanOrEqualTo(3));
    });

    testWidgets('invite expiry labels >= 4.5:1 (${e.key})', (t) async {
      final workspace = Workspace(
        id: 'w1',
        name: 'Team',
        type: 'shared',
        ownerId: 'owner-1',
        role: 'owner',
        createdAt: _now,
        updatedAt: _now,
      );
      await t.pumpWidget(_app(
        e.value,
        [
          activeWorkspaceProvider.overrideWithValue(workspace),
          workspacePendingInvitesProvider.overrideWith((ref) async => [
                _invite('urgent', const Duration(hours: 5)),
                _invite('soon', const Duration(days: 3, hours: -2)),
              ]),
          workspaceMembersProvider
              .overrideWith((ref) async => <WorkspaceMemberSummary>[]),
        ],
        const WorkspaceManagementScreen(),
      ));
      await t.pumpAndSettle();
      // Invites now sit below the Members section; scroll so they are built.
      await t.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await t.pumpAndSettle();
      final bg = e.value.cardTheme.color ?? e.value.colorScheme.surface;
      for (final label in ['Urgent', 'Expiring soon']) {
        final span = t
            .widgetList<RichText>(find.byType(RichText))
            .map((r) => r.text)
            .expand((s) {
          final out = <TextSpan>[];
          s.visitChildren((c) {
            if (c is TextSpan) out.add(c);
            return true;
          });
          return out;
        }).firstWhere((s) => (s.text ?? '').startsWith(label),
                orElse: () => throw 'missing $label');
        expect(AppSurfaceTokens.contrast(span.style!.color!, bg),
            greaterThanOrEqualTo(4.5),
            reason: label);
      }
    });
  }
}
