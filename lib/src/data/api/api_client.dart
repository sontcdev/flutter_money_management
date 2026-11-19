import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show
        AuthChangeEvent,
        AuthException,
        AuthResponse,
        AuthState,
        FileOptions,
        OtpType,
        PostgrestException,
        Session,
        SignOutScope,
        StorageException,
        User,
        UserAttributes,
        UserResponse;

/// Client for the MyMoney API (`/v1`).
///
/// It keeps the same surface as the parts of `SupabaseClient` that the app
/// uses (`from`, `rpc`, `storage`, `auth`), so call sites only change type.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required SharedPreferences prefs,
    http.Client? httpClient,
  })  : _base = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _prefs = prefs,
        _http = httpClient ?? http.Client() {
    auth = ApiAuth._(this);
    storage = ApiStorage._(this);
    _restoreSession();
  }

  static const _sessionKey = 'mm_api_session';

  final String _base;
  final SharedPreferences _prefs;
  final http.Client _http;
  late final ApiAuth auth;
  late final ApiStorage storage;

  Session? _session;
  Future<void>? _refreshing;
  final _authEvents = StreamController<AuthState>.broadcast();

  String get baseUrl => _base;

  /// Headers for requests made outside this client, e.g. `Image.network`.
  Map<String, String> get authHeaders => {
        if (_session != null)
          'Authorization': 'Bearer ${_session!.accessToken}',
      };

  ApiQueryBuilder from(String table) => ApiQueryBuilder._(this, table);

  Future<dynamic> rpc(String fn, {Map<String, dynamic>? params}) =>
      _json('POST', '/rpc/$fn', body: params ?? const {}, kind: _Kind.rpc);

  /// Workspaces of the current user (`w.*` + `role`).
  Future<List<Map<String, dynamic>>> getMyWorkspaces() async {
    final res = await _json('GET', '/me/workspaces', kind: _Kind.db);
    return (res as List).cast<Map<String, dynamic>>();
  }

  /// Deletes the account of the current user, then clears the session.
  Future<void> deleteAccount() async {
    await _json('DELETE', '/account', kind: _Kind.account);
    await _setSession(null, AuthChangeEvent.signedOut);
  }

  // ---------------------------------------------------------------- session

  void _restoreSession() {
    final raw = _prefs.getString(_sessionKey);
    if (raw == null) return;
    try {
      _session = Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _prefs.remove(_sessionKey);
    }
  }

  Future<void> _setSession(Session? session, AuthChangeEvent event) async {
    _session = session;
    if (session == null) {
      await _prefs.remove(_sessionKey);
    } else {
      await _prefs.setString(_sessionKey, jsonEncode(session.toJson()));
    }
    _authEvents.add(AuthState(event, session));
  }

  Session _sessionFromJson(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(json['user'] as Map);
    final createdAt = user['created_at'] ?? DateTime.now().toIso8601String();
    user
      ..putIfAbsent('aud', () => 'authenticated')
      ..putIfAbsent('app_metadata', () => <String, dynamic>{})
      ..putIfAbsent('user_metadata', () => <String, dynamic>{})
      ..putIfAbsent('created_at', () => createdAt)
      ..putIfAbsent('email_confirmed_at', () => createdAt);
    return Session(
      accessToken: json['access_token'] as String,
      tokenType: (json['token_type'] as String?) ?? 'bearer',
      expiresIn: (json['expires_in'] as num?)?.toInt(),
      refreshToken: json['refresh_token'] as String?,
      user: User.fromJson(user)!,
    );
  }

  bool get _expiresSoon {
    final exp = _session?.expiresAt;
    if (exp == null) return false;
    final at = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return at.difference(DateTime.now()) < const Duration(seconds: 60);
  }

  /// Single-flight token refresh. Clears the session when it fails.
  Future<void> _refresh() {
    return _refreshing ??= () async {
      try {
        final token = _session?.refreshToken;
        if (token == null) throw const AuthException('No refresh token');
        final res = await _send('POST', '/auth/refresh',
            body: {'refresh_token': token}, withAuth: false);
        if (res.statusCode != 200) {
          throw _error(res, _Kind.auth);
        }
        await _setSession(
          _sessionFromJson(jsonDecode(res.body) as Map<String, dynamic>),
          AuthChangeEvent.tokenRefreshed,
        );
      } catch (e) {
        if (e is AuthException) {
          await _setSession(null, AuthChangeEvent.signedOut);
        }
        rethrow;
      } finally {
        _refreshing = null;
      }
    }();
  }

  // ------------------------------------------------------------------- http

  Future<http.Response> _send(
    String method,
    String path, {
    Object? body,
    List<int>? bytes,
    String? contentType,
    bool withAuth = true,
  }) async {
    final req = http.Request(method, Uri.parse('$_base$path'));
    if (withAuth && _session != null) {
      req.headers['Authorization'] = 'Bearer ${_session!.accessToken}';
    }
    if (bytes != null) {
      req.headers['Content-Type'] = contentType ?? 'application/octet-stream';
      req.bodyBytes = bytes;
    } else if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    return http.Response.fromStream(await _http.send(req));
  }

  /// Sends an authorized request. Refreshes the token before it expires and
  /// retries once after a 401.
  Future<http.Response> _authed(
    String method,
    String path, {
    Object? body,
    List<int>? bytes,
    String? contentType,
  }) async {
    if (_session != null && _expiresSoon) await _refresh();
    var res = await _send(method, path,
        body: body, bytes: bytes, contentType: contentType);
    if (res.statusCode == 401 && _session?.refreshToken != null) {
      await _refresh();
      res = await _send(method, path,
          body: body, bytes: bytes, contentType: contentType);
    }
    return res;
  }

  Future<dynamic> _json(String method, String path,
      {Object? body, required _Kind kind}) async {
    final res = await _authed(method, path, body: body);
    if (res.statusCode >= 400) throw _error(res, kind);
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  Exception _error(http.Response res, _Kind kind) {
    Map<String, dynamic> body = const {};
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}
    final code = body['code']?.toString();
    final message = body['message']?.toString() ?? 'HTTP ${res.statusCode}';
    switch (kind) {
      case _Kind.auth:
        return AuthException(_authMessage(code, message),
            statusCode: '${res.statusCode}', code: code);
      case _Kind.storage:
        return StorageException(message,
            error: code, statusCode: '${res.statusCode}');
      case _Kind.account:
        return ApiException(res.statusCode, code, message, body);
      case _Kind.rpc:
        if (res.statusCode == 404 && code != null && code.startsWith('P')) {
          return PostgrestException(
              message: message,
              code: code,
              details: body['details'],
              hint: body['hint']?.toString());
        }
        if (res.statusCode == 404) {
          return PostgrestException(message: message, code: 'PGRST202');
        }
        continue db;
      db:
      case _Kind.db:
        return PostgrestException(
          message: message,
          code: code ?? '${res.statusCode}',
          details: body['details'],
          hint: body['hint']?.toString(),
        );
    }
  }

  /// Gives the messages that `mapSupabaseException` already knows.
  static String _authMessage(String? code, String message) {
    switch (code) {
      case 'invalid_credentials':
        return 'Invalid login credentials';
      case 'email_exists':
        return 'User already registered';
      default:
        return message;
    }
  }
}

