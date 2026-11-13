import 'package:flutter/material.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_surface_tokens.dart';

enum EmptyStateType {
  firstRun, // First-run onboarding style
  noData, // General no data state
  noSearchResult, // Search returned no results
  noFilterResult, // Filter returned no results
}

/// Reusable empty state widget with friendly messages
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final EmptyStateType type;
  final bool compact;

  /// Renders the primary action as an outlined button (de-emphasized).
  final bool outlinedAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.add,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.type = EmptyStateType.noData,
    this.compact = false,
    this.outlinedAction = false,
  });

  // Convenience constructors
  const EmptyState.firstRun({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.add,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.compact = false,
    this.outlinedAction = false,
  }) : type = EmptyStateType.firstRun;

  const EmptyState.noSearchResult({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.add,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.compact = false,
    this.outlinedAction = false,
  }) : type = EmptyStateType.noSearchResult;

  const EmptyState.compact({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.add,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.type = EmptyStateType.noData,
  })  : compact = true,
        outlinedAction = false;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 80.0 : 120.0;
    final iconInnerSize = compact ? 40.0 : 64.0;
    final padding = compact ? 24.0 : 32.0;

    // Reduce animation intensity for non-first-run states
    final shouldAnimate =
        type == EmptyStateType.firstRun && !AppMotion.reduced(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with optional animation
            if (shouldAnimate)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: _buildIcon(context, iconSize, iconInnerSize),
              )
            else
              _buildIcon(context, iconSize, iconInnerSize),

            SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),

            // Title with optional fade animation
            if (shouldAnimate)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: _buildTitle(context),
              )
            else
              _buildTitle(context),

            // Message with optional fade animation
            if (message.isNotEmpty) ...[
              SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
              if (shouldAnimate)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: _buildMessage(context),
                )
              else
                _buildMessage(context),
            ],

            // Action buttons
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xxl),
              if (shouldAnimate)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: child,
                      ),
                    );
                  },
                  child: _buildActions(context),
                )
              else
                _buildActions(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, double size, double innerSize) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final page = theme.scaffoldBackgroundColor;
    final tint = Color.alphaBlend(scheme.primary.withValues(alpha: 0.1), page);
    final iconColor = AppSurfaceTokens.ensureContrast(
      Color.alphaBlend(scheme.primary.withValues(alpha: 0.6), tint),
      tint,
      minRatio: 3,
      toward: scheme.onSurface,
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: innerSize, color: iconColor),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      title,
      style: (compact
              ? Theme.of(context).textTheme.titleLarge
              : Theme.of(context).textTheme.headlineSmall)
          ?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final messageColor = AppSurfaceTokens.ensureContrastOnAll(
      Color.alphaBlend(scheme.onSurface.withValues(alpha: 0.6),
          theme.scaffoldBackgroundColor),
      [theme.scaffoldBackgroundColor, scheme.surface],
      toward: scheme.onSurface,
    );
    return Text(
      message,
      style: theme.textTheme.bodyMedium?.copyWith(color: messageColor),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActions(BuildContext context) {
    final actionPadding = EdgeInsets.symmetric(
      horizontal: compact ? AppSpacing.lg : AppSpacing.xl,
      vertical: compact ? AppSpacing.md : AppSpacing.lg,
    );
    return Column(
      children: [
        if (outlinedAction)
          OutlinedButton.icon(
            onPressed: onAction,
            icon: Icon(actionIcon),
            label: Text(actionLabel!),
            style: OutlinedButton.styleFrom(padding: actionPadding),
          )
        else
          ElevatedButton.icon(
            onPressed: onAction,
            icon: Icon(actionIcon),
            label: Text(actionLabel!),
            style: ElevatedButton.styleFrom(padding: actionPadding),
          ),
        if (secondaryActionLabel != null && onSecondaryAction != null) ...[
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: onSecondaryAction,
            child: Text(secondaryActionLabel!),
          ),
        ],
      ],
    );
  }
}
