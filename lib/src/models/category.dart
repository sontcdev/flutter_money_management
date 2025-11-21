// path: lib/src/models/category.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

enum CategoryType {
  @JsonValue('expense')
  expense,
  @JsonValue('income')
  income,
}

@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required CategoryType type,
    String? colorHex,
    String? iconName,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}

