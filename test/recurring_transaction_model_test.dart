import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_money_management/src/features/recurring/models/recurring_transaction.dart';

void main() {
  test('shared recurring history loads after its authors are deleted', () {
    final transaction = RecurringTransaction.fromJson({
      'id': 'recurring-1',
      'workspace_id': 'workspace-1',
      'title': 'Rent',
      'category_id': 'category-1',
      'amount_minor': 100,
      'transaction_type': 'expense',
      'frequency': 'monthly',
      'mode': 'manualConfirm',
      'start_date': '2026-10-01T00:00:00Z',
      'next_occurrence_at': '2026-11-01T00:00:00Z',
      'created_by_user_id': null,
      'updated_by_user_id': null,
      'created_at': '2026-10-01T00:00:00Z',
      'updated_at': '2026-10-01T00:00:00Z',
    });

    expect(transaction.createdByUserId, isNull);
    expect(transaction.updatedByUserId, isNull);
    expect(transaction.title, 'Rent');
    expect(transaction.toJson()['created_by_user_id'], isNull);
    expect(transaction.copyWith(title: 'Updated rent').createdByUserId, isNull);
  });
}
