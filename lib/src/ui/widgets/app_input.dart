// path: lib/src/ui/widgets/app_input.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_surface_tokens.dart';

class AppInput extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int? maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final bool showKeyboardToolbar;
  final VoidCallback? onToolbarOkPressed;
  final VoidCallback? onToolbarSkipPressed;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final AutovalidateMode? autovalidateMode;

  const AppInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.showKeyboardToolbar = true,
    this.onToolbarOkPressed,
    this.onToolbarSkipPressed,
    this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
    this.autovalidateMode,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  FocusNode? _ownedFocusNode;
  late FocusNode _focusNode;
  OverlayEntry? _overlayEntry;

  FocusNode _resolveNode() =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode = _resolveNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _resolveNode();
    if (!identical(next, _focusNode)) {
      _removeOverlay();
      _focusNode.removeListener(_onFocusChange);
      _focusNode = next;
      _focusNode.addListener(_onFocusChange);
      if (widget.focusNode != null) {
        _ownedFocusNode?.dispose();
        _ownedFocusNode = null;
      }
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && widget.showKeyboardToolbar) {
      // Delay để đợi bàn phím hiển thị
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_focusNode.hasFocus && mounted) {
          _showOverlay();
        }
      });
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final toolbarBg = Theme.of(context).scaffoldBackgroundColor;
        final okColor = AppSurfaceTokens.ensureContrast(
          colorScheme.primary,
          toolbarBg,
          toward: colorScheme.onSurface,
        );
        final skipColor = AppSurfaceTokens.ensureContrast(
          Color.alphaBlend(
              colorScheme.onSurface.withValues(alpha: 0.6), toolbarBg),
          toolbarBg,
          toward: colorScheme.onSurface,
        );
        return Positioned(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(color: colorScheme.outline, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nút "Bỏ qua"
                  TextButton(
                    onPressed: () {
                      if (widget.onToolbarSkipPressed != null) {
                        widget.onToolbarSkipPressed!();
                      }
                      _focusNode.unfocus();
                    },
                    child: Text(
                      AppLocalizations.of(context)!.skip,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: skipColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  // Nút "OK"
                  TextButton(
                    onPressed: () {
                      if (widget.onToolbarOkPressed != null) {
                        widget.onToolbarOkPressed!();
                      }
                      _focusNode.unfocus();
                    },
                    child: Text(
                      AppLocalizations.of(context)!.done,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: okColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          obscureText: widget.obscureText,
          maxLines: widget.maxLines,
          readOnly: widget.readOnly,
          focusNode: _focusNode,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          autovalidateMode: widget.autovalidateMode,
          decoration: InputDecoration(
            hintText: widget.hint,
            suffixIcon: widget.suffixIcon,
            prefixIcon: widget.prefixIcon,
          ),
        ),
      ],
    );
  }
}
