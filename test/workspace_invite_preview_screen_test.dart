import 'package:flutter/material.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/workspace/models/workspace_management_models.dart';
import 'package:flutter_money_management/src/features/workspace/presentation/screens/workspace_invite_preview_screen.dart';
import 'package:flutter_money_management/src/features/workspace/providers/workspace_management_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

WorkspaceInvitePreviewMember _m(String id, String role) =>
    WorkspaceInvitePreviewMember(
      userId: id,
      displayName: 'User $id',
      email: null,
      avatarUrl: null,
      role: role,
      joinedAt: null,
    );

Future<void> _pump(WidgetTester t, String locale) async {
  final preview = WorkspaceInvitePreview(
    workspaceId: 'w',
    workspaceName: 'Home',
    workspaceType: 'family',
    description: null,
    avatarPath: null,
    email: 'a@b.c',
    role: 'member',
    token: 'tok',
    expiresAt: DateTime(2030),
    invitedByUserId: null,
    invitedByDisplayName: null,
    invitedByEmail: null,
    members: [_m('1', 'owner'), _m('2', 'admin'), _m('3', 'member'), _m('4', 'zzz')],
  );
  await t.pumpWidget(ProviderScope(
    overrides: [
      workspaceInvitePreviewProvider('tok').overrideWith((ref) async => preview),
    ],
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const WorkspaceInvitePreviewScreen(token: 'tok'),
    ),
  ));
  await t.pumpAndSettle();
}

void main() {
  const exp = {
    'en': ['Members', 'Owner', 'Admin', 'Member', 'Role: zzz'],
    'vi': ['Thành viên', 'Chủ sở hữu', 'Quản trị viên', 'Thành viên', 'Vai trò: zzz'],
    'ja': ['メンバー', 'オーナー', '管理者', 'メンバー', '役割: zzz'],
  };
  for (final e in exp.entries) {
    testWidgets('localizes invite preview (${e.key})', (t) async {
      await _pump(t, e.key);
      final l = AppLocalizations.of(t.element(find.byType(Scaffold)))!;
      final v = e.value;
      expect(find.text(l.membersSection), findsWidgets);
      expect(find.text(l.ownerRole), findsOneWidget);
      expect(find.text(l.adminRole), findsOneWidget);
      expect(find.text(l.roleValue('zzz')), findsOneWidget);
      expect(find.text(v[2]), findsOneWidget);
      expect(find.text(v[4]), findsOneWidget);
      expect(find.text(v[0]), findsWidgets);
      expect(find.text(v[3]), findsWidgets);
      expect(find.text('owner'), findsNothing);
    });
  }
}
