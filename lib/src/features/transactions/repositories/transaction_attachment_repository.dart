import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_money_management/src/features/transactions/models/transaction_attachment.dart';

class TransactionAttachmentRepository {
  TransactionAttachmentRepository(
    this._supabase,
    this._getActiveWorkspaceId,
    this._getCurrentUserId,
  );

  final SupabaseClient _supabase;
  final String? Function() _getActiveWorkspaceId;
  final String? Function() _getCurrentUserId;
  final _uuid = const Uuid();

  Future<TransactionAttachment?> getLatestReceiptAttachmentByTransactionId(
    String transactionId,
  ) async {
    final workspaceId = _requireWorkspaceId();
    final response = await _supabase
        .from('transaction_attachments')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('transaction_id', transactionId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return _mapAttachment(response);
  }

  Future<TransactionAttachment> createAttachment({
    required String transactionId,
    required String storageBucket,
    required String storagePath,
    required String fileName,
    String? mimeType,
    int? fileSize,
  }) async {
    final workspaceId = _requireWorkspaceId();
    final userId = _requireUserId();
    final id = _uuid.v4();

    await _supabase.from('transaction_attachments').insert({
      'id': id,
      'workspace_id': workspaceId,
      'transaction_id': transactionId,
      'storage_bucket': storageBucket,
      'storage_path': storagePath,
      'file_name': fileName,
      'mime_type': mimeType,
      'file_size': fileSize,
      'uploaded_by_user_id': userId,
    });

    return TransactionAttachment(
      id: id,
      workspaceId: workspaceId,
      transactionId: transactionId,
      storageBucket: storageBucket,
      storagePath: storagePath,
      fileName: fileName,
      mimeType: mimeType,
      fileSize: fileSize,
      createdAt: DateTime.now(),
    );
  }

  Future<void> deleteAttachment(String attachmentId) async {
    final workspaceId = _requireWorkspaceId();
    await _supabase
        .from('transaction_attachments')
        .delete()
        .eq('workspace_id', workspaceId)
        .eq('id', attachmentId);
  }

  TransactionAttachment _mapAttachment(Map<String, dynamic> item) {
    return TransactionAttachment(
      id: item['id'] as String,
      workspaceId: item['workspace_id'] as String,
      transactionId: item['transaction_id'] as String,
      storageBucket: item['storage_bucket'] as String,
      storagePath: item['storage_path'] as String,
      fileName: item['file_name'] as String,
      mimeType: item['mime_type'] as String?,
      fileSize: item['file_size'] as int?,
      createdAt: DateTime.parse(item['created_at'] as String),
      deletedAt: item['deleted_at'] != null
          ? DateTime.parse(item['deleted_at'] as String)
          : null,
    );
  }

  String _requireWorkspaceId() {
    final workspaceId = _getActiveWorkspaceId();
    if (workspaceId == null || workspaceId.isEmpty) {
      throw Exception('No active workspace selected');
    }
    return workspaceId;
  }

  String _requireUserId() {
    final userId = _getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('No authenticated user');
    }
    return userId;
  }
}
