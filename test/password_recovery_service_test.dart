import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/src/data/repositories/supabase_error_mapper.dart';
import 'package:flutter_money_management/src/features/auth/services/supabase_auth_service.dart';

class _MemoryStorage extends GotrueAsyncStorage {
  final _values = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _values[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _values.remove(key);
  }
}

void main() {
  SupabaseClient clientFor(
    Future<http.Response> Function(http.Request) handler,
  ) {
    final client = SupabaseClient(
      'https://example.invalid',
      'test-key',
      authOptions: AuthClientOptions(
        autoRefreshToken: false,
        pkceAsyncStorage: _MemoryStorage(),
      ),
      httpClient: MockClient(handler),
    );
    addTearDown(client.dispose);
    return client;
  }

  test('requests an emailed recovery code for the trimmed address', () async {
    final client = clientFor((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/auth/v1/recover');
      expect(jsonDecode(request.body)['email'], 'test@example.com');
      return http.Response('{}', 200);
    });
    await SupabaseAuthService(client).resetPassword(' test@example.com ');
    expect(client.auth.currentSession, isNull);
  });

  test('verified recovery code creates the password recovery session',
      () async {
    final client = clientFor((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/auth/v1/verify');
      final body = jsonDecode(request.body);
      expect(body['email'], 'test@example.com');
      expect(body['token'], '123456');
      expect(body['type'], 'recovery');
      return http.Response(
          jsonEncode({
            'access_token': 'test-access-token',
            'refresh_token': 'test-refresh-token',
            'token_type': 'bearer',
            'user': {
              'id': 'recovery-user',
              'app_metadata': <String, dynamic>{},
              'user_metadata': <String, dynamic>{},
              'aud': 'authenticated',
              'created_at': '2026-10-10T00:00:00Z',
            },
          }),
          200);
    });
    final event = client.auth.onAuthStateChange.firstWhere(
      (state) => state.event == AuthChangeEvent.passwordRecovery,
    );
    await SupabaseAuthService(client).verifyPasswordResetCode(
      email: ' test@example.com ',
      code: ' 123456 ',
    );
    expect((await event).session?.user.id, 'recovery-user');
    expect(client.auth.currentSession, isNotNull);
  });

  for (final code in ['otp_expired', 'validation_failed']) {
    test('rejected code $code cannot establish a recovery session', () async {
      final client = clientFor((request) async => http.Response(
            jsonEncode({'code': code, 'msg': 'Invalid recovery code'}),
            403,
          ));
      await expectLater(
        SupabaseAuthService(client).verifyPasswordResetCode(
          email: 'test@example.com',
          code: '123456',
        ),
        throwsA(isA<SupabaseOperationException>()),
      );
      expect(client.auth.currentSession, isNull);
    });
  }
}
