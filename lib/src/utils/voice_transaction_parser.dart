// path: lib/src/utils/voice_transaction_parser.dart

import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';

/// Kết quả parse một câu nói tiếng Việt thành các trường của giao dịch.
/// Mọi trường đều có thể null nếu không nhận diện được — màn hình luôn để
/// người dùng xem lại/chỉnh sửa trước khi lưu, không tự động submit.
class VoiceParseResult {
  const VoiceParseResult({
    required this.rawText,
    this.amountVnd,
    this.date,
    this.type,
    this.categoryId,
    this.categoryName,
    this.note,
  });

  final String rawText;
  final double? amountVnd;
  final DateTime? date;
  final TransactionType? type;
  final String? categoryId;
  final String? categoryName;
  final String? note;
}

/// Parser rule-based cho câu nói tiếng Việt kiểu:
/// "hôm nay đi chợ hết 150k", "hôm qua nhận lương 5 triệu 2".
///
/// Không gọi API ngoài — chạy on-device, miễn phí. Độ chính xác phụ thuộc
/// vào các từ khóa/định dạng số tiền được liệt kê bên dưới; câu nói quá
/// khác biệt có thể không nhận diện được hết, người dùng luôn có thể sửa
/// tay các trường trước khi lưu.
class VoiceTransactionParser {
  const VoiceTransactionParser._();

  static const List<String> _incomeKeywords = [
    'nhận lương',
    'lương',
    'thu nhập',
    'thưởng',
    'được thưởng',
    'bán được',
    'thu về',
    'kiếm được',
    'nhận được',
    'hoàn tiền',
    'được cho',
    'lãi',
    'cổ tức',
    'nhận chuyển khoản',
    'trả lại cho tôi',
  ];

  static const List<String> _expenseKeywords = [
    'mua',
    'chi',
    'trả',
    'hết',
    'tiêu',
    'đóng',
    'nạp',
    'thanh toán',
    'đi chợ',
    'ăn',
    'đổ xăng',
    'ship',
    'phí',
  ];

  /// Parse [text] (kết quả từ speech-to-text) thành các trường giao dịch.
  ///
  /// [categories] là danh sách category của workspace hiện tại (chưa lọc
  /// theo loại thu/chi) — categories là do người dùng tự tạo nên việc
  /// khớp category dựa trên so khớp tên (không dấu, không phân biệt hoa
  /// thường) thay vì danh sách cố định.
  static VoiceParseResult parse(
    String text, {
    List<Category> categories = const [],
    DateTime Function()? clock,
  }) {
    final trimmed = text.trim();
    final normalized = _normalize(trimmed);

    final date = _extractDate(normalized, (clock ?? DateTime.now)());
    final type = _extractType(normalized);
    final amount = _extractAmount(normalized);

    final relevantCategories = type == null
        ? categories
        : categories
            .where((c) => c.type == _categoryTypeFor(type))
            .toList();
    final category = _matchCategory(normalized, relevantCategories);

    return VoiceParseResult(
      rawText: trimmed,
      amountVnd: amount,
      date: date,
      type: type,
      categoryId: category?.id,
      categoryName: category?.name,
      note: trimmed.isEmpty ? null : trimmed,
    );
  }

  static CategoryType _categoryTypeFor(TransactionType type) {
    return type == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
  }

  // ---------------------------------------------------------------------
  // Date
  // ---------------------------------------------------------------------

  static final RegExp _calendarDate = RegExp(
    r'(?<![\d.,])([0-3]?\d)[/\-]([01]?\d)(?:[/\-](\d{4}))?(?![\d.,])',
  );
  static final RegExp _dayOfMonth = RegExp(r'\bngay\s+(\d{1,2})\b');
  static final RegExp _weekday = RegExp(
    r'\b(?:thu\s+([2-7]|hai|ba|tu|nam|sau|bay)|chu nhat|cn)\b(?:\s+tuan\s+(nay|truoc))?',
  );

