import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/src/features/budgets/services/budget_service.dart';

Exception mapSupabaseException(PostgrestException exception) {
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
      return CategoryInUseException('Category is in use and cannot be deleted');
    case 'INVALID_CATEGORY':
      return InvalidCategoryException('Category is invalid for this workspace');
    case 'CATEGORY_TYPE_MISMATCH':
      return CategoryTypeMismatchException(
        'Category type does not match transaction type',
      );
  }

  if (exception.code == '23505') {
    return DuplicateCategoryException(
      'Category with the same name already exists for this type',
    );
  }

  return RepositoryOperationException(exception.message);
}

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
