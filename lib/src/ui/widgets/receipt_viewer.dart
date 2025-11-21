// path: lib/src/ui/widgets/receipt_viewer.dart
import 'package:flutter/material.dart';
import 'dart:io';

class ReceiptViewer extends StatelessWidget {
  final String? receiptPath;

  const ReceiptViewer({
    super.key,
    this.receiptPath,
  });

  @override
  Widget build(BuildContext context) {
    if (receiptPath == null) {
      return const SizedBox.shrink();
    }

    final file = File(receiptPath!);
    if (!file.existsSync()) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Image.file(file),
          ),
        );
      },
      child: Image.file(
        file,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}

