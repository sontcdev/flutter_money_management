class RecurringOccurrence {
  const RecurringOccurrence({
    required this.id,
    required this.recurringTransactionId,
    required this.workspaceId,
    required this.scheduledFor,
    required this.remindAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.generatedTransactionId,
  });

  final String id;
  final String recurringTransactionId;
  final String workspaceId;
  final DateTime scheduledFor;
  final DateTime remindAt;
  final RecurringOccurrenceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? generatedTransactionId;

  factory RecurringOccurrence.fromJson(Map<String, dynamic> json) {
    return RecurringOccurrence(
      id: json['id'] as String,
      recurringTransactionId: json['recurring_transaction_id'] as String,
      workspaceId: json['workspace_id'] as String,
      scheduledFor: DateTime.parse(json['scheduled_for'] as String),
      remindAt: DateTime.parse(json['remind_at'] as String),
      status: RecurringOccurrenceStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      generatedTransactionId: json['generated_transaction_id'] as String?,
    );
  }
}

enum RecurringOccurrenceStatus { pending, completed, skipped, dismissed }
