import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../core/errors/logger_service.dart';
import '../core/utils/download_path_resolver.dart';
import 'download_engine.dart';
import 'models/download_progress.dart';
import 'models/download_request.dart';
import 'models/media_info.dart';
import 'models/stream_option.dart';

class _CachedMedia {
  final Video video;
  final StreamManifest manifest;
  final DateTime fetchedAt;

  _CachedMedia(this.video, this.manifest) : fetchedAt = DateTime.now();

  bool get isExpired => DateTime.now().difference(fetchedAt).inMinutes > 15;
}

/// Pure Dart implementation of [DownloadEngine] powered by youtube_explode_dart.
/// Runs natively across iOS, Android, macOS, Windows, and Linux without Python or subprocesses.
class DartEngine implements DownloadEngine {
  final YoutubeExplode _yt = YoutubeExplode();
  final Map<String, bool> _cancellationMap = {};
  final Map<String, bool> _pauseMap = {};
  final Map<String, _CachedMedia> _cache = {};
  bool _isFetchCancelled = false;

  static String? _ffmpegPath;
  static bool _checkedFfmpeg = false;

  /// Locates the system FFmpeg binary if available.
  static Future<String?> findFfmpeg() async {
    if (_checkedFfmpeg) return _ffmpegPath;
    _checkedFfmpeg = true;
    try {
      final cmd = Platform.isWindows ? 'where' : 'which';
      final res = await Process.run(cmd, ['ffmpeg']);
      if (res.exitCode == 0) {
        final path = (res.stdout as String).trim().split('\n').first.trim();
        if (path.isNotEmpty && await File(path).exists()) {
          _ffmpegPath = path;
          LoggerService.info('DartEngine: Found system FFmpeg at $path');
          return _ffmpegPath;
        }
      }
    } catch (_) {}

    final candidates = [
      '/opt/homebrew/bin/ffmpeg',
      '/usr/local/bin/ffmpeg',
      '/usr/bin/ffmpeg',
      'C:\\ffmpeg\\bin\\ffmpeg.exe',
      'C:\\Program Files\\ffmpeg\\bin\\ffmpeg.exe',
    ];
    for (final c in candidates) {
      if (await File(c).exists()) {
        _ffmpegPath = c;
        LoggerService.info('DartEngine: Found FFmpeg at fallback path $c');
        return _ffmpegPath;
      }
    }
    return null;
  }

  @override
  String get engineName => 'Pure Dart Engine (youtube_explode_dart)';

  @override
  Future<void> cancelFetch() async {
    _isFetchCancelled = true;
    LoggerService.info('DartEngine: fetchMediaInfo cancelled');
  }

  Future<_CachedMedia> _resolveMedia(String url) async {
    final cleanUrl = url.trim();
    final cached = _cache[cleanUrl];
    if (cached != null && !cached.isExpired) {
      return cached;
    }

    final video = await _yt.videos.get(cleanUrl);
    final manifest = await _yt.videos.streamsClient.getManifest(video.id);
    final media = _CachedMedia(video, manifest);

    _cache[cleanUrl] = media;
    _cache[video.id.value] = media;
    _cache[video.url] = media;
    return media;
  }

  @override
  Future<MediaInfo> fetchMediaInfo(String url) async {
    _isFetchCancelled = false;
    try {
      final cleanUrl = url.trim();

      // Check if it's a playlist
      if (cleanUrl.contains('list=')) {
        try {
          final playlist = await _yt.playlists.get(cleanUrl);
          return MediaInfo(
            url: cleanUrl,
            title: playlist.title,
            author: playlist.author,
            description: playlist.description,
            thumbnailUrl: playlist.thumbnails.highResUrl,
            isPlaylist: true,
            playlistCount: null, // Will be resolved if requested
          );
        } catch (_) {
          // Fall back to single video extraction if playlist lookup fails
        }
      }

      final media = await _resolveMedia(cleanUrl);
      if (_isFetchCancelled) {
        throw const DownloadCancelledException('Media fetch cancelled by user');
      }
      final video = media.video;
      final manifest = media.manifest;

      final List<String> qualities = [];
      final sortedVideos = manifest.video.toList()
        ..sort(
          (a, b) =>
              b.videoResolution.height.compareTo(a.videoResolution.height),
        );
      for (final s in sortedVideos) {
        final h = s.videoResolution.height;
        if (h > 0) {
          final label = '${h}p';
          if (!qualities.contains(label)) {
            qualities.add(label);
          }
        }
      }

      return MediaInfo(
        url: cleanUrl,
        title: video.title,
        author: video.author,
        duration: video.duration ?? Duration.zero,
        thumbnailUrl: video.thumbnails.highResUrl,
        description: video.description,
        isPlaylist: false,
        availableQualities: qualities.isNotEmpty ? qualities : ['Best'],
        viewCount: video.engagement.viewCount,
      );
    } catch (e, st) {
      LoggerService.error(
        'DartEngine.fetchMediaInfo failed for $url',
        error: e,
        stackTrace: st,
      );
      throw Exception('Failed to fetch media info: $e');
    }
  }

