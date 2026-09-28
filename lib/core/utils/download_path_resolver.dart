import 'dart:io';
import 'package:path/path.dart' as p;

/// Resolves, constructs, and prepares target download directories across platforms.
///
/// Directory structure hierarchy:
/// [Base Directory] (e.g., ~/Downloads/MediaGrab)
///   ├── video/
///   │     ├── [Playlist Title]/ (for playlists)
///   │     └── video_file.mp4 (for standalone videos)
///   └── audio/
///         ├── [Playlist Title]/ (for playlists)
///         └── audio_track.mp3 (for standalone audio)
class DownloadPathResolver {
  static const String videoSubdir = 'video';
  static const String audioSubdir = 'audio';

  /// Returns 'audio' if [isAudioOnly] is true, otherwise 'video'.
  static String getCategorySubfolder({required bool isAudioOnly}) {
    return isAudioOnly ? audioSubdir : videoSubdir;
  }

  /// Sanitizes folder or file names by removing invalid OS filesystem characters
  /// across Windows, macOS, Linux, and Android.
  static String sanitizeFolderName(String name) {
    // Strip illegal filesystem characters: \ / : * ? " < > | and common problematic shell characters
    final clean = name
        .replaceAll(RegExp(r'[\/\\:*?"<>|#%&{}!@+`|=~^]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[\x00-\x1F]'), '')
        .trim();

    // Strip trailing dots or spaces which Windows forbids in folder names
    final trimmed = clean.replaceAll(RegExp(r'[.\s]+$'), '');
    if (trimmed.isEmpty) {
      return 'playlist_${DateTime.now().millisecondsSinceEpoch}';
    }
    return trimmed;
  }

  /// Builds the full target directory path synchronously.
  static String buildDestinationPath({
    required String baseDirectory,
    required bool isAudioOnly,
    bool isPlaylist = false,
    String? playlistTitle,
  }) {
    final cleanBase = baseDirectory.trim().isNotEmpty
        ? baseDirectory.trim()
        : p.join(Directory.systemTemp.path, 'MediaGrab');

    final category = getCategorySubfolder(isAudioOnly: isAudioOnly);

    if (isPlaylist &&
        playlistTitle != null &&
        playlistTitle.trim().isNotEmpty) {
      final sanitizedTitle = sanitizeFolderName(playlistTitle);
      return p.join(cleanBase, category, sanitizedTitle);
    }

    return p.join(cleanBase, category);
  }

  /// Resolves the destination directory, creating it recursively if needed.
  static Future<Directory> resolveDestinationDirectory({
    required String baseDirectory,
    required bool isAudioOnly,
    bool isPlaylist = false,
    String? playlistTitle,
  }) async {
    final targetPath = buildDestinationPath(
      baseDirectory: baseDirectory,
      isAudioOnly: isAudioOnly,
      isPlaylist: isPlaylist,
      playlistTitle: playlistTitle,
    );

    final dir = Directory(targetPath);
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (_) {
      // Fallback: Ensure at least base temp exists if storage permission fails
      final fallback = Directory(
        p.join(
          Directory.systemTemp.path,
          'MediaGrab',
          getCategorySubfolder(isAudioOnly: isAudioOnly),
        ),
      );
      if (!await fallback.exists()) {
        await fallback.create(recursive: true);
      }
      return fallback;
    }
  }
}
