import 'package:path/path.dart' as p;
import '../core/utils/download_path_resolver.dart';
import 'models/download_request.dart';

/// Builds sanitized yt-dlp CLI arguments from high-level DownloadRequests.
/// Inspired by Seal's TaskFactory.kt architecture.
class TaskFactory {
  /// Builds yt-dlp argument list for desktop/subprocess and android execution.
  static List<String> buildArgs(
    DownloadRequest request, {
    String? ffmpegPath,
    String? aria2cPath,
  }) {
    final List<String> args = [
      '--newline',
      '--progress-template',
      '%(progress)j',
      '--no-mtime',
      '-c',
    ];

    if (ffmpegPath != null && ffmpegPath.isNotEmpty) {
      args.addAll(['--ffmpeg-location', ffmpegPath]);
    }

    // Output directory & filename pattern
    final typeSubdir = DownloadPathResolver.getCategorySubfolder(
      isAudioOnly: request.isAudioOnly,
    );
    final String outputPath;
    if (request.isPlaylist) {
      final playlistFolder =
          (request.playlistTitle != null &&
              request.playlistTitle!.trim().isNotEmpty)
          ? DownloadPathResolver.sanitizeFolderName(request.playlistTitle!)
          : '%(playlist_title)s';
      outputPath = p.join(
        request.outputDirectory,
        typeSubdir,
        playlistFolder,
        '%(playlist_index)02d - %(title)s.%(ext)s',
      );
    } else {
      outputPath = p.join(
        request.outputDirectory,
        typeSubdir,
        '%(title)s.%(ext)s',
      );
    }
    args.addAll(['-o', outputPath]);

    // Playlist handling
    if (!request.isPlaylist) {
      args.add('--no-playlist');
    } else {
      args.add('--yes-playlist');
      if (request.playlistIndices != null &&
          request.playlistIndices!.isNotEmpty) {
        args.addAll(['--playlist-items', request.playlistIndices!.join(',')]);
      }
    }

    if (request.isAudioOnly) {
      // Audio extraction mode
      args.addAll(['-x', '--audio-format', request.outputFormat]);

      // Audio tagging & cover art
      if (request.embedMetadata) {
        args.add('--embed-metadata');
      }
      if (request.embedThumbnail) {
        args.add('--embed-thumbnail');
      }
    } else {
      // Video mode: Format & Quality
      final quality = request.selectedQuality;
      if (quality == 'Best' || quality.isEmpty) {
        args.addAll(['-f', 'bestvideo+bestaudio/best']);
      } else {
        final height = _extractResolutionHeight(quality);
        if (height != null) {
          args.addAll([
            '-f',
            'bestvideo[height<=$height]+bestaudio/best[height<=$height]/best',
          ]);
        } else {
          args.addAll(['-f', 'bestvideo+bestaudio/best']);
        }
      }

      // Merge output container (e.g. mp4, mkv)
      args.addAll(['--merge-output-format', request.outputFormat]);

      // Subtitles
      if (request.embedSubtitles) {
        args.addAll([
          '--write-subs',
          '--write-auto-subs',
          '--embed-subs',
          '--sub-langs',
          '${request.subtitleLanguage}.*,all',
        ]);
      }

      // Video metadata & chapter markers
      if (request.embedMetadata) {
        args.add('--embed-metadata');
      }
      if (request.embedThumbnail) {
        args.add('--embed-thumbnail');
      }
    }

    // External downloader (aria2c) acceleration
    if (request.useAria2c) {
      if (aria2cPath != null && aria2cPath.isNotEmpty) {
        args.addAll(['--downloader', aria2cPath]);
      } else {
        args.addAll(['--downloader', 'aria2c']);
      }
      args.addAll([
        '--downloader-args',
        'aria2c:-c -x 16 -s 16 -k 1M -j 16 --summary-interval=1',
      ]);
    }

    // Custom power-user arguments
    if (request.customArgs != null && request.customArgs!.trim().isNotEmpty) {
      final customTokens = _tokenizeCustomArgs(request.customArgs!);
      args.addAll(customTokens);
    }

    // Target URL is always appended last
    args.add(request.url);

    return args;
  }

  /// Extracts numeric height from labels like '1080p', '720p', '2160p (4K)', 'high1080'
  static int? _extractResolutionHeight(String quality) {
    final match = RegExp(r'(\d+)').firstMatch(quality);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  /// Tokenizes custom command string safely, handling quotes and whitespace.
  static List<String> _tokenizeCustomArgs(String input) {
    final List<String> tokens = [];
    final matches = RegExp(
      r'''[^\s"']+|"([^"]*)"|'([^']*)' ''',
    ).allMatches(input);
    for (final match in matches) {
      final token = match.group(1) ?? match.group(2) ?? match.group(0);
      if (token != null && token.trim().isNotEmpty) {
        // Prevent dangerous shell command injection flags
        if (token == '--exec' || token.startsWith('--exec=')) {
          continue;
        }
        tokens.add(token.trim());
      }
    }
    return tokens;
  }
}
