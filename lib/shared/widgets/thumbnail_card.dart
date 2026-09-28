import 'package:flutter/material.dart';

/// Displays a media thumbnail with an optional duration badge and playlist count overlay.
class ThumbnailCard extends StatelessWidget {
  final String? imageUrl;
  final String? durationText;
  final bool isPlaylist;
  final int? playlistCount;
  final double width;
  final double height;
  final double borderRadius;

  const ThumbnailCard({
    super.key,
    this.imageUrl,
    this.durationText,
    this.isPlaylist = false,
    this.playlistCount,
    this.width = 120,
    this.height = 70,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image or placeholder
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildPlaceholder(context),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  );
                },
              )
            else
              _buildPlaceholder(context),

            // Duration badge in bottom right corner
            if (durationText != null && durationText!.isNotEmpty && !isPlaylist)
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    durationText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // Playlist overlay on right edge
            if (isPlaylist)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: 40,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.65),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.playlist_play,
                        color: Colors.white,
                        size: 20,
                      ),
                      if (playlistCount != null)
                        Text(
                          '$playlistCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
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
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        isPlaylist
            ? Icons.playlist_play_rounded
            : Icons.play_circle_fill_rounded,
        size: 32,
        color: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
    );
  }
}
