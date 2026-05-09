import 'dart:convert';
import 'dart:io';

enum AuditType {
  hardText('hard_text'),
  localeFormat('locale_format'),
  brand('brand_consistency');

  const AuditType(this.label);

  final String label;
}

enum Priority {
  p1('P1'),
  p2('P2'),
  p3('P3'),
  p4('P4');

  const Priority(this.label);

  final String label;
}

class AuditFinding {
  AuditFinding({
    required this.filePath,
    required this.lineNumber,
    required this.currentText,
    required this.type,
    required this.priority,
    required this.recommendation,
  });

  final String filePath;
  final int lineNumber;
  final String currentText;
  final AuditType type;
  final Priority priority;
  final String recommendation;
}

class AuditRule {
  const AuditRule({
    required this.regex,
    required this.type,
    required this.priority,
    required this.recommendation,
  });

  final RegExp regex;
  final AuditType type;
  final Priority priority;
  final String recommendation;
}

void main() {
  final repoRoot = Directory.current;
  final findings = <AuditFinding>[];

  final sourceFiles = _collectSourceFiles(repoRoot)
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in sourceFiles) {
    findings.addAll(_scanFile(repoRoot, file));
  }

  findings.addAll(_scanBrandConsistency(repoRoot));

  findings.sort((a, b) {
    final priorityCompare = a.priority.index.compareTo(b.priority.index);
    if (priorityCompare != 0) {
      return priorityCompare;
    }

    final fileCompare = a.filePath.compareTo(b.filePath);
    if (fileCompare != 0) {
      return fileCompare;
    }

    return a.lineNumber.compareTo(b.lineNumber);
  });

  final reportPath = _writeMarkdownReport(repoRoot, findings);
  _printSummary(findings, reportPath);
}

List<File> _collectSourceFiles(Directory repoRoot) {
  final libDir = Directory('${repoRoot.path}${Platform.pathSeparator}lib');
  if (!libDir.existsSync()) {
    return const <File>[];
  }

  return libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !_shouldIgnoreFile(_toRelativePath(repoRoot, file.path)))
      .toList();
}

bool _shouldIgnoreFile(String relativePath) {
  return relativePath.endsWith('.g.dart') ||
      relativePath.endsWith('.freezed.dart') ||
      relativePath == 'lib/l10n/app_localizations.dart' ||
      relativePath == 'lib/l10n/app_localizations_en.dart' ||
      relativePath == 'lib/l10n/app_localizations_vi.dart' ||
      relativePath == 'lib/l10n/app_localizations_ja.dart';
}

List<AuditFinding> _scanFile(Directory repoRoot, File file) {
  final findings = <AuditFinding>[];
  final relativePath = _toRelativePath(repoRoot, file.path);
  final skipHardTextAudit =
      relativePath.startsWith('lib/src/data/repositories/');
  final lines = const LineSplitter().convert(file.readAsStringSync());

  for (var index = 0; index < lines.length; index++) {
    final lineNumber = index + 1;
    final line = lines[index];
    final trimmed = line.trim();
    final previousTrimmed = index > 0 ? lines[index - 1].trim() : '';

    if (_skipLine(trimmed)) {
      continue;
    }

    var matchedHardText = false;
    if (!skipHardTextAudit) {
      for (final rule in _hardTextRules) {
        if (rule.regex.hasMatch(line) && !_shouldSkipHardTextLine(line)) {
          findings.add(
            AuditFinding(
              filePath: relativePath,
              lineNumber: lineNumber,
              currentText: _extractSnippet(line),
              type: rule.type,
              priority: rule.priority,
              recommendation: rule.recommendation,
            ),
          );
          matchedHardText = true;
          break;
        }
      }

      if (!matchedHardText &&
          _isStringLiteralContinuation(trimmed, previousTrimmed) &&
          !_shouldSkipHardTextLine(trimmed)) {
        findings.add(
          AuditFinding(
            filePath: relativePath,
            lineNumber: lineNumber,
            currentText: _extractSnippet(trimmed),
            type: AuditType.hardText,
            priority: Priority.p1,
            recommendation:
                'Move this user-facing text into ARB and read it from AppLocalizations.',
          ),
        );
      }
    }

    for (final rule in _localeRules) {
      if (rule.regex.hasMatch(line)) {
        findings.add(
          AuditFinding(
            filePath: relativePath,
            lineNumber: lineNumber,
            currentText: _extractSnippet(line),
            type: rule.type,
            priority: rule.priority,
            recommendation: rule.recommendation,
          ),
        );
        break;
      }
    }
  }

  return findings;
}

