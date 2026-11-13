// path: lib/src/ui/widgets/app_button.dart

import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_surface_tokens.dart';

enum AppButtonStyle {
  filled,
  outlined,
  text,
  prominent, // For primary CTAs
}

/// Spinner color for a loading (hence disabled) [AppButton].
///
/// Filled/prominent buttons render the Material disabled fill
/// (onSurface @ 12%) over the surface or scaffold; outlined/text buttons have
/// no fill and sit directly on those backgrounds. The spinner reaches 3:1
/// against every such actual background.
Color loadingSpinnerColor(ThemeData theme, AppButtonStyle style) {
  final scheme = theme.colorScheme;
  final behind = <Color>[scheme.surface, theme.scaffoldBackgroundColor];
  final filled = style == AppButtonStyle.filled ||
      style == AppButtonStyle.prominent;
  final backgrounds = filled
      ? [
          for (final bg in behind)
            Color.alphaBlend(scheme.onSurface.withValues(alpha: 0.12), bg),
        ]
      : behind;
  return AppSurfaceTokens.ensureContrastOnAll(
    filled ? scheme.onSurface : scheme.primary,
    backgrounds,
    minRatio: 3,
    toward: scheme.onSurface,
  );
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
            textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
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
            loadingSpinnerColor(Theme.of(context), style),
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