  @override
  Future<List<StreamOption>> getAvailableStreams(String url) async {
    try {
      final media = await _resolveMedia(url);
      final manifest = media.manifest;

      final List<StreamOption> options = [];

      // Add all available video resolutions sorted descending by height, then bitrate
      final sortedVideos = manifest.video.toList()
        ..sort((a, b) {
          final cmp = b.videoResolution.height.compareTo(
            a.videoResolution.height,
          );
          if (cmp != 0) return cmp;
          return b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond);
        });

      final seenVideoKeys = <String>{};
      for (final s in sortedVideos) {
        final h = s.videoResolution.height;
        String label = '${h}p';
        if (h >= 4320) {
          label = '4320p (8K UHD)';
        } else if (h >= 2160) {
          label = '2160p (4K UHD)';
        } else if (h >= 1440) {
          label = '1440p (2K QHD)';
        } else if (h >= 1080) {
          label = '1080p (FHD)';
        } else if (h >= 720) {
          label = '720p (HD)';
        }

        final key = '${s.tag}_${s.container.name}_${s.videoCodec}';
        if (!seenVideoKeys.contains(key)) {
          seenVideoKeys.add(key);
          options.add(
            StreamOption(
              label: label,
              format: s.container.name,
              isAudioOnly: false,
              isMuxed: s is MuxedStreamInfo,
              width: s.videoResolution.width,
              height: s.videoResolution.height,
              sizeBytes: s.size.totalBytes,
              bitrate: s.bitrate.bitsPerSecond,
              codec: s.videoCodec,
              itag: s.tag,
              fps: s.framerate.framesPerSecond.round(),
            ),
          );
        }
      }

      // Audio options sorted descending by bitrate
      final sortedAudio = manifest.audioOnly.toList()
        ..sort(
          (a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond),
        );

      final seenAudioKeys = <String>{};
      for (final a in sortedAudio) {
        final kbps = a.bitrate.kiloBitsPerSecond.round();
        final key = '${a.tag}_${a.container.name}_$kbps';
        if (!seenAudioKeys.contains(key)) {
          seenAudioKeys.add(key);
          options.add(
            StreamOption(
              label: '$kbps kbps Audio',
              format: a.container.name,
              isAudioOnly: true,
              isMuxed: false,
              sizeBytes: a.size.totalBytes,
              bitrate: a.bitrate.bitsPerSecond,
              codec: a.audioCodec,
              itag: a.tag,
            ),
          );
        }
      }

      return options;
    } catch (e) {
      LoggerService.error('Error getting streams: $e');
      return [];
    }
  }

  /// Downloads an individual stream to a file with granular progress reporting and resume capability.
  Future<void> _downloadStreamToFile({
    required StreamInfo streamInfo,
    required File destinationFile,
    required String taskId,
    required void Function(
      double progress,
      int bytes,
      double speed,
      int eta, {
      bool isSlow,
      bool isStalled,
    })
    onProgressUpdate,
    double progressStart = 0.0,
    double progressEnd = 1.0,
  }) async {
    final partFile = File('${destinationFile.path}.part');
    int downloadedBytes = 0;
    if (await partFile.exists()) {
      downloadedBytes = await partFile.length();
    }

    final totalBytes = streamInfo.size.totalBytes;
    if (totalBytes > 0 && downloadedBytes >= totalBytes) {
      if (await destinationFile.exists()) await destinationFile.delete();
      await partFile.rename(destinationFile.path);
      onProgressUpdate(progressEnd, totalBytes, 0.0, 0);
      return;
    }

    Stream<List<int>> stream;
    IOSink? sink;
    HttpClient? httpClient;

    if (downloadedBytes > 0) {
      try {
        httpClient = HttpClient();
        final request = await httpClient.getUrl(streamInfo.url);
        request.headers.add(HttpHeaders.rangeHeader, 'bytes=$downloadedBytes-');
        final response = await request.close();
        if (response.statusCode == HttpStatus.partialContent ||
            response.statusCode == HttpStatus.ok) {
          stream = response;
          if (response.statusCode == HttpStatus.ok) {
            downloadedBytes = 0;
            sink = partFile.openWrite(mode: FileMode.write);
          } else {
            sink = partFile.openWrite(mode: FileMode.append);
          }
        } else {
          stream = _yt.videos.streamsClient.get(streamInfo);
          downloadedBytes = 0;
          sink = partFile.openWrite(mode: FileMode.write);
        }
      } catch (e) {
        stream = _yt.videos.streamsClient.get(streamInfo);
        downloadedBytes = 0;
        sink = partFile.openWrite(mode: FileMode.write);
      }
    } else {
      stream = _yt.videos.streamsClient.get(streamInfo);
      sink = partFile.openWrite(mode: FileMode.write);
    }

    int lastFlushedBytes = downloadedBytes;
    Stopwatch? stopwatch;
    DateTime lastUpdateTime = DateTime.now();
    DateTime lastSpeedTime = DateTime.now();
    int lastBytesForSpeed = downloadedBytes;
    double currentSpeed = 0.0;

    try {
      final activeSink = sink;
      await for (final chunk in stream) {
        if (_pauseMap[taskId] == true) {
          await activeSink.flush();
          await activeSink.close();
          sink = null;
          httpClient?.close(force: true);
          throw const DownloadPausedException();
        }

        if (_cancellationMap[taskId] == true) {
          await activeSink.flush();
          await activeSink.close();
          sink = null;
          httpClient?.close(force: true);
          try {
            if (await partFile.exists()) await partFile.delete();
          } catch (_) {}
          throw const DownloadCancelledException();
        }

        activeSink.add(chunk);
        downloadedBytes += chunk.length;

        if (stopwatch == null) {
          stopwatch = Stopwatch()..start();
          lastSpeedTime = DateTime.now();
          lastBytesForSpeed = downloadedBytes;
          final p =
              progressStart +
              ((downloadedBytes / (totalBytes > 0 ? totalBytes : 1)) *
                      (progressEnd - progressStart))
                  .clamp(0.0, progressEnd - progressStart);
          onProgressUpdate(p, downloadedBytes, 0.0, 0);
        }

        if (downloadedBytes - lastFlushedBytes >= 1024 * 1024) {
          lastFlushedBytes = downloadedBytes;
          await activeSink.flush();
        }

        final now = DateTime.now();
        final speedIntervalMs = now.difference(lastSpeedTime).inMilliseconds;
        if (speedIntervalMs >= 1000) {
          final deltaBytes = downloadedBytes - lastBytesForSpeed;
          currentSpeed = deltaBytes / (speedIntervalMs / 1000.0);
          lastBytesForSpeed = downloadedBytes;
          lastSpeedTime = now;
        }

        if (now.difference(lastUpdateTime).inMilliseconds >= 250) {
          lastUpdateTime = now;
          final remainingBytes = totalBytes - downloadedBytes;
          final effectiveSpeed = currentSpeed > 0
              ? currentSpeed
              : (stopwatch.elapsedMilliseconds > 0
                    ? (downloadedBytes - lastBytesForSpeed) /
                          (stopwatch.elapsedMilliseconds / 1000.0)
                    : 0.0);
          final eta = effectiveSpeed > 0
              ? (remainingBytes / effectiveSpeed).round()
              : 0;
          final streamRatio = totalBytes > 0
              ? (downloadedBytes / totalBytes).clamp(0.0, 1.0)
              : 0.0;
          final overallProgress =
              progressStart + (streamRatio * (progressEnd - progressStart));

          final isSlow = currentSpeed > 0 && currentSpeed < 20 * 1024;
          onProgressUpdate(
            overallProgress,
            downloadedBytes,
            effectiveSpeed,
            eta,
            isSlow: isSlow,
            isStalled: false,
          );
        }
      }

      await activeSink.flush();
      await activeSink.close();
      sink = null;
      httpClient?.close();
      stopwatch?.stop();

      // Successfully finished stream: replace .part with target destination file
      if (await destinationFile.exists()) await destinationFile.delete();
      await partFile.rename(destinationFile.path);
    } finally {
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      httpClient?.close(force: true);
    }
  }

  @override
  Future<String> startDownload(
    String taskId,
    DownloadRequest request, {
    required void Function(DownloadProgress progress) onProgress,
  }) async {
    onProgress(
      const DownloadProgress(
        percentage: 0.0,
        downloadedBytes: 0,
        statusMessage: 'Resolving stream formats...',
      ),
    );

    try {
      if (_cancellationMap[taskId] == true) {
        throw const DownloadCancelledException();
      }

      final media = await _resolveMedia(request.url);
      final video = media.video;
      final manifest = media.manifest;

      if (_cancellationMap[taskId] == true) {
        throw const DownloadCancelledException();
      }

      final ffmpegPath = await findFfmpeg();

      // Destination directory resolution respecting category and playlist structure
      final outDir = await DownloadPathResolver.resolveDestinationDirectory(
        baseDirectory: request.outputDirectory,
        isAudioOnly: request.isAudioOnly,
        isPlaylist: request.isPlaylist,
        playlistTitle: request.playlistTitle,
      );

      final sanitizedTitle = DownloadPathResolver.sanitizeFolderName(
        video.title,
      );
      final extension = request.outputFormat.toLowerCase();
      final finalFilePath = p.join(outDir.path, '$sanitizedTitle.$extension');
      final finalFile = File(finalFilePath);

      // AUDIO ONLY MODE
      if (request.isAudioOnly) {
        StreamInfo audioStream;
        if (manifest.audioOnly.isNotEmpty) {
          final match = RegExp(r'(\d+)').firstMatch(request.selectedQuality);
          if (match != null) {
            final targetKbps = int.tryParse(match.group(1)!);
            if (targetKbps != null) {
              final sorted = manifest.audioOnly.toList()
                ..sort(
                  (a, b) => (a.bitrate.kiloBitsPerSecond - targetKbps)
                      .abs()
                      .compareTo(
                        (b.bitrate.kiloBitsPerSecond - targetKbps).abs(),
                      ),
                );
              audioStream = sorted.first;
            } else {
              audioStream = manifest.audioOnly.withHighestBitrate();
            }
          } else {
            audioStream = manifest.audioOnly.withHighestBitrate();
          }
        } else if (manifest.muxed.isNotEmpty) {
          audioStream = manifest.muxed.sortByBitrate().first;
        } else {
          audioStream = manifest.streams.first;
        }

        final audioExt = audioStream.container.name.toLowerCase();
        final needsConversion = ffmpegPath != null && extension != audioExt;

        final targetDownloadFile = needsConversion
            ? File(
                p.join(
                  outDir.path,
                  '.${sanitizedTitle}_${taskId}_temp.$audioExt',
                ),
              )
            : finalFile;

        try {
          await _downloadStreamToFile(
            streamInfo: audioStream,
            destinationFile: targetDownloadFile,
            taskId: taskId,
            onProgressUpdate:
                (
                  progress,
                  bytes,
                  speed,
                  eta, {
                  isSlow = false,
                  isStalled = false,
                }) {
                  onProgress(
                    DownloadProgress(
                      downloadedBytes: bytes,
                      totalBytes: audioStream.size.totalBytes,
                      speedBytesPerSecond: speed,
                      etaSeconds: eta,
                      percentage: needsConversion ? progress * 0.95 : progress,
                      statusMessage: isSlow
                          ? 'Slow connection detected (${(speed / 1024).toStringAsFixed(1)} KB/s)...'
                          : 'Downloading audio...',
                      isSlowSpeed: isSlow,
                      isStalled: isStalled,
                    ),
                  );
                },
          );

          if (_cancellationMap[taskId] == true) {
            throw const DownloadCancelledException();
          }

          if (needsConversion) {
            onProgress(
              DownloadProgress(
                downloadedBytes: audioStream.size.totalBytes,
                totalBytes: audioStream.size.totalBytes,
                percentage: 0.96,
                statusMessage:
                    'Converting to ${extension.toUpperCase()} with FFmpeg...',
              ),
            );

            final convertArgs = [
              '-i',
              targetDownloadFile.path,
              '-vn',
              if (extension == 'mp3') ...[
                '-c:a',
                'libmp3lame',
                '-b:a',
                '320k',
              ] else if (extension == 'aac') ...[
                '-c:a',
                'aac',
                '-b:a',
                '256k',
              ] else if (extension == 'wav') ...[
                '-c:a',
                'pcm_s16le',
              ] else if (extension == 'flac') ...[
                '-c:a',
                'flac',
              ] else ...[
                '-c:a',
                'copy',
              ],
              '-y',
              finalFilePath,
            ];

            final proc = await Process.run(ffmpegPath, convertArgs);
            try {
              if (await targetDownloadFile.exists()) {
                await targetDownloadFile.delete();
              }
            } catch (_) {}

            if (proc.exitCode != 0) {
              LoggerService.warning(
                'FFmpeg audio convert failed: ${proc.stderr}. Keeping original format.',
              );
              final fallbackPath = p.join(
                outDir.path,
                '$sanitizedTitle.$audioExt',
              );
              await targetDownloadFile.rename(fallbackPath);
              return fallbackPath;
            }
          }

          onProgress(
            DownloadProgress(
              downloadedBytes: audioStream.size.totalBytes,
              totalBytes: audioStream.size.totalBytes,
              percentage: 1.0,
              statusMessage: 'Complete',
            ),
          );

          return finalFilePath;
        } catch (e) {
          try {
            if (await targetDownloadFile.exists()) {
              await targetDownloadFile.delete();
            }
            if (await finalFile.exists()) {
              await finalFile.delete();
            }
          } catch (_) {}
          rethrow;
        }
      }

      // VIDEO MODE
      final quality = request.selectedQuality.trim();
      final match = RegExp(r'(\d+)').firstMatch(quality);
      final targetHeight = match != null ? int.tryParse(match.group(1)!) : null;

      StreamInfo? selectedStream;

      if (targetHeight != null) {
        // If FFmpeg is present, match targetHeight across all video streams
        if (ffmpegPath != null) {
          final matchingVideos = manifest.video
              .where((s) => s.videoResolution.height == targetHeight)
              .toList();
          if (matchingVideos.isNotEmpty) {
            matchingVideos.sort((a, b) {
              final aIsFmt = a.container.name.toLowerCase() == extension;
              final bIsFmt = b.container.name.toLowerCase() == extension;
              if (aIsFmt != bIsFmt) return aIsFmt ? -1 : 1;
              return b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond);
            });
            selectedStream = matchingVideos.first;
          }
        }

        // If not found or no FFmpeg, try matching in muxed streams
        if (selectedStream == null && manifest.muxed.isNotEmpty) {
          final matchingMuxed = manifest.muxed
              .where((s) => s.videoResolution.height == targetHeight)
              .toList();
          if (matchingMuxed.isNotEmpty) {
            selectedStream = matchingMuxed.first;
          }
        }
      }

      // Fallback: Best quality
      if (selectedStream == null) {
        if (ffmpegPath != null && manifest.video.isNotEmpty) {
          final sortedVideos = manifest.video.toList()
            ..sort((a, b) {
              final cmp = b.videoResolution.height.compareTo(
                a.videoResolution.height,
              );
              if (cmp != 0) return cmp;
              return b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond);
            });
          selectedStream = sortedVideos.first;
        } else if (manifest.muxed.isNotEmpty) {
          final sortedMuxed = manifest.muxed.toList()
            ..sort(
              (a, b) =>
                  b.videoResolution.height.compareTo(a.videoResolution.height),
            );
          selectedStream = sortedMuxed.first;
        } else if (manifest.video.isNotEmpty) {
          selectedStream = manifest.video.first;
        } else {
          selectedStream = manifest.streams.first;
        }
      }

      final chosenStream = selectedStream;

      // Check if video needs audio muxing (i.e. it's a VideoOnlyStreamInfo and FFmpeg is available)
      if (chosenStream is VideoOnlyStreamInfo && ffmpegPath != null) {
        final audioStream = manifest.audioOnly.isNotEmpty
            ? manifest.audioOnly.withHighestBitrate()
            : manifest.streams.first;

        final videoBytes = chosenStream.size.totalBytes;
        final audioBytes = audioStream.size.totalBytes;
        final totalBytes = videoBytes + audioBytes;

        final tempVideoFile = File(
          p.join(
            outDir.path,
            '.${sanitizedTitle}_${taskId}_v.${chosenStream.container.name}',
          ),
        );
        final tempAudioFile = File(
          p.join(
            outDir.path,
            '.${sanitizedTitle}_${taskId}_a.${audioStream.container.name}',
          ),
        );

        try {
          // 1. Download Video Track (0% to 85%)
          await _downloadStreamToFile(
            streamInfo: chosenStream,
            destinationFile: tempVideoFile,
            taskId: taskId,
            progressStart: 0.0,
            progressEnd: 0.85,
            onProgressUpdate:
                (prog, bytes, speed, eta, {isSlow = false, isStalled = false}) {
                  onProgress(
                    DownloadProgress(
                      downloadedBytes: bytes,
                      totalBytes: totalBytes,
                      speedBytesPerSecond: speed,
                      etaSeconds: eta,
                      percentage: prog,
                      isSlowSpeed: isSlow,
                      isStalled: isStalled,
                      statusMessage: isSlow
                          ? 'Slow connection detected (${(speed / 1024).toStringAsFixed(1)} KB/s)...'
                          : 'Downloading video (${chosenStream.videoResolution.height}p)...',
                    ),
                  );
                },
          );

          if (_pauseMap[taskId] == true) {
            throw const DownloadPausedException();
          }

          if (_cancellationMap[taskId] == true) {
            throw const DownloadCancelledException();
          }

          // 2. Download Audio Track (85% to 97%)
          await _downloadStreamToFile(
            streamInfo: audioStream,
            destinationFile: tempAudioFile,
            taskId: taskId,
            progressStart: 0.85,
            progressEnd: 0.97,
            onProgressUpdate:
                (prog, bytes, speed, eta, {isSlow = false, isStalled = false}) {
                  onProgress(
                    DownloadProgress(
                      downloadedBytes: videoBytes + bytes,
                      totalBytes: totalBytes,
                      speedBytesPerSecond: speed,
                      etaSeconds: eta,
                      percentage: prog,
                      isSlowSpeed: isSlow,
                      isStalled: isStalled,
                      statusMessage: isSlow
                          ? 'Slow connection detected (${(speed / 1024).toStringAsFixed(1)} KB/s)...'
                          : 'Downloading audio track...',
                    ),
                  );
                },
          );

          if (_pauseMap[taskId] == true) {
            throw const DownloadPausedException();
          }

          if (_cancellationMap[taskId] == true) {
            throw const DownloadCancelledException();
          }

          // 3. Mux Video and Audio via FFmpeg (98%)
          onProgress(
            DownloadProgress(
              downloadedBytes: totalBytes,
              totalBytes: totalBytes,
              percentage: 0.98,
              statusMessage: 'Muxing video & audio with FFmpeg...',
            ),
          );

          final isCopyAudio = (extension == 'mkv' || extension == 'webm');
          final muxArgs = [
            '-i',
            tempVideoFile.path,
            '-i',
            tempAudioFile.path,
            '-c:v',
            'copy',
            if (isCopyAudio) ...[
              '-c:a',
              'copy',
            ] else ...[
              '-c:a',
              'aac',
              '-b:a',
              '256k',
            ],
            '-y',
            finalFilePath,
          ];

          final proc = await Process.run(ffmpegPath, muxArgs);

          // Clean up temp files
          try {
            if (await tempVideoFile.exists()) await tempVideoFile.delete();
            if (await tempAudioFile.exists()) await tempAudioFile.delete();
          } catch (_) {}

          if (proc.exitCode != 0) {
            LoggerService.error('FFmpeg muxing failed: ${proc.stderr}');
            throw Exception('FFmpeg muxing failed: ${proc.stderr}');
          }

          onProgress(
            DownloadProgress(
              downloadedBytes: totalBytes,
              totalBytes: totalBytes,
              percentage: 1.0,
              statusMessage: 'Complete',
            ),
          );

          return finalFilePath;
        } on DownloadPausedException {
          rethrow;
        } on DownloadCancelledException {
          try {
            if (await tempVideoFile.exists()) await tempVideoFile.delete();
            final vp = File('${tempVideoFile.path}.part');
            if (await vp.exists()) await vp.delete();
            if (await tempAudioFile.exists()) await tempAudioFile.delete();
            final ap = File('${tempAudioFile.path}.part');
            if (await ap.exists()) await ap.delete();
            if (await finalFile.exists()) await finalFile.delete();
            final fp = File('${finalFile.path}.part');
            if (await fp.exists()) await fp.delete();
          } catch (_) {}
          rethrow;
        } catch (e) {
          rethrow;
        }
      } else {
        // Single stream download (e.g. MuxedStreamInfo or video-only without ffmpeg)
        try {
          await _downloadStreamToFile(
            streamInfo: chosenStream,
            destinationFile: finalFile,
            taskId: taskId,
            progressStart: 0.0,
            progressEnd: 1.0,
            onProgressUpdate:
                (prog, bytes, speed, eta, {isSlow = false, isStalled = false}) {
                  onProgress(
                    DownloadProgress(
                      downloadedBytes: bytes,
                      totalBytes: chosenStream.size.totalBytes,
                      speedBytesPerSecond: speed,
                      etaSeconds: eta,
                      percentage: prog,
                      isSlowSpeed: isSlow,
                      isStalled: isStalled,
                      statusMessage: isSlow
                          ? 'Slow connection detected (${(speed / 1024).toStringAsFixed(1)} KB/s)...'
                          : 'Downloading...',
                    ),
                  );
                },
          );

          onProgress(
            DownloadProgress(
              downloadedBytes: chosenStream.size.totalBytes,
              totalBytes: chosenStream.size.totalBytes,
              percentage: 1.0,
              statusMessage: 'Complete',
            ),
          );

          return finalFilePath;
        } on DownloadPausedException {
          rethrow;
        } on DownloadCancelledException {
          try {
            if (await finalFile.exists()) await finalFile.delete();
            final fp = File('${finalFile.path}.part');
            if (await fp.exists()) await fp.delete();
          } catch (_) {}
          rethrow;
        } catch (e) {
          rethrow;
        }
      }
    } finally {
      _cancellationMap.remove(taskId);
      _pauseMap.remove(taskId);
    }
  }

  @override
  Future<void> pauseDownload(String taskId) async {
    _pauseMap[taskId] = true;
  }

  @override
  Future<void> cancelDownload(String taskId) async {
    _cancellationMap[taskId] = true;
    _pauseMap.remove(taskId);
  }

  @override
  Future<bool> isPlaylist(String url) async {
    return url.contains('list=');
  }

  @override
  Future<List<MediaInfo>> fetchPlaylistItems(String url) async {
    try {
      final List<MediaInfo> items = [];
      await for (final video in _yt.playlists.getVideos(url)) {
        items.add(
          MediaInfo(
            url: video.url,
            title: video.title,
            author: video.author,
            duration: video.duration ?? Duration.zero,
            thumbnailUrl: video.thumbnails.highResUrl,
          ),
        );
      }
      return items;
    } catch (e) {
      LoggerService.error('Error fetching playlist items: $e');
      return [];
    }
  }

  @override
  Future<String?> checkEngineUpdate() async {
    return null; // Pure Dart package, updated via app release
  }
}
