import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../core/errors/logger_service.dart';
import 'dart_engine.dart';
import 'download_engine.dart';
import 'ytdlp_engine.dart';

/// Resolves the optimal download engine for the active platform.
class EngineResolver {
  static DownloadEngine? _cachedEngine;

  /// Gets the default engine based on OS and availability.
  static Future<DownloadEngine> resolveDefaultEngine({
    String? customBinaryPath,
    String? ffmpegPath,
    String? aria2cPath,
  }) async {
    if (_cachedEngine != null) {
      return _cachedEngine!;
    }

    if (kIsWeb) {
      _cachedEngine = DartEngine();
      return _cachedEngine!;
    }

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      // Check if yt-dlp is present
      try {
        final testCommand = Platform.isWindows ? 'where' : 'which';
        final check = await Process.run(testCommand, ['yt-dlp']);
        if (check.exitCode == 0 ||
            (customBinaryPath != null && customBinaryPath.isNotEmpty)) {
          LoggerService.info('Selected YtDlpEngine for Desktop');
          _cachedEngine = YtDlpEngine(
            customBinaryPath: customBinaryPath,
            ffmpegPath: ffmpegPath,
            aria2cPath: aria2cPath,
          );
          return _cachedEngine!;
        }
      } catch (e) {
        LoggerService.warning('Failed to detect yt-dlp in PATH: $e');
      }

      LoggerService.info(
        'yt-dlp not detected in PATH; using DartEngine as desktop fallback',
      );
      _cachedEngine = DartEngine();
      return _cachedEngine!;
    }

    // iOS and Android default to DartEngine
    LoggerService.info('Selected DartEngine for mobile platform');
    _cachedEngine = DartEngine();
    return _cachedEngine!;
  }
}
