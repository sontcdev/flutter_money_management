import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:flutter_money_management/l10n/app_localizations.dart';
import 'package:flutter_money_management/src/features/categories/models/category.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction.dart';
import 'package:flutter_money_management/src/features/transactions/presentation/widgets/voice_input_sheet.dart';
import 'package:flutter_money_management/src/features/transactions/services/category_suggestion_service.dart';
import 'package:flutter_money_management/src/features/wallets/models/wallet.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';

void main() => runApp(const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _Preview(),
    ));

class _Preview extends HookWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final historyEnabled = useState(false);
    final result = useState('No result yet');
    final categories = [
      Category(
        id: 'food',
        name: 'Ăn uống',
        type: CategoryType.expense,
        iconName: 'restaurant',
        colorValue: 0,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    final wallets = [
      Wallet(
        id: 'momo',
        workspaceId: 'preview',
        name: 'Momo',
        walletType: WalletType.ewallet,
        iconName: 'wallet',
        colorValue: 0,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    final history = [
      for (var i = 0; i < 3; i++)
        Transaction(
          id: 'preview-$i',
          amountCents: 3000000,
          currency: 'VND',
          dateTime: now,
          type: TransactionType.expense,
          categoryId: 'food',
          walletId: 'momo',
          note: 'quán quen espresso',
          createdAt: now,
          updatedAt: now,
        ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Quick input preview — synthetic data')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          const Text(
              'No backend calls or saves. Test typed text and Vietnamese speech.'),
          SwitchListTile(
            title: const Text('Enable synthetic workspace history'),
            value: historyEnabled.value,
            onChanged: (value) => historyEnabled.value = value,
          ),
          FilledButton(
            onPressed: () async {
              final items = await showQuickInputSheet(
                context,
                categories: categories,
                wallets: wallets,
                classifier: historyEnabled.value
                    ? CategoryClassifier.train(history)
                    : null,
              );
              if (!context.mounted || items == null) return;
              result.value = items
                  .map((item) => 'amount=${item.amountVnd}; date=${item.date}; '
                      'category=${item.categoryName}; wallet=${item.walletName}; '
                      'note=${item.note}; confidence=${item.categoryConfidence}')
                  .join('\n');
            },
            child: const Text('Open quick input'),
          ),
          SelectableText(result.value),
        ],
      ),
    );
  }
}
