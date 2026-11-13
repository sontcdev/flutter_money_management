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

Workspace _workspace(String role) => Workspace(
      id: 'w1',
      name: 'Team',
      type: 'shared',
      ownerId: 'owner-1',
      role: role,
      createdAt: _now,
      updatedAt: _now,
    );

final _members = [
  WorkspaceMemberSummary(
    memberId: 'm1',
    userId: 'u2',
    displayName: 'Alice',
    email: 'alice@example.com',
    avatarUrl: null,
    role: 'member',
    membershipStatus: 'active',
    joinedAt: _now,
  ),
];

final _invites = [
  WorkspaceInviteSummary(
    id: 'a',
    email: 'a@example.com',
    role: 'member',
    status: 'pending',
    token: 'tok-a',
    expiresAt: _now.add(const Duration(days: 5)),
    createdAt: _now,
    updatedAt: null,
    matchedUserId: null,
    matchedDisplayName: null,
    matchedAvatarUrl: null,
  ),
];

Widget _app(
  String role, {
  String lang = 'en',
  double scale = 1.0,
  bool dark = false,
}) {
  final canManage = role == 'owner' || role == 'admin';
  return ProviderScope(
    overrides: [
      activeWorkspaceProvider.overrideWithValue(_workspace(role)),
      canManageWorkspaceMembersProvider.overrideWithValue(canManage),
      canLeaveWorkspaceProvider.overrideWithValue(role != 'owner'),
      isWorkspaceOwnerProvider.overrideWithValue(role == 'owner'),
      workspacePendingInvitesProvider.overrideWith((ref) async => _invites),
      workspaceMembersProvider.overrideWith((ref) async => _members),
    ],
    child: MaterialApp(
      theme: dark
          ? AppTheme.darkTheme(primaryColor: const Color(0xFF00884B))
          : AppTheme.lightTheme(primaryColor: const Color(0xFF00884B)),
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
  );
}

double _top(WidgetTester t, Finder f) => t.getTopLeft(f).dy;

void main() {
  Future<void> setSize(WidgetTester t, Size s) async {
    t.view.physicalSize = s;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  testWidgets('owner/admin: Members -> Invites -> Settings -> danger order',
      (t) async {
    await setSize(t, const Size(390, 3000));
    for (final role in ['owner', 'admin']) {
      await t.pumpWidget(_app(role));
      await t.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final members = find.text(l10n.membersSection);
      final invite = find.text(l10n.inviteMember);
      final tabs = find.byType(TabBar);
      final settings = find.text(l10n.settings);
      final info = find.text('Team');
      expect(members, findsOneWidget);
      expect(invite, findsOneWidget);
      expect(settings, findsOneWidget);
      expect(_top(t, members), lessThan(_top(t, invite)));
      expect(_top(t, invite), lessThan(_top(t, tabs)));
      expect(_top(t, tabs), lessThan(_top(t, settings)));
      expect(_top(t, settings), lessThan(_top(t, info)));
      // Owner: no leave. Admin: leave exists and is last.
      expect(find.text(l10n.dangerZone),
          role == 'owner' ? findsNothing : findsOneWidget);
      expect(find.byIcon(Icons.person_remove_outlined), findsOneWidget);
    }
  });

  testWidgets('admin (can leave) danger zone is last', (t) async {
    await setSize(t, const Size(390, 3000));
    // role admin: manage=true, leave=true via override above.
    await t.pumpWidget(_app('admin'));
    await t.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(_top(t, find.text('Team')),
        lessThan(_top(t, find.text(l10n.dangerZone))));
  });

  testWidgets('member: no invite controls or remove, members + settings only',
      (t) async {
    await setSize(t, const Size(390, 3000));
    await t.pumpWidget(_app('member'));
    await t.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.inviteMember), findsNothing);
    expect(find.byType(TabBar), findsNothing);
    expect(find.byIcon(Icons.person_remove_outlined), findsNothing);
    expect(find.text(l10n.membersSection), findsOneWidget);
    expect(_top(t, find.text(l10n.membersSection)),
        lessThan(_top(t, find.text(l10n.settings))));
    expect(find.text(l10n.dangerZone), findsOneWidget);
  });

  testWidgets('invite form state and validation preserved', (t) async {
    await setSize(t, const Size(390, 3000));
    await t.pumpWidget(_app('owner'));
    await t.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final field = find.widgetWithText(TextField, l10n.memberEmail);
    await t.enterText(field, 'bad');
    await t.pump();
    expect(find.text(l10n.workspaceInviteInvalidEmail), findsOneWidget);
    await t.enterText(field, 'a@example.com');
    await t.pump();
    expect(find.text(l10n.workspaceInviteAlreadyPending), findsOneWidget);
    expect(find.text(l10n.refreshInvite), findsWidgets);
    await t.enterText(field, 'alice@example.com');
    await t.pump();
    expect(find.text(l10n.workspaceInviteAlreadyMember), findsOneWidget);
    await t.enterText(field, 'new@example.com');
    await t.pump();
    expect(find.text(l10n.workspaceInviteInvalidEmail), findsNothing);
    expect(t.widget<TextField>(field).controller!.text, 'new@example.com');
  });

  for (final lang in ['vi', 'en', 'ja']) {
    for (final scale in [1.0, 1.3]) {
      for (final dark in [false, true]) {
        for (final s in const {
          'portrait': Size(390, 844),
          'landscape': Size(844, 390),
        }.entries) {
          testWidgets(
              'no overflow $lang x$scale ${dark ? 'dark' : 'light'} ${s.key}',
              (t) async {
            await setSize(t, s.value);
            await t.pumpWidget(
                _app('admin', lang: lang, scale: scale, dark: dark));
            await t.pumpAndSettle();
            final scrollable = find.byType(Scrollable).first;
            await t.drag(scrollable, const Offset(0, -4000));
            await t.pumpAndSettle();
            expect(t.takeException(), isNull);
          });
        }
      }
    }
  }
}
