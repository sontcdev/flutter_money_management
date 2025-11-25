// path: lib/src/services/import_export_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart' as model;

/// Service để import và export giao dịch
class ImportExportService {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  /// Export giao dịch ra file CSV
  /// 
  /// Các trường trong CSV:
  /// - date: Ngày giao dịch (dd/MM/yyyy)
  /// - type: Loại giao dịch (income/expense)
  /// - amount: Số tiền (VND)
  /// - category: Tên danh mục
  /// - note: Ghi chú (optional)
  Future<String> exportToCSV(
    List<Transaction> transactions,
    List<model.Category> categories,
  ) async {
    final categoryMap = {for (var c in categories) c.id: c.name};
    
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('date,type,amount,category,note');
    
    // Data rows
    for (final txn in transactions) {
      final date = _dateFormat.format(txn.dateTime);
      final type = txn.type == TransactionType.income ? 'income' : 'expense';
      final amount = txn.amountCents ~/ 100; // Convert cents to VND
      final category = categoryMap[txn.categoryId] ?? 'Unknown';
      final note = _escapeCSV(txn.note ?? '');
      
      buffer.writeln('$date,$type,$amount,$category,$note');
    }
    
    return buffer.toString();
  }

  /// Export giao dịch ra file JSON
  Future<String> exportToJSON(
    List<Transaction> transactions,
    List<model.Category> categories,
  ) async {
    final categoryMap = {for (var c in categories) c.id: c.name};
    
    final data = {
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
      'transactions': transactions.map((txn) => {
        'date': _dateFormat.format(txn.dateTime),
        'type': txn.type == TransactionType.income ? 'income' : 'expense',
        'amount': txn.amountCents ~/ 100,
        'category': categoryMap[txn.categoryId] ?? 'Unknown',
        'note': txn.note ?? '',
      }).toList(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Lưu nội dung ra file và trả về đường dẫn
  Future<String> saveToFile(String content, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(content);
    return file.path;
  }

  /// Parse file CSV thành danh sách ImportTransaction
  /// 
  /// Format CSV yêu cầu:
  /// - Dòng đầu tiên là header
  /// - Các cột: date, type, amount, category, note
  Future<List<ImportTransaction>> parseCSV(String content) async {
    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) {
      throw ImportException('File CSV trống');
    }

    // Skip header
    final dataLines = lines.skip(1).where((line) => line.trim().isNotEmpty);
    
    final result = <ImportTransaction>[];
    int lineNumber = 1;
    
    for (final line in dataLines) {
      lineNumber++;
      try {
        final fields = _parseCSVLine(line);
        if (fields.length < 4) {
          throw ImportException('Dòng $lineNumber: Thiếu trường dữ liệu');
        }
        
        final date = _dateFormat.parse(fields[0].trim());
        final type = fields[1].trim().toLowerCase() == 'income' 
            ? TransactionType.income 
            : TransactionType.expense;
        final amount = int.parse(fields[2].trim().replaceAll(',', '').replaceAll('.', ''));
        final categoryName = fields[3].trim();
        final note = fields.length > 4 ? fields[4].trim() : '';
        
        result.add(ImportTransaction(
          date: date,
          type: type,
          amountCents: amount * 100, // Convert VND to cents
          categoryName: categoryName,
          note: note.isEmpty ? null : note,
        ));
      } catch (e) {
        if (e is ImportException) rethrow;
        throw ImportException('Dòng $lineNumber: Lỗi định dạng - ${e.toString()}');
      }
    }
    
    return result;
  }

  /// Parse file JSON thành danh sách ImportTransaction
  Future<List<ImportTransaction>> parseJSON(String content) async {
    try {
      final data = jsonDecode(content) as Map<String, dynamic>;
      final transactions = data['transactions'] as List<dynamic>;
      
      return transactions.map((txn) {
        final map = txn as Map<String, dynamic>;
        return ImportTransaction(
          date: _dateFormat.parse(map['date'] as String),
          type: map['type'] == 'income' ? TransactionType.income : TransactionType.expense,
          amountCents: (map['amount'] as int) * 100,
          categoryName: map['category'] as String,
          note: (map['note'] as String?)?.isEmpty == true ? null : map['note'] as String?,
        );
      }).toList();
    } catch (e) {
      throw ImportException('Lỗi đọc file JSON: ${e.toString()}');
    }
  }

  /// Parse một dòng CSV (xử lý dấu phẩy trong quotes)
  List<String> _parseCSVLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    
    result.add(buffer.toString());
    return result;
  }

  /// Escape string cho CSV
  String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Tạo template CSV
  String getCSVTemplate() {
    return '''date,type,amount,category,note
25/11/2024,expense,50000,Ăn uống,Ăn sáng
25/11/2024,income,10000000,Lương,Lương tháng 11
26/11/2024,expense,100000,Di chuyển,Đổ xăng
''';
  }

  /// Tạo template JSON
  String getJSONTemplate() {
    return const JsonEncoder.withIndent('  ').convert({
      'exportDate': '2024-11-25T10:00:00.000',
      'version': '1.0',
      'transactions': [
        {
          'date': '25/11/2024',
          'type': 'expense',
          'amount': 50000,
          'category': 'Ăn uống',
          'note': 'Ăn sáng',
        },
        {
          'date': '25/11/2024',
          'type': 'income',
          'amount': 10000000,
          'category': 'Lương',
          'note': 'Lương tháng 11',
        },
        {
          'date': '26/11/2024',
          'type': 'expense',
          'amount': 100000,
          'category': 'Di chuyển',
          'note': 'Đổ xăng',
        },
      ],
    });
  }
}

/// Model cho giao dịch được import
class ImportTransaction {
  final DateTime date;
  final TransactionType type;
  final int amountCents;
  final String categoryName;
  final String? note;

  ImportTransaction({
    required this.date,
    required this.type,
    required this.amountCents,
    required this.categoryName,
    this.note,
  });
}

/// Exception khi import
class ImportException implements Exception {
  final String message;
  ImportException(this.message);
  
  @override
  String toString() => message;
}
