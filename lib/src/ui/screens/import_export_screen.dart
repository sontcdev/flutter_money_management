// path: lib/src/ui/screens/import_export_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/import_export_service.dart';
import '../../providers/providers.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../../l10n/app_localizations.dart';

class ImportExportScreen extends ConsumerStatefulWidget {
  const ImportExportScreen({super.key});

  @override
  ConsumerState<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends ConsumerState<ImportExportScreen> {
  final _importExportService = ImportExportService();
  bool _isLoading = false;
  String? _statusMessage;
  bool _isError = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importExport),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status message
            if (_statusMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isError ? Colors.red[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isError ? Colors.red[300]! : Colors.green[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isError ? Icons.error_outline : Icons.check_circle_outline,
                      color: _isError ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _isError ? Colors.red[800] : Colors.green[800],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _statusMessage = null),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Export Section
            Text(
              l10n.exportData,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.exportDataDesc,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.table_chart,
                    title: l10n.exportCsv,
                    subtitle: l10n.exportCsvDesc,
                    onTap: _isLoading ? null : () => _exportData('csv', l10n),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.code,
                    title: l10n.exportJson,
                    subtitle: l10n.exportJsonDesc,
                    onTap: _isLoading ? null : () => _exportData('json', l10n),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Import Section
            Text(
              l10n.importData,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.importDataDesc,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Import from File buttons
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.upload_file,
                    title: l10n.importFromFile,
                    subtitle: l10n.importFromFileDesc,
                    onTap: _isLoading ? null : () => _pickAndImportFile(l10n),
                    isPrimary: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.content_paste,
                    title: l10n.pasteCsv,
                    subtitle: l10n.fromClipboard,
                    onTap: _isLoading ? null : () => _showImportDialog('csv', l10n),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.content_paste,
                    title: l10n.pasteJson,
                    subtitle: l10n.fromClipboard,
                    onTap: _isLoading ? null : () => _showImportDialog('json', l10n),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Template Section
            Text(
              l10n.templateSection,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.templateDesc,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.download,
                    title: l10n.templateCsv,
                    subtitle: l10n.downloadTemplate,
                    onTap: _isLoading ? null : () => _saveTemplate('csv', l10n),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.download,
                    title: l10n.templateJson,
                    subtitle: l10n.downloadTemplate,
                    onTap: _isLoading ? null : () => _saveTemplate('json', l10n),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Format Guide
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          l10n.formatGuide,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFormatRow('date', l10n.formatDate),
                    _buildFormatRow('type', l10n.formatType),
                    _buildFormatRow('amount', l10n.formatAmount),
                    _buildFormatRow('category', l10n.formatCategory),
                    _buildFormatRow('note', l10n.formatNote),
                  ],
                ),
              ),
            ),

            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormatRow(String field, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              field,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(description)),
        ],
      ),
    );
  }

  Future<void> _pickAndImportFile(AppLocalizations l10n) async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json'],
        allowMultiple: false,
      );

      if (result == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        setState(() {
          _statusMessage = l10n.cannotReadFile;
          _isError = true;
          _isLoading = false;
        });
        return;
      }

      final content = await File(file.path!).readAsString();
      final extension = file.extension?.toLowerCase() ?? '';

      if (extension == 'csv') {
        await _importData(content, 'csv', l10n);
      } else if (extension == 'json') {
        await _importData(content, 'json', l10n);
      } else {
        setState(() {
          _statusMessage = l10n.unsupportedFormat;
          _isError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '${l10n.fileReadError}: ${e.toString()}';
        _isError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportData(String format, AppLocalizations l10n) async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final transactions = await ref.read(transactionsProvider.future);
      final categories = await ref.read(categoriesProvider.future);

      if (transactions.isEmpty) {
        setState(() {
          _statusMessage = l10n.noTransactionToExport;
          _isError = true;
          _isLoading = false;
        });
        return;
      }

      String content;
      String defaultFilename;
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      if (format == 'csv') {
        content = await _importExportService.exportToCSV(transactions, categories);
        defaultFilename = 'transactions_$timestamp.csv';
      } else {
        content = await _importExportService.exportToJSON(transactions, categories);
        defaultFilename = 'transactions_$timestamp.json';
      }

      String filePath;
      
      // On mobile platforms, FilePicker.saveFile requires bytes
      // So we save to documents directory first, then allow sharing
      if (Platform.isAndroid || Platform.isIOS) {
        // Save to documents directory
        filePath = await _importExportService.saveToFile(content, defaultFilename);
      } else {
        // On desktop, let user choose save location
        String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: l10n.chooseSaveLocation,
          fileName: defaultFilename,
          type: FileType.custom,
          allowedExtensions: [format],
        );

        if (outputPath != null) {
          // User chose a location - save there
          final file = File(outputPath);
          await file.writeAsString(content);
          filePath = outputPath;
        } else {
          // User cancelled - save to default location
          filePath = await _importExportService.saveToFile(content, defaultFilename);
        }
      }

      setState(() {
        _statusMessage = '${l10n.exportedTransactions(transactions.length)}\n${l10n.fileSavedAt(filePath)}';
        _isError = false;
        _isLoading = false;
      });

      // Show share dialog
      _showExportSuccessDialog(filePath, content, format, l10n);
    } catch (e) {
      setState(() {
        _statusMessage = '${l10n.exportError}: ${e.toString()}';
        _isError = true;
        _isLoading = false;
      });
    }
  }

  void _showExportSuccessDialog(String filePath, String content, String format, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.exportSuccess)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    format == 'csv' ? Icons.table_chart : Icons.code,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      filePath.split('/').last,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.fileSavedAtPath,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              filePath,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          // Left side - Copy button
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.copiedToClipboard)),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: Text(l10n.copyContent),
          ),
          // Right side - Share and Close buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Share button
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _shareFile(filePath, format, l10n);
                },
                icon: const Icon(Icons.share, size: 18),
                label: Text(l10n.share),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _shareFile(String filePath, String format, AppLocalizations l10n) async {
    try {
      final file = XFile(filePath);
      
      await Share.shareXFiles(
        [file],
        subject: l10n.exportedTransactionsSubject,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.shareError}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImportDialog(String format, AppLocalizations l10n) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importFromFormat(format.toUpperCase())),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.pasteContentHere),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: format == 'csv' 
                      ? 'date,type,amount,category,note\n25/11/2024,expense,50000,Ăn uống,Ăn sáng'
                      : '{"transactions": [...]}',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _importData(controller.text, format, l10n);
            },
            child: Text(l10n.import),
          ),
        ],
      ),
    );
  }

  Future<void> _importData(String content, String format, AppLocalizations l10n) async {
    if (content.trim().isEmpty) {
      setState(() {
        _statusMessage = l10n.emptyContent;
        _isError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      List<ImportTransaction> importedTransactions;
      
      if (format == 'csv') {
        importedTransactions = await _importExportService.parseCSV(content);
      } else {
        importedTransactions = await _importExportService.parseJSON(content);
      }

      if (importedTransactions.isEmpty) {
        setState(() {
          _statusMessage = l10n.noTransactionToImport;
          _isError = true;
          _isLoading = false;
        });
        return;
      }

      // Get existing categories
      final categories = await ref.read(categoriesProvider.future);
      final categoryMap = {for (var c in categories) c.name.toLowerCase(): c};

      // Create missing categories and import transactions
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final transactionRepo = ref.read(transactionRepositoryProvider);
      
      int successCount = 0;
      final newCategories = <String>[];

      for (final imported in importedTransactions) {
        // Find or create category
        int categoryId;
        final existingCategory = categoryMap[imported.categoryName.toLowerCase()];
        
        if (existingCategory != null) {
          categoryId = existingCategory.id;
        } else {
          // Check if we already created this category in this import
          final alreadyCreated = categoryMap[imported.categoryName.toLowerCase()];
          if (alreadyCreated != null) {
            categoryId = alreadyCreated.id;
          } else {
            // Create new category
            final now = DateTime.now();
            final newCategoryModel = Category(
              id: 0,
              name: imported.categoryName,
              iconName: _getDefaultIconForCategory(imported.categoryName),
              colorValue: _getDefaultColorForCategory(imported.categoryName),
              createdAt: now,
              updatedAt: now,
            );
            final newCategory = await categoryRepo.createCategory(newCategoryModel);
            categoryId = newCategory.id;
            categoryMap[imported.categoryName.toLowerCase()] = newCategory;
            newCategories.add(imported.categoryName);
          }
        }

        // Create transaction
        final now = DateTime.now();
        final newTransaction = Transaction(
          id: 0,
          amountCents: imported.amountCents,
          currency: 'VND',
          dateTime: imported.date,
          categoryId: categoryId,
          type: imported.type,
          note: imported.note,
          createdAt: now,
          updatedAt: now,
        );
        await transactionRepo.createTransaction(newTransaction);
        
        successCount++;
      }

      // Refresh providers
      ref.invalidate(transactionsProvider);
      ref.invalidate(categoriesProvider);

      String message = l10n.importedTransactions(successCount);
      if (newCategories.isNotEmpty) {
        message += '\n${l10n.createdCategories(newCategories.length, newCategories.join(", "))}';
      }

      setState(() {
        _statusMessage = message;
        _isError = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '${l10n.importError}: ${e.toString()}';
        _isError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTemplate(String format, AppLocalizations l10n) async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      String content;
      String filename;

      if (format == 'csv') {
        content = _importExportService.getCSVTemplate();
        filename = 'template_transactions.csv';
      } else {
        content = _importExportService.getJSONTemplate();
        filename = 'template_transactions.json';
      }

      final filePath = await _importExportService.saveToFile(content, filename);

      setState(() {
        _statusMessage = '${l10n.savedTemplate}\n${l10n.fileSavedAt(filePath)}';
        _isError = false;
        _isLoading = false;
      });

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: content));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.copiedTemplateToClipboard)),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = '${l10n.error}: ${e.toString()}';
        _isError = true;
        _isLoading = false;
      });
    }
  }

  String _getDefaultIconForCategory(String categoryName) {
    final nameLower = categoryName.toLowerCase();
    // Return Material Icon keys instead of emoji for consistency
    if (nameLower.contains('ăn') || nameLower.contains('food') || nameLower.contains('eat') || 
        nameLower.contains('cơm') || nameLower.contains('sáng') || nameLower.contains('trưa') || 
        nameLower.contains('tối') || nameLower.contains('nấu')) {
      return 'restaurant';
    } else if (nameLower.contains('di chuyển') || nameLower.contains('xăng') || 
               nameLower.contains('transport') || nameLower.contains('xe') || nameLower.contains('đi lại')) {
      return 'directions_car';
    } else if (nameLower.contains('lương') || nameLower.contains('salary') || 
               nameLower.contains('income') || nameLower.contains('tiền')) {
      return 'attach_money';
    } else if (nameLower.contains('mua sắm') || nameLower.contains('shopping') || 
               nameLower.contains('shopee') || nameLower.contains('tiktok')) {
      return 'shopping_bag';
    } else if (nameLower.contains('giải trí') || nameLower.contains('entertainment') || 
               nameLower.contains('chơi') || nameLower.contains('game')) {
      return 'sports_esports';
    } else if (nameLower.contains('sức khỏe') || nameLower.contains('health') || 
               nameLower.contains('thuốc') || nameLower.contains('bệnh')) {
      return 'local_hospital';
    } else if (nameLower.contains('nhà') || nameLower.contains('home') || 
               nameLower.contains('điện') || nameLower.contains('nước')) {
      return 'home';
    } else if (nameLower.contains('công việc') || nameLower.contains('work') || 
               nameLower.contains('việc')) {
      return 'work';
    } else if (nameLower.contains('credit') || nameLower.contains('thẻ') || 
               nameLower.contains('bank') || nameLower.contains('ngân hàng')) {
      return 'credit_card';
    } else if (nameLower.contains('linh tinh') || nameLower.contains('khác') || 
               nameLower.contains('other')) {
      return 'category';
    }
    return 'shopping_cart'; // Default Material Icon
  }

  int _getDefaultColorForCategory(String categoryName) {
    final nameLower = categoryName.toLowerCase();
    if (nameLower.contains('ăn') || nameLower.contains('food')) {
      return Colors.orange.value;
    } else if (nameLower.contains('di chuyển') || nameLower.contains('xăng')) {
      return Colors.blue.value;
    } else if (nameLower.contains('lương') || nameLower.contains('salary')) {
      return Colors.green.value;
    } else if (nameLower.contains('mua sắm') || nameLower.contains('shopping')) {
      return Colors.pink.value;
    }
    return 0xFF9E9E9E; // Default light gray color
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isPrimary ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon, 
                size: 32, 
                color: isPrimary 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? Theme.of(context).colorScheme.primary : null,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
