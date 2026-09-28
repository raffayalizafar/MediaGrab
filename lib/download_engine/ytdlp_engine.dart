import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../core/errors/logger_service.dart';
import 'download_engine.dart';
import 'models/download_progress.dart';
import 'models/download_request.dart';
import 'models/media_info.dart';
import 'models/stream_option.dart';
import 'task_factory.dart';

/// Desktop yt-dlp subprocess engine for macOS, Windows, and Linux.
/// Provides full access to 1,800+ sites supported by yt-dlp.
class YtDlpEngine implements DownloadEngine {
  final String? customBinaryPath;
  final String? ffmpegPath;
  final String? aria2cPath;
  final Map<String, Process> _runningProcesses = {};
  final Set<String> _pausedTasks = {};
  Process? _activeInfoProcess;

  YtDlpEngine({this.customBinaryPath, this.ffmpegPath, this.aria2cPath});

  @override
  String get engineName => 'yt-dlp Subprocess Engine';

  @override
  Future<void> cancelFetch() async {
    try {
      _activeInfoProcess?.kill();
      _activeInfoProcess = null;
      LoggerService.info('YtDlpEngine: fetchMediaInfo process killed');
    } catch (_) {}
  }

  /// Resolves the yt-dlp executable path.
  Future<String> _getYtDlpPath() async {
    if (customBinaryPath != null && customBinaryPath!.isNotEmpty) {
      if (await File(customBinaryPath!).exists()) {
        return customBinaryPath!;
      }
    }

    // Check system PATH
    try {
      final testCommand = Platform.isWindows ? 'where' : 'which';
      final result = await Process.run(testCommand, ['yt-dlp']);
      if (result.exitCode == 0) {
        final path = result.stdout.toString().trim().split('\n').first.trim();
        if (path.isNotEmpty) return path;
      }
    } catch (_) {}

    // Fallback to standard command name
    return Platform.isWindows ? 'yt-dlp.exe' : 'yt-dlp';
  }

  @override
  Future<MediaInfo> fetchMediaInfo(String url) async {
    final bin = await _getYtDlpPath();
    final args = [
      '--dump-single-json',
      '--flat-playlist',
      '--no-warnings',
      url.trim(),
    ];

    try {
      final process = await Process.start(bin, args);
      _activeInfoProcess = process;

      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();

      final exitCode = await process.exitCode;
      _activeInfoProcess = null;

      if (exitCode != 0) {
        final err = await stderrFuture;
        throw Exception('yt-dlp error: $err');
      }

      final stdoutStr = await stdoutFuture;
      final json = jsonDecode(stdoutStr) as Map<String, dynamic>;
      final isPlaylist = json['_type'] == 'playlist';

      final List<String> qualities = [];
      if (json['formats'] != null && json['formats'] is List) {
        final heights = <int>{};
        for (final f in json['formats'] as List) {
          final h = f['height'];
          if (h is num && h > 0) {
            heights.add(h.toInt());
          }
        }
        final sorted = heights.toList()..sort((a, b) => b.compareTo(a));
        for (final h in sorted) {
          qualities.add('${h}p');
        }
      }

      final List<String> subtitles = [];
      if (json['subtitles'] != null && json['subtitles'] is Map) {
        subtitles.addAll((json['subtitles'] as Map).keys.cast<String>());
      }

      return MediaInfo(
        url: url,
        title: json['title'] as String? ?? 'Unknown Title',
        author:
            json['uploader'] as String? ??
            json['channel'] as String? ??
            'Unknown',
        duration: Duration(seconds: (json['duration'] as num?)?.round() ?? 0),
        thumbnailUrl: json['thumbnail'] as String?,
        description: json['description'] as String?,
        isPlaylist: isPlaylist,
        playlistCount: isPlaylist ? (json['playlist_count'] as int?) : null,
        availableQualities: qualities.isNotEmpty ? qualities : ['Best'],
        availableSubtitles: subtitles,
        viewCount: (json['view_count'] as num?)?.round(),
      );
    } catch (e, st) {
      LoggerService.error(
        'YtDlpEngine.fetchMediaInfo failed for $url',
        error: e,
        stackTrace: st,
      );
      throw Exception('Failed to fetch media info via yt-dlp: $e');
    }
  }

  @override
  Future<List<StreamOption>> getAvailableStreams(String url) async {
    final bin = await _getYtDlpPath();
    final args = ['--dump-json', url.trim()];

    try {
      final result = await Process.run(bin, args);
      if (result.exitCode != 0) return [];

      final json = jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
      final formats = json['formats'] as List? ?? [];
      final List<StreamOption> options = [];

      for (final f in formats) {
        final height = f['height'] as int?;
        final ext = f['ext'] as String? ?? 'mp4';
        final vcodec = f['vcodec'] as String?;
        final acodec = f['acodec'] as String?;
        final isAudioOnly =
            (vcodec == null || vcodec == 'none') &&
            acodec != null &&
            acodec != 'none';

        options.add(
          StreamOption(
            label: isAudioOnly
                ? '${f['abr'] ?? 128} kbps Audio'
                : '${height ?? 'Unknown'}p (${f['format_note'] ?? ext})',
            format: ext,
            isAudioOnly: isAudioOnly,
            height: height,
            sizeBytes: f['filesize'] as int? ?? f['filesize_approx'] as int?,
            codec: isAudioOnly ? acodec : vcodec,
          ),
        );
      }

      return options;
    } catch (e) {
      LoggerService.error('Error fetching stream options: $e');
      return [];
    }
  }

