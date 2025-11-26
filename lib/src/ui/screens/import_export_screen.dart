// path: lib/src/ui/screens/import_export_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/import_export_service.dart';
import '../../providers/providers.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import / Export'),
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
              'Export dữ liệu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Xuất tất cả giao dịch ra file để sao lưu hoặc chuyển sang thiết bị khác.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.table_chart,
                    title: 'Export CSV',
                    subtitle: 'Mở được bằng Excel',
                    onTap: _isLoading ? null : () => _exportData('csv'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.code,
                    title: 'Export JSON',
                    subtitle: 'Định dạng chuẩn',
                    onTap: _isLoading ? null : () => _exportData('json'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Import Section
            Text(
              'Import dữ liệu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhập giao dịch từ file CSV hoặc JSON. Danh mục mới sẽ được tự động tạo.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Import from File buttons
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.upload_file,
                    title: 'Import từ File',
                    subtitle: 'Chọn file .csv hoặc .json',
                    onTap: _isLoading ? null : _pickAndImportFile,
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
                    title: 'Dán CSV',
                    subtitle: 'Từ clipboard',
                    onTap: _isLoading ? null : () => _showImportDialog('csv'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.content_paste,
                    title: 'Dán JSON',
                    subtitle: 'Từ clipboard',
                    onTap: _isLoading ? null : () => _showImportDialog('json'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Template Section
            Text(
              'Template mẫu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tải template mẫu để biết định dạng file import.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.download,
                    title: 'Template CSV',
                    subtitle: 'Tải file mẫu',
                    onTap: _isLoading ? null : () => _saveTemplate('csv'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.download,
                    title: 'Template JSON',
                    subtitle: 'Tải file mẫu',
                    onTap: _isLoading ? null : () => _saveTemplate('json'),
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
                          'Hướng dẫn định dạng',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFormatRow('date', 'Ngày giao dịch (dd/MM/yyyy)'),
                    _buildFormatRow('type', 'income hoặc expense'),
                    _buildFormatRow('amount', 'Số tiền (VND, không có dấu)'),
                    _buildFormatRow('category', 'Tên danh mục'),
                    _buildFormatRow('note', 'Ghi chú (không bắt buộc)'),
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

  Future<void> _pickAndImportFile() async {
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
          _statusMessage = 'Không thể đọc file';
          _isError = true;
          _isLoading = false;
        });
        return;
      }

      final content = await File(file.path!).readAsString();
      final extension = file.extension?.toLowerCase() ?? '';

      if (extension == 'csv') {
        await _importData(content, 'csv');
      } else if (extension == 'json') {
        await _importData(content, 'json');
      } else {
        setState(() {
          _statusMessage = 'Định dạng file không được hỗ trợ. Vui lòng chọn file .csv hoặc .json';
          _isError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi đọc file: ${e.toString()}';
        _isError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportData(String format) async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final transactions = await ref.read(transactionsProvider.future);
      final categories = await ref.read(categoriesProvider.future);

      if (transactions.isEmpty) {
        setState(() {
          _statusMessage = 'Không có giao dịch nào để export';
          _isError = true;
          _isLoading = false;
        });
        return;
      }

      String content;
      String filename;
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      if (format == 'csv') {
        content = await _importExportService.exportToCSV(transactions, categories);
        filename = 'transactions_$timestamp.csv';
      } else {
        content = await _importExportService.exportToJSON(transactions, categories);
        filename = 'transactions_$timestamp.json';
      }

      final filePath = await _importExportService.saveToFile(content, filename);

      setState(() {
        _statusMessage = 'Đã export ${transactions.length} giao dịch\nFile: $filePath';
        _isError = false;
        _isLoading = false;
      });

      // Show share dialog
      _showExportSuccessDialog(filePath, content);
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi export: ${e.toString()}';
        _isError = true;
        _isLoading = false;
      });
    }
  }

  void _showExportSuccessDialog(String filePath, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export thành công'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File đã được lưu tại:\n$filePath'),
            const SizedBox(height: 16),
            const Text('Bạn muốn làm gì tiếp?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã copy nội dung vào clipboard')),
              );
            },
            child: const Text('Copy nội dung'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(String format) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import từ ${format.toUpperCase()}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dán nội dung file vào đây:'),
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
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _importData(controller.text, format);
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _importData(String content, String format) async {
    if (content.trim().isEmpty) {
      setState(() {
        _statusMessage = 'Nội dung trống';
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
          _statusMessage = 'Không có giao dịch nào để import';
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

      String message = 'Đã import $successCount giao dịch';
      if (newCategories.isNotEmpty) {
        message += '\nĐã tạo ${newCategories.length} danh mục mới: ${newCategories.join(", ")}';
      }

      setState(() {
        _statusMessage = message;
        _isError = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi import: ${e.toString()}';
        _isError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTemplate(String format) async {
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
        _statusMessage = 'Đã lưu template\nFile: $filePath';
        _isError = false;
        _isLoading = false;
      });

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: content));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã copy template vào clipboard')),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi: ${e.toString()}';
        _isError = true;
        _isLoading = false;
      });
    }
  }

  String _getDefaultIconForCategory(String categoryName) {
    final nameLower = categoryName.toLowerCase();
    if (nameLower.contains('ăn') || nameLower.contains('food') || nameLower.contains('eat')) {
      return '🍔';
    } else if (nameLower.contains('di chuyển') || nameLower.contains('xăng') || nameLower.contains('transport')) {
      return '🚗';
    } else if (nameLower.contains('lương') || nameLower.contains('salary') || nameLower.contains('income')) {
      return '💰';
    } else if (nameLower.contains('mua sắm') || nameLower.contains('shopping')) {
      return '🛍️';
    } else if (nameLower.contains('giải trí') || nameLower.contains('entertainment')) {
      return '🎮';
    } else if (nameLower.contains('sức khỏe') || nameLower.contains('health')) {
      return '🏥';
    }
    return '📦';
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
    return Colors.grey.value;
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
