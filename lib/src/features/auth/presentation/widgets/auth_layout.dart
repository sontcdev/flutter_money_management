import 'package:flutter/material.dart';
import 'package:flutter_money_management/src/theme/app_spacing.dart';

/// Shared scrollable, width-bounded body for auth screens.
///
/// Wraps [child] in a [SafeArea] and a [SingleChildScrollView] centered with a
/// [maxWidth]. It uses no fixed heights. The enclosing [Scaffold] already
/// resizes for the keyboard, so no extra view-inset padding is added here.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child});

  static const double maxWidth = 480;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}
