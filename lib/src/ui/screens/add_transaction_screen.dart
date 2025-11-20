// path: lib/src/ui/screens/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:test3_cursor/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/providers.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/account.dart';
import '../widgets/app_input.dart';
import '../widgets/app_button.dart';
import '../../services/budget_service.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String? transactionId;

  const AddTransactionScreen({
    super.key,
    this.transactionId,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TransactionType _selectedType = TransactionType.expense;
  Category? _selectedCategory;
  Account? _selectedAccount;
  String? _receiptPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.transactionId != null) {
      _loadTransaction();
    }
  }

  Future<void> _loadTransaction() async {
    final repo = ref.read(transactionRepositoryProvider);
    final transaction = await repo.getTransactionById(widget.transactionId!);
    if (transaction != null) {
      setState(() {
        _amountController.text = '${transaction.amountCents / 100}';
        _noteController.text = transaction.note ?? '';
        _selectedDate = transaction.dateTime;
        _selectedType = transaction.type;
        _receiptPath = transaction.receiptPath;
      });

      final categories = await ref.read(categoryRepositoryProvider).getAllCategories();
      final accounts = await ref.read(accountRepositoryProvider).getAllAccounts();
      
      setState(() {
        _selectedCategory = categories.firstWhere(
          (c) => c.id == transaction.categoryId,
          orElse: () => categories.first,
        );
        _selectedAccount = accounts.firstWhere(
          (a) => a.id == transaction.accountId,
          orElse: () => accounts.first,
        );
      });
    }
  }

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _receiptPath = image.path);
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null || _selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.required)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amountText = _amountController.text.replaceAll(',', '');
      final amount = (double.parse(amountText) * 100).toInt();
      
      final transaction = Transaction(
        id: widget.transactionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        amountCents: amount,
        currency: 'VND',
        dateTime: _selectedDate,
        categoryId: _selectedCategory!.id,
        accountId: _selectedAccount!.id,
        type: _selectedType,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        receiptPath: _receiptPath,
        createdAt: widget.transactionId != null
            ? DateTime.now()
            : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repo = ref.read(transactionRepositoryProvider);
      
      if (widget.transactionId != null) {
        await repo.updateTransaction(transaction);
      } else {
        await repo.createTransaction(transaction, allowOverdraft: false);
      }

      if (mounted) {
        ref.invalidate(transactionsProvider);
        Navigator.of(context).pop();
      }
    } on BudgetExceededException catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        final format = NumberFormat.currency(symbol: '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.budgetExceededMessage(
              format.format(e.remainingCents / 100),
            )),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(categoriesProvider);
    final accounts = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transactionId != null
            ? l10n.editTransaction
            : l10n.addTransaction),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<TransactionType>(
                segments: [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text(l10n.expense),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text(l10n.income),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<TransactionType> selected) {
                  setState(() => _selectedType = selected.first);
                },
              ),
              const SizedBox(height: 16),
              AppInput(
                label: l10n.amount,
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.required;
                  }
                  final amount = double.tryParse(value.replaceAll(',', ''));
                  if (amount == null || amount <= 0) {
                    return l10n.invalidAmount;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppInput(
                label: l10n.date,
                controller: TextEditingController(
                  text: DateFormat('yyyy-MM-dd').format(_selectedDate),
                ),
                readOnly: true,
                onTap: _selectDate,
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              const SizedBox(height: 16),
              categories.when(
                data: (categoriesList) {
                  return DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    decoration: InputDecoration(labelText: l10n.category),
                    items: categoriesList.map((category) {
                      return DropdownMenuItem<Category>(
                        value: category,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (category) {
                      setState(() => _selectedCategory = category);
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 16),
              accounts.when(
                data: (accountsList) {
                  return DropdownButtonFormField<Account>(
                    value: _selectedAccount,
                    decoration: InputDecoration(labelText: l10n.account),
                    items: accountsList.map((account) {
                      return DropdownMenuItem<Account>(
                        value: account,
                        child: Text(account.name),
                      );
                    }).toList(),
                    onChanged: (account) {
                      setState(() => _selectedAccount = account);
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 16),
              AppInput(
                label: l10n.note,
                controller: _noteController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              if (_receiptPath != null)
                Image.file(File(_receiptPath!), height: 200),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickReceipt,
                icon: const Icon(Icons.attach_file),
                label: Text(l10n.attachReceipt),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: l10n.save,
                onPressed: _save,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

