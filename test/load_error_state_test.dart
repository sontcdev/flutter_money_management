import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_money_management/src/ui/widgets/load_error_state.dart';

void main() {
  testWidgets(
      'LoadErrorState keeps technical exceptions out of the UI and retries',
      (tester) async {
    var retryCount = 0;
    const technicalError =
        'ClientException with SocketException: Failed host lookup: supabase.co';

    await tester.pumpWidget(
      MaterialApp(
        home: LoadErrorState(
          title: 'Không thể tải dữ liệu',
          message: 'Vui lòng kiểm tra kết nối mạng và thử lại.',
          retryLabel: 'Thử lại',
          onRetry: () => retryCount++,
        ),
      ),
    );

    expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
    expect(find.text('Vui lòng kiểm tra kết nối mạng và thử lại.'),
        findsOneWidget);
    expect(find.textContaining('ClientException'), findsNothing);
    expect(find.textContaining('supabase.co'), findsNothing);
    expect(find.text(technicalError), findsNothing);

    await tester.tap(find.text('Thử lại'));
    expect(retryCount, 1);
  });
}
