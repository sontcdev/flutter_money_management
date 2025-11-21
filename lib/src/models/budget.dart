// path: lib/src/models/budget.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget.freezed.dart';
part 'budget.g.dart';

@freezed
class Budget with _$Budget {
  const factory Budget({
    required String id,
    String? name, // Tên hũ chi tiêu
    required String categoryId,
    required PeriodType periodType,
    required DateTime periodStart,
    required DateTime periodEnd,
    required int limitCents,
    required int consumedCents,
    required bool allowOverdraft,
    required int overdraftCents,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Budget;

  factory Budget.fromJson(Map<String, dynamic> json) =>
      _$BudgetFromJson(json);
}

enum PeriodType {
  @JsonValue('monthly')
  monthly,
  @JsonValue('yearly')
  yearly,
  @JsonValue('custom')
  custom,
}

