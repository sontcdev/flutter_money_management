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

