import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/src/features/budgets/services/budget_service.dart';

class SupabaseOperationException implements Exception {
  const SupabaseOperationException(this.message, {this.source});

  final String message;
  final Object? source;

  @override
  String toString() => message;
}

class SupabaseErrorMapper {
  const SupabaseErrorMapper._();

  static Exception map(Object error) {
    if (error is PostgrestException) {
      return _mapPostgrestException(error);
    }

    if (error is AuthException) {
      return SupabaseOperationException(
        _authMessage(error),
        source: error,
      );
    }

    if (error is StorageException) {
      return SupabaseOperationException(
        'Không thể xử lý tệp đính kèm. Vui lòng thử lại.',
        source: error,
      );
    }

    if (_isNetworkError(error)) {
      return SupabaseOperationException(
        'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng rồi thử lại.',
        source: error,
      );
    }

    if (_looksLikeSupabaseError(error)) {
      return SupabaseOperationException(
        'Không thể hoàn tất yêu cầu. Vui lòng thử lại sau.',
        source: error,
      );
    }

    return error is Exception ? error : Exception(error.toString());
  }

  static bool isSupabaseException(Object error) {
    return error is PostgrestException ||
        error is AuthException ||
        error is StorageException ||
        _isNetworkError(error) ||
        _looksLikeSupabaseError(error);
  }

  static Exception _mapPostgrestException(PostgrestException exception) {
    switch (exception.message) {
      case 'BUDGET_EXCEEDED':
        final detailMap = _parseDetailMap(exception.details);
        final remainingCents = _asInt(detailMap['remaining_cents']);
        final limitCents = _asInt(detailMap['limit_cents']);
        return BudgetExceededException(
          message:
              'Budget exceeded! Remaining: $remainingCents cents, Limit: $limitCents cents',
          remainingCents: remainingCents,
          limitCents: limitCents,
        );
      case 'BUDGET_OVERLAP':
        return BudgetOverlapException(
          'Budget period overlaps with existing budget for this category',
        );
      case 'CATEGORY_IN_USE':
        return CategoryInUseException(
            'Category is in use and cannot be deleted');
      case 'INVALID_CATEGORY':
        return InvalidCategoryException(
            'Category is invalid for this workspace');
      case 'CATEGORY_TYPE_MISMATCH':
        return CategoryTypeMismatchException(
          'Category type does not match transaction type',
        );
      case 'WORKSPACE_INVITE_USER_NOT_FOUND':
        return SupabaseOperationException(
          'Không tìm thấy người dùng với email này.',
          source: exception,
        );
      case 'WORKSPACE_INVITE_ALREADY_MEMBER':
        return SupabaseOperationException(
          'Email này đã là thành viên của workspace.',
          source: exception,
        );
      case 'WORKSPACE_INVITE_ALREADY_PENDING':
        return SupabaseOperationException(
          'Đã có lời mời đang chờ cho email này.',
          source: exception,
        );
      case 'SIGNUP_EMAIL_ALREADY_EXISTS':
        return SupabaseOperationException(
          'Email này đã được đăng ký.',
          source: exception,
        );
      case 'SIGNUP_USERNAME_ALREADY_EXISTS':
        return SupabaseOperationException(
          'Tên người dùng này đã tồn tại.',
          source: exception,
        );
    }

    if (exception.code == '23505') {
      return DuplicateCategoryException(
        'Category with the same name already exists for this type',
      );
    }

    if (exception.code == '42501') {
      return SupabaseOperationException(
        'Bạn không có quyền thực hiện thao tác này.',
        source: exception,
      );
    }

    return SupabaseOperationException(
      'Không thể đồng bộ dữ liệu. Vui lòng thử lại sau.',
      source: exception,
    );
  }

  static String _authMessage(AuthException exception) {
    final message = exception.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Email hoặc mật khẩu không đúng.';
    }
    if (message.contains('email not confirmed')) {
      return 'Vui lòng xác nhận email trước khi đăng nhập.';
    }
    if (message.contains('user already registered') ||
        message.contains('already registered')) {
      return 'Email này đã được đăng ký.';
    }
    if (message.contains('password')) {
      return 'Mật khẩu không hợp lệ. Vui lòng kiểm tra lại.';
    }

    return 'Không thể xác thực tài khoản. Vui lòng thử lại.';
  }

  static bool _isNetworkError(Object error) {
    if (error is TimeoutException || error is SocketException) {
      return true;
    }
    if (error is http.ClientException) {
      return true;
    }

    final message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network is unreachable') ||
        message.contains('connection refused') ||
        message.contains('connection timed out') ||
        message.contains('authretryablefetchexception');
  }

  static bool _looksLikeSupabaseError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('supabase') ||
        message.contains('postgrest') ||
        message.contains('storageexception') ||
        message.contains('authexception');
  }
}

Exception mapSupabaseException(Object exception) =>
    SupabaseErrorMapper.map(exception);

Map<String, dynamic> _parseDetailMap(dynamic details) {
  if (details is Map<String, dynamic>) {
    return details;
  }
  if (details is String && details.isNotEmpty) {
    try {
      final decoded = jsonDecode(details);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return const {};
    }
  }
  return const {};
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}
