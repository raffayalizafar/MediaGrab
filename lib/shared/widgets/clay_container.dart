import 'package:flutter/material.dart';
import 'animated_pressable.dart';

/// A modern Claymorphic container featuring soft, inflated surfaces,
/// dual ambient shadows, and gentle rim highlights.
class ClayContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final double depth;
  final double spread;
  final BoxBorder? border;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Clip clipBehavior;

  const ClayContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.depth = 8.0,
    this.spread = 0.0,
    this.border,
    this.onTap,
    this.gradient,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final r = borderRadius ?? BorderRadius.circular(22);

    // Resolve base surface color
    final baseColor =
        color ??
        (isDark
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surfaceContainerLowest);

    // Claymorphism: Dark bottom/right soft shadow + light top/left subtle highlight
    final List<BoxShadow> shadows = [];
    if (depth > 0) {
      final darkShadowColor = isDark
          ? Colors.black.withValues(alpha: 0.55)
          : theme.colorScheme.shadow.withValues(alpha: 0.08);

      final lightShadowColor = isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.white.withValues(alpha: 0.9);

      shadows.addAll([
        // Bottom-right diffuse shadow (inflation effect)
        BoxShadow(
          color: darkShadowColor,
          offset: Offset(0, depth),
          blurRadius: depth * 2.2,
          spreadRadius: spread,
        ),
        // Top-left soft highlight
        BoxShadow(
          color: lightShadowColor,
          offset: Offset(0, -depth * 0.3),
          blurRadius: depth * 1.2,
          spreadRadius: spread,
        ),
      ]);
    }

    // Default gentle top rim highlight
    final defaultBorder =
        border ??
        Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.8),
          width: 1.2,
        );

    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? baseColor : null,
        gradient: gradient,
        borderRadius: r,
        boxShadow: shadows,
        border: defaultBorder,
      ),
      child: ClipRRect(
        borderRadius: r,
        clipBehavior: clipBehavior,
        child: Material(
          type: MaterialType.transparency,
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );

    if (onTap != null) {
      return AnimatedPressable(onTap: onTap, borderRadius: r, child: container);
    }

    return container;
  }
}

/// An animated claymorphic shimmer skeleton box for responsive loading states.
class ClayShimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? color;

  const ClayShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.color,
  });

  @override
  State<ClayShimmer> createState() => _ClayShimmerState();
}

class _ClayShimmerState extends State<ClayShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.35,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = widget.borderRadius ?? BorderRadius.circular(16);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final base =
            widget.color ??
            (isDark ? const Color(0xFF242730) : const Color(0xFFE2E7EE));

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: base.withValues(alpha: _animation.value),
            borderRadius: r,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.6),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.grey.shade400)
                    .withValues(alpha: 0.15 * _animation.value),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
        );
      },
    );
  }
}
