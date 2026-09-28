import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/animated_pressable.dart';
import '../../../shared/widgets/stitch_top_bar.dart';
import '../../../shared/widgets/top_notification.dart';
import '../../../shared/widgets/url_input_field.dart';
import '../../downloads/providers/download_manager.dart';
import '../../downloads/ui/download_card.dart';
import '../../templates/models/command_template.dart';
import '../../templates/providers/template_provider.dart';
import '../providers/home_provider.dart';
import 'media_config_sheet.dart';

/// Main Home Screen featuring the Stitch "Modernized MediaGrab" design.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// Instantly opens the configuration sheet and initiates metadata resolution.
  void _onUrlSubmitted(String url) {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      _showSnack('Please paste a video or audio link first', isError: true);
      return;
    }

    ref.read(homeProvider.notifier).setUrl(cleanUrl);
    ref.read(homeProvider.notifier).fetchInfo(cleanUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MediaConfigSheet(),
    ).whenComplete(() {
      if (ref.read(homeProvider).status == HomeStateStatus.fetchingInfo) {
        ref.read(homeProvider.notifier).cancelFetch();
      }
    });
  }

  void _showSnack(
    String msg, {
    String? actionLabel,
    VoidCallback? onAction,
    bool isError = false,
  }) {
    if (!mounted) return;
    TopNotification.show(
      context,
      message: msg,
      actionLabel: actionLabel,
      onAction: onAction,
      isError: isError,
    );
  }

  Future<void> _handleQuickDownload() async {
    final cleanUrl = _urlController.text.trim();
    if (cleanUrl.isEmpty) {
      _showSnack(
        'Please paste a video or audio link to download',
        isError: true,
      );
      return;
    }

    final homeNotifier = ref.read(homeProvider.notifier);
    await homeNotifier.quickDownload(cleanUrl);
    if (mounted && ref.read(homeProvider).status != HomeStateStatus.error) {
      _showSnack(
        'Download started in background!',
        actionLabel: 'VIEW',
        onAction: () {
          ref.read(activeTabProvider.notifier).state = 1;
        },
      );
    }
  }

  Future<void> _applyTemplate(CommandTemplate template) async {
    final cleanUrl = _urlController.text.trim();
    if (cleanUrl.isEmpty) {
      _showSnack('Please paste a link first to apply "${template.name}"');
      return;
    }

    final homeNotifier = ref.read(homeProvider.notifier);
    await homeNotifier.fetchInfo(cleanUrl);
    if (mounted && ref.read(homeProvider).status == HomeStateStatus.ready) {
      await homeNotifier.startDownload(customArgs: template.templateArgs);
      _showSnack(
        'Downloading with "${template.name}"!',
        actionLabel: 'VIEW',
        onAction: () {
          ref.read(activeTabProvider.notifier).state = 1;
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final homeNotifier = ref.read(homeProvider.notifier);
    final downloadState = ref.watch(downloadManagerProvider);
    final templates = ref.watch(templateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAmoled = theme.scaffoldBackgroundColor == Colors.black;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Stitch TopBar Sticky Header
            StitchTopBar(
              trailing: downloadState.activeTasks.isNotEmpty
                  ? AnimatedPressable(
                      onTap: () {
                        ref.read(activeTabProvider.notifier).state = 1;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.indigo500.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.downloading_rounded,
                              size: 16,
                              color: AppColors.indigo400,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${downloadState.activeTasks.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.indigo400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
            ),

            // Scrollable Content Area with Ambient Radial Glows
            Expanded(
              child: Stack(
                children: [
                  // Ambient Decorative Gradients (subtle in dark, disabled in AMOLED for true pitch black)
                  if (isDark && !isAmoled) ...[
                    // Ambient glow top-left (indigo & sky)
                    Positioned(
                      top: -120,
                      left: 40,
                      width: 550,
                      height: 420,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.indigo500.withValues(alpha: 0.12),
                                AppColors.sky400.withValues(alpha: 0.04),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.45, 0.8],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Ambient glow bottom-right (violet)
                    Positioned(
                      bottom: -100,
                      right: 20,
                      width: 500,
                      height: 400,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.75],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Main Scrollable Body
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Hero Downloader Card (Stitch Primary Downloader Card)
                            _buildHeroDownloaderCard(
                              context,
                              homeState,
                              homeNotifier,
                            ),

                            // 2. Active Downloads Section (when any active tasks exist)
                            if (downloadState.activeTasks.isNotEmpty) ...[
                              const SizedBox(height: 32),
                              _buildActiveDownloadsSection(
                                context,
                                downloadState,
                              ),
                            ],

                            // 3. Quick Templates Section (Stitch 5 Curated Batch Presets)
                            const SizedBox(height: 36),
                            _buildQuickTemplatesSection(context, templates),

                            // 4. Supported Platforms & Engines Section
                            const SizedBox(height: 36),
                            _buildSupportedPlatformsSection(context),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Stitch Primary Hero Downloader Card with Hairline Top Accent & Glow.
  Widget _buildHeroDownloaderCard(
    BuildContext context,
    HomeState homeState,
    HomeNotifier homeNotifier,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAmoled = theme.scaffoldBackgroundColor == Colors.black;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? (isAmoled
                    ? [
                        const Color(0xFF0E0E0E),
                        const Color(0xFF080808),
                        const Color(0xFF0E0E0E),
                      ]
                    : [
                        AppColors.slate900.withValues(alpha: 0.95),
                        AppColors.slate900.withValues(alpha: 0.6),
                        AppColors.slate900.withValues(alpha: 0.85),
                      ])
              : [Colors.white, Colors.grey.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark
              ? (isAmoled
                    ? const Color(0xFF222222)
                    : AppColors.slate800.withValues(alpha: 0.85))
              : Colors.grey.shade200,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF030712).withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Hairline top gradient accent line
          Positioned(
            top: 0,
            left: 32,
            right: 32,
            child: Container(
              height: 1.2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.indigo500.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Sparkle Icon Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.indigo500, AppColors.indigo600],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.indigo500.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.cloud_download_rounded,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Download Any Video or Audio',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Paste links from YouTube, TikTok, Instagram, Twitter/X, and 1,800+ supported sites.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark
                                  ? AppColors.slate400
                                  : Colors.grey.shade600,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Stitch URL Input Bar
                UrlInputField(
                  controller: _urlController,
                  isBusy: homeState.status == HomeStateStatus.fetchingInfo,
                  errorText: homeState.errorMessage,
                  onSubmitted: _onUrlSubmitted,
                  onPaste: () {
                    if (_urlController.text.isNotEmpty) {
                      _onUrlSubmitted(_urlController.text);
                    }
                  },
                  onClear: () {
                    homeNotifier.reset();
                  },
                ),

                const SizedBox(height: 16),

                // Dual Action Buttons: Configure vs Quick Download
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 620;

                    final configureBtn = AnimatedPressable(
                      onTap: () => _onUrlSubmitted(_urlController.text),
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.slate800.withValues(alpha: 0.8)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.slate700.withValues(alpha: 0.7)
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.slate300
                                  : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Configure Formats & Quality',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.slate200
                                      : Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    final quickBtn = AnimatedPressable(
                      onTap: homeState.isQuickLoading
                          ? null
                          : _handleQuickDownload,
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.indigo600,
                              AppColors.indigo500,
                              AppColors.sky500,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.indigo500.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: homeState.isQuickLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Processing...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.bolt_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Quick Download',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          quickBtn,
                          const SizedBox(height: 10),
                          configureBtn,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: configureBtn),
                        const SizedBox(width: 14),
                        Expanded(child: quickBtn),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Active Downloads live cards section.
  Widget _buildActiveDownloadsSection(
    BuildContext context,
    DownloadManagerState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Active Downloads',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${state.activeTasks.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.indigo400,
                    ),
                  ),
                ),
              ],
            ),
            AnimatedPressable(
              onTap: () {
                ref.read(activeTabProvider.notifier).state = 1;
              },
              child: Row(
                children: const [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.indigo400,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.indigo400,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...state.activeTasks.map(
          (task) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: ActiveDownloadCard(
              task: task,
              onCancel: () => ref
                  .read(downloadManagerProvider.notifier)
                  .cancelTask(task.id),
              onRetry: () =>
                  ref.read(downloadManagerProvider.notifier).retryTask(task.id),
            ),
          ),
        ),
      ],
    );
  }

  /// Stitch Quick Templates 5-Preset Cards Section.
  Widget _buildQuickTemplatesSection(
    BuildContext context,
    List<CommandTemplate> templates,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title Bar
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 2,
                children: [
                  const Text(
                    'Quick Templates',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    '1-Click Automation',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      color: isDark ? AppColors.slate500 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              AnimatedPressable(
                onTap: () {
                  ref.read(activeTabProvider.notifier).state = 2;
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Power-User Presets',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.indigo400,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: AppColors.indigo400,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Responsive Cards Grid / Scrollable Row
        LayoutBuilder(
          builder: (context, constraints) {
            // If wide enough (desktop >= 1050px), show all 5 columns side-by-side
            if (constraints.maxWidth >= 1050) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(templates.length.clamp(0, 5), (i) {
                  final t = templates[i];
                  final meta = _TemplateVisualMeta.fromTemplate(t, isDark);
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i < templates.length - 1 ? 12.0 : 0.0,
                      ),
                      child: _buildTemplateCard(t, meta, isDark),
                    ),
                  );
                }),
              );
            }

            // On smaller screens, horizontally scrollable row of cards
            return SizedBox(
              height: 148,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: templates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final t = templates[i];
                  final meta = _TemplateVisualMeta.fromTemplate(t, isDark);
                  return SizedBox(
                    width: 205,
                    child: _buildTemplateCard(t, meta, isDark),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  /// Individual Stitch Quick Template Card.
  Widget _buildTemplateCard(
    CommandTemplate template,
    _TemplateVisualMeta meta,
    bool isDark,
  ) {
    return AnimatedPressable(
      onTap: () => _applyTemplate(template),
      child: Container(
        height: 148,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.slate900.withValues(alpha: 0.6)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.slate800 : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + Badge Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: meta.iconBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: meta.iconBorder, width: 1),
                      ),
                      child: Icon(meta.icon, size: 16, color: meta.iconColor),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: meta.badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        meta.badgeText,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: meta.badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  template.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),

                // Description
                Text(
                  template.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? AppColors.slate400 : Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),

            // Card Bottom Bar
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.slate800.withValues(alpha: 0.7)
                        : Colors.grey.shade200,
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      meta.footerLeft,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.slate500
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    meta.footerRight,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: meta.footerColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Stitch Supported Platforms & Engines Section.
  Widget _buildSupportedPlatformsSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'SUPPORTED PLATFORMS & ENGINES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.slate400 : Colors.grey.shade600,
                ),
              ),
              Text(
                'Auto-detected upon pasting',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.slate500 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Brand Pills Wrap
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildPlatformPill(
              icon: Icons.play_circle_fill,
              label: 'YouTube',
              iconColor: const Color(0xFFFF0000),
              isDark: isDark,
            ),
            _buildPlatformPill(
              icon: Icons.music_video,
              label: 'TikTok',
              iconColor: const Color(0xFF38BDF8),
              isDark: isDark,
            ),
            _buildPlatformPill(
              icon: Icons.camera_alt,
              label: 'Instagram',
              iconColor: const Color(0xFFEC4899),
              isDark: isDark,
            ),
            _buildPlatformPill(
              icon: Icons.tag,
              label: 'Twitter / X',
              iconColor: isDark ? AppColors.slate300 : Colors.grey.shade800,
              isDark: isDark,
            ),
            _buildPlatformPill(
              icon: Icons.forum_rounded,
              label: 'Reddit',
              iconColor: const Color(0xFFF97316),
              isDark: isDark,
            ),
            _buildPlatformPill(
              icon: Icons.live_tv_rounded,
              label: 'Twitch',
              iconColor: const Color(0xFFA855F7),
              isDark: isDark,
            ),
            // 1,800+ more pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.indigo500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 14,
                    color: AppColors.indigo400,
                  ),
                  SizedBox(width: 6),
                  Text(
                    '1,800+ more',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.indigo300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlatformPill({
    required IconData icon,
    required String label,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.slate900.withValues(alpha: 0.8)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.slate800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: isDark ? AppColors.slate200 : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper data class for styling the 5 Stitch preset cards.
class _TemplateVisualMeta {
  final String badgeText;
  final Color badgeColor;
  final Color badgeBg;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color iconBorder;
  final String footerLeft;
  final String footerRight;
  final Color footerColor;

  const _TemplateVisualMeta({
    required this.badgeText,
    required this.badgeColor,
    required this.badgeBg,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.iconBorder,
    required this.footerLeft,
    required this.footerRight,
    required this.footerColor,
  });

  /// Dynamically computes theme-consistent visual metadata based on template traits.
  static _TemplateVisualMeta fromTemplate(
    CommandTemplate template,
    bool isDark,
  ) {
    final lower = template.name.toLowerCase();
    if (lower.contains('audio') || lower.contains('mp3')) {
      return _TemplateVisualMeta(
        badgeText: 'AUDIO',
        badgeColor: AppColors.emerald400,
        badgeBg: isDark
            ? const Color(0xFF064E3B).withValues(alpha: 0.5)
            : const Color(0xFFD1FAE5),
        icon: Icons.headphones_rounded,
        iconColor: AppColors.emerald400,
        iconBg: AppColors.emerald400.withValues(alpha: 0.1),
        iconBorder: AppColors.emerald400.withValues(alpha: 0.2),
        footerLeft: 'Lossless audio',
        footerRight: 'Apply preset',
        footerColor: AppColors.emerald400,
      );
    } else if (lower.contains('batch') || lower.contains('playlist')) {
      return _TemplateVisualMeta(
        badgeText: 'BATCH',
        badgeColor: AppColors.sky400,
        badgeBg: isDark ? AppColors.slate800 : Colors.grey.shade200,
        icon: Icons.folder_copy_outlined,
        iconColor: AppColors.sky400,
        iconBg: AppColors.sky400.withValues(alpha: 0.1),
        iconBorder: AppColors.sky400.withValues(alpha: 0.2),
        footerLeft: 'Multi-stream',
        footerRight: 'Apply preset',
        footerColor: AppColors.sky400,
      );
    } else if (lower.contains('sponsor') || lower.contains('filter')) {
      return _TemplateVisualMeta(
        badgeText: 'FILTER',
        badgeColor: AppColors.amber400,
        badgeBg: isDark
            ? const Color(0xFF78350F).withValues(alpha: 0.4)
            : const Color(0xFFFEF3C7),
        icon: Icons.shield_outlined,
        iconColor: AppColors.amber400,
        iconBg: AppColors.amber400.withValues(alpha: 0.1),
        iconBorder: AppColors.amber400.withValues(alpha: 0.2),
        footerLeft: 'Clean cut',
        footerRight: 'Apply preset',
        footerColor: AppColors.amber400,
      );
    } else if (lower.contains('speed') ||
        lower.contains('aria2c') ||
        lower.contains('fast')) {
      return _TemplateVisualMeta(
        badgeText: 'SPEED',
        badgeColor: AppColors.purple400,
        badgeBg: isDark
            ? const Color(0xFF581C87).withValues(alpha: 0.5)
            : const Color(0xFFF3E8FF),
        icon: Icons.rocket_launch_outlined,
        iconColor: AppColors.purple400,
        iconBg: AppColors.purple400.withValues(alpha: 0.1),
        iconBorder: AppColors.purple400.withValues(alpha: 0.2),
        footerLeft: 'Multi-thread',
        footerRight: 'Apply preset',
        footerColor: AppColors.purple400,
      );
    } else {
      return _TemplateVisualMeta(
        badgeText: 'VIDEO',
        badgeColor: AppColors.indigo400,
        badgeBg: isDark ? AppColors.slate800 : Colors.grey.shade200,
        icon: Icons.movie_outlined,
        iconColor: Colors.blue.shade400,
        iconBg: Colors.blue.withValues(alpha: 0.1),
        iconBorder: Colors.blue.withValues(alpha: 0.2),
        footerLeft: 'Direct remux',
        footerRight: 'Apply preset',
        footerColor: AppColors.indigo400,
      );
    }
  }
}
