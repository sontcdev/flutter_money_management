import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/src/data/repositories/supabase_error_mapper.dart';
import 'package:flutter_money_management/src/features/auth/models/account_deletion_exception.dart';
import 'package:flutter_money_management/src/features/auth/services/supabase_auth_service.dart';

void main() {
  SupabaseAuthService service(int status, Map<String, dynamic> body) {
    final client = SupabaseClient('https://example.invalid', 'test-key',
        httpClient: MockClient((request) async => http.Response(
              jsonEncode(body),
              status,
              headers: {'content-type': 'application/json'},
              request: request,
            )));
    addTearDown(client.dispose);
    return SupabaseAuthService(client);
  }

  test('server deletion success completes', () async {
    await service(200, {'status': 'deleted'}).deleteAccount();
  });

  test('race-time shared membership preserves workspace navigation data',
      () async {
    await expectLater(
        service(409, {
          'code': 'shared_workspace_membership',
          'workspaces': [
            {'workspace_id': 'shared-1', 'workspace_name': 'Family'}
          ],
        }).deleteAccount(),
        throwsA(isA<SharedWorkspaceMembershipException>()
            .having((e) => e.workspaces.single.workspaceId, 'workspace ID',
                'shared-1')
            .having((e) => e.workspaces.single.workspaceName, 'workspace name',
                'Family')));
  });

  test('server failure uses centralized error mapping', () async {
    await expectLater(
        service(500, {'code': 'account_deletion_failed'}).deleteAccount(),
        throwsA(isA<SupabaseOperationException>()));
  });

  test('unexpected success payload cannot claim deletion', () async {
    await expectLater(service(200, {'status': 'prepared'}).deleteAccount(),
        throwsA(isA<SupabaseOperationException>()));
  });

  for (final status in [200, 401, 400]) {
    test('deleted account clears local session with logout status $status',
        () async {
      late Uri logoutUrl;
      final client = SupabaseClient('https://example.invalid', 'test-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((request) async {
        logoutUrl = request.url;
        return http.Response(
          status == 200 ? '{}' : '{"message":"Account unavailable"}',
          status,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }));
      addTearDown(client.dispose);
      await client.auth.recoverSession(jsonEncode({
        'access_token': 'test-access-token',
        'refresh_token': 'test-refresh-token',
        'token_type': 'bearer',
        'user': {
          'id': 'deleted-user',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'aud': 'authenticated',
          'created_at': '2026-10-10T00:00:00Z',
        },
      }));
      expect(client.auth.currentSession, isNotNull);
      await SupabaseAuthService(client).clearDeletedAccountSession();
      expect(client.auth.currentSession, isNull);
      expect(client.auth.currentUser, isNull);
      expect(logoutUrl.path, '/auth/v1/logout');
      expect(logoutUrl.queryParameters['scope'], 'local');
    });
  }
}
