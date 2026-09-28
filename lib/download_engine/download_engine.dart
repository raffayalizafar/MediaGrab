import 'models/download_progress.dart';
import 'models/download_request.dart';
import 'models/media_info.dart';
import 'models/stream_option.dart';

/// Abstract contract for platform-specific download engines.
/// Allows swapping between pure Dart (iOS/Mobile), native yt-dlp (Desktop),
/// and youtubedl-android (Android) transparently.
abstract class DownloadEngine {
  /// Name of the current download engine.
  String get engineName;

  /// Fetches video or playlist metadata from a URL.
  Future<MediaInfo> fetchMediaInfo(String url);

  /// Retrieves available video/audio streams and resolutions for a URL.
  Future<List<StreamOption>> getAvailableStreams(String url);

  /// Cancels an active metadata/stream fetch operation.
  Future<void> cancelFetch();

  /// Initiates a download task and streams progress updates.
  /// Returns the final destination file path upon completion.
  Future<String> startDownload(
    String taskId,
    DownloadRequest request, {
    required void Function(DownloadProgress progress) onProgress,
  });

  /// Cancels an in-progress download task.
  Future<void> cancelDownload(String taskId);

  /// Pauses an in-progress download task while retaining partial files.
  Future<void> pauseDownload(String taskId);

  /// Checks if the URL represents a playlist.
  Future<bool> isPlaylist(String url);

  /// Fetches individual entries from a playlist.
  Future<List<MediaInfo>> fetchPlaylistItems(String url);

  /// Checks if the engine binary / extractors have an update available.
  Future<String?> checkEngineUpdate();
}

/// Exception thrown when a download task is cancelled by user action or system request.
class DownloadCancelledException implements Exception {
  final String message;
  const DownloadCancelledException([
    this.message = 'Download cancelled by user',
  ]);

  @override
  String toString() => message;
}

/// Exception thrown when a download task is paused by user action or network policy.
class DownloadPausedException implements Exception {
  final String message;
  const DownloadPausedException([this.message = 'Download paused']);

  @override
  String toString() => message;
}
