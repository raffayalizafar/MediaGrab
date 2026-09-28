import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/clipboard_service.dart';
import '../../../core/utils/download_path_resolver.dart';
import '../../../shared/widgets/animated_pressable.dart';
import '../../../shared/widgets/clay_container.dart';
import '../../../shared/widgets/quality_chip.dart';
import '../../../shared/widgets/thumbnail_card.dart';
import '../../../shared/widgets/top_notification.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/home_provider.dart';

import '../../../download_engine/models/media_info.dart';
import '../../../download_engine/models/stream_option.dart';

/// Modal bottom sheet for configuring format, resolution, subtitles, and metadata before downloading.
/// Displays maximum available options: all video resolutions (up to 8K), audio bitrates, format choices,
/// and an expandable raw stream inspector.
class MediaConfigSheet extends ConsumerStatefulWidget {
  const MediaConfigSheet({super.key});

  @override
  ConsumerState<MediaConfigSheet> createState() => _MediaConfigSheetState();
}

class _MediaConfigSheetState extends ConsumerState<MediaConfigSheet> {
  bool _showStreamInspector = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final notifier = ref.read(homeProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final info = state.mediaInfo;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          final s = ref.read(homeProvider);
          if (s.status == HomeStateStatus.fetchingInfo) {
            ref.read(homeProvider.notifier).cancelFetch();
          }
        }
      },
      child: Material(
        color: isDark
            ? theme.colorScheme.surfaceContainer
            : theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.paddingOf(context).bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.6,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Render based on state
                  if (state.status == HomeStateStatus.fetchingInfo ||
                      info == null)
                    if (state.status == HomeStateStatus.error)
                      _buildErrorState(
                        context,
                        state.errorMessage ?? 'Failed to load video',
                        () {
                          notifier.fetchInfo(state.url);
                        },
                      )
                    else
                      _buildLoadingSkeleton(context)
                  else
                    _buildReadyContent(context, state, info),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Instant loading skeleton with pulsating clay shimmers
  Widget _buildLoadingSkeleton(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Skeleton Preview Card
        ClayContainer(
          depth: 4,
          padding: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ClayShimmer(
                width: 100,
                height: 65,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SizedBox(height: 4),
                    ClayShimmer(width: double.infinity, height: 16),
                    SizedBox(height: 8),
                    ClayShimmer(width: 140, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Analyzing Status Pill
        ClayContainer(
          depth: 2,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Resolving available streams & formats...',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        // Drag-down hint
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Drag down or tap to cancel',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.8,
                  ),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Skeleton Toggle
        const ClayShimmer(
          width: double.infinity,
          height: 46,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),

        const SizedBox(height: 20),

        // Skeleton Quality Chips
        const ClayShimmer(width: 90, height: 14),
        const SizedBox(height: 10),
        Row(
          children: const [
            ClayShimmer(
              width: 72,
              height: 36,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            SizedBox(width: 8),
            ClayShimmer(
              width: 72,
              height: 36,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            SizedBox(width: 8),
            ClayShimmer(
              width: 72,
              height: 36,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Skeleton Format Chips
        const ClayShimmer(width: 70, height: 14),
        const SizedBox(height: 10),
        Row(
          children: const [
            ClayShimmer(
              width: 64,
              height: 36,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            SizedBox(width: 8),
            ClayShimmer(
              width: 64,
              height: 36,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            SizedBox(width: 8),
            ClayShimmer(
              width: 64,
              height: 36,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Cancel Button
        Center(
          child: TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Cancel Loading'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// Error state with retry
  Widget _buildErrorState(
    BuildContext context,
    String message,
    VoidCallback onRetry,
  ) {
    final theme = Theme.of(context);

    return ClayContainer(
      depth: 6,
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(22),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to Load Media',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  /// Full claymorphic ready content showing maximum options
  Widget _buildReadyContent(
    BuildContext context,
    HomeState state,
    MediaInfo info,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notifier = ref.read(homeProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final baseDir = state.customOutputDirectory ?? settings.downloadDirectory;
    final resolvedPath = DownloadPathResolver.buildDestinationPath(
      baseDirectory: baseDir,
      isAudioOnly: state.isAudioOnly,
      isPlaylist: info.isPlaylist,
      playlistTitle: info.isPlaylist ? info.title : null,
    );

    // Build unique resolution options list strictly from actual streams available
    final List<String> videoResolutions = ['Best'];
    final availableHeights =
        state.streamOptions
            .where((s) => !s.isAudioOnly && s.height != null && s.height! > 0)
            .map((s) => s.height!)
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    if (availableHeights.isNotEmpty) {
      for (final h in availableHeights) {
        final label = '${h}p';
        if (!videoResolutions.contains(label)) {
          videoResolutions.add(label);
        }
      }
    } else {
      for (final q in info.availableQualities) {
        if (!videoResolutions.contains(q)) {
          videoResolutions.add(q);
        }
      }
    }

    // Build audio bitrates list dynamically from actual audio tracks
    final List<String> audioBitrates = ['Best'];
    final availableBitrates =
        state.streamOptions
            .where((s) => s.isAudioOnly && s.bitrate != null && s.bitrate! > 0)
            .map((s) => (s.bitrate! / 1000).round())
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    if (availableBitrates.isNotEmpty) {
      for (final kbps in availableBitrates) {
        final label = '$kbps kbps';
        if (!audioBitrates.contains(label)) {
          audioBitrates.add(label);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video Preview Info in a soft Clay Card
        ClayContainer(
          depth: 5,
          padding: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ThumbnailCard(
                imageUrl: info.thumbnailUrl,
                durationText: info.durationFormatted,
                isPlaylist: info.isPlaylist,
                playlistCount: info.playlistCount,
                width: 110,
                height: 65,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Media Type Segmented Pill (Video / Audio)
        ClayContainer(
          depth: 3,
          padding: const EdgeInsets.all(4),
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              Expanded(
                child: _buildTypeToggleItem(
                  context,
                  title: 'Video',
                  icon: Icons.videocam_rounded,
                  isSelected: !state.isAudioOnly,
                  onTap: () => notifier.setAudioOnly(false),
                ),
              ),
              Expanded(
                child: _buildTypeToggleItem(
                  context,
                  title: 'Audio',
                  icon: Icons.music_note_rounded,
                  isSelected: state.isAudioOnly,
                  onTap: () => notifier.setAudioOnly(true),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // VIDEO MODE OPTIONS
        if (!state.isAudioOnly) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Resolutions (${videoResolutions.length})',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                videoResolutions.length > 1
                    ? 'Max: ${_formatResolutionLabel(videoResolutions[1])}'
                    : 'Best Available',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: videoResolutions.map((q) {
              final formattedLabel = _formatResolutionLabel(q);
              final subtitle = _getResolutionSubtitle(q, state.streamOptions);
              final isSelected = _isResolutionSelected(
                q,
                state.selectedQuality,
              );

              return QualityChip(
                label: formattedLabel,
                subtitle: subtitle,
                isSelected: isSelected,
                onSelected: (_) => notifier.setSelectedQuality(q),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          Text(
            'Container Format',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.videoFormats.map((fmt) {
              final isSelected =
                  state.selectedFormat.toLowerCase() == fmt.toLowerCase();
              String badge = '';
              if (fmt == 'mp4') badge = ' (Universal)';
              if (fmt == 'mkv') badge = ' (HQ)';
              if (fmt == 'mov') badge = ' (Apple)';
              if (fmt == 'webm') badge = ' (Open)';

              return AnimatedPressable(
                child: ChoiceChip(
                  label: Text('${fmt.toUpperCase()}$badge'),
                  selected: isSelected,
                  onSelected: (_) => notifier.setSelectedFormat(fmt),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Subtitles Toggle
          ClayContainer(
            depth: 2,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            borderRadius: BorderRadius.circular(18),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Embed Subtitles',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Muxes subtitle tracks directly into video file',
                style: TextStyle(fontSize: 12),
              ),
              value: state.embedSubtitles,
              onChanged: notifier.setEmbedSubtitles,
            ),
          ),
        ] else ...[
          // AUDIO MODE OPTIONS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Audio Quality / Bitrate (${audioBitrates.length})',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                audioBitrates.length > 1
                    ? 'Max: ${audioBitrates[1]}'
                    : 'Crystal-clear audio',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: audioBitrates.map((q) {
              final subtitle = _getAudioSubtitle(q, state.streamOptions);
              final isSelected = _isAudioQualitySelected(
                q,
                state.selectedQuality,
              );

              return QualityChip(
                label: q,
                subtitle: subtitle,
                isSelected: isSelected,
                onSelected: (_) => notifier.setSelectedQuality(q),
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          Text(
            'Audio Format',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.audioFormats.map((fmt) {
              final isSelected =
                  state.selectedFormat.toLowerCase() == fmt.toLowerCase();
              String badge = '';
              if (fmt == 'mp3') badge = ' (Universal)';
              if (fmt == 'm4a') badge = ' (AAC)';
              if (fmt == 'flac') badge = ' (Lossless)';
              if (fmt == 'wav') badge = ' (PCM)';

              return AnimatedPressable(
                child: ChoiceChip(
                  label: Text('${fmt.toUpperCase()}$badge'),
                  selected: isSelected,
                  onSelected: (_) => notifier.setSelectedFormat(fmt),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Audio Metadata
          ClayContainer(
            depth: 2,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            borderRadius: BorderRadius.circular(18),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Embed Metadata Tags',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Saves title, artist, and album tags into audio',
                style: TextStyle(fontSize: 12),
              ),
              value: state.embedMetadata,
              onChanged: notifier.setEmbedMetadata,
            ),
          ),

          const SizedBox(height: 10),

          // Audio Thumbnail Cover Art
          ClayContainer(
            depth: 2,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            borderRadius: BorderRadius.circular(18),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Embed Thumbnail Cover Art',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Sets video thumbnail as album cover',
                style: TextStyle(fontSize: 12),
              ),
              value: state.embedThumbnail,
              onChanged: notifier.setEmbedThumbnail,
            ),
          ),
        ],

        const SizedBox(height: 18),

        // EXPANDABLE RAW STREAM INSPECTOR
        if (state.streamOptions.isNotEmpty)
          ClayContainer(
            depth: 3,
            padding: const EdgeInsets.all(14),
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(
                    () => _showStreamInspector = !_showStreamInspector,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inspect All Streams (${state.streamOptions.length} available)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _showStreamInspector
                                  ? 'Tap any track to select exact stream directly'
                                  : 'Raw codecs, itags, framerates & exact sizes',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _showStreamInspector
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                if (_showStreamInspector) ...[
                  const Divider(height: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: state.streamOptions.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final stream = state.streamOptions[index];
                        return _buildStreamOptionTile(context, stream, state);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 20),

        // Destination Folder Selector
        ClayContainer(
          depth: 3,
          padding: const EdgeInsets.all(14),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Download Destination',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (state.customOutputDirectory != null) ...[
                        AnimatedPressable(
                          onTap: () => notifier.setCustomOutputDirectory(null),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.restore_rounded,
                                  size: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Reset',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      AnimatedPressable(
                        onTap: () async {
                          try {
                            final selected = await FilePicker.getDirectoryPath(
                              dialogTitle: 'Select Download Folder',
                            );
                            if (selected != null &&
                                selected.trim().isNotEmpty) {
                              notifier.setCustomOutputDirectory(
                                selected.trim(),
                              );
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
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.folder_open_rounded,
                                size: 13,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Change',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        resolvedPath,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedPressable(
                      onTap: () {
                        ClipboardService.copyToClipboard(resolvedPath);
                        TopNotification.show(
                          context,
                          message: 'Destination path copied',
                        );
                      },
                      child: Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (info.isPlaylist) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.playlist_play_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Playlist will be stored in a dedicated subfolder',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Schedule Download Section
        _buildScheduleSection(context, state, notifier),

        const SizedBox(height: 24),

        // Start Download Button (Inflated Clay Pill)
        ClayContainer(
          depth: 6,
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
          ),
          onTap: () {
            final rootContext = Navigator.of(
              context,
              rootNavigator: true,
            ).context;
            final isScheduled = state.scheduledAt != null;
            final scheduledTime = state.scheduledAt;
            Navigator.of(context).pop();
            notifier.startDownload();
            TopNotification.show(
              rootContext,
              message: isScheduled && scheduledTime != null
                  ? 'Download scheduled for ${_formatScheduledDateTime(scheduledTime)}'
                  : 'Download started in background!',
              actionLabel: 'VIEW',
              onAction: () {
                ref.read(activeTabProvider.notifier).state = 1;
              },
            );
          },
          child: Container(
            height: 54,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  state.scheduledAt != null
                      ? Icons.alarm_on_rounded
                      : Icons.download_rounded,
                  color: theme.colorScheme.onPrimary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  state.scheduledAt != null
                      ? 'Schedule Download'
                      : 'Start Download',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _formatScheduledDateTime(DateTime dt) {
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

  Widget _buildScheduleSection(
    BuildContext context,
    HomeState state,
    HomeNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheduledAt = state.scheduledAt;
    final isScheduled = scheduledAt != null;

    return ClayContainer(
      depth: 3,
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Schedule Download',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (isScheduled)
                AnimatedPressable(
                  onTap: () => notifier.setScheduledAt(null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.close_rounded,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Clear',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isScheduled
                ? 'Will start automatically at ${_formatScheduledDateTime(scheduledAt)}'
                : 'Download immediately or schedule for later (e.g. overnight)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isScheduled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isScheduled ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildScheduleChip(
                context: context,
                label: 'Now',
                isSelected: !isScheduled,
                onTap: () => notifier.setScheduledAt(null),
              ),
              _buildScheduleChip(
                context: context,
                label: '+30m',
                isSelected:
                    isScheduled &&
                    scheduledAt.difference(DateTime.now()).inMinutes >= 25 &&
                    scheduledAt.difference(DateTime.now()).inMinutes <= 35,
                onTap: () => notifier.setScheduledAt(
                  DateTime.now().add(const Duration(minutes: 30)),
                ),
              ),
              _buildScheduleChip(
                context: context,
                label: '+1h',
                isSelected:
                    isScheduled &&
                    scheduledAt.difference(DateTime.now()).inMinutes >= 55 &&
                    scheduledAt.difference(DateTime.now()).inMinutes <= 65,
                onTap: () => notifier.setScheduledAt(
                  DateTime.now().add(const Duration(hours: 1)),
                ),
              ),
              _buildScheduleChip(
                context: context,
                label: '+2h',
                isSelected:
                    isScheduled &&
                    scheduledAt.difference(DateTime.now()).inMinutes >= 115 &&
                    scheduledAt.difference(DateTime.now()).inMinutes <= 125,
                onTap: () => notifier.setScheduledAt(
                  DateTime.now().add(const Duration(hours: 2)),
                ),
              ),
              _buildScheduleChip(
                context: context,
                label: 'Tonight (2 AM)',
                isSelected: false,
                onTap: () {
                  final now = DateTime.now();
                  var target = DateTime(now.year, now.month, now.day, 2, 0);
                  if (target.isBefore(now)) {
                    target = target.add(const Duration(days: 1));
                  }
                  notifier.setScheduledAt(target);
                },
              ),
              _buildScheduleChip(
                context: context,
                label: 'Custom...',
                icon: Icons.calendar_today_rounded,
                isSelected: isScheduled,
                onTap: () async {
                  final now = DateTime.now();
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: scheduledAt ?? now,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 30)),
                  );
                  if (pickedDate == null || !context.mounted) return;
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: scheduledAt != null
                        ? TimeOfDay(
                            hour: scheduledAt.hour,
                            minute: scheduledAt.minute,
                          )
                        : TimeOfDay(hour: (now.hour + 1) % 24, minute: 0),
                  );
                  if (pickedTime == null) return;
                  final combined = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );
                  if (combined.isAfter(DateTime.now())) {
                    notifier.setScheduledAt(combined);
                  } else {
                    if (context.mounted) {
                      TopNotification.show(
                        context,
                        message: 'Scheduled time must be in the future',
                        isError: true,
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.18)
              : isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamOptionTile(
    BuildContext context,
    StreamOption stream,
    HomeState state,
  ) {
    final theme = Theme.of(context);
    final notifier = ref.read(homeProvider.notifier);

    final bool isSelected =
        stream.isAudioOnly == state.isAudioOnly &&
        (stream.isAudioOnly
            ? state.selectedQuality.contains('${(stream.bitrate ?? 0) ~/ 1000}')
            : (stream.height != null &&
                  state.selectedQuality.contains('${stream.height}')));

    return AnimatedPressable(
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (stream.isAudioOnly) {
              notifier.setAudioOnly(true);
              if (stream.bitrate != null) {
                notifier.setSelectedQuality(
                  '${(stream.bitrate! / 1000).round()} kbps',
                );
              }
              notifier.setSelectedFormat(stream.format);
            } else {
              notifier.setAudioOnly(false);
              if (stream.height != null) {
                notifier.setSelectedQuality('${stream.height}p');
              }
              notifier.setSelectedFormat(stream.format);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        (stream.isAudioOnly
                                ? theme.colorScheme.secondary
                                : theme.colorScheme.primary)
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    stream.isAudioOnly
                        ? Icons.audiotrack_rounded
                        : Icons.videocam_rounded,
                    size: 18,
                    color: stream.isAudioOnly
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            stream.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (stream.fps != null && stream.fps! > 30) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${stream.fps}fps',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${stream.format.toUpperCase()} • ${stream.codec ?? 'stream'} • itag #${stream.itag ?? '?'} • ${stream.isMuxed ? 'Video+Audio' : (stream.isAudioOnly ? 'Audio Only' : 'Video Only')}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      stream.formattedSize,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatResolutionLabel(String q) {
    if (q.toLowerCase() == 'best') return 'Best';
    final match = RegExp(r'(\d+)').firstMatch(q);
    if (match == null) return q;
    final h = int.tryParse(match.group(1)!);
    if (h == null) return q;
    if (h >= 4320) return '4320p (8K)';
    if (h >= 2160) return '2160p (4K)';
    if (h >= 1440) return '1440p (2K)';
    if (h >= 1080) return '1080p (FHD)';
    if (h >= 720) return '720p (HD)';
    return '${h}p';
  }

  String? _getResolutionSubtitle(String q, List<StreamOption> streams) {
    final highestAudioBytes = streams
        .where((s) => s.isAudioOnly)
        .fold<int>(
          0,
          (max, a) => (a.sizeBytes ?? 0) > max ? (a.sizeBytes ?? 0) : max,
        );

    if (q.toLowerCase() == 'best') {
      final best = streams.where((s) => !s.isAudioOnly).firstOrNull;
      if (best == null) return 'Highest';
      final total =
          (best.sizeBytes ?? 0) + (best.isMuxed ? 0 : highestAudioBytes);
      return total > 0 ? _formatBytes(total) : 'Highest';
    }
    final match = RegExp(r'(\d+)').firstMatch(q);
    if (match == null) return null;
    final h = int.tryParse(match.group(1)!);
    if (h == null) return null;
    final matching = streams
        .where((s) => !s.isAudioOnly && s.height == h)
        .toList();
    if (matching.isEmpty) return null;

    final bestStream = matching.first;
    final total =
        (bestStream.sizeBytes ?? 0) +
        (bestStream.isMuxed ? 0 : highestAudioBytes);
    return total > 0 ? _formatBytes(total) : null;
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String? _getAudioSubtitle(String q, List<StreamOption> streams) {
    if (q.toLowerCase() == 'best') {
      final best = streams.where((s) => s.isAudioOnly).firstOrNull;
      return best != null && best.formattedSize.isNotEmpty
          ? best.formattedSize
          : 'Highest';
    }
    final match = RegExp(r'(\d+)').firstMatch(q);
    if (match == null) return null;
    final targetKbps = int.tryParse(match.group(1)!);
    if (targetKbps == null) return null;

    final matching = streams.where((s) => s.isAudioOnly).toList()
      ..sort((a, b) {
        final aDiff = (((a.bitrate ?? 0) / 1000) - targetKbps).abs();
        final bDiff = (((b.bitrate ?? 0) / 1000) - targetKbps).abs();
        return aDiff.compareTo(bDiff);
      });

    if (matching.isEmpty) return null;
    final size = matching.first.formattedSize;
    return size.isNotEmpty ? size : null;
  }

  bool _isResolutionSelected(String chipQuality, String selectedQuality) {
    if (chipQuality.toLowerCase() == selectedQuality.toLowerCase()) return true;
    final m1 = RegExp(r'(\d+)').firstMatch(chipQuality);
    final m2 = RegExp(r'(\d+)').firstMatch(selectedQuality);
    if (m1 != null && m2 != null && m1.group(1) == m2.group(1)) return true;
    return false;
  }

  bool _isAudioQualitySelected(String chipQuality, String selectedQuality) {
    if (chipQuality.toLowerCase() == selectedQuality.toLowerCase()) return true;
    final m1 = RegExp(r'(\d+)').firstMatch(chipQuality);
    final m2 = RegExp(r'(\d+)').firstMatch(selectedQuality);
    if (m1 != null && m2 != null && m1.group(1) == m2.group(1)) return true;
    return false;
  }

  Widget _buildTypeToggleItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    if (isSelected) {
      return ClayContainer(
        depth: 4,
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
