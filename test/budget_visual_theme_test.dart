import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/budgets/models/budget.dart';
import 'package:flutter_money_management/src/features/budgets/presentation/screens/budget_edit_screen.dart';
import 'package:flutter_money_management/src/features/budgets/presentation/screens/budgets_screen.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/providers/providers.dart';
import 'package:flutter_money_management/src/theme/app_colors.dart';
import 'package:flutter_money_management/src/theme/app_semantic_colors.dart';
import 'package:flutter_money_management/src/theme/app_surface_tokens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _boundaryKey = GlobalKey();
final _now = DateTime(2026, 1, 1);

Budget _budget({int consumed = 25000}) => Budget(
      id: 'b1',
      categoryId: 'c1',
      periodType: PeriodType.monthly,
      periodStart: DateTime(2026, 1, 1),
      periodEnd: DateTime(2026, 1, 31),
      limitCents: 100000,
      consumedCents: consumed,
      allowOverdraft: false,
      overdraftCents: 0,
      createdAt: _now,
      updatedAt: _now,
    );

Category _category() => Category(
      id: 'c1',
      name: 'Food',
      iconName: 'shopping_cart',
      colorValue: 0xFF9E9E9E,
      createdAt: _now,
      updatedAt: _now,
    );

ThemeData _theme(Brightness b, Color primary) => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: b)
          .copyWith(primary: primary),
      extensions: [
        b == Brightness.dark ? AppSemanticColors.dark : AppSemanticColors.light,
      ],
    );

Future<void> _pump(WidgetTester tester, Widget screen, ThemeData theme) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      categoriesProvider.overrideWith((ref) async => [_category()]),
      transactionsProvider.overrideWith((ref) async => []),
    ],
    child: RepaintBoundary(
      key: _boundaryKey,
      child: MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

double _ratio(Color a, Color b) => AppSurfaceTokens.contrast(a, b);

void main() {
  for (final b in Brightness.values) {
    for (final primary in [const Color(0xFFBFE8D0), const Color(0xFF00E676)]) {
      final tag = '${b.name} ${primary.toARGB32().toRadixString(16)}';
      testWidgets('selected period text readable on primary ($tag)',
          (tester) async {
        final theme = _theme(b, primary);
        await _pump(tester, BudgetEditScreen(budget: _budget()), theme);
        final text = tester.widget<Text>(find.text('Monthly').first);
        final fg = text.style!.color!;
        expect(
            _ratio(fg, theme.colorScheme.primary), greaterThanOrEqualTo(4.5));
      });

      for (final c in const [
        (25000, 'normal'),
        (85000, 'warning'),
        (120000, 'overlimit'),
      ]) {
        testWidgets('hero progress ${c.$2} rendered ($tag)', (tester) async {
          final theme = _theme(b, primary);
          await _pump(
              tester,
              BudgetTransactionsDetailScreen(
                  budget: _budget(consumed: c.$1), categoryName: 'Food'),
              theme);
          final sem = b == Brightness.dark
              ? AppSemanticColors.dark
              : AppSemanticColors.light;
          final pct = c.$1 / 1000;
          final container = pct > 100
              ? sem.expenseContainer
              : pct >= 80
                  ? sem.warningContainer
                  : sem.incomeContainer;
          final end = Color.alphaBlend(
              container.withValues(alpha: 0.6), theme.scaffoldBackgroundColor);
          final remaining =
              tester.widget<Text>(find.textContaining('Remaining:'));
          final r1 = _ratio(remaining.style!.color!, container);
          final r2 = _ratio(remaining.style!.color!, end);
          final bar = tester.widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator));
          final fill =
              (bar.valueColor! as AlwaysStoppedAnimation<Color?>).value!;
          final track = bar.backgroundColor!;
          final fillTrack = _ratio(fill, track);
          // ignore: avoid_print
          print('${c.$2} $tag remaining=${r1.toStringAsFixed(2)}/'
              '${r2.toStringAsFixed(2)} fill/track=${fillTrack.toStringAsFixed(2)}');
          expect(r1, greaterThanOrEqualTo(4.5));
          expect(r2, greaterThanOrEqualTo(4.5));
          expect(fillTrack, greaterThanOrEqualTo(3));
          expect(_ratio(fill, container), greaterThanOrEqualTo(3));
          expect(_ratio(fill, end), greaterThanOrEqualTo(3));
          expect(bar.value, closeTo((pct / 100).clamp(0.0, 1.0), 1e-9));

          // Rendered pixels: filled vs unfilled region.
          final rect = tester.getRect(find.byType(LinearProgressIndicator));
          final boundary = _boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final img = await boundary.toImage();
            final data = (await img.toByteData())!;
            Color px(double x, double y) {
              final i = ((y.round() * img.width) + x.round()) * 4;
              return Color.fromARGB(255, data.getUint8(i), data.getUint8(i + 1),
                  data.getUint8(i + 2));
            }

            final y = rect.center.dy;
            final filledPx = px(rect.left + rect.width * 0.1, y);
            if (bar.value! < 0.9) {
              final emptyPx = px(rect.left + rect.width * 0.97, y);
              final rr = _ratio(filledPx, emptyPx);
              // ignore: avoid_print
              print('  rendered filled/unfilled=${rr.toStringAsFixed(2)}');
              expect(rr, greaterThanOrEqualTo(3));
            }
          });
        });
      }
    }
  }

  for (final b in Brightness.values) {
    for (final c in const [
      (25000, 'normal'),
      (85000, 'warning'),
      (120000, 'error'),
    ]) {
      testWidgets('hero pill ${c.$2} contrast (${b.name})', (tester) async {
        final theme = _theme(b, const Color(0xFF00E676));
        await _pump(
            tester,
            BudgetTransactionsDetailScreen(
                budget: _budget(consumed: c.$1), categoryName: 'Food'),
            theme);
        final sem = b == Brightness.dark
            ? AppSemanticColors.dark
            : AppSemanticColors.light;
        final expectedFill = c.$1 > 100000
            ? AppColors.error
            : c.$1 >= 80000
                ? sem.warning
                : AppColors.primary;
        final label = '${(c.$1 / 1000).toStringAsFixed(1)}%';
        final textFinder = find.text(label);
        final text = tester.widget<Text>(textFinder);
        final box = tester.widget<Container>(find
            .ancestor(of: textFinder, matching: find.byType(Container))
            .first);
        final fill = (box.decoration! as BoxDecoration).color!;
        final r = _ratio(text.style!.color!, fill);
        // ignore: avoid_print
        print('pill ${c.$2} ${b.name} ratio=${r.toStringAsFixed(2)}');
        expect(fill, expectedFill);
        expect(r, greaterThanOrEqualTo(4.5));
      });
    }
  }
}
