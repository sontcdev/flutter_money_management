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
  }) {
    final trimmed = text.trim();
    final normalized = _normalize(trimmed);

    final date = _extractDate(normalized);
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

  static DateTime? _extractDate(String normalized) {
    final now = DateTime.now();
    if (normalized.contains('hom kia')) {
      return DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 2));
    }
    if (normalized.contains('hom qua')) {
      return DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1));
    }
    if (normalized.contains('hom nay')) {
      return DateTime(now.year, now.month, now.day);
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Transaction type
  // ---------------------------------------------------------------------

  static TransactionType? _extractType(String normalized) {
    for (final keyword in _incomeKeywords) {
      if (normalized.contains(_normalize(keyword))) {
        return TransactionType.income;
      }
    }
    for (final keyword in _expenseKeywords) {
      if (normalized.contains(_normalize(keyword))) {
        return TransactionType.expense;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Amount
  // ---------------------------------------------------------------------

  // "1 trieu 5", "1tr5", "1.5tr", "1,5 trieu" -> 1_500_000
  static final RegExp _millionWithSub =
      RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:trieu|tr)\s*(\d{1,3})?');

  // "150k", "150 k", "150 nghin", "150 ngan" -> 150_000
  static final RegExp _thousand =
      RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:k|nghin|ngan)\b');

  // Số thuần với dấu chấm/phẩy phân cách nghìn: "150.000", "1.500.000"
  static final RegExp _plainGrouped = RegExp(r'\d{1,3}(?:[.,]\d{3})+');

  // Số thuần không có phân cách: "150000"
  static final RegExp _plainDigits = RegExp(r'\d+');

  static double? _extractAmount(String normalized) {
    final millionMatch = _millionWithSub.firstMatch(normalized);
    if (millionMatch != null) {
      final whole = double.tryParse(millionMatch.group(1)!.replaceAll(',', '.'));
      if (whole != null) {
        var amount = whole * 1000000;
        final sub = millionMatch.group(2);
        if (sub != null && sub.isNotEmpty) {
          // "1 trieu 5" => 1 trieu + 500 nghin (chu so le sau trieu la tram nghin)
          final subValue = int.tryParse(sub) ?? 0;
          amount += subValue * 100000;
        }
        return amount;
      }
    }

    final thousandMatch = _thousand.firstMatch(normalized);
    if (thousandMatch != null) {
      final value =
          double.tryParse(thousandMatch.group(1)!.replaceAll(',', '.'));
      if (value != null) {
        return value * 1000;
      }
    }

    final groupedMatch = _plainGrouped.firstMatch(normalized);
    if (groupedMatch != null) {
      final cleaned = groupedMatch.group(0)!.replaceAll(RegExp(r'[.,]'), '');
      final value = double.tryParse(cleaned);
      if (value != null) return value;
    }

    final digitsMatch = _plainDigits.firstMatch(normalized);
    if (digitsMatch != null) {
      final value = double.tryParse(digitsMatch.group(0)!);
      if (value != null) return value;
    }

    return null;
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
        .replaceAll(RegExp(r'[^\w\s.,]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
