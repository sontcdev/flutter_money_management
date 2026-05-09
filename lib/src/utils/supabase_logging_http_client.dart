import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'app_logger.dart';

class SupabaseLoggingHttpClient extends http.BaseClient {
  SupabaseLoggingHttpClient({http.Client? inner})
      : _inner = inner ?? http.Client();

  static const _logName = 'MM.Api';
  static const _jsonLogEncoder = JsonEncoder.withIndent('  ');
  static const _sensitiveKeys = {
    'apikey',
    'authorization',
    'password',
    'access_token',
    'refresh_token',
    'token',
    'cookie',
    'set-cookie',
  };

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!kDebugMode) {
      return _inner.send(request);
    }

    final stopwatch = Stopwatch()..start();
    final requestLog = _buildRequestLog(request);
    AppLogger.debug(requestLog, name: _logName);

    try {
      final response = await _inner.send(request);
      stopwatch.stop();
      AppLogger.debug(
        'Supabase response ${request.method} ${request.url} '
        'status=${response.statusCode} elapsed=${stopwatch.elapsedMilliseconds}ms',
        name: _logName,
      );
      return response;
    } catch (error, stackTrace) {
      stopwatch.stop();
      AppLogger.error(
        'Supabase request failed ${request.method} ${request.url} '
        'elapsed=${stopwatch.elapsedMilliseconds}ms',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
  }

  String _buildRequestLog(http.BaseRequest request) {
    final buffer = StringBuffer(
      'Supabase request ${request.method} ${request.url}',
    );

    final query = _sanitizeMap(request.url.queryParametersAll);
    if (query.isNotEmpty) {
      buffer.write('\nquery=${_formatJsonLog(query)}');
    }

    final headers = _sanitizeHeaders(request.headers);
    if (headers.isNotEmpty) {
      buffer.write('\nheaders=${_formatJsonLog(headers)}');
    }

    final body = _extractRequestBody(request);
    if (body != null) {
      buffer.write('\nbody=$body');
    }

    return buffer.toString();
  }

  Map<String, dynamic> _sanitizeHeaders(Map<String, String> headers) {
    final sanitized = <String, dynamic>{};

    for (final entry in headers.entries) {
      final key = entry.key.toLowerCase();
      if (_sensitiveKeys.contains(key)) {
        sanitized[entry.key] = '<redacted>';
      } else {
        sanitized[entry.key] = entry.value;
      }
    }

    return sanitized;
  }

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> input) {
    final sanitized = <String, dynamic>{};

    for (final entry in input.entries) {
      sanitized[entry.key] = _sanitizeValue(entry.key, entry.value);
    }

    return sanitized;
  }

  dynamic _sanitizeValue(String? key, dynamic value) {
    final normalizedKey = key?.toLowerCase();
    if (normalizedKey != null && _sensitiveKeys.contains(normalizedKey)) {
      return '<redacted>';
    }

    if (value is Map) {
      return _sanitizeMap(
        value.map(
          (mapKey, mapValue) => MapEntry(mapKey.toString(), mapValue),
        ),
      );
    }

    if (value is List) {
      return value.map((item) => _sanitizeValue(key, item)).toList();
    }

    return value;
  }

  String? _extractRequestBody(http.BaseRequest request) {
    if (request is http.Request) {
      if (request.bodyBytes.isEmpty) {
        return null;
      }

      final contentType = request.headers['content-type']?.toLowerCase() ?? '';
      if (contentType.contains('application/json')) {
        return _formatJsonBody(request.body);
      }

      if (contentType.contains('application/x-www-form-urlencoded')) {
        return _formatJsonLog(_sanitizeMap(request.bodyFields));
      }

      return '"<${request.bodyBytes.length} bytes>"';
    }

    if (request is http.MultipartRequest) {
      final fields = request.fields.isEmpty
          ? null
          : _formatJsonLog(_sanitizeMap(request.fields));
      final files = request.files
          .map(
            (file) => {
              'field': file.field,
              'filename': file.filename,
              'length': file.length,
              'contentType': file.contentType.toString(),
            },
          )
          .toList();

      return _formatJsonLog({
        if (fields != null) 'fields': jsonDecode(fields),
        if (files.isNotEmpty) 'files': files,
      });
    }

    return null;
  }

  String _formatJsonBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return _formatJsonLog(
          _sanitizeMap(
            decoded.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          ),
        );
      }

      if (decoded is List) {
        return _formatJsonLog(
          decoded.map((item) => _sanitizeValue(null, item)).toList(),
        );
      }
    } catch (_) {
      // Keep raw body if JSON parsing fails.
    }

    return body;
  }

  String _formatJsonLog(Object? value) => _jsonLogEncoder.convert(value);
}