enum _Kind { db, rpc, auth, storage, account }

/// Error from a non-PostgREST endpoint, e.g. `DELETE /account`.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.code, this.message, this.body);

  final int statusCode;
  final String? code;
  final String message;
  final Map<String, dynamic> body;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

/// PostgREST-like builder for `POST /db/:table`.
class ApiQueryBuilder implements Future<dynamic> {
  ApiQueryBuilder._(this._client, this._table);

  final ApiClient _client;
  final String _table;
  String _op = 'select';
  String? _columns;
  Object? _values;
  int? _limit;
  final _filters = <Map<String, dynamic>>[];
  final _order = <Map<String, dynamic>>[];

  ApiQueryBuilder select([String columns = '*']) {
    _columns = columns;
    return this;
  }

  ApiQueryBuilder insert(Object values) {
    _op = 'insert';
    _values = values;
    return this;
  }

  ApiQueryBuilder delete() {
    _op = 'delete';
    return this;
  }

  ApiQueryBuilder _filter(String col, String op, Object? value) {
    _filters.add({'col': col, 'op': op, 'value': value});
    return this;
  }

  ApiQueryBuilder eq(String col, Object value) => _filter(col, 'eq', value);
  ApiQueryBuilder neq(String col, Object value) => _filter(col, 'neq', value);
  ApiQueryBuilder gt(String col, Object value) => _filter(col, 'gt', value);
  ApiQueryBuilder gte(String col, Object value) => _filter(col, 'gte', value);
  ApiQueryBuilder lt(String col, Object value) => _filter(col, 'lt', value);
  ApiQueryBuilder lte(String col, Object value) => _filter(col, 'lte', value);
  ApiQueryBuilder isFilter(String col, Object? value) =>
      _filter(col, 'is', value);
  ApiQueryBuilder inFilter(String col, List<Object?> values) =>
      _filter(col, 'in', values);

  ApiQueryBuilder order(String col, {bool ascending = false}) {
    _order.add({'col': col, 'ascending': ascending});
    return this;
  }

  ApiQueryBuilder limit(int count) {
    _limit = count;
    return this;
  }

  Future<Map<String, dynamic>?> maybeSingle() async {
    final rows = await _execute();
    if (rows.isEmpty) return null;
    if (rows.length > 1) {
      throw const PostgrestException(
          message: 'Multiple rows returned', code: 'PGRST116');
    }
    return rows.first;
  }

  Future<Map<String, dynamic>> single() async {
    final row = await maybeSingle();
    if (row == null) {
      throw const PostgrestException(message: 'No rows', code: 'PGRST116');
    }
    return row;
  }

