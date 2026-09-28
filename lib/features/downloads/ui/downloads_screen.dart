import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/animated_pressable.dart';
import '../../../shared/widgets/stitch_top_bar.dart';
import '../providers/download_manager.dart';
import 'download_card.dart';

/// Modernized Downloads screen matching Google Stitch MediaGrab specifications.
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(downloadManagerProvider);
    final manager = ref.read(downloadManagerProvider.notifier);
    final theme = Theme.of(context);

    final active = state.activeTasks.where((t) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return t.mediaInfo.title.toLowerCase().contains(q) ||
          t.mediaInfo.author.toLowerCase().contains(q) ||
          t.mediaInfo.url.toLowerCase().contains(q);
    }).toList();

    final history = state.history.where((r) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.title.toLowerCase().contains(q) ||
          r.url.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Unified Stitch TopBar
            const StitchTopBar(),

            // Content Area
            Expanded(
              child: SingleChildScrollView(
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
                        // Hero Header Section
                        _buildHeroHeader(
                          context,
                          activeCount: state.activeTasks.length,
                          completedCount: state.history.length,
                          onClearCompleted: state.history.isEmpty
                              ? null
                              : () => _confirmClearHistory(context, manager),
                        ),

                        const SizedBox(height: 18),

                        // Segmented Filter Tabs & Telemetry Bar
                        _buildSegmentedTabsAndStorage(
                          context,
                          activeCount: state.activeTasks.length,
                          completedCount: state.history.length,
                        ),

                        const SizedBox(height: 20),

                        // Active / Completed Lists
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _tabController.index == 0
                              ? _buildActiveSection(
                                  context,
                                  active: active,
                                  totalActiveCount: state.activeTasks.length,
                                  manager: manager,
                                )
                              : _buildCompletedSection(
                                  context,
                                  history: history,
                                  totalHistoryCount: state.history.length,
                                  manager: manager,
                                ),
                        ),

                        const SizedBox(height: 32),
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

  /// Hero toolbar with title, live badges, and filter search input.
  Widget _buildHeroHeader(
    BuildContext context, {
    required int activeCount,
    required int completedCount,
    required VoidCallback? onClearCompleted,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isWrap = constraints.maxWidth < 780;

            final titleSection = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    Text(
                      'Downloads & Activity',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.indigo500.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.indigo500.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$activeCount Active',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.indigo300,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.slate800.withValues(alpha: 0.6)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isDark
                              ? AppColors.slate700
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$completedCount Completed',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.slate400
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Multi-source asynchronous pipeline powered by aria2c & yt-dlp native bindings',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.slate400 : Colors.grey.shade600,
                  ),
                  maxLines: isWrap ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );

            return Flex(
              direction: isWrap ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: isWrap
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title and Counts
                if (isWrap) titleSection else Expanded(child: titleSection),

                if (!isWrap) const SizedBox(width: 16),
                if (isWrap) const SizedBox(height: 14),

                // Search Bar & Action Buttons
                Row(
                  mainAxisSize: isWrap ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    // Search Filter
                    Expanded(
                      flex: isWrap ? 1 : 0,
                      child: Container(
                        width: isWrap ? null : 210,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.slate900 : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? AppColors.slate800
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 17,
                              color: isDark
                                  ? AppColors.slate400
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                style: const TextStyle(fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'Filter downloads...',
                                  hintStyle: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.slate500
                                        : Colors.grey.shade400,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  filled: false,
                                  fillColor: Colors.transparent,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val.trim();
                                  });
                                },
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () => setState(() => _searchQuery = ''),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 15,
                                  color: isDark
                                      ? AppColors.slate400
                                      : Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Clear Completed Button (if applicable)
                    if (onClearCompleted != null) ...[
                      const SizedBox(width: 8),
                      AnimatedPressable(
                        onTap: onClearCompleted,
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.slate900 : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.slate800
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.delete_sweep_rounded,
                                size: 16,
                                color: AppColors.roseSeed,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.roseSeed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // New Download CTA
                    const SizedBox(width: 8),
                    AnimatedPressable(
                      onTap: () {
                        // Switch to Home screen
                        ref.read(activeTabProvider.notifier).state = 0;
                      },
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.indigo500, AppColors.indigo600],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.indigo500.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              constraints.maxWidth < 420
                                  ? 'New'
                                  : 'New Download',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Segmented filter buttons matching Stitch dark pill tabs.
  Widget _buildSegmentedTabsAndStorage(
    BuildContext context, {
    required int activeCount,
    required int completedCount,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.slate800.withValues(alpha: 0.8)
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            // Segmented Tabs
            Container(
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.slate900.withValues(alpha: 0.9)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSegmentTab(
                    index: 0,
                    label: 'Active',
                    count: activeCount,
                    isSelected: _tabController.index == 0,
                  ),
                  _buildSegmentTab(
                    index: 1,
                    label: 'Completed',
                    count: completedCount,
                    isSelected: _tabController.index == 1,
                  ),
                ],
              ),
            ),

            // Storage info badge
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.speed_rounded,
                  size: 15,
                  color: isDark ? AppColors.slate500 : Colors.grey.shade500,
                ),
                const SizedBox(width: 5),
                Text(
                  'Speed Limit: ',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: isDark ? AppColors.slate500 : Colors.grey.shade600,
                  ),
                ),
                const Text(
                  'Unlimited',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: AppColors.emerald400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentTab({
    required int index,
    required String label,
    required int count,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedPressable(
      onTap: () {
        _tabController.animateTo(index);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.indigo600 : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.indigo600.withValues(alpha: 0.35),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.slate400 : Colors.grey.shade700),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : (isDark ? AppColors.slate800 : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.slate300 : AppColors.slate800),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSection(
    BuildContext context, {
    required List active,
    required int totalActiveCount,
    required dynamic manager,
  }) {
    if (active.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.download_done_rounded,
        title: totalActiveCount == 0
            ? 'No active downloads'
            : 'No matching downloads',
        subtitle: totalActiveCount == 0
            ? 'Paste any valid link on the Home screen to trigger the engine.'
            : 'Try modifying your search query.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: active.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = active[index];
        return ActiveDownloadCard(
          task: task,
          onCancel: () => manager.cancelTask(task.id),
          onRetry: () => manager.retryTask(task.id),
          onPause: () => manager.pauseTask(task.id),
          onResume: () => manager.resumeTask(task.id),
          onStartNow: () => manager.startScheduledTaskNow(task.id),
        );
      },
    );
  }

  Widget _buildCompletedSection(
    BuildContext context, {
    required List history,
    required int totalHistoryCount,
    required dynamic manager,
  }) {
    if (history.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.folder_open_rounded,
        title: totalHistoryCount == 0
            ? 'No finished downloads'
            : 'No matching records',
        subtitle: totalHistoryCount == 0
            ? 'Completed audio and video extractions will appear here.'
            : 'Try modifying your search query.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final record = history[index];
        return CompletedDownloadCard(
          record: record,
          onOpen: () => manager.openFile(record.filePath),
          onShare: () =>
              manager.shareFile(record.filePath, title: record.title),
          onDelete: () {
            manager.deleteTask(record.id, deleteFile: false);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.slate900.withValues(alpha: 0.6)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.slate800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.indigo500.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.indigo500.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 40, color: AppColors.indigo400),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.slate400 : Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          AnimatedPressable(
            onTap: () {
              ref.read(activeTabProvider.notifier).state = 0;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.indigo500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Return Home',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.indigo400,
                      ),
                      overflow: TextOverflow.ellipsis,
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
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context, dynamic manager) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.slate900 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isDark ? AppColors.slate800 : Colors.grey.shade200,
          ),
        ),
        title: const Text('Clear Downloads History?'),
        content: const Text(
          'This will clear the history list. Downloaded media files will remain on your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.roseSeed),
            onPressed: () {
              manager.clearCompleted();
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
