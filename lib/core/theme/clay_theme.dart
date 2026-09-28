import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Claymorphic theme utilities for rendering soft, tactile, inflated surfaces
/// with realistic dual-ambient shadows and rim highlights.
class ClayTheme {
  /// Generates a modern Claymorphic [BoxDecoration] with configurable depth,
  /// spread, and surface tint.
  static BoxDecoration decoration({
    required bool isDark,
    double borderRadius = 32,
    double depth = 7,
    double spread = 0.5,
    Color? color,
    BoxBorder? border,
    bool isAmoled = false,
  }) {
    // Determine base surface background
    final baseColor =
        color ??
        (isDark
            ? (isAmoled
                  ? Colors.black.withValues(alpha: 0.9)
                  : AppColors.slate900.withValues(alpha: 0.85))
            : Colors.white.withValues(alpha: 0.88));

    // Dual ambient shadows: bottom-right inflation shadow + top-left gentle reflection
    final List<BoxShadow> shadows = [];
    if (depth > 0) {
      final darkShadowColor = isDark
          ? (isAmoled
                ? Colors.black.withValues(alpha: 0.7)
                : Colors.black.withValues(alpha: 0.45))
          : const Color(0xFF0F172A).withValues(alpha: 0.09);

      final lightShadowColor = isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.white.withValues(alpha: 0.85);

      shadows.addAll([
        BoxShadow(
          color: darkShadowColor,
          offset: Offset(0, depth),
          blurRadius: depth * 2.2,
          spreadRadius: spread,
        ),
        BoxShadow(
          color: lightShadowColor,
          offset: Offset(0, -depth * 0.35),
          blurRadius: depth * 1.2,
          spreadRadius: spread,
        ),
      ]);
    }

    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border:
          border ??
          Border.all(
            color: isDark
                ? (isAmoled
                      ? const Color(0xFF242424)
                      : AppColors.slate800.withValues(alpha: 0.8))
                : Colors.white.withValues(alpha: 0.8),
            width: 1.2,
          ),
      boxShadow: shadows.isNotEmpty ? shadows : null,
    );
  }
}
