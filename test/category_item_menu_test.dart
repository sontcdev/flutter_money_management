import 'package:flutter/material.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/categories/presentation/widgets/category_item.dart';
import 'package:flutter_money_management/src/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

const _names = {
  'vi':
      'Danh mục chi tiêu gia đình rất dài cho kế hoạch mua nhà và đầu tư năm 2030 và hơn nữa',
  'en':
      'Very long family spending category for the house purchase and investments in 2030 and more',
  'ja': '住宅購入と家族の投資のための非常に長いカテゴリ名の例です二〇三〇年以降もずっと',
};

Category _cat(String name) => Category(
      id: 'c',
      name: name,
      iconName: 'restaurant',
      colorValue: 0xFF2196F3,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Widget _app(String lang, Brightness b, double scale, Widget child) {
  const seed = Color(0xFF00884B);
  return MaterialApp(
    theme: b == Brightness.light
        ? AppTheme.lightTheme(primaryColor: seed)
        : AppTheme.darkTheme(primaryColor: seed),
    locale: Locale(lang),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (c, w) => MediaQuery(
      data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
      child: w!,
    ),
    home: Scaffold(body: child),
  );
}

final _menu = find.byWidgetPredicate((w) => w is PopupMenuButton);

void main() {
  for (final lang in _names.keys) {
    for (final b in Brightness.values) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('long name no overflow $lang ${b.name} x$scale',
            (tester) async {
          tester.view.physicalSize = const Size(360, 740);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(_app(
              lang,
              b,
              scale,
              CategoryItem(
                  category: _cat(_names[lang]!),
                  onEdit: () {},
                  onDelete: () {})));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text(_names[lang]!), findsOneWidget);
          expect(_menu, findsOneWidget);
          await tester.tap(_menu);
          await tester.pumpAndSettle();
          final l10n = await AppLocalizations.delegate.load(Locale(lang));
          expect(find.text(l10n.edit), findsOneWidget);
          expect(find.text(l10n.delete), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('row tap and menu callbacks', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(_app(
        'en',
        Brightness.light,
        1,
        CategoryItem(
            category: _cat('Food'),
            onEdit: () => calls.add('edit'),
            onDelete: () => calls.add('delete'))));
    await tester.tap(find.text('Food'));
    expect(calls, ['edit']);
    await tester.tap(_menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(calls, ['edit', 'delete']);
    await tester.tap(_menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(calls, ['edit', 'delete', 'edit']);
  });

  testWidgets('onTap takes precedence over onEdit on row', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(_app(
        'en',
        Brightness.light,
        1,
        CategoryItem(
            category: _cat('Food'),
            onTap: () => calls.add('tap'),
            onEdit: () => calls.add('edit'))));
    await tester.tap(find.text('Food'));
    expect(calls, ['tap']);
  });

  testWidgets('read-only shows no menu', (tester) async {
    await tester.pumpWidget(
        _app('en', Brightness.light, 1, CategoryItem(category: _cat('Food'))));
    expect(_menu, findsNothing);
  });
}
