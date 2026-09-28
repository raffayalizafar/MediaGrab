import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../download_engine/engine_resolver.dart';
import '../../download_engine/ytdlp_engine.dart';

/// Dynamically queries real disk space and directory status for the download directory.
final storageInfoProvider = FutureProvider.family<String, String>((
  ref,
  path,
) async {
  if (path.isEmpty) return 'Default Storage Ready';

  if (!kIsWeb && (Platform.isMacOS || Platform.isLinux)) {
    try {
      final targetPath = Directory(path).existsSync()
          ? path
          : Directory(path).parent.path;
      final res = await Process.run('df', ['-h', targetPath]);
      if (res.exitCode == 0) {
        final lines = (res.stdout as String).trim().split('\n');
        if (lines.length >= 2) {
          final parts = lines[1].split(RegExp(r'\s+'));
          // In df -h: Filesystem Size Used Avail Capacity Mounted on
          if (parts.length >= 4) {
            final avail = parts[3];
            return '$avail free on disk';
          }
        }
      }
    } catch (_) {}
  }

  // Graceful fallback across mobile platforms & tests
  try {
    final dir = Directory(path);
    if (dir.existsSync()) {
      return 'Directory Ready • Verified';
    } else {
      return 'Auto-create on Start';
    }
  } catch (_) {
    return 'Active Storage';
  }
});

/// Dynamically inspects the active engine binary and returns live version info.
final engineInfoProvider = FutureProvider<String>((ref) async {
  try {
    final engine = await EngineResolver.resolveDefaultEngine();
    if (engine is YtDlpEngine) {
      if (!kIsWeb) {
        try {
          final res = await Process.run('yt-dlp', ['--version']);
          if (res.exitCode == 0) {
            return 'yt-dlp v${(res.stdout as String).trim()}';
          }
        } catch (_) {}
      }
      return 'yt-dlp (Native CLI)';
    }
    return 'Pure Dart Engine (youtube_explode_dart)';
  } catch (_) {
    return 'Pure Dart Engine (Core)';
  }
});
