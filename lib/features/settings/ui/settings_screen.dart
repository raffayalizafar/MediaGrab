import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/clipboard_service.dart';
import '../../../core/services/system_telemetry_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/animated_pressable.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/stitch_top_bar.dart';
import '../../../shared/widgets/top_notification.dart';
import '../providers/settings_provider.dart';

/// Modernized Application Settings & Preferences screen matching Stitch specifications.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _appearanceKey = GlobalKey();
  final GlobalKey _downloadsKey = GlobalKey();
  final GlobalKey _processingKey = GlobalKey();
  final GlobalKey _engineKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();

  int _selectedCategoryIndex = 0;

  void _scrollToKey(GlobalKey key, int index) {
    setState(() => _selectedCategoryIndex = index);
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Unified Stitch TopBar
            const StitchTopBar(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Header
                        _buildHeroHeader(context),

                        const SizedBox(height: 18),

                        // Category Quick Navigation Pills
                        _buildCategoryNavigation(context),

                        const SizedBox(height: 24),

                        // Section 1: Appearance
                        Container(key: _appearanceKey),
                        _buildSectionHeader(
                          context,
                          title: 'Appearance',
                          badge: 'UI Skin: Modern Dark Glass',
                          icon: Icons.palette_outlined,
                        ),
                        const SizedBox(height: 10),
                        _buildAppearanceCard(context, settings, notifier),

                        const SizedBox(height: 28),

                        // Section 2: Download Preferences
                        Container(key: _downloadsKey),
                        _buildSectionHeader(
                          context,
                          title: 'Download Preferences',
                          badge: 'aria2c pipeline',
                          icon: Icons.download_rounded,
                        ),
                        const SizedBox(height: 10),
                        _buildDownloadsCard(context, settings, notifier),

                        const SizedBox(height: 28),

                        // Section 3: Media Processing & Metadata
                        Container(key: _processingKey),
                        _buildSectionHeader(
                          context,
                          title: 'Media Processing & Metadata',
                          badge: 'FFmpeg & Mutagen core',
                          icon: Icons.auto_awesome_rounded,
                        ),
                        const SizedBox(height: 10),
                        _buildProcessingCard(context, settings, notifier),

                        const SizedBox(height: 28),

                        // Section 4: Engine & Network
                        Container(key: _engineKey),
                        _buildSectionHeader(
                          context,
                          title: 'Engine & Network',
                          badge: 'Multi-threaded socket & network resilience',
                          icon: Icons.rocket_launch_rounded,
                        ),
                        const SizedBox(height: 10),
                        _buildEngineCard(context, settings, notifier),

                        const SizedBox(height: 28),

                        // Section 5: About
                        Container(key: _aboutKey),
                        _buildSectionHeader(
                          context,
                          title: 'About & Open Source',
                          badge: 'v${AppConstants.appVersion} Pre-release',
                          icon: Icons.info_outline_rounded,
                        ),
                        const SizedBox(height: 10),
                        _buildAboutCard(context),

                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            Text(
              'Application Settings & Preferences',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: AppColors.emerald400.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.emerald400.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 6, color: AppColors.emerald400),
                  SizedBox(width: 5),
                  Text(
                    'System Synchronized',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.emerald400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Configure engine binaries, download paths, post-processing pipelines, and interface aesthetics.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.slate400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryNavigation(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categories = [
      'Appearance',
      'Download Preferences',
      'Media Processing',
      'Engine & Network',
      'About',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(categories.length, (index) {
          final isSelected = _selectedCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: AnimatedPressable(
              onTap: () {
                if (index == 0) _scrollToKey(_appearanceKey, 0);
                if (index == 1) _scrollToKey(_downloadsKey, 1);
                if (index == 2) _scrollToKey(_processingKey, 2);
                if (index == 3) _scrollToKey(_engineKey, 3);
                if (index == 4) _scrollToKey(_aboutKey, 4);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.indigo600
                      : (isDark
                            ? AppColors.slate900.withValues(alpha: 0.8)
                            : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.indigo500
                        : (isDark ? AppColors.slate800 : Colors.grey.shade300),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.indigo600.withValues(alpha: 0.35),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  categories[index],
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.slate400 : Colors.grey.shade700),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String badge,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxTitleWidth = (constraints.maxWidth - 40).clamp(
          60.0,
          double.infinity,
        );

        return SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxTitleWidth),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: AppColors.indigo400),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.indigo400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                badge,
                style: TextStyle(
                  fontSize: 10.5,
                  fontFamily: 'monospace',
                  color: isDark ? AppColors.slate500 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppearanceCard(
    BuildContext context,
    SettingsState settings,
    SettingsNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAmoled = isDark && theme.scaffoldBackgroundColor == Colors.black;

    return _buildAcrylicContainer(
      isDark: isDark,
      isAmoled: isAmoled,
      children: [
        // Row 1: Theme Mode Segmented
        _buildSettingsRow(
          context,
          icon: Icons.brightness_6_rounded,
          iconColor: AppColors.indigo400,
          title: 'Theme Mode',
          subtitle:
              'Select your preferred window theme & ambient contrast ratio',
          isDark: isDark,
          trailing: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark
                  ? (isAmoled ? Colors.black : AppColors.slate950)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? (isAmoled ? const Color(0xFF222222) : AppColors.slate800)
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThemeSegmentButton(
                  label: 'Auto',
                  isSelected: settings.themeMode == ThemeMode.system,
                  onTap: () => notifier.setThemeMode(ThemeMode.system),
                  isDark: isDark,
                ),
                _buildThemeSegmentButton(
                  label: 'Light',
                  isSelected: settings.themeMode == ThemeMode.light,
                  onTap: () => notifier.setThemeMode(ThemeMode.light),
                  isDark: isDark,
                ),
                _buildThemeSegmentButton(
                  label: 'Dark',
                  isSelected: settings.themeMode == ThemeMode.dark,
                  onTap: () => notifier.setThemeMode(ThemeMode.dark),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),

        const Divider(height: 1),

        // Row 2: Dynamic Colors
        _buildSettingsRow(
          context,
          icon: Icons.color_lens_rounded,
          iconColor: AppColors.sky400,
          title: 'Dynamic Colors',
          subtitle: 'Match system wallpaper & accent colors seamlessly',
          isDark: isDark,
          trailing: Switch.adaptive(
            value: settings.useDynamicColor,
            activeTrackColor: AppColors.indigo500,
            onChanged: notifier.setUseDynamicColor,
          ),
        ),

        const Divider(height: 1),

        // Row 3: AMOLED Pure Black
        _buildSettingsRow(
          context,
          icon: Icons.contrast_rounded,
          iconColor: AppColors.purple400,
          title: 'AMOLED Pure Black',
          subtitle:
              'Turn off pixels on OLED displays in dark mode to save power',
          isDark: isDark,
          trailing: Switch.adaptive(
            value: settings.isAmoledDark,
            activeTrackColor: AppColors.indigo500,
            onChanged: notifier.setAmoledDark,
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadsCard(
    BuildContext context,
    SettingsState settings,
    SettingsNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAmoled = isDark && theme.scaffoldBackgroundColor == Colors.black;

    return _buildAcrylicContainer(
      isDark: isDark,
      isAmoled: isAmoled,
      children: [
        // Directory banner
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 460;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.amber400.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.folder_rounded,
                              color: AppColors.amber400,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Default Download Directory',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.slate900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Primary storage destination for completed media files',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.slate400
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isCompact) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.emerald400.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.emerald400.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                ref
                                        .watch(
                                          storageInfoProvider(
                                            settings.downloadDirectory,
                                          ),
                                        )
                                        .value ??
                                    'Storage Ready',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.emerald400,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (isCompact) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.emerald400.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.emerald400.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            ref
                                    .watch(
                                      storageInfoProvider(
                                        settings.downloadDirectory,
                                      ),
                                    )
                                    .value ??
                                'Storage Ready',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.emerald400,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              // Path banner with copy button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? (isAmoled ? Colors.black : AppColors.slate950)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? (isAmoled
                              ? const Color(0xFF222222)
                              : AppColors.slate800)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        settings.downloadDirectory.isNotEmpty
                            ? settings.downloadDirectory
                            : '~/Downloads/MediaGrab (System Sandbox Default)',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: isDark
                              ? AppColors.slate300
                              : AppColors.slate700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AnimatedPressable(
                      onTap: () {
                        ClipboardService.copyToClipboard(
                          settings.downloadDirectory,
                        );
                        TopNotification.show(
                          context,
                          message: 'Directory path copied',
                        );
                      },
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 15,
                        color: AppColors.indigo400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Folder Actions & Subfolder Information
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AnimatedPressable(
                    onTap: () async {
                      try {
                        final selected = await FilePicker.getDirectoryPath(
                          dialogTitle: 'Select Default Download Directory',
                        );
                        if (selected != null && selected.trim().isNotEmpty) {
                          await notifier.setDownloadDirectory(selected.trim());
                          if (context.mounted) {
                            TopNotification.show(
                              context,
                              message: 'Download directory updated',
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          TopNotification.show(
                            context,
                            message: 'Could not select folder: $e',
                            isError: true,
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.indigo500.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.indigo500.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.folder_open_rounded,
                            size: 14,
                            color: AppColors.indigo400,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Change Folder',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.indigo400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedPressable(
                    onTap: () async {
                      await notifier.resetDownloadDirectory();
                      if (context.mounted) {
                        TopNotification.show(
                          context,
                          message: 'Download directory reset to default',
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.restore_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.slate300
                                : AppColors.slate700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Reset to Default',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.slate300
                                  : AppColors.slate700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Organization hierarchy badges
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.video_collection_outlined,
                          size: 13,
                          color: AppColors.indigo400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'video/ for videos',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark
                                ? AppColors.slate400
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.audio_file_outlined,
                          size: 13,
                          color: AppColors.purple400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'audio/ for audio',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark
                                ? AppColors.slate400
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.playlist_play_rounded,
                          size: 14,
                          color: AppColors.sky400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'playlist subfolders',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark
                                ? AppColors.slate400
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Max Concurrent Downloads
        _buildSettingsRow(
          context,
          icon: Icons.speed_rounded,
          iconColor: AppColors.violetSeed,
          title: 'Max Concurrent Downloads',
          subtitle:
              'Simultaneous tasks queued (Optimal CPU & bandwidth balance)',
          isDark: isDark,
          trailing: AppDropdown<int>(
            title: 'Max Concurrent Downloads',
            value: settings.maxConcurrentDownloads,
            items: const [1, 2, 3, 4, 6, 8],
            itemLabel: (n) => '$n downloads',
            onChanged: notifier.setMaxConcurrentDownloads,
          ),
        ),

        const Divider(height: 1),

        // Default Video Quality
        _buildSettingsRow(
          context,
          icon: Icons.high_quality_rounded,
          iconColor: AppColors.sky400,
          title: 'Default Video Quality',
          subtitle:
              'Automatic stream target when adding new links via Quick Download',
          isDark: isDark,
          trailing: AppDropdown<String>(
            title: 'Default Video Quality',
            value: settings.defaultVideoQuality,
            items:
                AppConstants.commonResolutions.contains(
                  settings.defaultVideoQuality,
                )
                ? AppConstants.commonResolutions
                : [
                    settings.defaultVideoQuality,
                    ...AppConstants.commonResolutions,
                  ],
            itemLabel: (r) {
              if (r == '1080p') return '1080p (FHD)';
              if (r == '2160p') return '2160p (4K UHD)';
              if (r == '1440p') return '1440p (QHD)';
              if (r == '720p') return '720p (HD)';
              return r;
            },
            onChanged: notifier.setDefaultVideoQuality,
          ),
        ),

        const Divider(height: 1),

        // Default Video Format
        _buildSettingsRow(
          context,
          icon: Icons.video_file_rounded,
          iconColor: AppColors.indigo400,
          title: 'Default Video Format',
          subtitle: 'Remux container for audio/video stream merging',
          isDark: isDark,
          trailing: AppDropdown<String>(
            title: 'Default Video Format',
            value: settings.defaultVideoFormat,
            items:
                AppConstants.videoFormats.contains(settings.defaultVideoFormat)
                ? AppConstants.videoFormats
                : [settings.defaultVideoFormat, ...AppConstants.videoFormats],
            itemLabel: (f) => f.toUpperCase(),
            onChanged: notifier.setDefaultVideoFormat,
          ),
        ),

        const Divider(height: 1),

        // Default Audio Format
        _buildSettingsRow(
          context,
          icon: Icons.audio_file_rounded,
          iconColor: AppColors.roseSeed,
          title: 'Default Audio Format',
          subtitle: 'Bitrate encoder profile when extracting standalone audio',
          isDark: isDark,
          trailing: AppDropdown<String>(
            title: 'Default Audio Format',
            value: settings.defaultAudioFormat,
            items:
                AppConstants.audioFormats.contains(settings.defaultAudioFormat)
                ? AppConstants.audioFormats
                : [settings.defaultAudioFormat, ...AppConstants.audioFormats],
            itemLabel: (f) => f.toUpperCase(),
            onChanged: notifier.setDefaultAudioFormat,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingCard(
    BuildContext context,
    SettingsState settings,
    SettingsNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAmoled = isDark && theme.scaffoldBackgroundColor == Colors.black;

    return _buildAcrylicContainer(
      isDark: isDark,
      isAmoled: isAmoled,
      children: [
        // Embed Subtitles
        _buildSettingsRow(
          context,
          icon: Icons.subtitles_rounded,
          iconColor: AppColors.indigo400,
          title: 'Embed Subtitles',
          subtitle:
              'Download all available subtitle tracks and embed into container',
          isDark: isDark,
          trailing: Switch.adaptive(
            value: settings.embedSubtitles,
            activeTrackColor: AppColors.indigo500,
            onChanged: notifier.setEmbedSubtitles,
          ),
        ),

        const Divider(height: 1),

        // Embed Metadata Tags
        _buildSettingsRow(
          context,
          icon: Icons.tag_rounded,
          iconColor: AppColors.emerald400,
          title: 'Embed Metadata Tags (ID3)',
          subtitle:
              'Write artist, title, album, year, and chapter bookmarks into file',
          isDark: isDark,
          trailing: Switch.adaptive(
            value: settings.embedMetadata,
            activeTrackColor: AppColors.indigo500,
            onChanged: notifier.setEmbedMetadata,
          ),
        ),

        const Divider(height: 1),

        // Embed Thumbnail Cover
        _buildSettingsRow(
          context,
          icon: Icons.image_rounded,
          iconColor: AppColors.amber400,
          title: 'Embed Thumbnail Cover Art',
          subtitle: 'Embed high-res video thumbnail into extracted audio files',
          isDark: isDark,
          trailing: Switch.adaptive(
            value: settings.embedThumbnail,
            activeTrackColor: AppColors.indigo500,
            onChanged: notifier.setEmbedThumbnail,
          ),
        ),
      ],
    );
  }

  Widget _buildEngineCard(
    BuildContext context,
    SettingsState settings,
    SettingsNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAmoled = isDark && theme.scaffoldBackgroundColor == Colors.black;

    return _buildAcrylicContainer(
      isDark: isDark,
      isAmoled: isAmoled,
      children: [
        _buildSettingsRow(
          context,
          icon: Icons.rocket_launch_rounded,
          iconColor: AppColors.sky400,
          title: 'Use aria2c Acceleration',
          subtitle:
              'Multi-connection accelerated socket pipeline with up to 16 chunks',
          isDark: isDark,
          trailing: Switch.adaptive(
            value: settings.useAria2c,
            activeTrackColor: AppColors.indigo500,
            onChanged: notifier.setUseAria2c,
          ),
        ),
        const Divider(height: 1),
        _buildSettingsRow(
          context,
          icon: Icons.wifi_rounded,
          iconColor: AppColors.sky400,
          title: 'Download Over Wi-Fi Only',
          subtitle:
              'Automatically pauses active downloads on cellular or metered data',
          isDark: isDark,
          trailing: Switch.adaptive(
            value: settings.downloadOverWifiOnly,
            activeTrackColor: AppColors.indigo500,
            onChanged: notifier.setDownloadOverWifiOnly,
          ),
        ),
        const Divider(height: 1),
        _buildSettingsRow(
          context,
          icon: Icons.sync_rounded,
          iconColor: AppColors.emerald400,
          title: 'Auto-Resume on Reconnect',
          subtitle:
              'Automatically resumes paused tasks when internet connectivity is restored',
          isDark: isDark,
          trailing: Switch.adaptive(
            value: settings.autoResumeOnReconnect,
            activeTrackColor: AppColors.indigo500,
            onChanged: notifier.setAutoResumeOnReconnect,
          ),
        ),
        const Divider(height: 1),
        _buildSettingsRow(
          context,
          icon: Icons.speed_rounded,
          iconColor: AppColors.amber400,
          title: 'Slow Speed & Stall Alert',
          subtitle:
              'Detects connection throttling (<20 KB/s) or stalled transfers and displays alerts',
          isDark: isDark,
          trailing: Switch.adaptive(
            value: settings.slowSpeedWarning,
            activeTrackColor: AppColors.indigo500,
            onChanged: notifier.setSlowSpeedWarning,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAmoled = isDark && theme.scaffoldBackgroundColor == Colors.black;

    return _buildAcrylicContainer(
      isDark: isDark,
      isAmoled: isAmoled,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.indigo500, AppColors.indigo600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo500.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Version ${AppConstants.appVersion} • Open Source Multi-Engine Architecture',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.slate400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.indigo500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.indigo500.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'v${AppConstants.appVersion}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.indigo400,
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        _buildSettingsRow(
          context,
          icon: Icons.code_rounded,
          iconColor: AppColors.violetSeed,
          title: 'GitHub Repository',
          subtitle: 'Open-source on GitHub • Pure Dart & yt-dlp core',
          isDark: isDark,
          trailing: AnimatedPressable(
            onTap: () async {
              final uri = Uri.parse(AppConstants.githubRepo);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isDark
                    ? (isAmoled ? const Color(0xFF1E1E1E) : AppColors.slate800)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: isDark ? AppColors.slate300 : AppColors.slate700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAcrylicContainer({
    required bool isDark,
    bool isAmoled = false,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isAmoled
            ? const Color(0xFF0D0D0D)
            : (isDark
                  ? AppColors.slate900.withValues(alpha: 0.85)
                  : Colors.white),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAmoled
              ? const Color(0xFF222222)
              : (isDark ? AppColors.slate800 : Colors.grey.shade200),
          width: 1,
        ),
        boxShadow: isAmoled
            ? null
            : [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSettingsRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.slate400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }

  Widget _buildThemeSegmentButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return AnimatedPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.indigo600 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.indigo600.withValues(alpha: 0.35),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.slate400 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }
}
