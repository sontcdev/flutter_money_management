import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_money_management/src/data/local/app_database.dart';
import 'package:flutter_money_management/src/data/repositories/budget_repository.dart';
import 'package:flutter_money_management/src/services/budget_service.dart';
import 'package:flutter_money_management/src/models/budget.dart';
import 'package:drift/native.dart';

void main() {
  late AppDatabase db;
  late BudgetService budgetService;
  late BudgetRepository budgetRepo;

  setUp(() async {
    db = AppDatabase.withQueryExecutor(NativeDatabase.memory());
    budgetService = BudgetService(db);
    budgetRepo = BudgetRepository(db, budgetService);

    // Create a test category first
    final now = DateTime.now();
    await db.categoryDao.insertCategory(
      CategoriesCompanion.insert(
        name: 'Test Category',
        iconName: '🧪',
        colorValue: 0xFF000000,
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('Create budget successfully', () async {
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month, 1);
    final periodEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final budget = Budget(
      id: 0,
      categoryId: 1,
      periodType: PeriodType.monthly,
      periodStart: periodStart,
      periodEnd: periodEnd,
      limitCents: 100000, // 1000 VND
      consumedCents: 0,
      allowOverdraft: false,
      overdraftCents: 0,
      createdAt: now,
      updatedAt: now,
    );

    final createdBudget = await budgetRepo.createBudget(budget);

    expect(createdBudget.id, greaterThan(0));
    expect(createdBudget.categoryId, equals(1));
    expect(createdBudget.limitCents, equals(100000));
  });

  test('Create budget with invalid category should fail', () async {
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month, 1);
    final periodEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final budget = Budget(
      id: 0,
      categoryId: 999, // Non-existent category
      periodType: PeriodType.monthly,
      periodStart: periodStart,
      periodEnd: periodEnd,
      limitCents: 100000,
      consumedCents: 0,
      allowOverdraft: false,
      overdraftCents: 0,
      createdAt: now,
      updatedAt: now,
    );

    expect(
      () async => await budgetRepo.createBudget(budget),
      throwsA(isA<Exception>()),
    );
  });

  test('Create overlapping budgets should fail', () async {
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month, 1);
    final periodEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final budget1 = Budget(
      id: 0,
      categoryId: 1,
      periodType: PeriodType.monthly,
      periodStart: periodStart,
      periodEnd: periodEnd,
      limitCents: 100000,
      consumedCents: 0,
      allowOverdraft: false,
      overdraftCents: 0,
      createdAt: now,
      updatedAt: now,
    );

    await budgetRepo.createBudget(budget1);

    // Try to create another budget for the same period
    final budget2 = Budget(
      id: 0,
      categoryId: 1,
      periodType: PeriodType.monthly,
      periodStart: periodStart,
      periodEnd: periodEnd,
      limitCents: 200000,
      consumedCents: 0,
      allowOverdraft: false,
      overdraftCents: 0,
      createdAt: now,
      updatedAt: now,
    );

    expect(
      () async => await budgetRepo.createBudget(budget2),
      throwsA(isA<BudgetOverlapException>()),
    );
  });
}

