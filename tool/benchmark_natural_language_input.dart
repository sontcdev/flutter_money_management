import 'dart:io';

import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/features/transactions/services/category_suggestion_service.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/utils/voice_transaction_parser.dart';

void main() {
  final now = DateTime(2026, 10, 9);
  const names = [
    'Ăn uống',
    'Di chuyển',
    'Mua sắm',
    'Nhà ở',
    'Sức khỏe',
    'Giải trí',
    'Giáo dục',
    'Gia đình',
    'Lương',
    'Đầu tư',
  ];
  const notes = [
    'cà phê espresso quán quen',
    'grab taxi đi làm',
    'mua áo cửa hàng',
    'tiền thuê nhà chung cư',
    'khám răng phòng khám',
    'vé phim rạp chiếu',
    'học tiếng Nhật lớp tối',
    'quà sinh nhật cho mẹ',
    'nhận lương công ty',
    'cổ tức đầu tư chứng khoán',
  ];
  final categories = [
    for (var i = 0; i < names.length; i++)
      Category(
        id: 'category-$i',
        name: names[i],
        iconName: 'category',
        colorValue: 0,
        type: i < 8 ? CategoryType.expense : CategoryType.income,
        createdAt: now,
        updatedAt: now,
      ),
  ];
  final wallets = [
    for (var i = 0; i < 3; i++)
      Wallet(
        id: 'wallet-$i',
        workspaceId: 'benchmark',
        name: ['Tiền mặt', 'Momo', 'Vietcombank'][i],
        walletType: [WalletType.cash, WalletType.ewallet, WalletType.bank][i],
        iconName: 'wallet',
        colorValue: 0,
        isDefault: i == 0,
        createdAt: now,
        updatedAt: now,
      ),
  ];
  final history = [
    for (var i = 0; i < 5000; i++)
      Transaction(
        id: 'transaction-$i',
        amountCents: 3000000,
        currency: 'VND',
        dateTime: now.subtract(Duration(days: i % 365)),
        categoryId: 'category-${i % names.length}',
        type: i % names.length < 8
            ? TransactionType.expense
            : TransactionType.income,
        walletId: 'wallet-${i % 3}',
        note: '${notes[i % notes.length]} ${i % 23} hôm qua',
        createdAt: now,
        updatedAt: now,
      ),
  ];
  final stopwatch = Stopwatch()..start();
  var classifier = CategoryClassifier.train(history, clock: () => now);
  final firstTrain = stopwatch.elapsedMicroseconds;
  final trainTimes = <int>[];
  for (var i = 0; i < 35; i++) {
    stopwatch.reset();
    classifier = CategoryClassifier.train(history, clock: () => now);
    if (i >= 5) trainTimes.add(stopwatch.elapsedMicroseconds);
  }
  const inputs = [
    'ăn trưa 50k hôm qua ví momo',
    'cafe 30k và grab 45k',
    'espresso 30k',
    'nhận lương 12tr thứ 2 tuần trước Vietcombank',
    'mua áo 1tr2 ngày 15/9',
    '寿司 150k hôm qua',
  ];
  final parseTimes = <int>[];
  var parsedItems = 0;
  for (var i = 0; i < 1100; i++) {
    stopwatch.reset();
    final results = VoiceTransactionParser.parseMany(
      inputs[i % inputs.length],
      categories: categories,
      wallets: wallets,
      classifier: classifier,
      clock: () => now,
    );
    if (i >= 100) parseTimes.add(stopwatch.elapsedMicroseconds);
    parsedItems += results.length;
  }
  stopwatch.stop();
  trainTimes.sort();
  parseTimes.sort();
  double ms(int value) => value / 1000;
  double percentile(List<int> values, double fraction) =>
      ms(values[((values.length - 1) * fraction).round()]);
  stdout.writeln('Synthetic history: ${history.length} transactions, '
      '${categories.length} categories, ${wallets.length} wallets');
  stdout.writeln('First train: ${ms(firstTrain).toStringAsFixed(3)} ms');
  stdout.writeln('Warm train median/p95: '
      '${percentile(trainTimes, 0.5).toStringAsFixed(3)}/'
      '${percentile(trainTimes, 0.95).toStringAsFixed(3)} ms (30 runs; target <50 ms)');
  stdout.writeln('Warm parse median/p95: '
      '${percentile(parseTimes, 0.5).toStringAsFixed(3)}/'
      '${percentile(parseTimes, 0.95).toStringAsFixed(3)} ms '
      '(1000 runs; target <5 ms; consumed $parsedItems results)');
}