  Future<List<Map<String, dynamic>>> _execute() async {
    final res = await _client._json('POST', '/db/$_table',
        body: {
          'op': _op,
          if (_columns != null) 'columns': _columns,
          if (_filters.isNotEmpty) 'filters': _filters,
          if (_order.isNotEmpty) 'order': _order,
          if (_limit != null) 'limit': _limit,
          if (_values != null) 'values': _values,
        },
        kind: _Kind.db);
    return ((res as List?) ?? const []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> get _future => _execute();

  @override
  Stream<dynamic> asStream() => _future.asStream();

  @override
  Future<dynamic> catchError(Function onError,
          {bool Function(Object error)? test}) =>
      _future.catchError(onError, test: test);

  @override
  Future<R> then<R>(FutureOr<R> Function(dynamic value) onValue,
          {Function? onError}) =>
      _future.then(onValue, onError: onError);

  @override
  Future<dynamic> timeout(Duration timeLimit,
          {FutureOr<dynamic> Function()? onTimeout}) =>
      _future.then<dynamic>((v) => v).timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<dynamic> whenComplete(FutureOr<void> Function() action) =>
      _future.whenComplete(action);
}

class ApiStorage {
  ApiStorage._(this._client);
  final ApiClient _client;

  ApiBucket from(String bucket) => ApiBucket._(_client, bucket);
}

class ApiBucket {
  ApiBucket._(this._client, this._bucket);

  final ApiClient _client;
  final String _bucket;

  Future<String> upload(String path, File file,
      {FileOptions fileOptions = const FileOptions()}) async {
    final res = await _client._authed('PUT', '/storage/$_bucket/$path',
        bytes: await file.readAsBytes(), contentType: fileOptions.contentType);
    if (res.statusCode >= 400) throw _client._error(res, _Kind.storage);
    return '$_bucket/$path';
  }

  Future<void> remove(List<String> paths) async {
    for (final path in paths) {
      final res = await _client._authed('DELETE', '/storage/$_bucket/$path');
      if (res.statusCode >= 400 && res.statusCode != 404) {
        throw _client._error(res, _Kind.storage);
      }
    }
  }

  /// The API has no signed URLs. Load the URL with [ApiClient.authHeaders].
  Future<String> createSignedUrl(String path, int expiresIn) async =>
      '${_client._base}/storage/$_bucket/$path';
}

class ApiAuth {
  ApiAuth._(this._client);
  final ApiClient _client;

  Session? get currentSession => _client._session;
  User? get currentUser => _client._session?.user;

  Stream<AuthState> get onAuthStateChange async* {
    yield AuthState(AuthChangeEvent.initialSession, _client._session);
    yield* _client._authEvents.stream;
  }

  Future<AuthResponse> _sessionCall(
      String path, Map<String, dynamic> body, AuthChangeEvent event) async {
    final res = await _client._send('POST', path, body: body, withAuth: false);
    if (res.statusCode >= 400) throw _client._error(res, _Kind.auth);
    final session =
        _client._sessionFromJson(jsonDecode(res.body) as Map<String, dynamic>);
    await _client._setSession(session, event);
    return AuthResponse(session: session);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
    String? emailRedirectTo,
  }) =>
      _sessionCall(
          '/auth/signup',
          {
            'email': email,
            'password': password,
            if (data?['display_name'] != null)
              'display_name': data!['display_name'],
          },
          AuthChangeEvent.signedIn);

  Future<AuthResponse> signInWithPassword(
          {required String email, required String password}) =>
      _sessionCall('/auth/login', {'email': email, 'password': password},
          AuthChangeEvent.signedIn);

  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    final token = _client._session?.refreshToken;
    try {
      if (token != null) {
        await _client._send('POST', '/auth/logout',
            body: {'refresh_token': token}, withAuth: false);
      }
    } catch (_) {
      // The local session is cleared anyway.
    }
    await _client._setSession(null, AuthChangeEvent.signedOut);
  }

  Future<void> resetPasswordForEmail(String email, {String? redirectTo}) async {
    final res = await _client._send('POST', '/auth/password/reset-request',
        body: {'email': email}, withAuth: false);
    if (res.statusCode >= 400) throw _client._error(res, _Kind.auth);
  }

  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
    required OtpType type,
  }) =>
      _sessionCall('/auth/password/verify-code',
          {'email': email, 'code': token}, AuthChangeEvent.passwordRecovery);

  Future<UserResponse> updateUser(UserAttributes attributes) async {
    final res = await _client._authed('PATCH', '/auth/user', body: {
      if (attributes.password != null) 'password': attributes.password,
      if (attributes.data != null) 'data': attributes.data,
    });
    if (res.statusCode >= 400) throw _client._error(res, _Kind.auth);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final userJson = Map<String, dynamic>.from(json['user'] as Map? ?? json);
    final session = _client._session;
    if (session != null) {
      final updated = _client._sessionFromJson({
        ...session.toJson(),
        'user': {...session.user.toJson(), ...userJson},
      });
      await _client._setSession(updated, AuthChangeEvent.userUpdated);
      return UserResponse.fromJson(updated.user.toJson());
    }
    return UserResponse.fromJson(userJson);
  }

  Future<AuthResponse> refreshSession() async {
    await _client._refresh();
    return AuthResponse(session: _client._session);
  }
}
