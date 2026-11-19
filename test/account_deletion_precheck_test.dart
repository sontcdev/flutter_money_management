import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/src/data/repositories/supabase_error_mapper.dart';
import 'package:flutter_money_management/src/features/auth/services/supabase_auth_service.dart';

import 'api_test_client.dart';

void main() {
  test('precheck uses caller-scoped RPC and preserves workspace links',
      () async {
    late http.Request recordedRequest;
    final client = await testApiClient((request) async {
      recordedRequest = request;
      return jsonResponse([
        {'workspace_id': 'workspace-1', 'workspace_name': 'Shared household'},
      ], 200);
    });

    final blockers =
        await SupabaseAuthService(client).getAccountDeletionBlockers();

    expect(recordedRequest.method, 'POST');
    expect(recordedRequest.url.path, '/v1/rpc/get_account_deletion_blockers');
    expect(jsonDecode(recordedRequest.body), isA<Map>());
    expect(blockers, hasLength(1));
    expect(blockers.single.workspaceId, 'workspace-1');
    expect(blockers.single.workspaceName, 'Shared household');
  });

  test('empty server result permits the later confirmation step', () async {
    final client =
        await testApiClient((request) async => jsonResponse([], 200));
    expect(
      await SupabaseAuthService(client).getAccountDeletionBlockers(),
      isEmpty,
    );
  });

  test('server rejection cannot be treated as an empty blocker list', () async {
    final client = await testApiClient((request) async => jsonResponse(
        {'code': '42501', 'message': 'Authentication required'}, 403));
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
