// path: lib/src/ui/screens/account_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../l10n/app_localizations.dart';

class AccountEditScreen extends ConsumerStatefulWidget {
  final int? accountId;

  const AccountEditScreen({super.key, this.accountId});

  @override
  ConsumerState<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends ConsumerState<AccountEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedType = 'cash';
  String _selectedCurrency = 'VND';

  @override
  void initState() {
    super.initState();
    if (widget.accountId != null) {
      // Load existing account data
      _loadAccountData();
    }
  }

  void _loadAccountData() {
    // TODO: Load account from repository
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.accountId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.editAccount : l10n.addAccount),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.accountName,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter account name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: l10n.accountType,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'cash', child: Text(l10n.cash)),
                DropdownMenuItem(value: 'card', child: Text(l10n.card)),
                DropdownMenuItem(value: 'bank', child: Text(l10n.bank)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _balanceController,
              decoration: InputDecoration(
                labelText: l10n.balance,
                border: const OutlineInputBorder(),
                prefixText: _selectedCurrency == 'VND' ? '₫ ' : '\$ ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter initial balance';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              decoration: InputDecoration(
                labelText: l10n.currency,
                border: const OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'VND', child: Text('VND (₫)')),
                DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCurrency = value);
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveAccount,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(l10n.save),
            ),
            if (isEdit) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _deleteAccount,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(l10n.delete),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _saveAccount() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save account to repository
      Navigator.pop(context);
    }
  }

  void _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Delete account from repository
      if (mounted) Navigator.pop(context);
    }
  }
}

