// path: lib/src/services/budget_service.dart

class BudgetExceededException implements Exception {
  final String message;
  final int remainingCents;
  final int limitCents;

  BudgetExceededException({
    required this.message,
    required this.remainingCents,
    required this.limitCents,
  });

  @override
  String toString() => message;
}

class BudgetOverlapException implements Exception {
  final String message;

  BudgetOverlapException(this.message);

  @override
  String toString() => message;
}

class CategoryInUseException implements Exception {
  final String message;

  CategoryInUseException(this.message);

  @override
  String toString() => message;
}

class DuplicateCategoryException implements Exception {
  final String message;

  DuplicateCategoryException(this.message);

  @override
  String toString() => message;
}

class InvalidCategoryException implements Exception {
  final String message;

  InvalidCategoryException(this.message);

  @override
  String toString() => message;
}

class CategoryTypeMismatchException implements Exception {
  final String message;

  CategoryTypeMismatchException(this.message);

  @override
  String toString() => message;
}

class RepositoryOperationException implements Exception {
  final String message;

  RepositoryOperationException(this.message);

  @override
  String toString() => message;
}
