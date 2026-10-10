import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/src/data/repositories/supabase_error_mapper.dart';
import 'package:flutter_money_management/src/features/auth/services/supabase_auth_service.dart';

void main() {
  test('precheck uses caller-scoped RPC and preserves workspace links',
      () async {
    late http.Request recordedRequest;
    final client = SupabaseClient(
      'https://example.invalid',
      'test-key',
      httpClient: MockClient((request) async {
        recordedRequest = request;
        return http.Response(
          jsonEncode([
            {
              'workspace_id': 'workspace-1',
              'workspace_name': 'Shared household'
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);

    final blockers =
        await SupabaseAuthService(client).getAccountDeletionBlockers();

    expect(recordedRequest.method, 'POST');
    expect(
        recordedRequest.url.path, '/rest/v1/rpc/get_account_deletion_blockers');
    expect(jsonDecode(recordedRequest.body), isNull);
    expect(blockers, hasLength(1));
    expect(blockers.single.workspaceId, 'workspace-1');
    expect(blockers.single.workspaceName, 'Shared household');
  });

  test('empty server result permits the later confirmation step', () async {
    final client = SupabaseClient(
      'https://example.invalid',
      'test-key',
      httpClient: MockClient((request) async => http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          )),
    );
    addTearDown(client.dispose);

    expect(
      await SupabaseAuthService(client).getAccountDeletionBlockers(),
      isEmpty,
    );
  });

  test('server rejection cannot be treated as an empty blocker list', () async {
    final client = SupabaseClient(
      'https://example.invalid',
      'test-key',
      httpClient: MockClient((request) async => http.Response(
            jsonEncode({'code': '42501', 'message': 'Authentication required'}),
            403,
            headers: {'content-type': 'application/json'},
            request: request,
          )),
    );
    addTearDown(client.dispose);

    await expectLater(
      SupabaseAuthService(client).getAccountDeletionBlockers(),
      throwsA(isA<SupabaseOperationException>().having(
        (error) => error.source,
        'source',
        isA<PostgrestException>(),
      )),
    );
  });
}
