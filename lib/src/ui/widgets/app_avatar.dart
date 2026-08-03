// path: lib/src/ui/widgets/app_avatar.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

/// Circular initials avatar matching the Claude Design `.avatar` component.
class AppAvatar extends StatelessWidget {
  final String name;
  final double size;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.onTap,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.primarySoftDark : AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: Text(
        _initials,
        style: GoogleFonts.sora(
          color: isDark ? AppColors.primaryStrongDark : AppColors.primaryStrong,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (onTap == null) return avatar;
    return GestureDetector(
      onTap: onTap,
      child: avatar,
    );
  }
}
