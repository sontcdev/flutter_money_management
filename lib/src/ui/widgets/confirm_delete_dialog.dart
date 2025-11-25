// path: lib/src/ui/widgets/confirm_delete_dialog.dart

import 'package:flutter/material.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String? title;
  final String? message;

  const ConfirmDeleteDialog({
    super.key,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? 'Xác nhận xóa'),
      content: Text(message ?? 'Bạn có chắc chắn muốn xóa giao dịch này?'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Hủy',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('Xóa'),
        ),
      ],
    );
  }
}

