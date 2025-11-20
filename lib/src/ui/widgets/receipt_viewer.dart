// path: lib/src/ui/widgets/receipt_viewer.dart

import 'dart:io';
import 'package:flutter/material.dart';

class ReceiptViewer extends StatelessWidget {
  final String? receiptPath;

  const ReceiptViewer({
    Key? key,
    this.receiptPath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (receiptPath == null || receiptPath!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No receipt attached'),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        File(receiptPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Failed to load receipt'),
              ],
            ),
          );
        },
      ),
    );
  }
}

