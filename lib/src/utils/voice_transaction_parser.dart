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
    this.hasExtraAmounts = false,
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
  final bool hasExtraAmounts;
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
    'bán',
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
    final segments = _splitSegments(text);
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

  static List<String> _splitSegments(String text) {
    final separators = _segmentSeparator.allMatches(text).toList();
    final segments = <String>[];
    var start = 0;
    for (var index = 0; index < separators.length; index++) {
      final separator = separators[index];
      final segment = text.substring(start, separator.start).trim();
      final nextEnd = index + 1 < separators.length
          ? separators[index + 1].start
          : text.length;
      final nextChunk = text.substring(separator.end, nextEnd).trim();
      if (_extractAmount(_normalize(segment), _hasForeignCurrency(segment)) !=
              null &&
          _extractAmount(
                  _normalize(nextChunk), _hasForeignCurrency(nextChunk)) !=
              null) {
        segments.add(segment);
        start = separator.end;
      }
    }
    segments.add(text.substring(start).trim());
    return segments.length > 1 ? segments : [text.trim()];
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
    final type = _extractType(trimmed);
    final foreignCurrency = _hasForeignCurrency(trimmed);
    final amount = _extractAmount(normalized, foreignCurrency);

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
      note: trimmed.isEmpty
          ? null
          : _cleanNote(trimmed, wallet, now, foreignCurrency),
      walletId: wallet?.id,
      walletName: wallet?.name,
      categoryConfidence: learned?.confidence,
      hasExtraAmounts: _hasExtraAmounts(normalized, foreignCurrency),
    );
  }

  static String _cleanNote(
      String raw, Wallet? wallet, DateTime now, bool foreignCurrency) {
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
      remove(_spokenDate);
      remove(_calendarDate);
      remove(_dayOfMonth);
      remove(_weekday);
      remove(_relativeCount);
      remove(RegExp(
          r'\b(?:hom\s+(?:kia|qua|truoc|nay)|ngay\s+mai|(?:sang|trua|toi)\s+nay|(?:tuan|thang)\s+truoc|(?:dau|cuoi)\s+thang)\b'));
    }
    remove(_yearContext);
    remove(_monthYear);
    remove(RegExp(r'\bv\.?\s?v\.?[,.;:-]*|\betc\.?[,.;:-]*'));
    if (foreignCurrency) {
      return raw;
    }
    remaining = remaining.replaceAllMapped(
        RegExp(r'\bthang\s+\d{1,2}\b'),
        (match) => ' ' * (match.end - match.start));
    if (_amountWithUnit.hasMatch(remaining)) {
      remove(_amountWithUnit);
    } else {
      remove(_currencyPattern(remaining), firstOnly: true);
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
        .replaceAllMapped(RegExp(r'\s+([,;.、，。])'), (match) => match[1]!)
        .replaceAll(RegExp(r'^[\s,;.:+\-、，。]+|[\s,;.:+\-、，。]+$'), '')
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
    r'(?<!\d)(?<!\d[.,])([0-3]?\d)[/\-]([01]?\d)(?:[/\-](\d{4}))?(?!\d|[.,]\d)',
  );
  static final RegExp _spokenDate = RegExp(
    r'\bngay\s+(\d{1,2})\s+thang\s+(\d{1,2})(?:\s+nam\s+(\d{4}))?\b',
  );
  static final RegExp _relativeCount = RegExp(
    r'\b([1-9]|[1-8]\d|90)\s+ngay\s+truoc\b|\b([1-9]|1[0-2])\s+tuan\s+truoc\b',
  );
  static final RegExp _dayOfMonth = RegExp(r'\bngay\s+(\d{1,2})\b');
  static final RegExp _weekday = RegExp(
    r'\b(?:thu\s+([2-7]|hai|ba|tu|nam|sau|bay)|chu nhat|cn)\b(?:\s+tuan\s+(nay|truoc))?',
  );

  static final RegExp _segmentSeparator = RegExp(
    r'[,，、](?!\d)|(?<=\p{L})[,，、](?=\d)',
    unicode: true,
  );

  static DateTime? _validDate(int year, int month, int day) {
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  static DateTime? _extractDate(String normalized, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final calendar = _spokenDate.firstMatch(normalized) ??
        _calendarDate.firstMatch(normalized);
    if (calendar != null) {
      final year = int.parse(calendar.group(3) ?? '${now.year}');
      final month = int.parse(calendar.group(2)!);
      final day = int.parse(calendar.group(1)!);
      final date = _validDate(year, month, day);
      return calendar.group(3) == null && date != null && date.isAfter(today)
          ? _validDate(year - 1, month, day)
          : date;
    }
    final day = _dayOfMonth.firstMatch(normalized);
    if (day != null) {
      final value = int.parse(day.group(1)!);
      if (value < 1 || value > 31) return null;
      for (var offset = 0; offset < 12; offset++) {
        final month = DateTime(now.year, now.month - offset);
        final date = _validDate(month.year, month.month, value);
        if (date != null && !date.isAfter(today)) return date;
      }
    }
    final weekday = _weekday.firstMatch(normalized);
    if (weekday != null) {
      const names = {'hai': 2, 'ba': 3, 'tu': 4, 'nam': 5, 'sau': 6, 'bay': 7};
      final token = weekday.group(1);
      final target =
          token == null ? 7 : (int.tryParse(token) ?? names[token]!) - 1;
      final offset = weekday.group(2) == 'truoc' ? 7 : 0;
      final date = DateTime(
          now.year, now.month, now.day + target - now.weekday - offset);
      return weekday.group(2) == null && date.isAfter(today)
          ? DateTime(date.year, date.month, date.day - 7)
          : date;
    }
    final count = _relativeCount.firstMatch(normalized);
    if (count != null) {
      final days = count.group(1) != null
          ? int.parse(count.group(1)!)
          : 7 * int.parse(count.group(2)!);
      return DateTime(today.year, today.month, today.day - days);
    }
    if (_containsPhrase(normalized, 'thang truoc')) {
      final lastDay = DateTime(now.year, now.month, 0);
      return DateTime(lastDay.year, lastDay.month,
          now.day > lastDay.day ? lastDay.day : now.day);
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
      final date = DateTime(now.year, now.month + 1, 0);
      return date.isAfter(today) ? DateTime(now.year, now.month, 0) : date;
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

  static TransactionType? _extractType(String raw) {
    final normalized = raw.toLowerCase().runes.map((rune) {
      final char = String.fromCharCode(rune);
      final token = _normalize(char);
      return token.padRight(char.length);
    }).join();
    final unaccented = _isUnaccented(raw);
    var text = raw.toLowerCase();
    final spans = [
      ..._amountWithUnit.allMatches(normalized),
      ..._currencyPattern(normalized).allMatches(normalized),
    ];
    for (final span in spans) {
      text = text.replaceRange(
          span.start, span.end, ' ' * (span.end - span.start));
    }
    if (unaccented) text = _normalize(text);
    final debt = unaccented ? 'tra no' : 'trả nợ';
    text = text.replaceAll(
        RegExp('(?<![\\p{L}0-9])$debt(?![\\p{L}0-9])', unicode: true), ' ');
    bool matches(String keyword) {
      if (unaccented && keyword == 'bán') {
        return false;
      }
      final phrase = RegExp.escape(unaccented ? _normalize(keyword) : keyword)
          .replaceAll(' ', r'\s+');
      return RegExp('(?<![\\p{L}0-9])$phrase(?![\\p{L}0-9])', unicode: true)
          .hasMatch(text);
    }

    for (final keyword in _incomeKeywords) {
      if (matches(keyword)) return TransactionType.income;
    }
    for (final keyword in _expenseKeywords) {
      if (matches(keyword)) return TransactionType.expense;
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
    r'(?<!\d)(?<!\d[.,])([0-9]+(?:[.,][0-9]+)?)\s*(trieu|tr|cu|ty|lit|tram\s+(?:nghin|ngan)|tram|m|nghin|ngan|k)(?![a-z])(?:(?<=(?<![\d.,])\d+\s*(?:trieu|tr|cu|ty|(?<![a-z])m))(?:(\d{1,3})(?![\d.,/\-])(?!\s*(?:trieu|tr|cu|ty|lit|tram|m|nghin|ngan|k)(?![a-z]))|\s+(\d{1,3})(?=\s*$)))?(\s*ruoi\b)?',
  );
  static final RegExp _yearContext = RegExp(
    r'\b(?:nam|thang\s+\d{1,2}[/\-])\s*(?:19|20)\d{2}\b',
  );
  static final RegExp _monthYear = RegExp(r'\b\d{1,2}[/\-](?:19|20)\d{2}\b');
  static final RegExp _currencyAmount = RegExp(
    r'(?<!\d)(?<!\d[.,])(\d{1,3}(?: \d{3})+(?!\s*(?:trieu|tr|cu|ty|lit|tram|m|nghin|ngan|k)\b)|\d+(?:[.,]\d+)*)(?:\s*(?:vnd|dong|d))?(?![a-z0-9])',
  );

  static final RegExp _foreignCurrency = RegExp(
    r'\$\s*\d|\d\s*(?:đô|đô|usd|\$)(?![\p{L}\p{M}0-9])',
    unicode: true,
  );
  static final RegExp _unaccentedForeignCurrency =
      RegExp(r'\d\s*do(?![a-z0-9])');
  static final RegExp _letterOrMark = RegExp(r'[\p{L}\p{M}]', unicode: true);

  static bool _isUnaccented(String raw) => !raw.runes.any((rune) {
        final char = String.fromCharCode(rune).toLowerCase();
        return _letterOrMark.hasMatch(char) && _normalize(char) != char;
      });

  static bool _hasForeignCurrency(String raw) {
    final text = raw.toLowerCase();
    return _foreignCurrency.hasMatch(text) ||
        (_isUnaccented(text) &&
            _unaccentedForeignCurrency.hasMatch(text) &&
            !_amountWithUnit.hasMatch(_normalize(text)));
  }

  static final RegExp _bareCurrencyAmount = RegExp(
    r'(?<!\d)(?<!\d[.,])(\d+(?:[.,]\d+)*)(?:\s*(?:vnd|dong|d))?(?![a-z0-9])',
  );

  static RegExp _currencyPattern(String text) =>
      RegExp(r'\bphong\s+\d').hasMatch(text)
          ? _bareCurrencyAmount
          : _currencyAmount;

  static String _withoutDates(String text) => text
      .replaceAll(_spokenDate, ' ')
      .replaceAll(_calendarDate, ' ')
      .replaceAll(_dayOfMonth, ' ')
      .replaceAll(_weekday, ' ')
      .replaceAll(_relativeCount, ' ')
      .replaceAll(_yearContext, ' ')
      .replaceAll(_monthYear, ' ')
      .replaceAll(RegExp(r'\bthang\s+\d{1,2}\b'), ' ');

  static bool _hasExtraAmounts(String normalized, bool foreignCurrency) {
    if (foreignCurrency) return false;
    final text = _withoutDates(normalized);
    final units = _amountWithUnit.allMatches(text).toList();
    final remaining = text.replaceAllMapped(
        _amountWithUnit, (match) => ' ' * (match.end - match.start));
    final currencyCount = _currencyPattern(text)
        .allMatches(remaining)
        .where((match) =>
            (_extractAmount(match.group(0)!, false) ?? 0) >= 1000 ||
            units.isEmpty ||
            units.any((unit) =>
                ['trieu', 'tr', 'cu', 'ty', 'tram', 'm']
                    .contains(unit.group(2)) &&
                unit.end <= match.start &&
                text.substring(unit.end, match.start).trim().isEmpty))
        .length;
    return units.length + currencyCount >= 2;
  }

  static double? _extractAmount(String normalized, bool foreignCurrency) {
    if (foreignCurrency) return null;
    final text = _withoutDates(normalized);
    final unit = _amountWithUnit.firstMatch(text);
    if (unit != null) {
      final whole = double.parse(unit.group(1)!.replaceAll(',', '.'));
      final suffix =
          unit.group(2)!.startsWith('tram') ? 'tram' : unit.group(2)!;
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
      if (['trieu', 'tr', 'cu', 'm', 'ty'].contains(suffix)) {
        final sub = unit.group(3) ?? unit.group(4);
        if (sub != null) {
          // "1 trieu 5" => 1 trieu + 500 nghin (chu so le sau trieu la tram nghin)
          amount += double.parse('0.$sub') * multipliers[suffix]!;
        }
      }
      if (unit.group(5) != null &&
          unit.group(3) == null &&
          unit.group(4) == null) {
        amount += 0.5 * multipliers[suffix]!;
      }
      return amount > 0 ? amount : null;
    }
    final currency = _currencyPattern(text).firstMatch(text);
    if (currency == null) return null;
    final digits = currency.group(1)!;
    final grouped = RegExp(r'^\d{1,3}(?:[., ]\d{3})+$').hasMatch(digits);
    final amount = double.tryParse(
      grouped
          ? digits.replaceAll(RegExp(r'[., ]'), '')
          : digits.replaceAll(',', '.'),
    );
    return amount != null && amount > 0 ? amount : null;
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
