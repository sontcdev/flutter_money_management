// path: lib/src/ui/widgets/keyboard_toolbar.dart

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Widget hiển thị thanh công cụ phía trên bàn phím với nút "Bỏ qua" và "OK"
class KeyboardToolbar extends StatelessWidget {
  final VoidCallback? onSkip;
  final VoidCallback? onOk;

  const KeyboardToolbar({
    super.key,
    this.onSkip,
    this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade300,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nút "Bỏ qua"
          TextButton(
            onPressed: onSkip ?? () => FocusScope.of(context).unfocus(),
            child: Text(
              l10n.skip,
              style: TextStyle(
                color: Colors.pink.shade300,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          // Nút "OK"
          TextButton(
            onPressed: onOk ?? () => FocusScope.of(context).unfocus(),
            child: Text(
              l10n.done,
              style: TextStyle(
                color: Colors.pink.shade300,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mixin để thêm keyboard toolbar cho widget
mixin KeyboardToolbarMixin<T extends StatefulWidget> on State<T> {
  OverlayEntry? _overlayEntry;
  final FocusNode _focusNode = FocusNode();

  FocusNode get keyboardToolbarFocusNode => _focusNode;

  void showKeyboardToolbar({
    VoidCallback? onSkip,
    VoidCallback? onOk,
  }) {
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 0,
        right: 0,
        child: KeyboardToolbar(
          onSkip: onSkip ??
              () {
                _focusNode.unfocus();
                hideKeyboardToolbar();
              },
          onOk: onOk ??
              () {
                _focusNode.unfocus();
                hideKeyboardToolbar();
              },
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void hideKeyboardToolbar() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // Delay để đợi bàn phím hiển thị
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_focusNode.hasFocus && mounted) {
            showKeyboardToolbar();
          }
        });
      } else {
        hideKeyboardToolbar();
      }
    });
  }

  @override
  void dispose() {
    hideKeyboardToolbar();
    _focusNode.dispose();
    super.dispose();
  }
}