List<AuditFinding> _scanBrandConsistency(Directory repoRoot) {
  final brandFiles = <String>[
    'README.md',
    'pubspec.yaml',
    'lib/src/app.dart',
    'lib/src/app_bootstrap.dart',
  ];
  final pattern = RegExp(r'\b(MyMoney|MoneyWise|Money Wise)\b');
  final matchedLines = <AuditFinding>[];
  final variants = <String>{};

  for (final relativePath in brandFiles) {
    final file = File('${repoRoot.path}${Platform.pathSeparator}$relativePath');
    if (!file.existsSync()) {
      continue;
    }

    final lines = const LineSplitter().convert(file.readAsStringSync());
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final match = pattern.firstMatch(line);
      if (match == null) {
        continue;
      }

      variants.add(match.group(1)!);
      matchedLines.add(
        AuditFinding(
          filePath: relativePath,
          lineNumber: index + 1,
          currentText: _extractSnippet(line),
          type: AuditType.brand,
          priority: Priority.p4,
          recommendation:
              'Keep brand names untranslated, but align on one canonical display name across app and docs.',
        ),
      );
    }
  }

  return variants.length > 1 ? matchedLines : <AuditFinding>[];
}

bool _skipLine(String trimmedLine) {
  return trimmedLine.isEmpty ||
      trimmedLine.startsWith('//') ||
      trimmedLine.startsWith('///') ||
      trimmedLine.startsWith('import ') ||
      trimmedLine.startsWith('export ') ||
      trimmedLine.startsWith('part ');
}

bool _isStringLiteralContinuation(String currentLine, String previousLine) {
  final hasStandaloneString =
      RegExp(r'''^['"].*['"],?$''').hasMatch(currentLine) ||
          RegExp(r'''^.+\?.*['"].*['"].*,?$''').hasMatch(currentLine);
  if (!hasStandaloneString) {
    return false;
  }

  return RegExp(
    r'''(?:\bText\s*\(|\btitle\s*:|\bsubtitle\s*:|\bcontent\s*:|\blabelText\s*:|\bhintText\s*:|\bhelperText\s*:|\berrorText\s*:|\btooltip\s*:|\bmessage\s*:|\bactionLabel\s*:|\bhelpText\s*:|\blabel\s*:)''',
  ).hasMatch(previousLine);
}

bool _shouldSkipHardTextLine(String line) {
  final normalized = line.trim();

  if (normalized.contains('AppLogger.') || normalized.contains("name: 'MM.")) {
    return true;
  }

  if (_isBrandOnlyLine(normalized) ||
      _isLocalizedInterpolationOnly(normalized) ||
      _isEmptyTextLine(normalized) ||
      _isNumericPresentationOnly(normalized) ||
      _isInterpolationPresentationOnly(normalized)) {
    return true;
  }

  const skipFragments = <String>[
    'assets/',
    'ValueKey(',
    'RouteSettings(',
    'Navigator.pushNamed(',
    'Navigator.of(context).pushReplacementNamed(',
    'Navigator.pushReplacementNamed(',
    'throw UnimplementedError(',
    'throw ArgumentError(',
    'throw StateError(',
    'SharedPreferences',
    'const Locale(',
    'DateFormat(',
  ];

  for (final fragment in skipFragments) {
    if (normalized.contains(fragment)) {
      return true;
    }
  }

  final isSimpleRouteString =
      RegExp(r'''['"]/+[a-z0-9\-_/]*['"]''').hasMatch(normalized);
  if (isSimpleRouteString) {
    return true;
  }

  final isLikelyIdentifierAssignment = RegExp(
    r'''\b(?:key|name|tag|heroTag|restorationId|debugLabel|groupValue|value)\s*:\s*['"][A-Za-z0-9_\-.]+['"]''',
  ).hasMatch(normalized);
  if (isLikelyIdentifierAssignment) {
    return true;
  }

  return false;
}

bool _isBrandOnlyLine(String line) {
  return RegExp(r'''['"](?:MyMoney|MoneyWise|Money Wise)['"]''').hasMatch(line);
}

