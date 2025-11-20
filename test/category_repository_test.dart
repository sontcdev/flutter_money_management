// path: test/category_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:test3_cursor/src/data/local/app_database.dart';
import 'package:test3_cursor/src/data/repositories/category_repository.dart';
import 'package:test3_cursor/src/data/local/daos/category_dao.dart';
import 'package:test3_cursor/src/models/category.dart';
import 'package:test3_cursor/src/models/transaction.dart' as model;
import 'package:test3_cursor/src/models/budget.dart';

void main() {
  late AppDatabase db;
  late CategoryRepository repository;

  setUp(() async {
    // Create in-memory database for testing
    db = createTestDatabase();
    final dao = CategoryDao(db);
    repository = CategoryRepository(dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryRepository', () {
    test('create category successfully', () async {
      final category = await repository.createCategory(
        name: 'Test Category',
        type: CategoryType.expense,
        colorHex: '#FF0000',
        iconName: 'shopping_cart',
      );

      expect(category.name, 'Test Category');
      expect(category.type, CategoryType.expense);
      expect(category.colorHex, '#FF0000');
      expect(category.iconName, 'shopping_cart');

      final retrieved = await repository.getCategoryById(category.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Test Category');
    });

    test('prevent duplicate category name', () async {
      await repository.createCategory(
        name: 'Duplicate',
        type: CategoryType.expense,
      );

      expect(
        () async => await repository.createCategory(
          name: 'Duplicate',
          type: CategoryType.income,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('update category successfully', () async {
      final category = await repository.createCategory(
        name: 'Original Name',
        type: CategoryType.expense,
      );

      final updated = category.copyWith(name: 'Updated Name');
      await repository.updateCategory(updated);

      final retrieved = await repository.getCategoryById(category.id);
      expect(retrieved!.name, 'Updated Name');
    });

    test('delete category throws CategoryInUseException when referenced by transaction', () async {
      // Create category
      final category = await repository.createCategory(
        name: 'Used Category',
        type: CategoryType.expense,
      );

      // Create transaction referencing category
      final now = DateTime.now();
      final transaction = model.Transaction(
        id: 'txn1',
        amountCents: 5000,
        currency: 'VND',
        dateTime: now,
        categoryId: category.id,
        type: model.TransactionType.expense,
        createdAt: now,
        updatedAt: now,
      );
      await db.transactionDao.insertTransaction(transaction);

      // Attempt to delete category should throw
      expect(
        () async => await repository.deleteCategory(category.id),
        throwsA(isA<CategoryInUseException>()),
      );

      // Verify the exception contains correct counts
      try {
        await repository.deleteCategory(category.id);
        fail('Should have thrown CategoryInUseException');
      } on CategoryInUseException catch (e) {
        expect(e.transactionsCount, 1);
        expect(e.budgetsCount, 0);
        expect(e.message, contains('1 transaction'));
      }
    });

    test('delete category throws CategoryInUseException when referenced by budget', () async {
      // Create category
      final category = await repository.createCategory(
        name: 'Budgeted Category',
        type: CategoryType.expense,
      );

      // Create budget referencing category
      final now = DateTime.now();
      final budget = Budget(
        id: 'bdg1',
        categoryId: category.id,
        limitCents: 100000,
        consumedCents: 0,
        allowOverdraft: false,
        overdraftCents: 0,
        periodType: PeriodType.monthly,
        periodStart: DateTime(2025, 11, 1),
        periodEnd: DateTime(2025, 11, 30),
        createdAt: now,
        updatedAt: now,
      );
      await db.budgetDao.insertBudget(budget);

      // Attempt to delete category should throw
      expect(
        () async => await repository.deleteCategory(category.id),
        throwsA(isA<CategoryInUseException>()),
      );

      // Verify the exception contains correct counts
      try {
        await repository.deleteCategory(category.id);
        fail('Should have thrown CategoryInUseException');
      } on CategoryInUseException catch (e) {
        expect(e.transactionsCount, 0);
        expect(e.budgetsCount, 1);
        expect(e.message, contains('1 budget'));
      }
    });

    test('delete category succeeds when not referenced', () async {
      final category = await repository.createCategory(
        name: 'Unused Category',
        type: CategoryType.expense,
      );

      await repository.deleteCategory(category.id);

      final retrieved = await repository.getCategoryById(category.id);
      expect(retrieved, isNull);
    });

    test('search categories by name', () async {
      await repository.createCategory(name: 'Food', type: CategoryType.expense);
      await repository.createCategory(name: 'Transport', type: CategoryType.expense);
      await repository.createCategory(name: 'Fast Food', type: CategoryType.expense);

      final results = await repository.searchByName('Food');
      expect(results.length, 2);
      expect(results.any((c) => c.name == 'Food'), true);
      expect(results.any((c) => c.name == 'Fast Food'), true);
    });

    test('get all categories', () async {
      await repository.createCategory(name: 'Cat1', type: CategoryType.expense);
      await repository.createCategory(name: 'Cat2', type: CategoryType.income);
      await repository.createCategory(name: 'Cat3', type: CategoryType.expense);

      final all = await repository.getAllCategories();
      expect(all.length, 3);
    });
  });
}

// Helper function to create test database
AppDatabase createTestDatabase() {
  return AppDatabase();
}

