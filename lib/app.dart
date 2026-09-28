import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/downloads/ui/downloads_screen.dart';
import 'features/home/ui/home_screen.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/settings/ui/settings_screen.dart';
import 'features/splash/ui/splash_screen.dart';
import 'features/templates/ui/templates_screen.dart';
import 'shared/widgets/adaptive_scaffold.dart';

/// Root Application widget configuring Material 3, Dynamic Colors, and Navigation.
class MediaGrabApp extends ConsumerWidget {
  final bool showSplash;

  const MediaGrabApp({super.key, this.showSplash = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final lightTheme = AppTheme.light(
          dynamicColorScheme: settings.useDynamicColor ? lightDynamic : null,
        );
        final darkTheme = AppTheme.dark(
          dynamicColorScheme: settings.useDynamicColor ? darkDynamic : null,
          isAmoled: settings.isAmoledDark,
        );

        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: settings.themeMode,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: showSplash ? const SplashScreen() : const MainNavigationShell(),
        );
      },
    );
  }
}

/// Provider to control active navigation tab index across the app.
final activeTabProvider = StateProvider<int>((ref) => 0);

/// Navigation Shell hosting Bottom Navigation on Mobile and Navigation Rail on Desktop.
class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({super.key});

  final List<Widget> _screens = const [
    HomeScreen(),
    DownloadsScreen(),
    TemplatesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(activeTabProvider);

    return AdaptiveScaffold(
      currentIndex: currentIndex,
      onNavigationChanged: (index) {
        ref.read(activeTabProvider.notifier).state = index;
      },
      destinations: const [
        AdaptiveDestination(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          label: 'Home',
        ),
        AdaptiveDestination(
          icon: Icons.download_outlined,
          selectedIcon: Icons.download_rounded,
          label: 'Downloads',
        ),
        AdaptiveDestination(
          icon: Icons.terminal_outlined,
          selectedIcon: Icons.terminal_rounded,
          label: 'Templates',
        ),
        AdaptiveDestination(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings_rounded,
          label: 'Settings',
        ),
      ],
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slideIn = Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slideIn, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(currentIndex),
          child: _screens[currentIndex],
        ),
      ),
    );
  }
}
