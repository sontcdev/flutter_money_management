import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/utils/voice_transaction_parser.dart';

Category _category(String name, CategoryType type) {
  final now = DateTime(2026, 1, 1);
  return Category(
    id: name,
    name: name,
    iconName: 'shopping_cart',
    colorValue: 0xFF000000,
    type: type,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('VoiceTransactionParser amount parsing', () {
    test('parses "k" suffix', () {
      final result = VoiceTransactionParser.parse('hôm nay đi chợ hết 150k');
      expect(result.amountVnd, 150000);
    });

    test('parses "nghìn" suffix', () {
      final result = VoiceTransactionParser.parse('mua cà phê hết 30 nghìn');
      expect(result.amountVnd, 30000);
    });

    test('parses "triệu" suffix', () {
      final result = VoiceTransactionParser.parse('hôm qua nhận lương 5 triệu');
      expect(result.amountVnd, 5000000);
    });

    test('parses "triệu" with trailing hundred-thousand digit', () {
      final result = VoiceTransactionParser.parse('nhận lương 5 triệu 2');
      expect(result.amountVnd, 5200000);
    });

    test('parses grouped plain digits', () {
      final result = VoiceTransactionParser.parse('trả tiền điện 250.000');
      expect(result.amountVnd, 250000);
    });

    test('parses plain digits without separators', () {
      final result = VoiceTransactionParser.parse('mua đồ hết 50000');
      expect(result.amountVnd, 50000);
    });

    test('returns null when no amount present', () {
      final result = VoiceTransactionParser.parse('hôm nay đi chợ');
      expect(result.amountVnd, isNull);
    });
  });

  group('VoiceTransactionParser date parsing', () {
    test('recognizes "hôm nay"', () {
      final now = DateTime.now();
      final result = VoiceTransactionParser.parse('hôm nay đi chợ hết 150k');
      expect(result.date, DateTime(now.year, now.month, now.day));
    });

    test('recognizes "hôm qua"', () {
      final yesterday =
          DateTime.now().subtract(const Duration(days: 1));
      final result = VoiceTransactionParser.parse('hôm qua mua sách hết 100k');
      expect(
        result.date,
        DateTime(yesterday.year, yesterday.month, yesterday.day),
      );
    });

    test('returns null when no date keyword present', () {
      final result = VoiceTransactionParser.parse('mua sách hết 100k');
      expect(result.date, isNull);
    });
  });

  group('VoiceTransactionParser type parsing', () {
    test('detects income keyword', () {
      final result = VoiceTransactionParser.parse('hôm qua nhận lương 5 triệu');
      expect(result.type, TransactionType.income);
    });

    test('detects expense keyword', () {
      final result = VoiceTransactionParser.parse('hôm nay đi chợ hết 150k');
      expect(result.type, TransactionType.expense);
    });

    test('returns null when no type keyword present', () {
      final result = VoiceTransactionParser.parse('150k tiền linh tinh');
      expect(result.type, isNull);
    });
  });

  group('VoiceTransactionParser category matching', () {
    test('matches category by overlapping token', () {
      final categories = [
        _category('Ăn uống', CategoryType.expense),
        _category('Di chuyển', CategoryType.expense),
        _category('Lương', CategoryType.income),
      ];
      final result = VoiceTransactionParser.parse(
        'hôm nay đi chợ hết 150k',
        categories: categories,
      );
      expect(result.categoryName, 'Ăn uống');
    });

    test('only matches categories of the detected type', () {
      final categories = [
        _category('Lương', CategoryType.income),
        _category('Ăn uống', CategoryType.expense),
      ];
      final result = VoiceTransactionParser.parse(
        'hôm qua nhận lương 5 triệu',
        categories: categories,
      );
      expect(result.categoryName, 'Lương');
    });

    test('returns null category when nothing matches', () {
      final categories = [
        _category('Du lịch', CategoryType.expense),
      ];
      final result = VoiceTransactionParser.parse(
        'hôm nay đi chợ hết 150k',
        categories: categories,
      );
      expect(result.categoryId, isNull);
    });
  });
}
