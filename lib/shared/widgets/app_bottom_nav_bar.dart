import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/clay_theme.dart';
import 'adaptive_scaffold.dart';

/// A modern, animated floating claymorphism navigation bar featuring:
/// - Animated sliding active pill indicator with spring physics
/// - Tactile icon scaling on selection
/// - Translucent backdrop blur container with opaque touch absorption
/// - Full AMOLED pure black mode support
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AdaptiveDestination>? destinations;
  final int activeBadgeCount;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.destinations,
    this.activeBadgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAmoled = isDark && theme.scaffoldBackgroundColor == Colors.black;

    // Use passed destinations or default 2-tab configuration
    final navItems =
        destinations ??
        const [
          AdaptiveDestination(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'Home',
          ),
          AdaptiveDestination(
            icon: Icons.auto_awesome_mosaic_outlined,
            selectedIcon: Icons.auto_awesome_mosaic_rounded,
            label: 'Templates',
          ),
        ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // Blocks interactions with background content behind navbar
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                height: 64,
                decoration: ClayTheme.decoration(
                  isDark: isDark,
                  isAmoled: isAmoled,
                  borderRadius: 32,
                  depth: 7,
                  spread: 0.5,
                ),
                padding: const EdgeInsets.all(5),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final count = navItems.length;
                    final tabWidth = constraints.maxWidth / count;

                    return Stack(
                      children: [
                        // Animated sliding active pill indicator
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutBack,
                          left: currentIndex.clamp(0, count - 1) * tabWidth,
                          top: 0,
                          bottom: 0,
                          width: tabWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        AppColors.brandPrimary.withValues(
                                          alpha: 0.28,
                                        ),
                                        AppColors.brandAccent.withValues(
                                          alpha: 0.18,
                                        ),
                                      ]
                                    : [
                                        AppColors.brandPrimary.withValues(
                                          alpha: 0.16,
                                        ),
                                        AppColors.brandAccentSoft.withValues(
                                          alpha: 0.25,
                                        ),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(27),
                              border: Border.all(
                                color: AppColors.brandPrimary.withValues(
                                  alpha: isDark ? 0.35 : 0.22,
                                ),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandPrimary.withValues(
                                    alpha: 0.12,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Tab buttons
                        Row(
                          children: List.generate(count, (index) {
                            final item = navItems[index];
                            final isSelected = currentIndex == index;
                            final hasPing =
                                (index == 1 && activeBadgeCount > 0);

                            return Expanded(
                              child: _NavBarTab(
                                index: index,
                                isSelected: isSelected,
                                label: item.label,
                                activeIcon: item.selectedIcon ?? item.icon,
                                inactiveIcon: item.icon,
                                hasPing: hasPing,
                                compact: count > 2,
                                onTap: () => onTap(index),
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarTab extends StatelessWidget {
  final int index;
  final bool isSelected;
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final bool hasPing;
  final bool compact;
  final VoidCallback onTap;

  const _NavBarTab({
    required this.index,
    required this.isSelected,
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    this.hasPing = false,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppColors.brandPrimary;
    final inactiveColor = isDark
        ? AppColors.darkOnSurfaceMuted
        : AppColors.lightOnSurfaceMuted;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label tab',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          splashColor: AppColors.brandPrimary.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          child: Center(
            child: compact
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedScale(
                            scale: isSelected ? 1.12 : 1.0,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutBack,
                            child: Icon(
                              isSelected ? activeIcon : inactiveIcon,
                              color: isSelected ? activeColor : inactiveColor,
                              size: 20,
                            ),
                          ),
                          if (hasPing)
                            Positioned(
                              top: -2,
                              right: -4,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: AppColors.sky400,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.sky400.withValues(
                                        alpha: 0.6,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: GoogleFonts.fraunces(
                          fontSize: 10.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? activeColor : inactiveColor,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: Text(label),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedScale(
                            scale: isSelected ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutBack,
                            child: Icon(
                              isSelected ? activeIcon : inactiveIcon,
                              color: isSelected ? activeColor : inactiveColor,
                              size: 24,
                            ),
                          ),
                          if (hasPing)
                            Positioned(
                              top: -2,
                              right: -3,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.sky400,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.sky400.withValues(
                                        alpha: 0.6,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: GoogleFonts.fraunces(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected ? activeColor : inactiveColor,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          child: Text(label),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
