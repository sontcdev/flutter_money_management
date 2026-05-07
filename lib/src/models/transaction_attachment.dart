class TransactionAttachment {
  const TransactionAttachment({
    required this.id,
    required this.workspaceId,
    required this.transactionId,
    required this.storageBucket,
    required this.storagePath,
    required this.fileName,
    this.mimeType,
    this.fileSize,
    required this.createdAt,
    this.deletedAt,
  });

  final String id;
  final String workspaceId;
  final String transactionId;
  final String storageBucket;
  final String storagePath;
  final String fileName;
  final String? mimeType;
  final int? fileSize;
  final DateTime createdAt;
  final DateTime? deletedAt;
}
