import 'dart:math' as math;

import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/utils/text_similarity.dart';

class CategorySuggestion {
  const CategorySuggestion(this.categoryId, this.confidence);

  final String categoryId;
  final double confidence;
}

class CategoryClassifier {
  CategoryClassifier._(this.minSamples, this.minConfidence);

  final int minSamples;
  final double minConfidence;
  final Map<String, _CategoryCounts> _categories = {};
  final Set<String> _vocabulary = {};
  int _samples = 0;

  factory CategoryClassifier.train(
    List<Transaction> transactions, {
    DateTime Function()? clock,
    int minSamples = 3,
    double minConfidence = 0.65,
  }) {
    final classifier = CategoryClassifier._(minSamples, minConfidence);
    final now = (clock ?? DateTime.now)();
    final recent = DateTime(now.year, now.month - 6, now.day);
    for (final transaction in transactions) {
      final categoryId = transaction.categoryId;
      if (transaction.type == TransactionType.transfer ||
          transaction.deletedAt != null ||
          categoryId == null) {
        continue;
      }
      final features = _features(transaction.note ?? '');
      if (features.isEmpty) continue;
      final type = transaction.type == TransactionType.income
          ? CategoryType.income
          : CategoryType.expense;
      final counts = classifier._categories
          .putIfAbsent(categoryId, () => _CategoryCounts(type));
      final weight = transaction.dateTime.isBefore(recent) ? 1 : 2;
      counts.documents += weight;
      classifier._samples++;
      for (final feature in features) {
        counts.tokens
            .update(feature, (count) => count + weight, ifAbsent: () => weight);
        counts.totalTokens += weight;
        classifier._vocabulary.add(feature);
      }
      final wallet = transaction.walletId;
      if (wallet != null) {
        counts.wallets
            .update(wallet, (count) => count + weight, ifAbsent: () => weight);
        for (final feature in features.toSet()) {
          final votes = counts.tokenWallets.putIfAbsent(feature, () => {});
          votes.update(wallet, (count) => count + weight,
              ifAbsent: () => weight);
        }
      }
    }
    return classifier;
  }

  CategorySuggestion? predict(
    String text, {
    CategoryType? type,
    Set<String>? categoryIds,
  }) {
    if (_samples < minSamples) return null;
    final features = _features(text).where(_vocabulary.contains).toList();
    if (features.isEmpty) return null;
    final candidates = _categories.entries
        .where((entry) =>
            (type == null || entry.value.type == type) &&
            (categoryIds == null || categoryIds.contains(entry.key)))
        .toList();
    if (candidates.isEmpty ||
        !candidates
            .any((entry) => features.any(entry.value.tokens.containsKey))) {
      return null;
    }
    final totalDocuments =
        candidates.fold<int>(0, (sum, entry) => sum + entry.value.documents);
    final scores = <String, double>{};
    for (final candidate in candidates) {
      final counts = candidate.value;
      var score = math.log(counts.documents / totalDocuments);
      for (final feature in features) {
        score += math.log(((counts.tokens[feature] ?? 0) + 1) /
            (counts.totalTokens + _vocabulary.length));
      }
      scores[candidate.key] = score;
    }
    if (scores.isEmpty) return null;
    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxScore = ranked.first.value;
    final denominator = ranked.fold<double>(
        0, (sum, entry) => sum + math.exp(entry.value - maxScore));
    final confidence = 1 / denominator;
    if (confidence < minConfidence) return null;
    return CategorySuggestion(ranked.first.key, confidence);
  }

  String? suggestWallet(String text, String categoryId,
      {Set<String>? walletIds}) {
    if (_samples < minSamples) return null;
    final counts = _categories[categoryId];
    if (counts == null) return null;
    final votes = <String, int>{};
    for (final feature in _features(text).toSet()) {
      for (final entry
          in (counts.tokenWallets[feature] ?? <String, int>{}).entries) {
        votes.update(entry.key, (count) => count + entry.value,
            ifAbsent: () => entry.value);
      }
    }
    final source = votes.isEmpty ? counts.wallets : votes;
    final eligible = source.entries
        .where((entry) => walletIds == null || walletIds.contains(entry.key))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (eligible.isEmpty) return null;
    final total = eligible.fold<int>(0, (sum, entry) => sum + entry.value);
    return eligible.first.value / total >= minConfidence
        ? eligible.first.key
        : null;
  }

  static final RegExp _featureTokens = RegExp(r'[\p{L}]+', unicode: true);
  static const _stopWords = {
    'hom',
    'nay',
    'qua',
    'kia',
    'ngay',
    'mai',
    'truoc',
    'thu',
    'tuan',
    'thang',
    'sang',
    'trua',
    'toi',
    'dau',
    'cuoi',
    'vi',
    'vnd',
    'dong',
    'k',
    'tr',
    'trieu',
    'nghin',
    'ngan',
    'cu',
    'ty',
    'lit',
    'tram',
    'm',
    'va',
    'roi',
    'xong',
  };

  static List<String> _features(String text) {
    final tokens = _featureTokens
        .allMatches(normalizeVi(text))
        .map((match) => match.group(0)!)
        .where((token) => !_stopWords.contains(token))
        .toList();
    return [
      ...tokens,
      for (var i = 1; i < tokens.length; i++) '${tokens[i - 1]} ${tokens[i]}',
    ];
  }
}

class _CategoryCounts {
  _CategoryCounts(this.type);

  final CategoryType type;
  int documents = 0;
  int totalTokens = 0;
  final Map<String, int> tokens = {};
  final Map<String, int> wallets = {};
  final Map<String, Map<String, int>> tokenWallets = {};
}
