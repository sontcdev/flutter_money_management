import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_money_management/src/data/api/api_client.dart';

/// Builds an [ApiClient] whose HTTP calls go to [handler].
Future<ApiClient> testApiClient(MockClientHandler handler) async {
  SharedPreferences.setMockInitialValues({});
  return ApiClient(
    baseUrl: 'https://example.invalid/v1',
    prefs: await SharedPreferences.getInstance(),
    httpClient: MockClient(handler),
  );
}

http.Response jsonResponse(Object? body, int status) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

/// A session body like the one `/auth/login` returns.
Map<String, dynamic> testSessionBody() {
  String b64(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final exp =
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000;
  return {
    'access_token':
        '${b64({'alg': 'none'})}.${b64({'sub': 'u1', 'exp': exp})}.sig',
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'test-refresh-token',
    'user': {
      'id': 'u1',
      'email': 'sontc.gemini@gmail.com',
      'user_metadata': <String, dynamic>{},
      'created_at': '2026-10-10T00:00:00Z',
    },
  };
}
