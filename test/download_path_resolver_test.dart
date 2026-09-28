import 'package:downloader_all_platform/core/utils/download_path_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('DownloadPathResolver Tests', () {
    const baseDir = '/storage/MediaGrab';

    test('Resolves standalone video path into video/ subfolder', () {
      final path = DownloadPathResolver.buildDestinationPath(
        baseDirectory: baseDir,
        isAudioOnly: false,
        isPlaylist: false,
      );

      expect(path, equals(p.join(baseDir, 'video')));
    });

    test('Resolves standalone audio path into audio/ subfolder', () {
      final path = DownloadPathResolver.buildDestinationPath(
        baseDirectory: baseDir,
        isAudioOnly: true,
        isPlaylist: false,
      );

      expect(path, equals(p.join(baseDir, 'audio')));
    });

    test(
      'Resolves playlist video path into video/[Playlist Name] subfolder',
      () {
        final path = DownloadPathResolver.buildDestinationPath(
          baseDirectory: baseDir,
          isAudioOnly: false,
          isPlaylist: true,
          playlistTitle: 'Best Coding Music 2026',
        );

        expect(
          path,
          equals(p.join(baseDir, 'video', 'Best Coding Music 2026')),
        );
      },
    );

    test(
      'Resolves playlist audio path into audio/[Playlist Name] subfolder',
      () {
        final path = DownloadPathResolver.buildDestinationPath(
          baseDirectory: baseDir,
          isAudioOnly: true,
          isPlaylist: true,
          playlistTitle: 'Lo-Fi Chill Beats',
        );

        expect(path, equals(p.join(baseDir, 'audio', 'Lo-Fi Chill Beats')));
      },
    );

    test('Sanitizes illegal characters in playlist folder names', () {
      final sanitized = DownloadPathResolver.sanitizeFolderName(
        'Rock: Hits / Metal * "Live?" <2026> | Top#1!',
      );

      expect(sanitized, isNot(contains(':')));
      expect(sanitized, isNot(contains('/')));
      expect(sanitized, isNot(contains('*')));
      expect(sanitized, isNot(contains('"')));
      expect(sanitized, isNot(contains('?')));
      expect(sanitized, isNot(contains('<')));
      expect(sanitized, isNot(contains('>')));
      expect(sanitized, isNot(contains('|')));
      expect(sanitized, isNot(contains('#')));

      final path = DownloadPathResolver.buildDestinationPath(
        baseDirectory: baseDir,
        isAudioOnly: false,
        isPlaylist: true,
        playlistTitle: 'Pop / Rock: Vol. 1...',
      );

      expect(path, isNot(endsWith('.')));
      expect(path, contains(p.join(baseDir, 'video')));
    });
  });
}