  static DateTime? _validDate(int year, int month, int day) {
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  static DateTime? _extractDate(String normalized, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final calendar = _calendarDate.firstMatch(normalized);
    if (calendar != null) {
      return _validDate(
        int.parse(calendar.group(3) ?? '${now.year}'),
        int.parse(calendar.group(2)!),
        int.parse(calendar.group(1)!),
      );
    }
    final day = _dayOfMonth.firstMatch(normalized);
    if (day != null) {
      return _validDate(now.year, now.month, int.parse(day.group(1)!));
    }
    final weekday = _weekday.firstMatch(normalized);
    if (weekday != null) {
      const names = {'hai': 2, 'ba': 3, 'tu': 4, 'nam': 5, 'sau': 6, 'bay': 7};
      final token = weekday.group(1);
      final target =
          token == null ? 7 : (int.tryParse(token) ?? names[token]!) - 1;
      final offset = weekday.group(2) == 'truoc' ? 7 : 0;
      return DateTime(
          now.year, now.month, now.day + target - now.weekday - offset);
    }
    const relative = {
      'hom kia': -2,
      'hom qua': -1,
      'hom truoc': -1,
      'ngay mai': 1,
      'hom nay': 0,
      'sang nay': 0,
      'trua nay': 0,
      'toi nay': 0,
      'tuan truoc': -7,
    };
    for (final entry in relative.entries) {
      if (_containsPhrase(normalized, entry.key)) {
        return DateTime(today.year, today.month, today.day + entry.value);
      }
    }
    if (_containsPhrase(normalized, 'dau thang')) {
      return DateTime(now.year, now.month);
    }
    if (_containsPhrase(normalized, 'cuoi thang')) {
      return DateTime(now.year, now.month + 1, 0);
    }
    return null;
  }

  static bool _containsPhrase(String text, String phrase) {
    return RegExp('(?<![a-z0-9])${RegExp.escape(phrase)}(?![a-z0-9])')
        .hasMatch(text);
  }

  // ---------------------------------------------------------------------
  // Transaction type
  // ---------------------------------------------------------------------

  static TransactionType? _extractType(String normalized) {
    for (final keyword in _incomeKeywords) {
      if (_containsPhrase(normalized, _normalize(keyword))) {
        return TransactionType.income;
      }
    }
    for (final keyword in _expenseKeywords) {
      if (_containsPhrase(normalized, _normalize(keyword))) {
        return TransactionType.expense;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Amount
  // ---------------------------------------------------------------------

  // "1 trieu 5", "1tr5", "1.5tr", "1,5 trieu" -> 1_500_000
  // "150k", "150 k", "150 nghin", "150 ngan" -> 150_000
  // Số thuần với dấu chấm/phẩy phân cách nghìn: "150.000", "1.500.000"
  // Số thuần không có phân cách: "150000"
  static final RegExp _amountWithUnit = RegExp(
    r'(?<![\d.,])([0-9]+(?:[.,][0-9]+)?)\s*(trieu|tr|cu|ty|lit|tram|m|nghin|ngan|k)(?![a-z])(?:\s*(\d{1,3})(?![\d.,/\-]))?',
  );
  static final RegExp _currencyAmount = RegExp(
    r'(?<![\d.,])(?:\$\s*)?(\d+(?:[.,]\d+)*)(?:\s*(?:vnd|dong|d|\$))?(?![a-z0-9])',
  );

  static double? _extractAmount(String normalized) {
    final text = normalized
        .replaceAll(_calendarDate, ' ')
        .replaceAll(_dayOfMonth, ' ')
        .replaceAll(_weekday, ' ');
    final unit = _amountWithUnit.firstMatch(text);
    if (unit != null) {
      final whole = double.parse(unit.group(1)!.replaceAll(',', '.'));
      final suffix = unit.group(2)!;
      const multipliers = {
        'trieu': 1000000,
        'tr': 1000000,
        'cu': 1000000,
        'm': 1000000,
        'ty': 1000000000,
        'lit': 100000,
        'tram': 100000,
        'nghin': 1000,
        'ngan': 1000,
        'k': 1000,
      };
      var amount = whole * multipliers[suffix]!;
      if (['trieu', 'tr', 'cu', 'm'].contains(suffix)) {
        final sub = unit.group(3);
        if (sub != null) {
          // "1 trieu 5" => 1 trieu + 500 nghin (chu so le sau trieu la tram nghin)
          amount += int.parse(sub) * 100000;
        }
      }
      return amount;
    }
    final currency = _currencyAmount.firstMatch(text);
    if (currency == null) return null;
    final digits = currency.group(1)!;
    final grouped = RegExp(r'^\d{1,3}(?:[.,]\d{3})+$').hasMatch(digits);
    return double.tryParse(
      grouped
          ? digits.replaceAll(RegExp(r'[.,]'), '')
          : digits.replaceAll(',', '.'),
    );
  }

  // ---------------------------------------------------------------------
  // Category matching
  // ---------------------------------------------------------------------

  // Cụm từ hoạt động thường gặp -> các từ khoá hay xuất hiện trong tên
  // category tương ứng (vd "Ăn uống", "Di chuyển"). Category do người dùng
  // tự đặt tên nên chỉ so khớp token thuần không đủ nhận ra "đi chợ" thuộc
  // nhóm "Ăn uống" — bảng này mở rộng câu nói bằng các từ khoá liên quan
  // trước khi so khớp, giữ parser ở mức rule-based đơn giản.
  static const Map<String, List<String>> _categorySynonyms = {
    'di cho': ['an', 'uong', 'thuc', 'pham', 'cho'],
    'an sang': ['an', 'uong'],
    'an trua': ['an', 'uong'],
    'an toi': ['an', 'uong'],
    'ca phe': ['an', 'uong'],
    'nha hang': ['an', 'uong'],
    'quan an': ['an', 'uong'],
    'sieu thi': ['an', 'uong', 'thuc', 'pham'],
    'xang': ['di', 'chuyen', 'xe'],
    'grab': ['di', 'chuyen'],
    'taxi': ['di', 'chuyen'],
    'xe bus': ['di', 'chuyen'],
    've xe': ['di', 'chuyen'],
    'tien dien': ['dien', 'nuoc', 'nha'],
    'tien nuoc': ['dien', 'nuoc', 'nha'],
    'thue nha': ['nha', 'thue'],
    'luong': ['luong', 'thu', 'nhap'],
    'thuong': ['thuong', 'thu', 'nhap'],
  };

  /// Chọn category có số từ trùng khớp với câu nói nhiều nhất. Trả về
  /// null nếu không category nào có ít nhất một từ trùng khớp.
  static Category? _matchCategory(
    String normalizedText,
    List<Category> categories,
  ) {
    final textTokens = normalizedText.split(_tokenSplitter).toSet()
      ..removeWhere((t) => t.isEmpty);

    for (final entry in _categorySynonyms.entries) {
      if (normalizedText.contains(entry.key)) {
        textTokens.addAll(entry.value);
      }
    }

    Category? best;
    var bestScore = 0;

    for (final category in categories) {
      final nameTokens = _normalize(category.name)
          .split(_tokenSplitter)
          .where((t) => t.isNotEmpty);
      var score = 0;
      for (final token in nameTokens) {
        if (textTokens.contains(token)) {
          score++;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        best = category;
      }
    }

    return bestScore > 0 ? best : null;
  }

  static final RegExp _tokenSplitter = RegExp(r'\s+');

  // ---------------------------------------------------------------------
  // Normalization
  // ---------------------------------------------------------------------

  static const Map<String, String> _diacriticsMap = {
    'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
    'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
    'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
    'đ': 'd',
    'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
    'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
    'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
    'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
    'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
    'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
    'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
    'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
    'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
  };

  /// Chuyển về chữ thường, bỏ dấu tiếng Việt, chuẩn hoá khoảng trắng —
  /// dùng để so khớp từ khóa/category, không dùng để hiển thị.
  static String _normalize(String input) {
    final lower = input.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_diacriticsMap[char] ?? char);
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r'[^\w\s.,/\-$]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
