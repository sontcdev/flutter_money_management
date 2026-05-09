// filepath: lib/src/utils/currency_formatter.dart

import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Format số tiền theo định dạng Việt Nam
  /// Ví dụ: 1000000 -> 1.000.000 ₫
  static String formatVND(double amount, {String locale = 'vi_VN'}) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: '₫',
      decimalDigits: 0, // VND không có số thập phân
    );
    return formatter.format(amount);
  }

  /// Format số tiền từ cents
  /// Ví dụ: 100000000 cents -> 1.000.000 ₫
  static String formatVNDFromCents(int cents, {String locale = 'vi_VN'}) {
    return formatVND(cents / 100, locale: locale);
  }

  /// Format số tiền với currency code
  static String format(double amount, String currency, {String? locale}) {
    final normalizedCurrency = currency.toUpperCase();
    final resolvedLocale =
        locale ?? _defaultLocaleForCurrency(normalizedCurrency);

    switch (currency.toUpperCase()) {
      case 'VND':
        return formatVND(amount, locale: resolvedLocale);
      case 'USD':
        return NumberFormat.currency(
          locale: resolvedLocale,
          symbol: '\$',
          decimalDigits: 2,
        ).format(amount);
      case 'EUR':
        return NumberFormat.currency(
          locale: resolvedLocale,
          symbol: '€',
          decimalDigits: 2,
        ).format(amount);
      default:
        return NumberFormat.currency(
          locale: resolvedLocale,
          symbol: currency,
          decimalDigits: 2,
        ).format(amount);
    }
  }

  /// Format số tiền từ cents với currency code
  static String formatFromCents(int cents, String currency, {String? locale}) {
    return format(cents / 100, currency, locale: locale);
  }

  /// Parse input text thành số tiền (loại bỏ dấu phân cách)
  /// Ví dụ: "1.000.000" -> 1000000.0
  static double? parseVND(String text) {
    if (text.isEmpty) return null;

    // Loại bỏ tất cả dấu chấm (.) và ký hiệu ₫
    String cleaned = text.replaceAll('.', '').replaceAll('₫', '').trim();

    // Chuyển dấu phẩy thành dấu chấm nếu có (để xử lý số thập phân)
    cleaned = cleaned.replaceAll(',', '.');

    return double.tryParse(cleaned);
  }

  /// Convert số tiền thành cents
  static int toCents(double amount) {
    return (amount * 100).round();
  }

  /// Format số tiền khi user đang nhập (thêm dấu phân cách ngàn)
  /// Ví dụ: "1000000" -> "1.000.000"
  static String formatInputVND(String text) {
    if (text.isEmpty) return text;

    // Loại bỏ tất cả ký tự không phải số
    String cleaned = text.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.isEmpty) return '';

    // Parse thành số
    int? value = int.tryParse(cleaned);
    if (value == null) return text;

    // Format với dấu chấm phân cách ngàn
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(value).replaceAll(',', '.');
  }

  /// Get currency symbol
  static String getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'VND':
        return '₫';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return currency;
    }
  }

  static String _defaultLocaleForCurrency(String currency) {
    switch (currency) {
      case 'VND':
        return 'vi_VN';
      case 'USD':
        return 'en_US';
      case 'EUR':
        return 'de_DE';
      default:
        return 'en_US';
    }
  }
}
