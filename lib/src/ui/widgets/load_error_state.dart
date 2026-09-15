import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'app_button.dart';

/// A safe, user-facing state for failed data loads.
///
/// The original exception is intentionally not accepted here so callers cannot
/// accidentally expose implementation details such as URLs or socket errors.
class LoadErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final bool compact;

  const LoadErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 64.0 : 80.0;
    final iconInnerSize = compact ? 32.0 : 40.0;
    final padding = compact ? AppSpacing.lg : AppSpacing.xl;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(
                      alpha: 0.1,
                    ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: iconInnerSize,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
            Text(
              title,
              style: (compact
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.titleLarge)
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.65),
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
            AppButton.outlined(
              text: retryLabel,
              onPressed: onRetry,
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
