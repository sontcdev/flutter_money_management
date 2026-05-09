// path: lib/src/models/budget.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget.freezed.dart';
part 'budget.g.dart';

enum PeriodType {
  monthly,
  yearly,
  custom,
}

enum SyncStatus { pending, synced, error }

@freezed
class Budget with _$Budget {
  const Budget._();

  const factory Budget({
    required String id, // Changed from int to String (UUID)
    required String categoryId, // Changed from int to String (UUID)
    required PeriodType periodType,
    required DateTime periodStart,
    required DateTime periodEnd,
    required int limitCents,
    required int consumedCents,
    required bool allowOverdraft,
    required int overdraftCents,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
    DateTime? syncedAt,
    String? lastSyncError,
    DateTime? deletedAt,
  }) = _Budget;

  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);

  int get remainingCents => limitCents - consumedCents;
  double get progressPercentage =>
      limitCents > 0 ? (consumedCents / limitCents * 100).clamp(0, 100) : 0;
  bool get isExceeded => consumedCents > limitCents;
}
