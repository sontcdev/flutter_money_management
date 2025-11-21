// path: lib/src/ui/widgets/app_input.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppInput extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final bool readOnly;

  const AppInput({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.validator,
    this.inputFormatters,
    this.suffixIcon,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

