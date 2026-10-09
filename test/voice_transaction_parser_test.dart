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
    amount: null,
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
    days: -9,
    type: TransactionType.expense,
    category: null,
    wallet: null
  ),
  (
    text: 'ngày 15 mua 50k',
    amount: 50000,
    days: -24,
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

const _formatCorpus = [
  ('1tr2', 1200000, null, null, null, false),
  ('1tr25', 1250000, null, null, null, false),
  ('1tr200', 1200000, null, null, null, false),
  ('1,5tr', 1500000, null, null, null, false),
  ('30 ngàn', 30000, null, null, null, false),
  ('2 trăm nghìn', 200000, null, null, null, false),
  ('2 trăm ngàn', 200000, null, null, null, false),
  ('1m', 1000000, null, null, null, false),
  ('1 tỷ', 1000000000, null, null, null, false),
  ('2 lít', 200000, null, null, null, false),
  ('30 000 vnd', 30000, null, null, null, false),
  ('vay', null, null, null, null, false),
  ('cho vay', null, null, null, null, false),
  ('trả nợ', null, null, null, null, false),
  ('tháng 10', null, null, null, 'Tháng 10', false),
  ('cafe 30k 90 ngày trước', 30000, '2026-07-11', null, 'Cafe', false),
  ('cafe 30k 12 tuần trước', 30000, '2026-07-17', null, 'Cafe', false),
  ('cafe 30k hôm nay', 30000, '2026-10-09', null, 'Cafe', false),
  ('cafe 30k hôm qua', 30000, '2026-10-08', null, 'Cafe', false),
  ('cafe 30k hôm kia', 30000, '2026-10-07', null, 'Cafe', false),
  ('cafe 30k hôm trước', 30000, '2026-10-08', null, 'Cafe', false),
  ('cafe 30k sáng nay', 30000, '2026-10-09', null, 'Cafe', false),
  ('cafe 30k trưa nay', 30000, '2026-10-09', null, 'Cafe', false),
  ('cafe 30k tối nay', 30000, '2026-10-09', null, 'Cafe', false),
  ('cafe 30k tuần trước', 30000, '2026-10-02', null, 'Cafe', false),
  ('cafe 30k đầu tháng', 30000, '2026-10-01', null, 'Cafe', false),
  ('cafe 30k cuối tháng', 30000, '2026-09-30', null, 'Cafe', false),
  ('cafe 30k ngày 15 tháng 10', 30000, '2025-10-15', null, 'Cafe', false),
  ('cafe 30k 15/10/2026', 30000, '2026-10-15', null, 'Cafe', false),
  ('cafe 30k thứ 2', 30000, '2026-10-05', null, 'Cafe', false),
  ('an   voi ban 200k!', 200000, null, TransactionType.expense, null, false),
  (
    'đóng học phí 1.500.000 đồng',
    1500000,
    null,
    TransactionType.expense,
    null,
    false
  ),
  (':cafe 30k;-', 30000, null, null, 'Cafe', false),
  ('30 000', 30000, null, null, null, false),
  ('cafe 1 500 000', 1500000, null, null, 'Cafe', false),
  ('phòng 12 500', 12, null, null, null, true),
  ('1tr rưỡi', 1500000, null, null, null, false),
  ('cafe 1 triệu rưỡi', 1500000, null, null, 'Cafe', false),
  ('2 củ rưỡi', 2500000, null, null, null, false),
  ('30 nghìn rưỡi', 30500, null, null, null, false),
  ('5 trăm rưỡi', 550000, null, null, null, false),
  (r'$20 sách', null, null, null, r'$20 sách', false),
  (
    'mua 2 đồ chơi 100k',
    100000,
    null,
    TransactionType.expense,
    'Mua 2 đồ chơi',
    false
  ),
  (
    'mua 20 đồ ăn 50k',
    50000,
    null,
    TransactionType.expense,
    'Mua 20 đồ ăn',
    false
  ),
  (
    'mua 20 do an 50k',
    50000,
    null,
    TransactionType.expense,
    'Mua 20 do an',
    false
  ),
  ('20 do', null, null, null, null, false),
  ('cafe 20 usd', null, null, null, null, false),
  ('cafe ban 50k', 50000, null, null, 'Cafe ban', false),
  ('gui ban 50k', 50000, null, null, 'Gui ban', false),
  (
    'an com voi ban 50k',
    50000,
    null,
    TransactionType.expense,
    'An com voi ban',
    false
  ),
  ('ban xe 5tr', 5000000, null, null, 'Ban xe', false),
  ('bán xe 5tr', 5000000, null, TransactionType.income, 'Bán xe', false),
  ('20 đô', null, null, null, null, false),
  ('20 usd', null, null, null, null, false),
  ('0k cafe', null, null, null, null, false),
  ('0đ', null, null, null, null, false),
  ('cafe năm 2026 30000', 30000, null, null, 'Cafe', false),
  ('tiền nhà tháng 10/2026 5tr', 5000000, null, null, null, false),
  ('cafe 30k ngày 25', 30000, '2026-09-25', null, 'Cafe', false),
  ('cafe 30k 15/10', 30000, '2025-10-15', null, 'Cafe', false),
  ('cafe 30k ngày 31', 30000, '2026-08-31', null, 'Cafe', false),
  ('cafe 30k ngày 5', 30000, '2026-10-05', null, 'Cafe', false),
  ('cafe 30k ngày 15 tháng 9', 30000, '2026-09-15', null, 'Cafe', false),
  (
    'cafe 30k ngày 15 tháng 10 năm 2026',
    30000,
    '2026-10-15',
    null,
    'Cafe',
    false
  ),
  ('cafe 30k tháng trước', 30000, '2026-09-09', null, 'Cafe', false),
  ('cafe 30k 3 ngày trước', 30000, '2026-10-06', null, 'Cafe', false),
  ('cafe 30k 2 tuần trước', 30000, '2026-09-25', null, 'Cafe', false),
  ('cafe 30k ngày mai', 30000, '2026-10-10', null, 'Cafe', false),
  ('cafe 30k v.v.', 30000, null, null, 'Cafe', false),
  ('cafe 30k etc.;', 30000, null, null, 'Cafe', false),
  ('1.500.000 đồng', 1500000, null, null, null, false),
  ('đóng học phí 1tr', 1000000, null, TransactionType.expense, null, false),
  ('bán đồ cũ 300k', 300000, null, TransactionType.income, null, false),
  ('ăn với bạn 200k', 200000, null, TransactionType.expense, null, false),
  ('an voi ban 200k', 200000, null, TransactionType.expense, null, false),
  ('30k', 30000, null, null, null, false),
  ('30 nghìn', 30000, null, null, null, false),
  ('30.000', 30000, null, null, null, false),
  ('30,000', 30000, null, null, null, false),
  ('30.000đ', 30000, null, null, null, false),
  ('30 000 đ', 30000, null, null, null, false),
  ('1tr5', 1500000, null, null, null, false),
  ('1tr 5', 1500000, null, null, null, false),
  ('1 triệu 5', 1500000, null, null, null, false),
  ('1.5tr', 1500000, null, null, null, false),
  ('2 củ', 2000000, null, null, null, false),
  ('5 trăm', 500000, null, null, null, false),
  ('1.2 tỷ', 1200000000, null, null, null, false),
  ('1.500.000', 1500000, null, null, null, false),
  ('iphone 15 20tr', 20000000, null, null, null, false),
  ('xăng 95 50k', 50000, null, null, null, false),
  ('grab 7h 50k', 50000, null, null, null, false),
  ('cafe lúc 9h30 30k', 30000, null, null, null, false),
  ('tiền nhà tháng 10 5tr', 5000000, null, null, null, false),
  ('mua 3 ly cafe 90k', 90000, null, null, null, false),
  ('500', 500, null, null, null, false),
  ('ba mươi nghìn', null, null, null, null, false),
  ('hai triệu', null, null, null, null, false),
  ('vay 50k', 50000, null, null, null, false),
  ('cho vay 50k', 50000, null, null, null, false),
  ('trả nợ 50k', 50000, null, null, null, false),
  ('tiền nhà 2026 5tr', 5000000, null, null, null, true),
  ('phòng 1203 tiền điện 500k', 500000, null, null, null, true),
  ('cafe 30k và 50k', 30000, null, null, null, true),
  ('cafe 30k + 50k', 30000, null, null, null, true),
  ('cafe 30k; 50k', 30000, null, null, null, true),
  ('cafe 30k bánh 20k', 30000, null, null, null, true),
];

void main() {
  group('Format corpus', () {
    for (final row in _formatCorpus) {
      test(row.$1, () {
        final result = VoiceTransactionParser.parse(row.$1,
            clock: () => DateTime(2026, 10, 9));
        expect(result.amountVnd, row.$2);
        if (row.$3 != null) expect(result.date, DateTime.parse(row.$3!));
        if (row.$4 != null ||
            [
              '1.500.000 đồng',
              'vay',
              'cho vay',
              'trả nợ',
              'vay 50k',
              'cho vay 50k',
              'trả nợ 50k',
              'cafe ban 50k',
              'gui ban 50k',
              'ban xe 5tr'
            ].contains(row.$1)) {
          expect(result.type, row.$4);
        }
        if (row.$5 != null) expect(result.note, row.$5);
        expect(result.hasExtraAmounts, row.$6);
      });
    }
  });
  group('Weekday date resolution', () {
    for (final fixture in [
      (text: 'thứ 6', now: DateTime(2026, 10, 5), date: DateTime(2026, 10, 2)),
      (text: 'thứ 6', now: DateTime(2026, 10, 9), date: DateTime(2026, 10, 9)),
      (text: 'thứ 2', now: DateTime(2026, 10, 7), date: DateTime(2026, 10, 5)),
      (
        text: 'chủ nhật',
        now: DateTime(2026, 10, 10),
        date: DateTime(2026, 10, 4)
      ),
      (
        text: 'thứ 6 tuần này',
        now: DateTime(2026, 10, 5),
        date: DateTime(2026, 10, 9)
      ),
      (
        text: 'thứ 6 tuần trước',
        now: DateTime(2026, 10, 5),
        date: DateTime(2026, 10, 2)
      ),
    ]) {
      test('${fixture.text} on ${fixture.now}', () {
        final result = VoiceTransactionParser.parse('cafe 30k ${fixture.text}',
            clock: () => fixture.now);
        expect(result.date, fixture.date);
      });
    }
    test('resolves dates without a year to the past', () {
      for (final fixture in [
        (text: 'ngày 15', date: DateTime(2026, 9, 15)),
        (text: '15/10', date: DateTime(2025, 10, 15)),
        (text: '15/10/2026', date: DateTime(2026, 10, 15)),
      ]) {
        expect(
            VoiceTransactionParser.parse('cafe 30k ${fixture.text}',
                clock: () => DateTime(2026, 10, 9)).date,
            fixture.date);
      }
    });
  });

  group('Multiple transactions and notes', () {
    for (final text in [
      'cafe 30k và bánh 50k',
      'cafe 30k và bánh và sữa 50k',
      'cafe 30k bánh 50000',
      'cafe 30000 bánh 50,000',
    ]) {
      test('flags extra amounts: $text', () {
        expect(VoiceTransactionParser.parse(text).hasExtraAmounts, isTrue);
      });
    }
    for (final text in [
      'cafe 30k, 2 ly trà 50k',
      'cafe 30k,2 ly trà 50k',
      '1 triệu 5',
      'cafe 30k hôm 15/10',
      'cafe 30k thứ 2',
      'cafe 30k ngày 15',
      '2 ly trà 50k',
      'mua 1,5tr',
      'sách 150,000',
    ]) {
      test('does not flag single amounts or counts: $text', () {
        expect(
            VoiceTransactionParser.parseMany(text)
                .every((r) => !r.hasExtraAmounts),
            isTrue);
      });
    }

    for (final text in [
      'cafe 30k,50k bánh',
      'cafe 30k,2 ly trà 50k',
      'cafe 30k、grab 45k',
      'cafe 30k，grab 45k',
    ]) {
      test('splits comma edge case: $text', () {
        expect(VoiceTransactionParser.parseMany(text).map((r) => r.amountVnd),
            text.contains('grab') ? [30000, 45000] : [30000, 50000]);
      });
    }
    test('recognizes dates adjacent to punctuation and shares them', () {
      for (final punctuation in [',', '.']) {
        final results = VoiceTransactionParser.parseMany(
            '15/10${punctuation}cafe 30k, grab 45k',
            clock: () => DateTime(2026, 10, 9));
        expect(results.map((r) => r.date),
            [DateTime(2025, 10, 15), DateTime(2025, 10, 15)]);
        expect(results.first.note, 'Cafe');
      }
      expect(VoiceTransactionParser.parse('15/10,5 cafe 30k').date, isNull);
    });
    test('detects amounts after non-numeric commas', () {
      expect(VoiceTransactionParser.parse('bánh,50k').amountVnd, 50000);
      expect(VoiceTransactionParser.parse('bánh,50000').amountVnd, 50000);
    });
    test('cleans note punctuation', () {
      for (final punctuation in ['.', ',', '。', '，', '、']) {
        expect(
            VoiceTransactionParser.parse('cafe 30k$punctuation').note, 'Cafe');
      }
      expect(
          VoiceTransactionParser.parseMany('cafe 30k, sữa 50k, mang về')
              .last
              .note,
          'Sữa, mang về');
    });

    for (final separator in [
      'và',
      'va',
      'rồi',
      'roi',
      'xong',
      ',',
      ';',
      '+',
      '\n'
    ]) {
      test('only splits transactions at commas: $separator', () {
        final results =
            VoiceTransactionParser.parseMany('cafe 30k $separator grab 45k');
        expect(results.map((r) => r.amountVnd),
            separator == ',' ? [30000, 45000] : [30000]);
        if (separator == ',') {
          expect(results.map((r) => r.note), ['Cafe', 'Grab']);
        } else {
          expect(results.single.rawText, 'cafe 30k $separator grab 45k');
        }
        expect(
            VoiceTransactionParser.parse('cafe 30k $separator grab 45k')
                .amountVnd,
            30000);
      });
    }
    test('preserves amount splitting and shared dates in review examples', () {
      for (final text in ['cafe 30k, ăn trưa 50k', 'cafe 30k, grab 45k']) {
        final results = VoiceTransactionParser.parseMany(text);
        expect(results.map((result) => result.amountVnd),
            text.contains('grab') ? [30000, 45000] : [30000, 50000]);
      }
      final results = VoiceTransactionParser.parseMany(
          'hôm qua cafe 30k, ăn trưa 50k',
          clock: () => DateTime(2026, 10, 9));
      expect(results.map((result) => result.date),
          [DateTime(2026, 10, 8), DateTime(2026, 10, 8)]);
    });
    test('preserves conjunctions in category names before an amount', () {
      final category = _category('Ăn và uống', CategoryType.expense);
      final results = VoiceTransactionParser.parseMany(
          'Ăn và uống 50k, cafe 30k',
          categories: [category]);
      expect(results.map((result) => result.amountVnd), [50000, 30000]);
      expect(results.first.categoryId, category.id);
    });
    test('preserves amount-first category names across separators', () {
      final category = _category('Ăn và uống', CategoryType.expense);
      final results = VoiceTransactionParser.parseMany(
          '50k ăn và uống, 30k cafe',
          categories: [category]);
      expect(results.map((result) => result.amountVnd), [50000, 30000]);
      expect(results.first.rawText, '50k ăn và uống');
      expect(results.first.categoryId, category.id);
    });
    test('keeps a single amount-first category name intact', () {
      final category = _category('Ăn và uống', CategoryType.expense);
      final results = VoiceTransactionParser.parseMany('50k ăn và uống',
          categories: [category]);
      expect(results, hasLength(1));
      expect(results.single.amountVnd, 50000);
      expect(results.single.rawText, '50k ăn và uống');
      expect(results.single.categoryId, category.id);
    });
    test('splits when both chunks start with an amount', () {
      final results = VoiceTransactionParser.parseMany('30k cafe, 50k ăn trưa');
      expect(results.map((result) => result.amountVnd), [30000, 50000]);
      expect(
          results.map((result) => result.rawText), ['30k cafe', '50k ăn trưa']);
    });
    test('merges amountless trailing text into the last transaction', () {
      final results =
          VoiceTransactionParser.parseMany('cafe 30k, sữa 50k, mang về');
      expect(results.map((result) => result.amountVnd), [30000, 50000]);
      expect(results.last.rawText, 'sữa 50k, mang về');
    });
    test('preserves conjunctions in the second category name', () {
      final category = _category('Bánh và sữa', CategoryType.expense);
      final results = VoiceTransactionParser.parseMany(
          'cafe 30k, bánh và sữa 50k',
          categories: [category]);
      expect(results.map((result) => result.amountVnd), [30000, 50000]);
      expect(results.last.rawText, 'bánh và sữa 50k');
      expect(results.last.categoryId, category.id);
    });
    test('keeps multiple amounts without a comma in one transaction', () {
      final results =
          VoiceTransactionParser.parseMany('cafe 30k và bánh và sữa 50k');
      expect(results, hasLength(1));
      expect(results.single.amountVnd, 30000);
      expect(results.single.rawText, 'cafe 30k và bánh và sữa 50k');
      expect(results.single.hasExtraAmounts, isTrue);
    });
    test('keeps amountless comma chunks with the transaction', () {
      for (final fixture in [
        (text: 'ví tiền mặt, thẻ 50k', amount: 50000),
        (text: 'cafe 30k, mang về', amount: 30000),
      ]) {
        final results = VoiceTransactionParser.parseMany(fixture.text);
        expect(results, hasLength(1));
        expect(results.single.amountVnd, fixture.amount);
        expect(results.single.rawText, fixture.text);
      }
    });
    test('keeps single amounts and wallet conjunctions intact', () {
      expect(VoiceTransactionParser.parseMany('mua 1,5tr'), hasLength(1));
      expect(VoiceTransactionParser.parse('mua 1,5tr').amountVnd, 1500000);
      expect(VoiceTransactionParser.parseMany('ví tiền mặt và thẻ 50k'),
          hasLength(1));
    });
    test('keeps amountless conjunction and numeric commas intact', () {
      expect(VoiceTransactionParser.parseMany('mua bánh và sữa 50k'),
          hasLength(1));
      expect(
          VoiceTransactionParser.parseMany('cafe 30,5k, grab 45k')
              .map((r) => r.amountVnd),
          [30500, 45000]);
      expect(
          VoiceTransactionParser.parseMany('sách 150,000, cafe 30k')
              .map((r) => r.amountVnd),
          [150000, 30000]);
      expect(VoiceTransactionParser.parseMany(''), hasLength(1));
    });
    test('propagates shared explicit context from either end', () {
      for (final text in [
        'hôm qua ví momo cafe 30k, ăn trưa 50k',
        'cafe 30k, ăn trưa 50k hôm qua ví momo'
      ]) {
        final results = VoiceTransactionParser.parseMany(text,
            clock: () => DateTime(2026, 10, 9),
            wallets: [_wallet('MoMo', WalletType.ewallet)]);
        expect(results.map((r) => r.date),
            [DateTime(2026, 10, 8), DateTime(2026, 10, 8)]);
        expect(results.map((r) => r.walletId), ['MoMo', 'MoMo']);
      }
    });
    test('keeps local contexts and does not guess conflicting shared contexts',
        () {
      final results = VoiceTransactionParser.parseMany(
          'hôm qua cafe 30k ví momo, grab 45k hôm nay cash, sách 100k',
          clock: () => DateTime(2026, 10, 9),
          wallets: [
            _wallet('MoMo', WalletType.ewallet),
            _wallet('Tiền mặt', WalletType.cash)
          ]);
      expect(results.map((r) => r.date),
          [DateTime(2026, 10, 8), DateTime(2026, 10, 9), null]);
      expect(results.map((r) => r.walletId), ['MoMo', 'Tiền mặt', null]);
    });
    test('cleans matched phrases while preserving accents and scripts', () {
      expect(
          VoiceTransactionParser.parse('ăn trưa 50k hôm qua ví momo',
              wallets: [_wallet('MoMo', WalletType.ewallet)]).note,
          'Ăn trưa');
      expect(
          VoiceTransactionParser.parse('cà phê 50.5k thứ 2 tuần trước cash',
              wallets: [_wallet('Tiền mặt', WalletType.cash)]).note,
          'Cà phê');
      expect(VoiceTransactionParser.parse('コーヒー 30000').note, 'コーヒー');
      expect(VoiceTransactionParser.parse('50k hôm qua').note, '50k hôm qua');
      expect(VoiceTransactionParser.parse('cà   phê 50k hôm   qua').note,
          'Cà phê');
    });
  });

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
          DateTime(2024, 1, 31));
    });
    test('type keywords require word boundaries', () {
      expect(VoiceTransactionParser.parse('phim 50k').type, isNull);
      expect(VoiceTransactionParser.parse('shipper 50k').type, isNull);
    });
    test('currency prefix and decimal amount', () {
      expect(VoiceTransactionParser.parse(r'coffee $30').amountVnd, isNull);
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

  group('Unit tails and spaced amounts', () {
    for (final fixture in [
      ('cafe 2 trăm 5', 200000, 'Cafe 5', true),
      ('2 trăm nghìn', 200000, '2 trăm nghìn', false),
      ('1.5tr 2', 1500000, '2', true),
      ('1,5tr', 1500000, '1,5tr', false),
      ('mua 1tr 2 cái áo', 1000000, 'Mua 2 cái áo', true),
      ('cafe 1 triệu 5', 1500000, 'Cafe', false),
      ('1 triệu 5 cafe', 1000000, '5 cafe', true),
      ('1tr2 cafe', 1200000, 'Cafe', false),
      ('cafe 1tr 25', 1250000, 'Cafe', false),
      ('cafe 1tr 200', 1200000, 'Cafe', false),
      ('cafe 1.5tr2', 1500000, 'Cafe 2', true),
      ('cafe 1,5tr 2', 1500000, 'Cafe 2', true),
      ('cafe 2tram5', 200000, 'Cafe 5', true),
      ('cafe 30k 2 ly', 30000, 'Cafe 2 ly', false),
    ]) {
      test('guards tail in ${fixture.$1}', () {
        final result = VoiceTransactionParser.parse(
          fixture.$1,
          clock: () => DateTime(2026, 10, 9),
        );
        expect(result.amountVnd, fixture.$2);
        expect(result.note, fixture.$3);
        expect(result.hasExtraAmounts, fixture.$4);
      });
    }
    for (final fixture in [
      ('1tr2', 1200000),
      ('1tr25', 1250000),
      ('1tr200', 1200000),
      ('1tr025', 1025000),
      ('1 triệu 5', 1500000),
      ('1 tỷ 2', 1200000000),
      ('1ty25', 1250000000),
      ('1ty200', 1200000000),
      ('1cu25', 1250000),
      ('1m200', 1200000),
    ]) {
      test('scales tail in ${fixture.$1}', () {
        final result = VoiceTransactionParser.parse(fixture.$1);
        expect(result.amountVnd, fixture.$2);
        expect(result.hasExtraAmounts, isFalse);
      });
    }
    for (final fixture in [
      ('cafe 1tr 200k', 1000000, 'Cafe'),
      ('1 triệu 500k', 1000000, '1 triệu 500k'),
      ('cafe 30k 50k', 30000, 'Cafe'),
      ('đổ xăng 2 lít 50k', 200000, 'Đổ xăng'),
      ('cafe 1ty 200k', 1000000000, 'Cafe'),
    ]) {
      test('keeps first spaced amount in ${fixture.$1}', () {
        final result = VoiceTransactionParser.parse(fixture.$1);
        expect(result.amountVnd, fixture.$2);
        expect(result.hasExtraAmounts, isTrue);
        expect(result.note, fixture.$3);
      });
    }
    for (final unit in ['trăm nghìn', 'trăm ngàn']) {
      test('consumes compound unit $unit', () {
        final result = VoiceTransactionParser.parse('cafe 2 $unit');
        expect(result.amountVnd, 200000);
        expect(result.note, 'Cafe');
        expect(result.hasExtraAmounts, isFalse);
      });
    }
    for (final text in [
      'cafe 30k năm 2026',
      'tiền nhà tháng 10/2026 5tr',
      'tiền nhà 10/2026 5tr',
    ]) {
      test('does not flag year context in $text', () {
        final result = VoiceTransactionParser.parse(text);
        expect(result.amountVnd, text.startsWith('cafe') ? 30000 : 5000000);
        expect(result.hasExtraAmounts, isFalse);
      });
    }
    test('retains ambiguous bare numbers as extra amounts', () {
      final result = VoiceTransactionParser.parse('phòng 1203 tiền điện 500k');
      expect(result.amountVnd, 500000);
      expect(result.hasExtraAmounts, isTrue);
    });
    test('preserves the accepted letter-comma-digit split', () {
      final results = VoiceTransactionParser.parseMany('mua 2tr,5 cafe 30k');
      expect(results.map((r) => r.amountVnd), [2000000, 30000]);
      expect(results.map((r) => r.note), ['Mua', '5 cafe']);
    });
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
