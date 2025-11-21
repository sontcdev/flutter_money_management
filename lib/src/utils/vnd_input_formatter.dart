// filepath: lib/src/utils/vnd_input_formatter.dart

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// TextInputFormatter cho tiền VND với dấu phân cách ngàn
/// Tự động thêm dấu chấm (.) khi user nhập số
class VNDInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Loại bỏ tất cả ký tự không phải số
    String cleaned = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Parse thành số
    int? value = int.tryParse(cleaned);
    if (value == null) {
      return oldValue;
    }

    // Format với dấu chấm phân cách ngàn
    final formatter = NumberFormat('#,###', 'vi_VN');
    String formatted = formatter.format(value).replaceAll(',', '.');

    // Tính toán vị trí cursor mới
    int cursorPosition = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

