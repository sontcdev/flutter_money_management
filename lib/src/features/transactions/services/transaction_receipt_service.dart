import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_money_management/src/features/transactions/repositories/transaction_attachment_repository.dart';
import 'package:flutter_money_management/src/features/transactions/models/transaction_attachment.dart';

class TransactionReceiptService {
  TransactionReceiptService(
    this._supabase,
    this._attachments,
    this._getActiveWorkspaceId,
  );

  static const receiptsBucket = 'transaction-receipts';

  final SupabaseClient _supabase;
  final TransactionAttachmentRepository _attachments;
  final String? Function() _getActiveWorkspaceId;

  Future<void> attachReceipt({
    required String transactionId,
    required String localFilePath,
    String? workspaceIdOverride,
  }) async {
    final existing =
        await _attachments.getLatestReceiptAttachmentByTransactionId(
      transactionId,
      workspaceIdOverride: workspaceIdOverride,
    );
    final uploaded = await _uploadReceipt(
      transactionId: transactionId,
      localFilePath: localFilePath,
      workspaceIdOverride: workspaceIdOverride,
    );

    try {
      await _attachments.createAttachment(
        transactionId: transactionId,
        storageBucket: uploaded.storageBucket,
        storagePath: uploaded.storagePath,
        fileName: uploaded.fileName,
        mimeType: uploaded.mimeType,
        fileSize: uploaded.fileSize,
        workspaceIdOverride: workspaceIdOverride,
      );
    } catch (_) {
      await _deleteStorageObject(
        storageBucket: uploaded.storageBucket,
        storagePath: uploaded.storagePath,
      );
      rethrow;
    }

    if (existing != null) {
      await _attachments.deleteAttachment(
        existing.id,
        workspaceIdOverride: workspaceIdOverride,
      );
      await _deleteStorageObject(
        storageBucket: existing.storageBucket,
        storagePath: existing.storagePath,
      );
    }
  }

  Future<void> removeReceipt(String transactionId,
      {String? workspaceIdOverride}) async {
    final existing =
        await _attachments.getLatestReceiptAttachmentByTransactionId(
      transactionId,
      workspaceIdOverride: workspaceIdOverride,
    );
    if (existing == null) {
      return;
    }

    await _attachments.deleteAttachment(
      existing.id,
      workspaceIdOverride: workspaceIdOverride,
    );
    await _deleteStorageObject(
      storageBucket: existing.storageBucket,
      storagePath: existing.storagePath,
    );
  }

  Future<String> createSignedReceiptUrl(TransactionAttachment attachment) {
    return _supabase.storage
        .from(attachment.storageBucket)
        .createSignedUrl(attachment.storagePath, 3600);
  }

  Future<_UploadedReceipt> _uploadReceipt({
    required String transactionId,
    required String localFilePath,
    String? workspaceIdOverride,
  }) async {
    final workspaceId = workspaceIdOverride ?? _getActiveWorkspaceId();
    if (workspaceId == null || workspaceId.isEmpty) {
      throw Exception('No active workspace selected');
    }

    final file = File(localFilePath);
    final fileName = _fileNameFromPath(localFilePath);
    final sanitizedFileName =
        fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final storagePath =
        'workspaces/$workspaceId/transactions/$transactionId/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
    final mimeType = _guessMimeType(fileName);

    await _supabase.storage.from(receiptsBucket).upload(
          storagePath,
          file,
          fileOptions: FileOptions(
            upsert: true,
            contentType: mimeType,
          ),
        );

    return _UploadedReceipt(
      storageBucket: receiptsBucket,
      storagePath: storagePath,
      fileName: fileName,
      mimeType: mimeType,
      fileSize: await file.length(),
    );
  }

  Future<void> _deleteStorageObject({
    required String storageBucket,
    required String storagePath,
  }) async {
    await _supabase.storage.from(storageBucket).remove([storagePath]);
  }

  String _fileNameFromPath(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  String _guessMimeType(String fileName) {
    final lowerFileName = fileName.toLowerCase();
    if (lowerFileName.endsWith('.png')) {
      return 'image/png';
    }
    if (lowerFileName.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lowerFileName.endsWith('.heic')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }
}

class _UploadedReceipt {
  const _UploadedReceipt({
    required this.storageBucket,
    required this.storagePath,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
  });

  final String storageBucket;
  final String storagePath;
  final String fileName;
  final String mimeType;
  final int fileSize;
}
