import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'app_card.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';

/// Shimmer loading effect widget
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  static const Duration _shimmerPeriod = Duration(milliseconds: 1500);

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _shimmerPeriod,
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ??
                BorderRadius.circular(AppSpacing.radiusSm),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                0.0,
                _animation.value.clamp(0.0, 1.0),
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer loading for list items
class ShimmerListItem extends StatelessWidget {
  const ShimmerListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const ShimmerLoading(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.all(
              Radius.circular(AppSpacing.radiusLg),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                const SizedBox(height: 8),
                ShimmerLoading(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 14,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer loading for cards
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      // Matches the app card theme: the surrounding list supplies the
      // horizontal screen padding.
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(
            width: double.infinity,
            height: 20,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          ),
          const SizedBox(height: 12),
          ShimmerLoading(
            width: MediaQuery.of(context).size.width * 0.7,
            height: 16,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          ),
          const SizedBox(height: 8),
          ShimmerLoading(
            width: MediaQuery.of(context).size.width * 0.5,
            height: 16,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          ),
        ],
      ),
    );
  }
}

class SectionSkeleton extends StatefulWidget {
  final double height;
  final int lineCount;
  final Duration revealDelay;

  const SectionSkeleton({
    super.key,
    this.height = 120,
    this.lineCount = 3,
    this.revealDelay = AppMotion.normal,
  });

  @override
  State<SectionSkeleton> createState() => _SectionSkeletonState();
}

class _SectionSkeletonState extends State<SectionSkeleton> {
  Timer? _revealTimer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _revealTimer = Timer(widget.revealDelay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context)!.loading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: widget.height,
          child: Opacity(
            opacity: _visible ? 1 : 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < widget.lineCount; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.sm),
                        ShimmerLoading(
                          width: i == 0
                              ? constraints.maxWidth
                              : constraints.maxWidth * (i.isOdd ? 0.7 : 0.5),
                          height: 14,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXs),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
