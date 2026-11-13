import 'package:flutter/material.dart';
import 'package:flutter_money_management/src/theme/app_theme.dart';
import 'package:flutter_money_management/src/ui/widgets/app_status_chip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const labels = {
    'vi': 'Đang chờ người nhận chấp nhận lời mời tham gia không gian',
    'en': 'Waiting for the recipient to accept the workspace invitation',
    'ja': '受信者がワークスペースへの招待を承認するのを待っています',
  };
  final themes = {
    'light': AppTheme.lightTheme(primaryColor: const Color(0xFF00884B)),
    'dark': AppTheme.darkTheme(primaryColor: const Color(0xFF00884B)),
  };

  for (final lang in labels.entries) {
    for (final th in themes.entries) {
      for (final outlined in [false, true]) {
        testWidgets('status chip long label ${lang.key} ${th.key} $outlined',
            (t) async {
          t.view.physicalSize = const Size(200, 800);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          await t.pumpWidget(MaterialApp(
            theme: th.value,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppStatusChip.info(
                      label: lang.value,
                      icon: Icons.info,
                      isOutlined: outlined,
                    ),
                  ],
                ),
              ),
            ),
          ));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          expect(find.text(lang.value), findsOneWidget);
          expect(find.byIcon(Icons.info), findsOneWidget);
          final w = t.getSize(find.byType(AppStatusChip)).width;
          expect(w, lessThanOrEqualTo(184.01));
        });
      }
    }
  }
}
