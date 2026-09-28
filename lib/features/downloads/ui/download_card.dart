import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../download_engine/models/download_task.dart';
import '../../../shared/widgets/animated_pressable.dart';
import '../../../shared/widgets/thumbnail_card.dart';
import '../models/download_record.dart';

/// Card displaying an active download task with live progress, speed, ETA, and controls.
class ActiveDownloadCard extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStartNow;

  const ActiveDownloadCard({
    super.key,
    required this.task,
    required this.onCancel,
    required this.onRetry,
    this.onPause,
    this.onResume,
    this.onStartNow,
  });

  static String _formatScheduledTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dt.month - 1];
    return '$month ${dt.day}, $hour:$minute $amPm';
  }

  static String _timeUntil(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'due now';
    if (diff.inHours > 0) {
      final mins = diff.inMinutes % 60;
      return 'in ${diff.inHours}h ${mins}m';
    }
    if (diff.inMinutes > 0) return 'in ${diff.inMinutes}m';
    return 'in ${diff.inSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAmoled = isDark && theme.scaffoldBackgroundColor == Colors.black;
    final progress = task.progress;

    // Detect format/quality badge color
    final isFailed = task.status == DownloadStatus.failed;
    final isPaused = task.status == DownloadStatus.paused;
    final isScheduled = task.status == DownloadStatus.scheduled;
    final isConnecting =
        progress.downloadedBytes == 0 &&
        task.status == DownloadStatus.downloading;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? (isAmoled
                  ? const Color(0xFF0E0E0E)
                  : AppColors.slate900.withValues(alpha: 0.85))
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFailed
              ? AppColors.error.withValues(alpha: 0.5)
              : (isPaused || isScheduled)
              ? AppColors.amber400.withValues(alpha: 0.4)
              : (isDark
                    ? (isAmoled ? const Color(0xFF222222) : AppColors.slate800)
                    : Colors.grey.shade200),
          width: 1,
        ),
        boxShadow: isAmoled
            ? null
            : [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video / Audio Thumbnail
              ThumbnailCard(
                imageUrl: task.mediaInfo.thumbnailUrl,
                durationText: task.mediaInfo.durationFormatted,
                width: 100,
                height: 62,
              ),
              const SizedBox(width: 14),

              // Title and Tags
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges Row
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Quality Tag
                        if (!task.request.isAudioOnly)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.amber400.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.amber400.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              task.request.selectedQuality.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                                color: AppColors.amber400,
                              ),
                            ),
                          ),

                        // Format Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.slate800
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.slate700
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            task.request.outputFormat.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              color: isDark
                                  ? AppColors.slate300
                                  : Colors.grey.shade800,
                            ),
                          ),
                        ),

                        // Status Tag (DOWNLOADING, CONNECTING, FAILED, PAUSED, SCHEDULED)
                        Text(
                          isFailed
                              ? 'FAILED'
                              : isScheduled
                              ? 'SCHEDULED'
                              : isPaused
                              ? (progress.waitingForWifi
                                    ? 'WAITING FOR WI-FI'
                                    : progress.waitingForNetwork
                                    ? 'WAITING FOR NETWORK'
                                    : 'PAUSED')
                              : (isConnecting
                                    ? 'CONNECTING'
                                    : task.status.name.toUpperCase()),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: isFailed
                                ? AppColors.error
                                : (isPaused || isScheduled
                                      ? AppColors.amber400
                                      : (isConnecting
                                            ? AppColors.indigo400
                                            : AppColors.emerald400)),
                          ),
                        ),

                        // Slow / Stalled Connection Indicator
                        if (progress.isStalled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 10,
                                  color: AppColors.error,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'STALLED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (progress.isSlowSpeed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.amber400.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.amber400.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.speed_rounded,
                                  size: 10,
                                  color: AppColors.amber400,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'SLOW SPEED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.amber400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Author/Channel if available
                        if (task.mediaInfo.author.isNotEmpty)
                          Text(
                            task.mediaInfo.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.slate400
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Title
                    Text(
                      task.mediaInfo.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Action Controls (Pause/Resume/Cancel/Retry/StartNow)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFailed)
                    AnimatedPressable(
                      onTap: onRetry,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                      ),
                    )
                  else if (isScheduled) ...[
                    if (onStartNow != null) ...[
                      AnimatedPressable(
                        onTap: onStartNow,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.emerald400.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: AppColors.emerald400.withValues(
                                alpha: 0.35,
                              ),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.emerald400,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    AnimatedPressable(
                      onTap: onCancel,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.slate800.withValues(alpha: 0.8)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: isDark
                                ? AppColors.slate700
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: isDark
                              ? AppColors.slate400
                              : Colors.grey.shade600,
                          size: 18,
                        ),
                      ),
                    ),
                  ] else if (isPaused) ...[
                    if (onResume != null) ...[
                      AnimatedPressable(
                        onTap: onResume,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.emerald400.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: AppColors.emerald400.withValues(
                                alpha: 0.35,
                              ),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.emerald400,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    AnimatedPressable(
                      onTap: onCancel,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.slate800.withValues(alpha: 0.8)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: isDark
                                ? AppColors.slate700
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: isDark
                              ? AppColors.slate400
                              : Colors.grey.shade600,
                          size: 18,
                        ),
                      ),
                    ),
                  ] else ...[
                    if (onPause != null) ...[
                      AnimatedPressable(
                        onTap: onPause,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.slate800.withValues(alpha: 0.8)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.slate700
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.pause_rounded,
                            color: isDark
                                ? AppColors.slate300
                                : AppColors.slate700,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    AnimatedPressable(
                      onTap: onCancel,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.slate800.withValues(alpha: 0.8)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: isDark
                                ? AppColors.slate700
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: isDark
                              ? AppColors.slate400
                              : Colors.grey.shade600,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // Status message when connecting or buffering
          if (progress.statusMessage != null &&
              progress.statusMessage!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (isConnecting) ...[
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.indigo400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    progress.statusMessage!,
                    style: TextStyle(
                      color: isFailed ? AppColors.error : AppColors.indigo400,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Scheduled countdown pill or Progress Bar & Metrics
          if (isScheduled && task.scheduledAt != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.amber400.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.amber400.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.alarm_rounded,
                    size: 16,
                    color: AppColors.amber400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scheduled for ${_formatScheduledTime(task.scheduledAt!)} (${_timeUntil(task.scheduledAt!)})',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.amber400,
                      ),
                    ),
                  ),
                  if (onStartNow != null)
                    AnimatedPressable(
                      onTap: onStartNow,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber400.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Start Now',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.amber400,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value:
                    (progress.downloadedBytes > 0 && progress.percentage > 0.01)
                    ? progress.percentage
                    : (isPaused ? progress.percentage : null),
                minHeight: 7,
                backgroundColor: isDark
                    ? AppColors.slate800
                    : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPaused ? AppColors.amber400 : AppColors.sky400,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Metrics Row: Bytes, Percentage, Speed, ETA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Downloaded / Total & Percent
                Row(
                  children: [
                    Text(
                      progress.downloadedBytes > 0
                          ? '${(progress.percentage * 100).toStringAsFixed(1)}% • ${progress.downloadedFormatted}'
                          : (progress.totalBytes > 0
                                ? '0% • ${progress.downloadedFormatted}'
                                : 'Starting connection...'),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.slate300 : AppColors.slate700,
                      ),
                    ),
                    if (progress.downloadedBytes > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.sky400.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${(progress.percentage * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.sky400,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Live Speed and ETA
                Row(
                  children: [
                    if (progress.downloadedBytes > 0 && !isPaused) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.arrow_downward_rounded,
                            size: 13,
                            color: AppColors.emerald400,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            progress.speedFormatted,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.emerald400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.slate600
                              : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ETA: ${progress.etaFormatted}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: isDark
                              ? AppColors.slate400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ] else ...[
                      Text(
                        task.status == DownloadStatus.failed
                            ? 'Failed'
                            : isPaused
                            ? (progress.waitingForWifi
                                  ? 'Waiting for Wi-Fi'
                                  : progress.waitingForNetwork
                                  ? 'No Connection'
                                  : 'Paused')
                            : 'Buffering...',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: task.status == DownloadStatus.failed
                              ? AppColors.error
                              : (isPaused
                                    ? AppColors.amber400
                                    : (isDark
                                          ? AppColors.slate400
                                          : Colors.grey.shade600)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Card displaying a completed download record with open, share, and delete actions.
class CompletedDownloadCard extends StatelessWidget {
  final DownloadRecord record;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const CompletedDownloadCard({
    super.key,
    required this.record,
    required this.onOpen,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAmoled = isDark && theme.scaffoldBackgroundColor == Colors.black;

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
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Completed Success Icon + Thumbnail Preview
          Stack(
            children: [
              ThumbnailCard(
                imageUrl: record.thumbnailUrl,
                width: 90,
                height: 56,
              ),
              Positioned(
                bottom: 3,
                right: 3,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.emerald400,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.black,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Record Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  record.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    letterSpacing: -0.2,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.slate800
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        record.isAudioOnly
                            ? record.format.toUpperCase()
                            : '${record.quality} • ${record.format.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          color: isDark
                              ? AppColors.slate300
                              : Colors.grey.shade800,
                        ),
                      ),
                    ),
                    if (record.formattedSize.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        record.formattedSize,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: isDark
                              ? AppColors.slate400
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.slate600
                            : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.emerald400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Actions: Play / Open Folder / Popup menu
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Play button
              AnimatedPressable(
                onTap: onOpen,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 15,
                        color: AppColors.indigo400,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Play',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.indigo400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // More options menu (share / delete)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: isDark ? AppColors.slate400 : Colors.grey.shade600,
                ),
                color: isDark ? AppColors.slate900 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark ? AppColors.slate800 : Colors.grey.shade200,
                  ),
                ),
                onSelected: (val) {
                  if (val == 'open') onOpen();
                  if (val == 'share') onShare();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'open',
                    child: ListTile(
                      leading: Icon(Icons.play_arrow_rounded, size: 18),
                      title: Text('Open File', style: TextStyle(fontSize: 12)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: ListTile(
                      leading: Icon(Icons.share_rounded, size: 18),
                      title: Text('Share', style: TextStyle(fontSize: 12)),
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
                        'Remove from History',
                        style: TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
