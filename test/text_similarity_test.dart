import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_money_management/src/utils/text_similarity.dart';

void main() {
  test('normalizes Vietnamese and preserves multilingual words', () {
    expect(normalizeVi('  CÀ PHÊ  ĐỒNG '), 'ca phe dong');
    expect(normalizeVi('ca\u0300 phe\u0302'), 'ca phe');
    expect(normalizeVi('ランチ lunch'), 'ランチ lunch');
  });

  test('ratio handles empty, exact, insertion and substitution', () {
    expect(levenshteinRatio('', ''), 1);
    expect(levenshteinRatio('', 'momo'), 0);
    expect(levenshteinRatio('momo', 'momoo'), closeTo(0.8, 0.001));
    expect(levenshteinRatio('momo', 'momo'), 1);
    expect(levenshteinRatio('cash', 'bank'), lessThan(0.8));
  });

  test('best match uses multi-token phrases and rejects weak matches', () {
    expect(bestTextMatch('vi tiet kiem 50k', ['Ví tiết kiệm'], (s) => s)?.value,
        'Ví tiết kiệm');
    expect(bestTextMatch('unrelated', ['MoMo'], (s) => s), isNull);
    expect(bestTextMatch('momoo momo', ['MoMo'], (s) => s)?.score, 1);
  });
}
