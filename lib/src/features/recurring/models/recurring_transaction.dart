class RecurringTransaction {
  const RecurringTransaction({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.categoryId,
    required this.amountCents,
    required this.currency,
    required this.type,
    required this.frequency,
    required this.mode,
    required this.intervalCount,
    required this.startDate,
    required this.nextOccurrenceAt,
    required this.reminderDaysBefore,
    required this.isActive,
    required this.createdByUserId,
    required this.updatedByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.dayOfMonth,
    this.dayOfWeek,
    this.monthOfYear,
    this.endDate,
    this.deletedAt,
  });

  final String id;
  final String workspaceId;
  final String title;
  final String categoryId;
  final int amountCents;
  final String currency;
  final RecurringTransactionType type;
  final RecurringFrequency frequency;
  final RecurringMode mode;
  final int intervalCount;
  final DateTime startDate;
  final DateTime nextOccurrenceAt;
  final int reminderDaysBefore;
  final bool isActive;
  final String createdByUserId;
  final String updatedByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? note;
  final int? dayOfMonth;
  final int? dayOfWeek;
  final int? monthOfYear;
  final DateTime? endDate;
  final DateTime? deletedAt;

  bool get isExpense => type == RecurringTransactionType.expense;

  bool get isIncome => type == RecurringTransactionType.income;

  RecurringTransaction copyWith({
    String? id,
    String? workspaceId,
    String? title,
    String? categoryId,
    int? amountCents,
    String? currency,
    RecurringTransactionType? type,
    RecurringFrequency? frequency,
    RecurringMode? mode,
    int? intervalCount,
    DateTime? startDate,
    DateTime? nextOccurrenceAt,
    int? reminderDaysBefore,
    bool? isActive,
    String? createdByUserId,
    String? updatedByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? note,
    int? dayOfMonth,
    int? dayOfWeek,
    int? monthOfYear,
    DateTime? endDate,
    DateTime? deletedAt,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      amountCents: amountCents ?? this.amountCents,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      mode: mode ?? this.mode,
      intervalCount: intervalCount ?? this.intervalCount,
      startDate: startDate ?? this.startDate,
      nextOccurrenceAt: nextOccurrenceAt ?? this.nextOccurrenceAt,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      isActive: isActive ?? this.isActive,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      updatedByUserId: updatedByUserId ?? this.updatedByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      note: note ?? this.note,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      monthOfYear: monthOfYear ?? this.monthOfYear,
      endDate: endDate ?? this.endDate,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] as String,
      workspaceId: json['workspace_id'] as String,
      title: json['title'] as String,
      categoryId: json['category_id'] as String,
      amountCents: json['amount_minor'] as int,
      currency: json['currency_code'] as String? ?? 'VND',
      type: RecurringTransactionType.values.byName(
        json['transaction_type'] as String,
      ),
      frequency: RecurringFrequency.values.byName(
        json['frequency'] as String,
      ),
      mode: RecurringMode.values.byName(json['mode'] as String),
      intervalCount: json['interval_count'] as int? ?? 1,
      startDate: DateTime.parse(json['start_date'] as String),
      nextOccurrenceAt: DateTime.parse(json['next_occurrence_at'] as String),
      reminderDaysBefore: json['reminder_days_before'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdByUserId: json['created_by_user_id'] as String,
      updatedByUserId: json['updated_by_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      note: json['note'] as String?,
      dayOfMonth: json['day_of_month'] as int?,
      dayOfWeek: json['day_of_week'] as int?,
      monthOfYear: json['month_of_year'] as int?,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workspace_id': workspaceId,
      'title': title,
      'category_id': categoryId,
      'amount_minor': amountCents,
      'currency_code': currency,
      'transaction_type': type.name,
      'frequency': frequency.name,
      'mode': mode.name,
      'interval_count': intervalCount,
      'start_date': startDate.toIso8601String(),
      'next_occurrence_at': nextOccurrenceAt.toIso8601String(),
      'reminder_days_before': reminderDaysBefore,
      'is_active': isActive,
      'created_by_user_id': createdByUserId,
      'updated_by_user_id': updatedByUserId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'note': note,
      'day_of_month': dayOfMonth,
      'day_of_week': dayOfWeek,
      'month_of_year': monthOfYear,
      'end_date': endDate?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory RecurringTransaction.draft({
    required String workspaceId,
    required String createdByUserId,
    required String updatedByUserId,
    required String categoryId,
    required DateTime startDate,
    required DateTime nextOccurrenceAt,
  }) {
    final now = DateTime.now();
    return RecurringTransaction(
      id: '',
      workspaceId: workspaceId,
      title: '',
      categoryId: categoryId,
      amountCents: 0,
      currency: 'VND',
      type: RecurringTransactionType.expense,
      frequency: RecurringFrequency.monthly,
      mode: RecurringMode.manualConfirm,
      intervalCount: 1,
      startDate: startDate,
      nextOccurrenceAt: nextOccurrenceAt,
      reminderDaysBefore: 0,
      isActive: true,
      createdByUserId: createdByUserId,
      updatedByUserId: updatedByUserId,
      createdAt: now,
      updatedAt: now,
      dayOfMonth: startDate.day,
    );
  }
}

enum RecurringTransactionType { income, expense }

enum RecurringFrequency { weekly, monthly, yearly }

enum RecurringMode { reminderOnly, manualConfirm }
