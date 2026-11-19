import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_money_management/src/data/repositories/supabase_error_mapper.dart';
import 'package:flutter_money_management/src/features/auth/models/account_deletion_exception.dart';
import 'package:flutter_money_management/src/features/auth/services/supabase_auth_service.dart';

import 'api_test_client.dart';

void main() {
  Future<SupabaseAuthService> service(
          int status, Map<String, dynamic> body) async =>
      SupabaseAuthService(
          await testApiClient((request) async => jsonResponse(body, status)));

  test('server deletion success completes', () async {
    await (await service(200, {'ok': true})).deleteAccount();
  });

  test('blocked deletion preserves workspace navigation data', () async {
    await expectLater(
        (await service(409, {
          'code': 'account_deletion_blocked',
          'message': 'blocked',
          'workspaces': [
            {'workspace_id': 'shared-1', 'workspace_name': 'Family'}
          ],
        }))
            .deleteAccount(),
        throwsA(isA<SharedWorkspaceMembershipException>()
            .having((e) => e.workspaces.single.workspaceId, 'workspace ID',
                'shared-1')
            .having((e) => e.workspaces.single.workspaceName, 'workspace name',
                'Family')));
  });

  test('server failure uses centralized error mapping', () async {
    await expectLater(
        (await service(
                500, {'code': 'account_deletion_failed', 'message': 'x'}))
            .deleteAccount(),
        throwsA(isA<SupabaseOperationException>()));
  });

  for (final status in [200, 401, 400]) {
    test('deleted account clears local session with logout status $status',
        () async {
      final paths = <String>[];
      final client = await testApiClient((request) async {
        paths.add(request.url.path);
        if (request.url.path.endsWith('/auth/login')) {
          return jsonResponse(testSessionBody(), 200);
        }
        return jsonResponse(
            status == 200 ? {} : {'message': 'Account unavailable'}, status);
      });
      await client.auth
          .signInWithPassword(email: 'sontc.gemini@gmail.com', password: 'x');
      expect(client.auth.currentSession, isNotNull);
      await SupabaseAuthService(client).clearDeletedAccountSession();
      expect(client.auth.currentSession, isNull);
      expect(client.auth.currentUser, isNull);
      expect(paths.last, '/v1/auth/logout');
    });
  }
}
