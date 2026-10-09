import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/utils/voice_transaction_parser.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';

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

final _sentenceCorpus = [
  (
    text: 'hôm nay đi chợ hết 150k',
    amount: 150000,
    days: 0,
    type: TransactionType.expense,
    category: 'Ăn uống',
    wallet: null
  ),
  (
    text: 'mua cà phê hết 30 nghìn',
    amount: 30000,
    days: null,
    type: TransactionType.expense,
    category: 'Ăn uống',
    wallet: null
  ),
  (
    text: 'hôm qua nhận lương 5 triệu',
    amount: 5000000,
    days: -1,
    type: TransactionType.income,
    category: 'Lương',
    wallet: null
  ),
  (
    text: 'nhận lương 5 triệu 2',
    amount: 5200000,
    days: null,
    type: TransactionType.income,
    category: 'Lương',
    wallet: null
  ),
  (
    text: 'trả tiền điện 250.000',
    amount: 250000,
    days: null,
    type: TransactionType.expense,
    category: 'Nhà',
    wallet: null
  ),
  (
    text: 'mua đồ hết 50000',
    amount: 50000,
    days: null,
    type: TransactionType.expense,
    category: null,
    wallet: null
  ),
  (
    text: 'hom nay di cho het 150k',
    amount: 150000,
    days: 0,
    type: TransactionType.expense,
    category: 'Ăn uống',
    wallet: null
  ),
  (
    text: 'hom qua mua sach 100k',
    amount: 100000,
    days: -1,
    type: TransactionType.expense,
    category: 'Sách',
    wallet: null
  ),
  (
    text: 'ăn trưa 50k hôm qua ví momo',
    amount: 50000,
    days: -1,
    type: TransactionType.expense,
    category: 'Ăn uống',
    wallet: 'MoMo'
  ),
  (
    text: 'mua vé xe 80 ngàn',
    amount: 80000,
    days: null,
    type: TransactionType.expense,
    category: 'Di chuyển',
    wallet: null
  ),
  (
    text: 'thưởng 2tr',
    amount: 2000000,
    days: null,
    type: TransactionType.income,
    category: 'Thưởng',
    wallet: null
  ),
  (
    text: 'đóng tiền nước 120,000',
    amount: 120000,
    days: null,
    type: TransactionType.expense,
    category: 'Nhà',
    wallet: null
  ),
  (
    text: 'mua sách 1,5 triệu',
    amount: 1500000,
    days: null,
    type: TransactionType.expense,
    category: 'Sách',
    wallet: null
  ),
  (
    text: 'nạp 200 k',
    amount: 200000,
    days: null,
    type: TransactionType.expense,
    category: null,
    wallet: null
  ),
  (
    text: 'hôm kia mua 20k',
    amount: 20000,
    days: -2,
    type: TransactionType.expense,
    category: null,
    wallet: null
  ),
  (
    text: '150k tiền linh tinh',
    amount: 150000,
    days: null,
    type: null,
    category: null,
    wallet: null
  ),
  (
    text: 'mua điện thoại 2 củ',
    amount: 2000000,
    days: null,
    type: TransactionType.expense,
    category: null,
    wallet: null
  ),
  (
    text: 'do xang 2 lit',
    amount: 200000,
    days: null,
    type: TransactionType.expense,
    category: 'Di chuyển',
    wallet: null
  ),
  (
    text: 'mua nhà 1 tỷ',
    amount: 1000000000,
    days: null,
    type: TransactionType.expense,
    category: 'Nhà',
    wallet: null
  ),
  (
    text: 'mua đồ 5 trăm',
    amount: 500000,
    days: null,
    type: TransactionType.expense,
    category: null,
    wallet: null
  ),
  (
    text: 'nhận lương 1tr2',
    amount: 1200000,
    days: null,
    type: TransactionType.income,
    category: 'Lương',
    wallet: null
  ),
  (
    text: 'salary 2m',
    amount: 2000000,
    days: null,
    type: null,
    category: null,
    wallet: null
  ),
  (
    text: 'mua cafe 50.5k',
    amount: 50500,
    days: null,
    type: TransactionType.expense,
    category: 'Ăn uống',
    wallet: null
  ),
  (
    text: 'mua sách 50000đ',
    amount: 50000,
    days: null,
    type: TransactionType.expense,
    category: 'Sách',
    wallet: null
  ),
  (
    text: 'mua sách 50000 vnd',
    amount: 50000,
    days: null,
    type: TransactionType.expense,
    category: 'Sách',
    wallet: null
  ),
  (
    text: r'coffee 30$',
    amount: 30,
    days: null,
    type: null,
    category: null,
    wallet: null
  ),
  (
    text: 'thứ 2 mua đồ 50k',
    amount: 50000,
    days: -4,
    type: TransactionType.expense,
    category: null,
    wallet: null
  ),
  (
    text: 'ngày mai mua đồ 50k',
    amount: 50000,
    days: 1,
    type: TransactionType.expense,
    category: null,
    wallet: null
  ),
  (
    text: 'hôm trước mua đồ 50k',
    amount: 50000,
    days: -1,
    type: TransactionType.expense,
    category: null,
    wallet: null
  ),
  (
    text: 'thứ 3 tuần trước mua 50k',
    amount: 50000,
    days: -10,
    type: TransactionType.expense,
    category: null,
    wallet: null
  ),
  (
    text: 'CN tuần này mua 50k',
    amount: 50000,
    days: 2,
    type: TransactionType.expense,
    category: null,
    wallet: null
  ),
  (
    text: 'tuần trước mua 50k',
    amount: 50000,
    days: -7,
    type: TransactionType.expense,
    category: null,
    wallet: null
  ),
  (
    text: 'đầu tháng mua 50k',
    amount: 50000,
    days: -8,
    type: TransactionType.expense,
    category: null,
    wallet: null
  ),
  (
    text: 'cuối tháng mua 50k',
    amount: 50000,
    days: 22,
    type: TransactionType.expense,
    category: null,
    wallet: null
  ),
  (
    text: 'ngày 15 mua 50k',
    amount: 50000,
    days: 6,
    type: TransactionType.expense,
    category: null,
    wallet: null
  ),
  (
    text: '15/9 mua 50k',
    amount: 50000,
    days: -24,
    type: TransactionType.expense,
    category: null,
    wallet: null
  ),
  (
    text: '15-9-2026 mua 50k',
    amount: 50000,
    days: -24,
    type: TransactionType.expense,
    category: null,
    wallet: null
  ),
  (
    text: 'sáng nay mua 50k',
    amount: 50000,
    days: 0,
    type: TransactionType.expense,
    category: null,
    wallet: null
  ),
  (
    text: 'trưa nay ăn 50k',
    amount: 50000,
    days: 0,
    type: TransactionType.expense,
    category: 'Ăn uống',
    wallet: null
  ),
  (
    text: 'tối nay ăn 50k',
    amount: 50000,
    days: 0,
    type: TransactionType.expense,
    category: 'Ăn uống',
    wallet: null
  ),
  (
    text: 'được cho 500k',
    amount: 500000,
    days: null,
    type: TransactionType.income,
    category: null,
    wallet: null
  ),
  (
    text: 'lãi 100k',
    amount: 100000,
    days: null,
    type: TransactionType.income,
    category: null,
    wallet: null
  ),
  (
    text: 'cổ tức 2 triệu',
    amount: 2000000,
    days: null,
    type: TransactionType.income,
    category: null,
    wallet: null
  ),
  (
    text: 'nhận chuyển khoản 1tr',
    amount: 1000000,
    days: null,
    type: TransactionType.income,
    category: null,
    wallet: 'Bank'
  ),
  (
    text: 'trả lại cho tôi 50k',
    amount: 50000,
    days: null,
    type: TransactionType.income,
    category: null,
    wallet: null
  ),
  (
    text: 'ship 30k',
    amount: 30000,
    days: null,
    type: TransactionType.expense,
    category: null,
    wallet: null
  ),
  (
    text: 'phí 10k',
    amount: 10000,
    days: null,
    type: TransactionType.expense,
    category: null,
    wallet: null
  ),
  (
    text: 'mua cafe 30k ví momo',
    amount: 30000,
    days: null,
    type: TransactionType.expense,
    category: 'Ăn uống',
    wallet: 'MoMo'
  ),
  (
    text: 'mua cà fê 30k ví momoo',
    amount: 30000,
    days: null,
    type: TransactionType.expense,
    category: 'Ăn uống',
    wallet: 'MoMo'
  ),
  (
    text: 'mua sách 100k tiền mặt',
    amount: 100000,
    days: null,
    type: TransactionType.expense,
    category: 'Sách',
    wallet: 'Tiền mặt'
  ),
  (
    text: 'mua sách 100k ck',
    amount: 100000,
    days: null,
    type: TransactionType.expense,
    category: 'Sách',
    wallet: 'Bank'
  ),
  (
    text: 'mua sách 100k ví tiết kiệm',
    amount: 100000,
    days: null,
    type: TransactionType.expense,
    category: 'Sách',
    wallet: 'Tiết kiệm'
  ),
  (
    text: 'lunch 50k cash',
    amount: 50000,
    days: null,
    type: null,
    category: null,
    wallet: 'Tiền mặt'
  ),
  (
    text: 'coffee 30k momo',
    amount: 30000,
    days: null,
    type: null,
    category: null,
    wallet: 'MoMo'
  ),
  (
    text: 'lunch 50k',
    amount: 50000,
    days: null,
    type: null,
    category: null,
    wallet: null
  ),
  (
    text: 'ランチ 50000',
    amount: 50000,
    days: null,
    type: null,
    category: null,
    wallet: null
  ),
  (
    text: 'コーヒー 30000',
    amount: 30000,
    days: null,
    type: null,
    category: null,
    wallet: null
  ),
  (
    text: '給与 5000000',
    amount: 5000000,
    days: null,
    type: null,
    category: null,
    wallet: null
  ),
  (
    text: 'ăn trưa 50k ví momo hôm nay',
    amount: 50000,
    days: 0,
    type: TransactionType.expense,
    category: 'Ăn uống',
    wallet: 'MoMo'
  ),
  (
    text: 'mua grab 45k ví momo hôm qua',
    amount: 45000,
    days: -1,
    type: TransactionType.expense,
    category: 'Di chuyển',
    wallet: 'MoMo'
  ),
];

