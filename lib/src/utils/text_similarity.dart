const Map<String, String> _diacriticsMap = {
  'à': 'a',
  'á': 'a',
  'ả': 'a',
  'ã': 'a',
  'ạ': 'a',
  'ă': 'a',
  'ằ': 'a',
  'ắ': 'a',
  'ẳ': 'a',
  'ẵ': 'a',
  'ặ': 'a',
  'â': 'a',
  'ầ': 'a',
  'ấ': 'a',
  'ẩ': 'a',
  'ẫ': 'a',
  'ậ': 'a',
  'đ': 'd',
  'è': 'e',
  'é': 'e',
  'ẻ': 'e',
  'ẽ': 'e',
  'ẹ': 'e',
  'ê': 'e',
  'ề': 'e',
  'ế': 'e',
  'ể': 'e',
  'ễ': 'e',
  'ệ': 'e',
  'ì': 'i',
  'í': 'i',
  'ỉ': 'i',
  'ĩ': 'i',
  'ị': 'i',
  'ò': 'o',
  'ó': 'o',
  'ỏ': 'o',
  'õ': 'o',
  'ọ': 'o',
  'ô': 'o',
  'ồ': 'o',
  'ố': 'o',
  'ổ': 'o',
  'ỗ': 'o',
  'ộ': 'o',
  'ơ': 'o',
  'ờ': 'o',
  'ớ': 'o',
  'ở': 'o',
  'ỡ': 'o',
  'ợ': 'o',
  'ù': 'u',
  'ú': 'u',
  'ủ': 'u',
  'ũ': 'u',
  'ụ': 'u',
  'ư': 'u',
  'ừ': 'u',
  'ứ': 'u',
  'ử': 'u',
  'ữ': 'u',
  'ự': 'u',
  'ỳ': 'y',
  'ý': 'y',
  'ỷ': 'y',
  'ỹ': 'y',
  'ỵ': 'y',
};

String normalizeVi(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    if (rune >= 0x0300 && rune <= 0x036f) continue;
    buffer.write(_diacriticsMap[char] ?? char);
  }
  return buffer
      .toString()
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s.,/\-$+;]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

double levenshteinRatio(String left, String right) {
  if (left == right) return 1;
  if (left.isEmpty || right.isEmpty) return 0;
  var previous = List.generate(right.length + 1, (index) => index);
  for (var i = 1; i <= left.length; i++) {
    final current = List.filled(right.length + 1, 0);
    current[0] = i;
    for (var j = 1; j <= right.length; j++) {
      final substitution =
          previous[j - 1] + (left[i - 1] == right[j - 1] ? 0 : 1);
      final insertion = current[j - 1] + 1;
      final deletion = previous[j] + 1;
      current[j] =
          [substitution, insertion, deletion].reduce((a, b) => a < b ? a : b);
    }
    previous = current;
  }
  final length = left.length > right.length ? left.length : right.length;
  return 1 - previous.last / length;
}

class TextMatch<T> {
  const TextMatch(this.value, this.score, this.phrase);

  final T value;
  final double score;
  final String phrase;
}

TextMatch<T>? bestTextMatch<T>(
  String text,
  Iterable<T> candidates,
  String Function(T) name, {
  double threshold = 0.8,
}) {
  final tokens = normalizeVi(text)
      .split(RegExp(r'[\s,;+]+'))
      .where((token) => token.isNotEmpty)
      .toList();
  TextMatch<T>? best;
  for (final candidate in candidates) {
    final normalizedName = normalizeVi(name(candidate));
    if (normalizedName.isEmpty) continue;
    for (var start = 0; start < tokens.length; start++) {
      for (var size = 1; size <= 3 && start + size <= tokens.length; size++) {
        final phrase = tokens.sublist(start, start + size).join(' ');
        final score = levenshteinRatio(phrase, normalizedName);
        if (score >= threshold && (best == null || score > best.score)) {
          best = TextMatch(candidate, score, phrase);
        }
      }
    }
  }
  return best;
}
