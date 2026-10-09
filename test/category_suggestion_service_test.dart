import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/features/transactions/providers/transaction_providers.dart';
import 'package:flutter_money_management/src/features/transactions/services/category_suggestion_service.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/utils/voice_transaction_parser.dart';

Transaction _txn(
  String note,
  String category, {
  TransactionType type = TransactionType.expense,
  String wallet = 'cash',
  DateTime? date,
}) {
  final now = date ?? DateTime(2026, 10, 9);
  return Transaction(
    id: '$category-$note',
    amountCents: 50000,
    currency: 'VND',
    dateTime: now,
    categoryId: category,
    type: type,
    walletId: wallet,
    note: note,
    createdAt: now,
    updatedAt: now,
  );
}

Category _category(String id, String name, CategoryType type) => Category(
      id: id,
      name: name,
      type: type,
      iconName: 'category',
      colorValue: 0,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  final history = [
    for (var i = 0; i < 5; i++) _txn('cà phê espresso', 'food'),
    for (var i = 0; i < 5; i++) _txn('grab taxi', 'travel', wallet: 'momo'),
    for (var i = 0; i < 5; i++)
      _txn('cà phê bán hàng', 'salary',
          type: TransactionType.income, wallet: 'bank'),
  ];

  test('learns unigrams and bigrams with confidence and type filtering', () {
    final classifier = CategoryClassifier.train(history);
    final suggestion =
        classifier.predict('espresso 30k hôm qua', type: CategoryType.expense);
    expect(suggestion?.categoryId, 'food');
    expect(suggestion!.confidence, greaterThanOrEqualTo(0.65));
    expect(classifier.predict('ca phe', type: CategoryType.income)?.categoryId,
        'salary');
    expect(classifier.suggestWallet('grab', 'travel'), 'momo');
    expect(classifier.predict('unseen words'), isNull);
  });

  test('cold start, empty notes, transfers and deleted transactions abstain',
      () {
    expect(CategoryClassifier.train([]).predict('espresso'), isNull);
    expect(
        CategoryClassifier.train([_txn('espresso', 'food')])
            .predict('espresso'),
        isNull);
    final ignored = [
      _txn('', 'food'),
      _txn('espresso', 'food', type: TransactionType.transfer),
      _txn('espresso', 'food').copyWith(deletedAt: DateTime(2026)),
    ];
    expect(CategoryClassifier.train(ignored).predict('espresso'), isNull);
  });

  test('ambiguous evidence abstains and recent examples carry more weight', () {
    final ambiguous = [
      for (var i = 0; i < 3; i++) ...[
        _txn('espresso', 'a'),
        _txn('espresso', 'b'),
      ]
    ];
    expect(CategoryClassifier.train(ambiguous).predict('espresso'), isNull);
    final recent = [
      for (var i = 0; i < 3; i++) ...[
        _txn('espresso', 'a', date: DateTime(2025)),
        _txn('espresso', 'b'),
      ]
    ];
    expect(
        CategoryClassifier.train(recent, clock: () => DateTime(2026, 10, 9))
            .predict('espresso')
            ?.categoryId,
        'b');
  });

  test('parser excludes missing and deleted categories and unavailable wallets',
      () {
    final classifier = CategoryClassifier.train(history);
    final categories = [_category('food', 'Meals', CategoryType.expense)];
    final result = VoiceTransactionParser.parse('espresso 30k',
        categories: categories, classifier: classifier);
    expect(result.categoryId, 'food');
    expect(result.categoryConfidence, isNotNull);
    expect(result.walletId, isNull);
    expect(
        VoiceTransactionParser.parse('espresso 30k', classifier: classifier)
            .categoryId,
        isNull);
    expect(
        VoiceTransactionParser.parse('espresso 30k',
                categories: [
                  categories.single.copyWith(deletedAt: DateTime(2026))
                ],
                classifier: classifier)
            .categoryId,
        isNull);
    final cash = Wallet(
        id: 'cash',
        workspaceId: 'workspace',
        name: 'Pocket',
        iconName: 'wallet',
        colorValue: 0,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026));
    expect(
        VoiceTransactionParser.parse('espresso 30k',
            categories: categories,
            classifier: classifier,
            wallets: [cash]).walletId,
        'cash');
    expect(
        VoiceTransactionParser.parse('espresso 30k',
            categories: categories,
            classifier: classifier,
            wallets: [cash.copyWith(isArchived: true)]).walletId,
        isNull);
  });

  test('explicit category and wallet override learned suggestions', () {
    final result = VoiceTransactionParser.parse(
      'espresso gifts 30k bank',
      categories: [
        _category('food', 'Meals', CategoryType.expense),
        _category('gifts', 'Gifts', CategoryType.expense)
      ],
      wallets: [
        Wallet(
            id: 'bank',
            workspaceId: 'workspace',
            name: 'Bank',
            iconName: 'wallet',
            colorValue: 0,
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026))
      ],
      classifier: CategoryClassifier.train(history),
    );
    expect(result.categoryId, 'gifts');
    expect(result.categoryConfidence, isNull);
    expect(result.walletId, 'bank');
  });

  test('learns Japanese history without network or persistence', () {
    final classifier = CategoryClassifier.train(
        [for (var i = 0; i < 3; i++) _txn('コーヒー', 'food')]);
    expect(classifier.predict('コーヒー 30000')?.categoryId, 'food');
  });

  test('classifier rebuilds when workspace transaction data is invalidated',
      () async {
    var transactions = history;
    final container = ProviderContainer(overrides: [
      transactionsProvider.overrideWith((ref) async => transactions)
    ]);
    addTearDown(container.dispose);
    final first = await container.read(categoryClassifierProvider.future);
    expect(first.predict('espresso', type: CategoryType.expense)?.categoryId,
        'food');
    transactions = [for (var i = 0; i < 3; i++) _txn('espresso', 'new')];
    container.invalidate(transactionsProvider);
    final second = await container.read(categoryClassifierProvider.future);
    expect(second.predict('espresso')?.categoryId, 'new');
    expect(identical(first, second), isFalse);
  });
}
