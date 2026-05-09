// path: lib/src/ui/widgets/app_button.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

enum AppButtonStyle {
  filled,
  outlined,
  text,
  prominent, // For primary CTAs
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style = AppButtonStyle.filled,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
  });

  // Convenience constructors
  const AppButton.outlined({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
  }) : style = AppButtonStyle.outlined;

  const AppButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
  }) : style = AppButtonStyle.text;

  const AppButton.prominent({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
  }) : style = AppButtonStyle.prominent;

  @override
  Widget build(BuildContext context) {
    final button = _buildButton(context);

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Widget _buildButton(BuildContext context) {
    switch (style) {
      case AppButtonStyle.outlined:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildChild(context),
        );
      case AppButtonStyle.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildChild(context),
        );
      case AppButtonStyle.prominent:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          child: _buildChild(context),
        );
      case AppButtonStyle.filled:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildChild(context),
        );
    }
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            style == AppButtonStyle.outlined || style == AppButtonStyle.text
                ? Theme.of(context).colorScheme.primary
                : AppColors.textLight,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.iconSizeSm),
          const SizedBox(width: AppSpacing.sm),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}
