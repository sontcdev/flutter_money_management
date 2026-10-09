// path: lib/src/utils/voice_transaction_parser.dart

import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/features/transactions/services/category_suggestion_service.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/utils/text_similarity.dart';

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
    this.walletId,
    this.walletName,
    this.categoryConfidence,
  });

  final String rawText;
  final double? amountVnd;
  final DateTime? date;
  final TransactionType? type;
  final String? categoryId;
  final String? categoryName;
  final String? note;
  final String? walletId;
  final String? walletName;
  final double? categoryConfidence;
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
    List<Wallet> wallets = const [],
    CategoryClassifier? classifier,
  }) {
    return parseMany(text,
            categories: categories,
            clock: clock,
            wallets: wallets,
            classifier: classifier)
        .first;
  }

  static List<VoiceParseResult> parseMany(
    String text, {
    List<Category> categories = const [],
    DateTime Function()? clock,
    List<Wallet> wallets = const [],
    CategoryClassifier? classifier,
  }) {
    final now = (clock ?? DateTime.now)();
    final parts = text
        .split(RegExp(
          r'(?<!\p{L})(?:và|va|rồi|roi|xong)(?!\p{L})|,(?!\d)|[;+\n]',
          unicode: true,
          caseSensitive: false,
        ))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    final segments = parts.length > 1 &&
            parts.every((part) => _extractAmount(_normalize(part)) != null)
        ? parts
        : [text.trim()];
    final dates = segments
        .map((part) => _extractDate(_normalize(part), now))
        .whereType<DateTime>()
        .toSet();
    final explicitWallets = segments
        .map((part) => _matchWallet(_normalize(part), wallets))
        .whereType<Wallet>()
        .toList();
    final walletIds = explicitWallets.map((wallet) => wallet.id).toSet();
    return segments
        .map((part) => _parseSingle(part,
            categories: categories,
            now: now,
            wallets: wallets,
            classifier: classifier,
            sharedDate: dates.length == 1 ? dates.single : null,
            sharedWallet: walletIds.length == 1 ? explicitWallets.first : null))
        .toList();
  }

  static VoiceParseResult _parseSingle(
    String text, {
    required List<Category> categories,
    required DateTime now,
    required List<Wallet> wallets,
    CategoryClassifier? classifier,
    DateTime? sharedDate,
    Wallet? sharedWallet,
  }) {
    final trimmed = text.trim();
    final normalized = _normalize(trimmed);

    final date = _extractDate(normalized, now) ?? sharedDate;
    final type = _extractType(normalized);
    final amount = _extractAmount(normalized);

    final relevantCategories = categories
        .where((category) =>
            category.deletedAt == null &&
            (type == null || category.type == _categoryTypeFor(type)))
        .toList();
    final explicitCategory = _matchCategory(normalized, relevantCategories);
    final learned = explicitCategory == null
        ? classifier?.predict(normalized,
            type: type == null ? null : _categoryTypeFor(type),
            categoryIds: relevantCategories.map((c) => c.id).toSet())
        : null;
    final category = explicitCategory ??
        relevantCategories
            .where((c) => c.id == learned?.categoryId)
            .firstOrNull;
    final availableWallets =
        wallets.where((w) => !w.isArchived && w.deletedAt == null).toList();
    final learnedWalletId = category == null
        ? null
        : classifier?.suggestWallet(normalized, category.id,
            walletIds: availableWallets.map((w) => w.id).toSet());
    final wallet = _matchWallet(normalized, availableWallets) ??
        sharedWallet ??
        availableWallets.where((w) => w.id == learnedWalletId).firstOrNull;

    return VoiceParseResult(
      rawText: trimmed,
      amountVnd: amount,
      date: date,
      type: type,
      categoryId: category?.id,
      categoryName: category?.name,
      note: trimmed.isEmpty ? null : _cleanNote(trimmed, wallet, now),
      walletId: wallet?.id,
      walletName: wallet?.name,
      categoryConfidence: learned?.confidence,
    );
  }

  static String _cleanNote(String raw, Wallet? wallet, DateTime now) {
    final normalized = StringBuffer();
    final starts = <int>[];
    final ends = <int>[];
    var offset = 0;
    for (final rune in raw.runes) {
      final char = String.fromCharCode(rune);
      final token = normalizeVi(char);
      final mapped =
          token.isEmpty && !(rune >= 0x0300 && rune <= 0x036f) ? ' ' : token;
      normalized.write(mapped);
      for (var i = 0; i < mapped.length; i++) {
        starts.add(offset);
        ends.add(offset + char.length);
      }
      offset += char.length;
      if (mapped.isEmpty && ends.isNotEmpty) ends[ends.length - 1] = offset;
    }
    final text = normalized.toString();
    final removed = List.filled(raw.length, false);
    var remaining = text;
    void remove(RegExp pattern, {bool firstOnly = false}) {
      final matches = pattern.allMatches(remaining).toList();
      for (final match in firstOnly ? matches.take(1) : matches) {
        if (match.start == match.end) continue;
        for (var i = starts[match.start]; i < ends[match.end - 1]; i++) {
          removed[i] = true;
        }
        remaining = remaining.replaceRange(
            match.start, match.end, ' ' * (match.end - match.start));
      }
    }

    if (_extractDate(_normalize(raw), now) != null) {
      remove(_calendarDate);
      remove(_dayOfMonth);
      remove(_weekday);
      remove(RegExp(
          r'\b(?:hom\s+(?:kia|qua|truoc|nay)|ngay\s+mai|(?:sang|trua|toi)\s+nay|tuan\s+truoc|(?:dau|cuoi)\s+thang)\b'));
    }
    if (_amountWithUnit.hasMatch(remaining)) {
      remove(_amountWithUnit, firstOnly: true);
    } else {
      remove(_currencyAmount, firstOnly: true);
    }
    if (wallet != null) {
      final named = bestTextMatch(text, [wallet], (w) => w.name);
      if (named != null) {
        final phrase = RegExp.escape(named.phrase).replaceAll(' ', r'\s+');
        remove(RegExp('(?<![a-z0-9])(?:vi\\s+)?$phrase(?![a-z0-9])'));
      } else {
        final aliases = wallet.walletType == WalletType.bank
            ? r'ck|chuyen\s+khoan'
            : wallet.walletType == WalletType.cash
                ? r'tien\s+mat|cash'
                : null;
        if (aliases != null) {
          remove(RegExp('\\b(?:vi\\s+)?(?:$aliases)\\b'));
        }
      }
    }
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      buffer.write(removed[i] ? ' ' : raw[i]);
    }
    final cleaned = buffer
        .toString()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\s,;+\-]+|[\s,;+\-]+$'), '')
        .trim();
    if (cleaned.isEmpty) return raw;
    final first = String.fromCharCode(cleaned.runes.first);
    return first.toUpperCase() + cleaned.substring(first.length);
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
    'ca fe': ['an', 'uong'],
    'cafe': ['an', 'uong'],
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
    final explicit = bestTextMatch(normalizedText, categories, (c) => c.name);
    if (explicit != null) return explicit.value;
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
        if (textTokens.any((textToken) =>
            textToken == token ||
            (token.length >= 4 && levenshteinRatio(textToken, token) >= 0.8))) {
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

  static Wallet? _matchWallet(String text, List<Wallet> wallets) {
    final available =
        wallets.where((w) => !w.isArchived && w.deletedAt == null).toList();
    final named = bestTextMatch(text, available, (w) => w.name);
    if (named != null) return named.value;
    WalletType? type;
    if (['ck', 'chuyen khoan'].any((phrase) => _containsPhrase(text, phrase))) {
      type = WalletType.bank;
    } else if (['tien mat', 'cash']
        .any((phrase) => _containsPhrase(text, phrase))) {
      type = WalletType.cash;
    }
    if (type == null) return null;
    final candidates = available.where((w) => w.walletType == type).toList();
    if (candidates.length == 1) return candidates.single;
    final defaults = candidates.where((w) => w.isDefault).toList();
    return defaults.length == 1 ? defaults.single : null;
  }

  static final RegExp _tokenSplitter = RegExp(r'\s+');

  // ---------------------------------------------------------------------
  // Normalization
  // ---------------------------------------------------------------------

  /// Chuyển về chữ thường, bỏ dấu tiếng Việt, chuẩn hoá khoảng trắng —
  /// dùng để so khớp từ khóa/category, không dùng để hiển thị.
  static String _normalize(String input) => normalizeVi(input);
}
