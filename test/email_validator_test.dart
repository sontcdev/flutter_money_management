import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_money_management/src/utils/email_validator.dart';

void main() {
  test('accepts long top-level domains', () {
    expect(isValidEmail('a@b.photography'), isTrue);
  });

  test('accepts plus addressing and surrounding spaces', () {
    expect(isValidEmail(' first.last+tag@mail.example.com '), isTrue);
  });

  test('rejects addresses without a domain suffix', () {
    expect(isValidEmail('a@b'), isFalse);
  });

  test('rejects addresses without a local part', () {
    expect(isValidEmail('@example.com'), isFalse);
  });
}
