import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression guard for Google Play "Misleading Claims".
///
/// The app reads/writes Supabase directly, needs internet, and has no durable
/// offline queue. This test fails if repo-controlled product copy again makes
/// the exact unsupported claims that were found in the audit. Truthful
/// negations ("not offline-first", "no offline mode") and historical evidence
/// documents are intentionally NOT scanned or matched.
void main() {
  // Exact defective claims. Each pattern targets the wording of the claim,
  // not the word "offline" itself, so truthful negations remain allowed.
  final defectiveClaims = <String, RegExp>{
    'offline-first local storage': RegExp(
      r'with offline-first local storage',
      caseSensitive: false,
    ),
    'primarily from local Drift state': RegExp(
      r'run primarily from local Drift',
      caseSensitive: false,
    ),
    'cloud hydrated into local DB': RegExp(
      r'hydrated into the local (db|database)',
      caseSensitive: false,
    ),
    'local data kept and synced (en)': RegExp(
      r'local data will be kept and synced',
      caseSensitive: false,
    ),
    'local data kept and synced (vi)': RegExp(
      r'dữ liệu cục bộ của bạn sẽ được giữ lại và đồng bộ',
      caseSensitive: false,
    ),
    'local data kept and synced (ja)': RegExp(r'ローカルデータは保持され'),
    'fully offline + auto sync (vi)': RegExp(
      r'offline hoàn toàn|tự động đồng bộ khi có mạng',
      caseSensitive: false,
    ),
    'fully offline + auto sync (en)': RegExp(
      r'(works?|working) (fully |completely )?offline|'
      r'automatically sync(s|ed)? when (you are |you\x27re )?online',
      caseSensitive: false,
    ),
  };

  // Exact previous values of the four localized keys that over-claimed sync.
  const oldValues = <String, List<String>>{
    'app_en.arb': [
      'Sign in to sync your data',
      'Sign in to sync your data across devices',
      'Create your account to sync across devices',
    ],
    'app_vi.arb': [
      'Đăng nhập để đồng bộ dữ liệu của bạn',
      'Đăng nhập để đồng bộ dữ liệu trên nhiều thiết bị',
      'Tạo tài khoản để đồng bộ trên nhiều thiết bị',
    ],
    'app_ja.arb': [
      'データを同期するにはサインインしてください',
      '複数の端末でデータを同期するにはサインインしてください',
      '複数の端末で同期するためにアカウントを作成してください',
    ],
  };

  String read(String path) => File(path).readAsStringSync();

  Map<String, String> arbStrings(String file) {
    final decoded = jsonDecode(read('lib/l10n/$file')) as Map<String, dynamic>;
    return {
      for (final e in decoded.entries)
        if (!e.key.startsWith('@') && e.value is String)
          e.key: e.value as String,
    };
  }

  // Active copy controlled in this repository.
  Map<String, String> activeCopy() {
    final copy = <String, String>{
      'README.md': read('README.md'),
      'docs/index.html': read('docs/index.html'),
      'docs/delete-account.html': read('docs/delete-account.html'),
    };
    for (final file in const ['app_en.arb', 'app_vi.arb', 'app_ja.arb']) {
      copy['lib/l10n/$file'] = arbStrings(file).values.join('\n');
    }
    // Only the pasteable listing text of the draft is scanned. Explanatory
    // sections legitimately quote the historical claim.
    final draft = File('docs/store-listing/google-play-listing-draft.md');
    if (draft.existsSync()) {
      copy[draft.path] = _listingText(draft.readAsStringSync());
    }
    return copy;
  }

  test('controlled product copy has none of the audited defective claims', () {
    final failures = <String>[];
    for (final entry in activeCopy().entries) {
      for (final claim in defectiveClaims.entries) {
        if (claim.value.hasMatch(entry.value)) {
          failures.add('${entry.key}: ${claim.key}');
        }
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('previous over-claiming localized values were not reintroduced', () {
    final failures = <String>[];
    for (final entry in oldValues.entries) {
      final values = arbStrings(entry.key).values.toSet();
      for (final old in entry.value) {
        if (values.contains(old)) failures.add('${entry.key}: "$old"');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('README states the real storage model (negation is allowed)', () {
    final readme = read('README.md');
    expect(readme, contains('not offline-first'));
    expect(readme, contains('internet connection is required'));
  });

  test('listing draft is marked not applied and respects length limits', () {
    final draft = read('docs/store-listing/google-play-listing-draft.md');
    expect(draft, contains('NOT APPLIED'));
    for (final key in const ['SHORT_VI', 'SHORT_EN']) {
      final match = RegExp('^$key: (.+)\$', multiLine: true).firstMatch(draft);
      expect(match, isNotNull, reason: '$key missing');
      expect(match!.group(1)!.trim().runes.length, lessThanOrEqualTo(80),
          reason: '$key exceeds 80 characters');
    }
    final full = RegExp(r'```text\n([\s\S]*?)```').allMatches(draft).toList();
    expect(full.length, 2);
    for (final m in full) {
      expect(m.group(1)!.runes.length, lessThanOrEqualTo(4000));
    }
  });
}

String _listingText(String markdown) {
  final buffer = StringBuffer();
  for (final line in markdown.split('\n')) {
    if (line.startsWith('SHORT_')) buffer.writeln(line);
  }
  for (final m in RegExp(r'```text\n([\s\S]*?)```').allMatches(markdown)) {
    buffer.writeln(m.group(1));
  }
  return buffer.toString();
}
