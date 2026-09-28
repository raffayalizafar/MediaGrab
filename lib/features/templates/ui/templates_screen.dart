import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/clipboard_service.dart';
import '../../../core/services/system_telemetry_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../shared/widgets/animated_pressable.dart';
import '../../../shared/widgets/stitch_top_bar.dart';
import '../../../shared/widgets/top_notification.dart';
import '../models/command_template.dart';
import '../providers/template_provider.dart';
import 'template_editor_dialog.dart';

/// Modernized Command Templates & Presets screen matching Stitch design system.
class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(templateProvider);
    final notifier = ref.read(templateProvider.notifier);
    final theme = Theme.of(context);

    // Filter templates
    final filtered = templates.where((t) {
      if (_selectedCategory == 'Built-in' && !t.isBuiltIn) return false;
      if (_selectedCategory == 'Custom' && t.isBuiltIn) return false;
      if (_selectedCategory == 'Audio' &&
          !t.templateArgs.contains('-x') &&
          !t.name.toLowerCase().contains('audio') &&
          !t.name.toLowerCase().contains('mp3')) {
        return false;
      }
      if (_selectedCategory == 'Video' &&
          (t.templateArgs.contains('-x') ||
              t.name.toLowerCase().contains('audio') ||
              t.name.toLowerCase().contains('mp3'))) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return t.name.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q) ||
            t.templateArgs.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Unified Stitch TopBar
            const StitchTopBar(),

            // Scrollable Content Container
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
                        // Page Title & Action Bar
                        _buildHeader(
                          context,
                          totalCount: templates.length,
                          onNewTemplate: () =>
                              _openNewTemplateDialog(context, notifier),
                        ),

                        const SizedBox(height: 20),

                        // Filters & Search Bar
                        _buildFilterBar(context, templates),

                        const SizedBox(height: 14),

                        // Telemetry Quick Info Ribbon
                        _buildTelemetryRibbon(context),

                        const SizedBox(height: 20),

                        // Template Cards List
                        if (filtered.isEmpty)
                          _buildEmptyState(context)
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final t = filtered[index];
                              return _buildTemplateCard(
                                context,
                                template: t,
                                onEdit: () => _openEditTemplateDialog(
                                  context,
                                  notifier,
                                  t,
                                ),
                                onDelete: () => notifier.deleteTemplate(t.id),
                              );
                            },
                          ),

                        const SizedBox(height: 36),
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

  /// Header with Title, Recipe count pill, and New Template CTA.
  Widget _buildHeader(
    BuildContext context, {
    required int totalCount,
    required VoidCallback onNewTemplate,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title & Recipes Available Badge
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 4,
                children: [
                  Text(
                    'Command Templates',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
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
                      '$totalCount Recipes Available',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.indigo400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // New Template CTA Button
            AnimatedPressable(
              onTap: onNewTemplate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.indigo500, AppColors.indigo600],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo500.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'New Template',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '⌘N',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.indigo200,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Custom flag recipes and automated yt-dlp execution profiles for high-speed multi-threaded workflows.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.slate400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// Filter category pills and Search input.
  Widget _buildFilterBar(
    BuildContext context,
    List<CommandTemplate> templates,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAmoled = isDark && theme.scaffoldBackgroundColor == Colors.black;

    final categories = ['All', 'Built-in', 'Custom', 'Audio', 'Video'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? (isAmoled
                  ? const Color(0xFF0D0D0D)
                  : AppColors.slate900.withValues(alpha: 0.8))
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? (isAmoled ? const Color(0xFF222222) : AppColors.slate800)
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWrap = constraints.maxWidth < 680;

          return Flex(
            direction: isWrap ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: isWrap
                ? CrossAxisAlignment.stretch
                : CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Category Buttons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = _selectedCategory == cat;

                    int count = 0;
                    if (cat == 'All') count = templates.length;
                    if (cat == 'Built-in') {
                      count = templates.where((t) => t.isBuiltIn).length;
                    }
                    if (cat == 'Custom') {
                      count = templates.where((t) => !t.isBuiltIn).length;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedPressable(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6.5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.indigo600
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.indigo600.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                            ? AppColors.slate400
                                            : Colors.grey.shade700),
                                ),
                              ),
                              if (count > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '($count)',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: isSelected
                                        ? Colors.white70
                                        : (isDark
                                              ? AppColors.slate500
                                              : Colors.grey.shade500),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              if (isWrap) const SizedBox(height: 8),

              // Search Bar
              Container(
                width: isWrap ? double.infinity : 220,
                height: 34,
                decoration: BoxDecoration(
                  color: isDark
                      ? (isAmoled ? Colors.black : AppColors.slate950)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? (isAmoled
                              ? const Color(0xFF222222)
                              : AppColors.slate800)
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 15,
                      color: isDark ? AppColors.slate500 : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(fontSize: 11.5),
                        decoration: InputDecoration(
                          hintText: 'Filter flags or tags...',
                          hintStyle: TextStyle(
                            fontSize: 11.5,
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
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Telemetry Quick Info Ribbon
  Widget _buildTelemetryRibbon(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final templates = ref.watch(templateProvider);
    final engineName =
        ref.watch(engineInfoProvider).value ?? 'Pure Dart Engine';
    final downloadDir = ref.watch(settingsProvider).downloadDirectory;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 750;

        return GridView.count(
          crossAxisCount: isCompact ? 1 : 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 8,
          childAspectRatio: isCompact ? 6.5 : 3.8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildRibbonCard(
              context,
              icon: Icons.star_rounded,
              iconColor: AppColors.amber400,
              label: 'Active in Quick Launcher:',
              value: '${templates.length} Presets Available',
              isDark: isDark,
            ),
            _buildRibbonCard(
              context,
              icon: Icons.code_rounded,
              iconColor: AppColors.sky400,
              label: 'Core Engine Target:',
              value: engineName,
              isDark: isDark,
            ),
            _buildRibbonCard(
              context,
              icon: Icons.folder_rounded,
              iconColor: AppColors.emerald400,
              label: 'Default Target:',
              value: downloadDir,
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildRibbonCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
  }) {
    final isAmoled =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? (isAmoled
                  ? const Color(0xFF0D0D0D)
                  : AppColors.slate900.withValues(alpha: 0.6))
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? (isAmoled ? const Color(0xFF222222) : AppColors.slate800)
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.slate400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
        ],
      ),
    );
  }

  /// Modernized Template Card
  Widget _buildTemplateCard(
    BuildContext context, {
    required CommandTemplate template,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAmoled = isDark && theme.scaffoldBackgroundColor == Colors.black;

    final isAudio =
        template.templateArgs.contains('-x') ||
        template.name.toLowerCase().contains('audio') ||
        template.name.toLowerCase().contains('mp3');

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? (isAmoled
                  ? const Color(0xFF0E0E0E)
                  : AppColors.slate900.withValues(alpha: 0.85))
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? (isAmoled ? const Color(0xFF222222) : AppColors.slate800)
              : Colors.grey.shade200,
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon, Title, Badges, Copy Flags & Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (isAudio ? AppColors.emerald400 : AppColors.indigo500)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        (isAudio ? AppColors.emerald400 : AppColors.indigo500)
                            .withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  isAudio ? Icons.music_note_rounded : Icons.terminal_rounded,
                  color: isAudio ? AppColors.emerald400 : AppColors.indigo400,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // Title and Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          template.name,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),

                        // Built-In vs Custom Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.slate800
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            template.isBuiltIn ? 'BUILT-IN' : 'CUSTOM',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                              color: isDark
                                  ? AppColors.slate300
                                  : Colors.grey.shade800,
                            ),
                          ),
                        ),

                        // Audio vs Video Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: isAudio
                                ? AppColors.emerald400.withValues(alpha: 0.12)
                                : AppColors.indigo500.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isAudio
                                  ? AppColors.emerald400.withValues(alpha: 0.3)
                                  : AppColors.indigo500.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isAudio ? 'AUDIO' : 'VIDEO',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: isAudio
                                  ? AppColors.emerald400
                                  : AppColors.indigo400,
                            ),
                          ),
                        ),

                        // Quick Bar indicator
                        if (template.isBuiltIn)
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: AppColors.amber400,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'Quick Bar',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.amber400,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    if (template.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        template.description,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AppColors.slate400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Action Buttons: Copy Flags & Popup Menu
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedPressable(
                    onTap: () {
                      ClipboardService.copyToClipboard(template.templateArgs);
                      TopNotification.show(
                        context,
                        message: 'Arguments copied to clipboard',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.indigo500.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.indigo500.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 13,
                            color: AppColors.indigo400,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Copy Flags',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.indigo400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Menu for custom recipes
                  if (!template.isBuiltIn) ...[
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: isDark
                            ? AppColors.slate400
                            : Colors.grey.shade600,
                      ),
                      color: isDark ? AppColors.slate900 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.slate800
                              : Colors.grey.shade200,
                        ),
                      ),
                      onSelected: (val) {
                        if (val == 'edit') onEdit();
                        if (val == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_rounded, size: 18),
                            title: Text('Edit', style: TextStyle(fontSize: 12)),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.error,
                              size: 18,
                            ),
                            title: Text(
                              'Delete',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // CLI ARGUMENTS Terminal Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? (isAmoled ? Colors.black : AppColors.slate950)
                  : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? (isAmoled ? const Color(0xFF222222) : AppColors.slate800)
                    : AppColors.slate700,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText(
                      template.templateArgs,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        color: AppColors.sky400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'CLI ARGUMENTS',
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: 'monospace',
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            ),
            child: const Icon(
              Icons.terminal_rounded,
              size: 40,
              color: AppColors.indigo400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No matching templates found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try choosing a different category or clearing your search.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.slate400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openNewTemplateDialog(
    BuildContext context,
    TemplateNotifier notifier,
  ) async {
    final result = await showDialog<CommandTemplate>(
      context: context,
      builder: (_) => const TemplateEditorDialog(),
    );
    if (result != null) {
      notifier.addTemplate(
        name: result.name,
        description: result.description,
        templateArgs: result.templateArgs,
      );
    }
  }

  Future<void> _openEditTemplateDialog(
    BuildContext context,
    TemplateNotifier notifier,
    CommandTemplate template,
  ) async {
    final result = await showDialog<CommandTemplate>(
      context: context,
      builder: (_) => TemplateEditorDialog(initialTemplate: template),
    );
    if (result != null) {
      notifier.updateTemplate(result);
    }
  }
}