bool _isLocalizedInterpolationOnly(String line) {
  if (!line.contains(r'${')) {
    return false;
  }

  final stripped = line.replaceAll(RegExp(r'''[\s'",:(){}]'''), '');
  return stripped.contains(r'$l10n.') || stripped.contains('l10n.');
}

bool _isEmptyTextLine(String line) {
  return RegExp(r'''\bText\s*\(\s*['"]\s*['"]\s*\)''').hasMatch(line);
}

bool _isNumericPresentationOnly(String line) {
  return RegExp(r'''['"]\$\{[^}]+\}%['"]''').hasMatch(line);
}

bool _isInterpolationPresentationOnly(String line) {
  final withoutInterpolations = line
      .replaceAll(RegExp(r'''\$\{[^}]+\}'''), '')
      .replaceAll(RegExp(r'''\$[A-Za-z_][A-Za-z0-9_]*'''), '');
  final remainingLetters = withoutInterpolations.replaceAll(
    RegExp(r'''[^A-Za-zÀ-ỹぁ-んァ-ヶ一-龯]'''),
    '',
  );
  return remainingLetters.isEmpty &&
      (line.contains(r'${') || RegExp(r'''\$[A-Za-z_]''').hasMatch(line));
}

String _extractSnippet(String line) {
  final trimmed = line.trim();
  return trimmed.length <= 140 ? trimmed : '${trimmed.substring(0, 137)}...';
}

String _writeMarkdownReport(Directory repoRoot, List<AuditFinding> findings) {
  final reportsDir =
      Directory('${repoRoot.path}${Platform.pathSeparator}reports');
  if (!reportsDir.existsSync()) {
    reportsDir.createSync(recursive: true);
  }

  final reportFile = File(
      '${reportsDir.path}${Platform.pathSeparator}localization_audit_report.md');
  reportFile.writeAsStringSync(_buildMarkdownReport(findings));
  return _toRelativePath(repoRoot, reportFile.path);
}

String _buildMarkdownReport(List<AuditFinding> findings) {
  final buffer = StringBuffer();
  final generatedAt = DateTime.now().toIso8601String();

  final totalByType = <AuditType, int>{
    for (final type in AuditType.values)
      type: findings.where((finding) => finding.type == type).length,
  };
  final totalByPriority = <Priority, int>{
    for (final priority in Priority.values)
      priority:
          findings.where((finding) => finding.priority == priority).length,
  };

  buffer.writeln('# Localization Audit Report');
  buffer.writeln();
  buffer.writeln('- Generated at: `$generatedAt`');
  buffer.writeln(
      '- Scope: `lib/**/*.dart` excluding generated localization/model files, plus brand checks in `README.md` and `pubspec.yaml`');
  buffer.writeln(
      '- Brand policy: keep brand names untranslated; only flag consistency mismatches');
  buffer.writeln();
  buffer.writeln('## Summary');
  buffer.writeln();
  buffer.writeln('| Metric | Count |');
  buffer.writeln('| --- | ---: |');
  buffer.writeln('| Total findings | ${findings.length} |');
  for (final priority in Priority.values) {
    buffer.writeln('| ${priority.label} | ${totalByPriority[priority]} |');
  }
  for (final type in AuditType.values) {
    buffer.writeln('| ${type.label} | ${totalByType[type]} |');
  }

  buffer.writeln();
  buffer.writeln('## Findings');
  buffer.writeln();
  buffer.writeln(
      '| File | Line | Current text | Type | Priority | Recommendation |');
  buffer.writeln('| --- | ---: | --- | --- | --- | --- |');

  for (final finding in findings) {
    buffer.writeln(
      '| `${finding.filePath}` | ${finding.lineNumber} | `${_escapePipes(finding.currentText)}` | ${finding.type.label} | ${finding.priority.label} | ${finding.recommendation} |',
    );
  }

  buffer.writeln();
  buffer.writeln('## Notes');
  buffer.writeln();
  buffer.writeln('- `P1`: direct user-facing hard text in UI or messages.');
  buffer.writeln(
      '- `P2`: shared-widget or repeated UI text that should be localized once and reused broadly.');
  buffer.writeln(
      '- `P3`: locale-specific formatting hard-coded to Vietnamese or fixed date/weekday conventions.');
  buffer
      .writeln('- `P4`: brand consistency only; do not translate brand names.');
  buffer.writeln(
      '- The audit is heuristic. Review before mass edits, especially around formatter usage and docs.');

  return buffer.toString();
}

