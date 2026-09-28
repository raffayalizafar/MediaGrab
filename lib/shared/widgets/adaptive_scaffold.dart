import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'animated_pressable.dart';
import 'app_bottom_nav_bar.dart';

/// Adaptive scaffold following the Stitch "Visual Style Redesign" design system.
/// Features a custom 80px desktop sidebar rail and matching modern glass bottom bar.
class AdaptiveScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigationChanged;
  final List<AdaptiveDestination> destinations;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final int activeBadgeCount;

  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.destinations,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.activeBadgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAmoled = theme.scaffoldBackgroundColor == Colors.black;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 768;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        body: Row(
          children: [
            // Stitch Custom Left Sidebar Navigation Rail (w-[84px])
            Container(
              width: 84,
              decoration: BoxDecoration(
                color: isDark
                    ? (isAmoled
                          ? Colors.black
                          : AppColors.slate900.withValues(alpha: 0.85))
                    : Colors.white.withValues(alpha: 0.95),
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? (isAmoled
                              ? const Color(0xFF1E1E1E)
                              : AppColors.slate800.withValues(alpha: 0.8))
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        // Stitch Application Navigation Brand Anchor
                        AnimatedPressable(
                          onTap: () => onNavigationChanged(0),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? (isAmoled
                                        ? const Color(0xFF141414)
                                        : AppColors.slate900)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.slate800
                                    : Colors.grey.shade200,
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.4)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.auto_awesome_mosaic_rounded,
                                size: 21,
                                color: AppColors.indigo400,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Navigation Items List
                        Expanded(
                          child: Column(
                            children: List.generate(destinations.length, (i) {
                              final d = destinations[i];
                              final isSelected = i == currentIndex;
                              final hasPing = i == 1 && activeBadgeCount > 0;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: SizedBox(
                                  width: 84,
                                  height: 58,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Rail edge active indicator bar (aligned to outer left rail border)
                                      if (isSelected)
                                        Positioned(
                                          left: 0,
                                          top: 15,
                                          bottom: 15,
                                          child: Container(
                                            width: 3.5,
                                            decoration: BoxDecoration(
                                              color: AppColors.indigo400,
                                              borderRadius:
                                                  const BorderRadius.horizontal(
                                                    right: Radius.circular(3),
                                                  ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.indigo500
                                                      .withValues(alpha: 0.6),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                      // Nav Tile Button
                                      AnimatedPressable(
                                        onTap: () => onNavigationChanged(i),
                                        child: Container(
                                          width: 68,
                                          height: 58,
                                          decoration: BoxDecoration(
                                            gradient: isSelected
                                                ? LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      AppColors.indigo500
                                                          .withValues(
                                                            alpha: 0.18,
                                                          ),
                                                      AppColors.indigo600
                                                          .withValues(
                                                            alpha: 0.08,
                                                          ),
                                                    ],
                                                  )
                                                : null,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: isSelected
                                                ? Border.all(
                                                    color: AppColors.indigo500
                                                        .withValues(
                                                          alpha: 0.35,
                                                        ),
                                                    width: 1,
                                                  )
                                                : null,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  Icon(
                                                    isSelected
                                                        ? (d.selectedIcon ??
                                                              d.icon)
                                                        : d.icon,
                                                    size: 21,
                                                    color: isSelected
                                                        ? AppColors.indigo400
                                                        : (isDark
                                                              ? AppColors
                                                                    .slate400
                                                              : Colors
                                                                    .grey
                                                                    .shade600),
                                                  ),
                                                  if (hasPing)
                                                    Positioned(
                                                      top: -2,
                                                      right: -3,
                                                      child: Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration: BoxDecoration(
                                                          color:
                                                              AppColors.sky400,
                                                          shape:
                                                              BoxShape.circle,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: AppColors
                                                                  .sky400
                                                                  .withValues(
                                                                    alpha: 0.6,
                                                                  ),
                                                              blurRadius: 6,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 2,
                                                    ),
                                                child: Text(
                                                  d.label,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                                    letterSpacing: -0.2,
                                                    color: isSelected
                                                        ? (isDark
                                                              ? AppColors
                                                                    .indigo300
                                                              : theme
                                                                    .colorScheme
                                                                    .primary)
                                                        : (isDark
                                                              ? AppColors
                                                                    .slate400
                                                              : Colors
                                                                    .grey
                                                                    .shade600),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        // Bottom Engine / Status Indicator
                        Tooltip(
                          message: 'MediaGrab Engine: Online & Ready',
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? (isAmoled
                                            ? const Color(0xFF141414)
                                            : AppColors.slate800)
                                      : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? (isAmoled
                                              ? const Color(0xFF222222)
                                              : AppColors.slate700)
                                        : Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.sensors_rounded,
                                    size: 18,
                                    color: isDark
                                        ? AppColors.slate400
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.emerald400,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.emerald400.withValues(
                                        alpha: 0.6,
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.slate900
                                        : Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    // Mobile Floating Claymorphism Bottom Navigation with extendBody
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        onTap: onNavigationChanged,
        destinations: destinations,
        activeBadgeCount: activeBadgeCount,
      ),
    );
  }
}

class AdaptiveDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const AdaptiveDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}
