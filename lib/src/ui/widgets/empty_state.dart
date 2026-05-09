import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

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
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final EmptyStateType type;
  final bool compact;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.type = EmptyStateType.noData,
    this.compact = false,
  });

  // Convenience constructors
  const EmptyState.firstRun({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.compact = false,
  }) : type = EmptyStateType.firstRun;

  const EmptyState.noSearchResult({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.compact = false,
  }) : type = EmptyStateType.noSearchResult;

  const EmptyState.compact({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.type = EmptyStateType.noData,
  }) : compact = true;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 80.0 : 120.0;
    final iconInnerSize = compact ? 40.0 : 64.0;
    final padding = compact ? 24.0 : 32.0;

    // Reduce animation intensity for non-first-run states
    final shouldAnimate = type == EmptyStateType.firstRun;

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

            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),

            // Message with optional fade animation
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: innerSize,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
      ),
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
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add),
          label: Text(actionLabel!),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.lg : AppSpacing.xl,
              vertical: compact ? AppSpacing.md : AppSpacing.lg,
            ),
          ),
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