String _escapePipes(String value) => value.replaceAll('|', r'\|');

String _toRelativePath(Directory repoRoot, String absolutePath) {
  final normalizedRoot = repoRoot.path.replaceAll('\\', '/');
  final normalizedPath = absolutePath.replaceAll('\\', '/');
  final prefix = '$normalizedRoot/';

  if (normalizedPath.startsWith(prefix)) {
    return normalizedPath.substring(prefix.length);
  }

  if (normalizedPath == normalizedRoot) {
    return '.';
  }

  return normalizedPath;
}

void _printSummary(List<AuditFinding> findings, String reportPath) {
  final byPriority = <Priority, int>{
    for (final priority in Priority.values)
      priority:
          findings.where((finding) => finding.priority == priority).length,
  };
  final byType = <AuditType, int>{
    for (final type in AuditType.values)
      type: findings.where((finding) => finding.type == type).length,
  };

  stdout.writeln('Localization audit completed.');
  stdout.writeln('Report: $reportPath');
  stdout.writeln('Total findings: ${findings.length}');

  for (final priority in Priority.values) {
    stdout.writeln('  ${priority.label}: ${byPriority[priority]}');
  }

  for (final type in AuditType.values) {
    stdout.writeln('  ${type.label}: ${byType[type]}');
  }
}

final List<AuditRule> _hardTextRules = <AuditRule>[
  AuditRule(
    regex: RegExp(r'''\bText\s*\(\s*['"]'''),
    type: AuditType.hardText,
    priority: Priority.p1,
    recommendation:
        'Move this user-facing text into ARB and read it from AppLocalizations.',
  ),
  AuditRule(
    regex: RegExp(
      r'''\b(?:labelText|hintText|helperText|errorText|tooltip|title|subtitle|content|semanticLabel)\s*:\s*['"]''',
    ),
    type: AuditType.hardText,
    priority: Priority.p1,
    recommendation:
        'Replace the hardcoded UI copy with an AppLocalizations key.',
  ),
  AuditRule(
    regex: RegExp(r'''\b(?:label|message|actionLabel|helpText)\s*:\s*['"]'''),
    type: AuditType.hardText,
    priority: Priority.p1,
    recommendation:
        'Replace the hardcoded UI copy with an AppLocalizations key.',
  ),
  AuditRule(
    regex: RegExp(r'''SnackBar\s*\([^\n]*Text\s*\(\s*['"]'''),
    type: AuditType.hardText,
    priority: Priority.p1,
    recommendation: 'Localize snackbar copy through AppLocalizations.',
  ),
];

final List<AuditRule> _localeRules = <AuditRule>[
  AuditRule(
    regex: RegExp(r'''locale\s*:\s*['"]vi['"]'''),
    type: AuditType.localeFormat,
    priority: Priority.p3,
    recommendation:
        'Use the active app locale instead of hardcoding Vietnamese locale formatting.',
  ),
  AuditRule(
    regex: RegExp(r'''symbol\s*:\s*['"]đ['"]'''),
    type: AuditType.localeFormat,
    priority: Priority.p3,
    recommendation:
        'Avoid hardcoded currency symbols in UI formatters; derive them from locale or app settings.',
  ),
  AuditRule(
    regex: RegExp(r'''DateFormat\s*\(\s*['"][^'"]+['"]\s*\)'''),
    type: AuditType.localeFormat,
    priority: Priority.p3,
    recommendation:
        'Review fixed date patterns and switch to locale-aware formatting where user-visible.',
  ),
  AuditRule(
    regex: RegExp(r"\[(?:[^\]]*'T2'[^\]]*'CN'[^\]]*)\]"),
    type: AuditType.localeFormat,
    priority: Priority.p3,
    recommendation:
        'Replace hardcoded Vietnamese weekday labels with localized weekday names.',
  ),
  AuditRule(
    regex: RegExp(r"'Yesterday'|'Hôm qua'|'T2'|'T3'|'T4'|'T5'|'T6'|'T7'|'CN'"),
    type: AuditType.localeFormat,
    priority: Priority.p3,
    recommendation:
        'Route relative-day and weekday labels through localization resources.',
  ),
];