  @override
  Future<String> startDownload(
    String taskId,
    DownloadRequest request, {
    required void Function(DownloadProgress progress) onProgress,
  }) async {
    final bin = await _getYtDlpPath();
    final args = TaskFactory.buildArgs(
      request,
      ffmpegPath: ffmpegPath,
      aria2cPath: aria2cPath,
    );

    LoggerService.info('Starting yt-dlp with args: ${args.join(' ')}');

    final process = await Process.start(bin, args);
    _runningProcesses[taskId] = process;

    String? destinationFile;
    final completer = Completer<String>();

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final trimmed = line.trim();
          if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
            try {
              final data = jsonDecode(trimmed) as Map<String, dynamic>;
              final status = data['status'] as String?;
              final downloaded =
                  (data['downloaded_bytes'] as num?)?.round() ?? 0;
              final total =
                  (data['total_bytes'] as num?)?.round() ??
                  (data['total_bytes_estimate'] as num?)?.round() ??
                  0;
              final speed = (data['speed'] as num?)?.toDouble() ?? 0.0;
              final eta = (data['eta'] as num?)?.round() ?? 0;
              final filename = data['filename'] as String?;

              if (filename != null) {
                destinationFile = filename;
              }

              final percent = total > 0
                  ? (downloaded / total).clamp(0.0, 1.0)
                  : 0.0;

              onProgress(
                DownloadProgress(
                  downloadedBytes: downloaded,
                  totalBytes: total,
                  speedBytesPerSecond: speed,
                  etaSeconds: eta,
                  percentage: percent,
                  statusMessage: status == 'finished'
                      ? 'Muxing/Processing...'
                      : 'Downloading...',
                ),
              );
            } catch (_) {}
          } else if (trimmed.contains('[download] Destination:')) {
            destinationFile = trimmed
                .split('[download] Destination:')
                .last
                .trim();
          }
        });

    final errorLines = <String>[];
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((err) {
          errorLines.add(err);
          LoggerService.warning('yt-dlp stderr: $err');
        });

    process.exitCode
        .then((code) {
          _runningProcesses.remove(taskId);
          if (_pausedTasks.remove(taskId)) {
            completer.completeError(const DownloadPausedException());
            return;
          }
          if (code == 0) {
            onProgress(
              const DownloadProgress(
                percentage: 1.0,
                statusMessage: 'Finished',
              ),
            );
            completer.complete(destinationFile ?? request.outputDirectory);
          } else {
            completer.completeError(
              Exception(
                'yt-dlp exited with code $code: ${errorLines.join('\n')}',
              ),
            );
          }
        })
        .catchError((err) {
          _runningProcesses.remove(taskId);
          _pausedTasks.remove(taskId);
          completer.completeError(err);
        });

    return completer.future;
  }

  @override
  Future<void> pauseDownload(String taskId) async {
    _pausedTasks.add(taskId);
    final process = _runningProcesses[taskId];
    if (process != null) {
      if (Platform.isWindows) {
        process.kill(ProcessSignal.sigkill);
      } else {
        process.kill(ProcessSignal.sigterm);
      }
    }
  }

  @override
  Future<void> cancelDownload(String taskId) async {
    _pausedTasks.remove(taskId);
    final process = _runningProcesses[taskId];
    if (process != null) {
      process.kill();
      _runningProcesses.remove(taskId);
    }
  }

  @override
  Future<bool> isPlaylist(String url) async {
    return url.contains('list=');
  }

  @override
  Future<List<MediaInfo>> fetchPlaylistItems(String url) async {
    final bin = await _getYtDlpPath();
    final args = ['--flat-playlist', '--dump-json', url];

    try {
      final result = await Process.run(bin, args);
      if (result.exitCode != 0) return [];

      final List<MediaInfo> items = [];
      final lines = result.stdout.toString().split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          items.add(
            MediaInfo(
              url: json['url'] ?? url,
              title: json['title'] ?? 'Untitled',
              author: json['uploader'] ?? json['channel'] ?? 'Unknown',
              duration: Duration(
                seconds: (json['duration'] as num?)?.round() ?? 0,
              ),
              thumbnailUrl: json['thumbnail'] as String?,
            ),
          );
        } catch (_) {}
      }
      return items;
    } catch (e) {
      LoggerService.error('Error fetching yt-dlp playlist items: $e');
      return [];
    }
  }

  @override
  Future<String?> checkEngineUpdate() async {
    try {
      final bin = await _getYtDlpPath();
      final result = await Process.run(bin, ['--version']);
      if (result.exitCode == 0) {
        return 'Installed yt-dlp: ${result.stdout.toString().trim()}';
      }
    } catch (_) {}
    return null;
  }
}
