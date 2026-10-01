import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/update_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/animated_pressable.dart';
import '../../../shared/widgets/clay_container.dart';

/// Modal dialog / bottom sheet presenting release information and direct download actions.
class UpdateDialog extends StatelessWidget {
  final AppRelease release;
  final ReleaseAsset? recommendedAsset;
  final String currentVersion;

  const UpdateDialog({
    super.key,
    required this.release,
    this.recommendedAsset,
    this.currentVersion = AppConstants.appVersion,
  });

  /// Displays the update details modal adaptively.
  static Future<void> show(
    BuildContext context, {
    required AppRelease release,
    ReleaseAsset? recommendedAsset,
    String currentVersion = AppConstants.appVersion,
  }) {
    final isDesktop = MediaQuery.of(context).size.width > 650;

    if (isDesktop) {
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540, maxHeight: 620),
            child: UpdateDialog(
              release: release,
              recommendedAsset: recommendedAsset,
              currentVersion: currentVersion,
            ),
          ),
        ),
      );
    } else {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: UpdateDialog(
            release: release,
            recommendedAsset: recommendedAsset,
            currentVersion: currentVersion,
          ),
        ),
      );
    }
  }

  String get _platformName {
    try {
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isLinux) return 'Linux';
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
    } catch (_) {}
    return 'Your Device';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClayContainer(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.indigo500, AppColors.violetSeed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo500.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Update Available',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildBadge(
                          release.isPrerelease ? 'Pre-release' : 'Stable',
                          isPrerelease: release.isPrerelease,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      release.name.isNotEmpty ? release.name : release.tagName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.slate300 : AppColors.slate700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20),
                tooltip: 'Close',
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Version comparison badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.slate900.withValues(alpha: 0.6)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.slate800 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildVersionPill('Current: v$currentVersion', isCurrent: true),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.indigo400,
                  ),
                ),
                _buildVersionPill('New: ${release.tagName}', isCurrent: false),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Release Notes Box
          Text(
            'Release Notes',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.slate400 : AppColors.slate600,
            ),
          ),
          const SizedBox(height: 8),

          Flexible(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.7)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : Colors.grey.shade200,
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  release.body.trim().isNotEmpty
                      ? release.body.trim()
                      : 'No detailed release notes provided for this build.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.4,
                    color: isDark ? AppColors.slate300 : AppColors.slate700,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Action Buttons
          if (recommendedAsset != null) ...[
            AnimatedPressable(
              onTap: () async {
                final uri = Uri.parse(recommendedAsset!.downloadUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.indigo500, AppColors.violetSeed],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo500.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Download for $_platformName (${recommendedAsset!.humanReadableSize})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          Row(
            children: [
              Expanded(
                child: AnimatedPressable(
                  onTap: () async {
                    final uri = Uri.parse(release.htmlUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.slate800
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.open_in_browser_rounded,
                          size: 16,
                          color: isDark ? AppColors.slate300 : AppColors.slate700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'View on GitHub',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.slate300 : AppColors.slate700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedPressable(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Later',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, {required bool isPrerelease}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isPrerelease
            ? Colors.amber.withValues(alpha: 0.15)
            : AppColors.emerald400.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPrerelease
              ? Colors.amber.withValues(alpha: 0.4)
              : AppColors.emerald400.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: isPrerelease ? Colors.amber.shade700 : AppColors.emerald400,
        ),
      ),
    );
  }

  Widget _buildVersionPill(String text, {required bool isCurrent}) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isCurrent
            ? AppColors.slate400
            : AppColors.emerald400,
      ),
    );
  }
}