Wallet _wallet(String name, WalletType type,
    {bool archived = false, bool isDefault = false}) {
  return Wallet(
      id: name,
      workspaceId: 'workspace',
      name: name,
      walletType: type,
      iconName: 'wallet',
      colorValue: 0,
      isArchived: archived,
      isDefault: isDefault,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026));
}

void main() {
  group('Natural-language rule corpus', () {
    for (final fixture in _sentenceCorpus) {
      test(fixture.text, () {
        final now = DateTime(2026, 10, 9, 14);
        final result = VoiceTransactionParser.parse(
          fixture.text,
          clock: () => now,
          categories: [
            _category('Ăn uống', CategoryType.expense),
            _category('Di chuyển', CategoryType.expense),
            _category('Lương', CategoryType.income),
            _category('Thưởng', CategoryType.income),
            _category('Nhà', CategoryType.expense),
            _category('Sách', CategoryType.expense)
          ],
          wallets: [
            _wallet('MoMo', WalletType.ewallet),
            _wallet('Bank', WalletType.bank),
            _wallet('Tiền mặt', WalletType.cash),
            _wallet('Tiết kiệm', WalletType.savings)
          ],
        );
        expect(result.amountVnd, fixture.amount);
        expect(result.type, fixture.type);
        expect(result.categoryName, fixture.category);
        expect(result.walletName, fixture.wallet);
        expect(
            result.date,
            fixture.days == null
                ? null
                : DateTime(2026, 10, 9 + fixture.days!));
      });
    }
    test('rejects invalid dates and does not use their digits as amounts', () {
      for (final text in ['ngày 32', '31/2', '15/13/2026', 'thứ 2']) {
        final result = VoiceTransactionParser.parse(text,
            clock: () => DateTime(2026, 10, 9));
        expect(result.amountVnd, isNull);
        if (text != 'thứ 2') expect(result.date, isNull);
      }
    });
    test('calendar boundaries and named weekdays', () {
      final now = DateTime(2026, 1, 1);
      expect(VoiceTransactionParser.parse('hôm qua', clock: () => now).date,
          DateTime(2025, 12, 31));
      expect(
          VoiceTransactionParser.parse('thứ hai tuần trước', clock: () => now)
              .date,
          DateTime(2025, 12, 22));
      expect(
          VoiceTransactionParser.parse('cuối tháng',
              clock: () => DateTime(2024, 2, 15)).date,
          DateTime(2024, 2, 29));
    });
    test('type keywords require word boundaries', () {
      expect(VoiceTransactionParser.parse('phim 50k').type, isNull);
      expect(VoiceTransactionParser.parse('shipper 50k').type, isNull);
    });
    test('currency prefix and decimal amount', () {
      expect(VoiceTransactionParser.parse(r'coffee $30').amountVnd, 30);
      expect(VoiceTransactionParser.parse('mua 50.5 vnd').amountVnd, 50.5);
    });
  });

  test('wallet aliases avoid arbitrary choices and archived wallets', () {
    final wallets = [
      _wallet('First', WalletType.bank),
      _wallet('Second', WalletType.bank)
    ];
    expect(
        VoiceTransactionParser.parse('mua 50k ck', wallets: wallets).walletId,
        isNull);
    expect(
        VoiceTransactionParser.parse('mua 50k ck', wallets: [
          ...wallets,
          _wallet('Default', WalletType.bank, isDefault: true)
        ]).walletName,
        'Default');
    expect(
        VoiceTransactionParser.parse('mua 50k momo',
                wallets: [_wallet('MoMo', WalletType.ewallet, archived: true)])
            .walletId,
        isNull);
  });

  test('matches multi-word names with a typo', () {
    expect(
        VoiceTransactionParser.parse('mua 50k vi tiet kiem',
            wallets: [_wallet('Ví tiết kiệm', WalletType.savings)]).walletName,
        'Ví tiết kiệm');
    expect(
        VoiceTransactionParser.parse('giai tri 50k',
                categories: [_category('Giải trí', CategoryType.expense)])
            .categoryName,
        'Giải trí');
  });

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
