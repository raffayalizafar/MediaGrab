import 'package:downloader_all_platform/download_engine/models/download_request.dart';
import 'package:downloader_all_platform/download_engine/task_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskFactory Argument Building Tests', () {
    test('Builds basic video download arguments correctly', () {
      const request = DownloadRequest(
        url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        isAudioOnly: false,
        selectedQuality: '1080p',
        outputFormat: 'mp4',
        outputDirectory: '/downloads/media',
        embedSubtitles: true,
        subtitleLanguage: 'en',
        embedMetadata: true,
        embedThumbnail: true,
      );

      final args = TaskFactory.buildArgs(request);

      expect(args, contains('--newline'));
      expect(args, contains('--progress-template'));
      expect(args, contains('%(progress)j'));
      expect(args, contains('--no-playlist'));
      expect(args, contains('--merge-output-format'));
      expect(args, contains('mp4'));
      expect(args, contains('--embed-subs'));
      expect(args, contains('--embed-metadata'));
      expect(args, contains('--embed-thumbnail'));
      expect(args.last, equals('https://www.youtube.com/watch?v=dQw4w9WgXcQ'));
    });

    test('Builds audio extraction arguments correctly', () {
      const request = DownloadRequest(
        url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        isAudioOnly: true,
        outputFormat: 'mp3',
        outputDirectory: '/downloads/music',
        embedMetadata: true,
        embedThumbnail: true,
      );

      final args = TaskFactory.buildArgs(request);

      expect(args, contains('-x'));
      expect(args, contains('--audio-format'));
      expect(args, contains('mp3'));
      expect(args, contains('--embed-metadata'));
      expect(args, contains('--embed-thumbnail'));
      expect(args, isNot(contains('--merge-output-format')));
      expect(args.last, equals('https://www.youtube.com/watch?v=dQw4w9WgXcQ'));
    });

    test('Configures aria2c acceleration when requested', () {
      const request = DownloadRequest(
        url: 'https://example.com/video',
        outputDirectory: '/downloads',
        useAria2c: true,
      );

      final args = TaskFactory.buildArgs(request);

      expect(args, contains('--downloader'));
      expect(args, contains('aria2c'));
      expect(args, contains('--downloader-args'));
    });

    test('Safely strips dangerous --exec arguments from custom templates', () {
      const request = DownloadRequest(
        url: 'https://example.com/video',
        outputDirectory: '/downloads',
        customArgs: '--sponsorblock-remove all --exec rm -rf /',
      );

      final args = TaskFactory.buildArgs(request);

      expect(args, contains('--sponsorblock-remove'));
      expect(args, contains('all'));
      expect(args, isNot(contains('--exec')));
    });

    test('Handles playlist requests correctly', () {
      const request = DownloadRequest(
        url: 'https://www.youtube.com/playlist?list=PL12345',
        outputDirectory: '/downloads/playlists',
        isPlaylist: true,
        playlistIndices: [1, 2, 5],
      );

      final args = TaskFactory.buildArgs(request);

      expect(args, contains('--yes-playlist'));
      expect(args, contains('--playlist-items'));
      expect(args, contains('1,2,5'));
    });

    test('Formats custom video quality height correctly in yt-dlp flags', () {
      const request720 = DownloadRequest(
        url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        outputDirectory: '/downloads',
        selectedQuality: '720p',
      );

      final args720 = TaskFactory.buildArgs(request720);
      final fIndex720 = args720.indexOf('-f');
      expect(fIndex720, isNot(-1));
      expect(args720[fIndex720 + 1], contains('height<=720'));

      const requestBest = DownloadRequest(
        url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        outputDirectory: '/downloads',
        selectedQuality: 'Best',
      );

      final argsBest = TaskFactory.buildArgs(requestBest);
      final fIndexBest = argsBest.indexOf('-f');
      expect(fIndexBest, isNot(-1));
      expect(argsBest[fIndexBest + 1], equals('bestvideo+bestaudio/best'));
    });

    test(
      'Builds structured destination path with video and audio subfolders',
      () {
        const videoReq = DownloadRequest(
          url: 'https://example.com/video',
          outputDirectory: '/downloads/MediaGrab',
          isAudioOnly: false,
        );
        final videoArgs = TaskFactory.buildArgs(videoReq);
        final oIndexVideo = videoArgs.indexOf('-o');
        expect(oIndexVideo, isNot(-1));
        expect(videoArgs[oIndexVideo + 1], contains('video'));

        const audioReq = DownloadRequest(
          url: 'https://example.com/audio',
          outputDirectory: '/downloads/MediaGrab',
          isAudioOnly: true,
        );
        final audioArgs = TaskFactory.buildArgs(audioReq);
        final oIndexAudio = audioArgs.indexOf('-o');
        expect(oIndexAudio, isNot(-1));
        expect(audioArgs[oIndexAudio + 1], contains('audio'));

        const playlistReq = DownloadRequest(
          url: 'https://example.com/playlist',
          outputDirectory: '/downloads/MediaGrab',
          isAudioOnly: false,
          isPlaylist: true,
          playlistTitle: 'Summer Hits 2026',
        );
        final playlistArgs = TaskFactory.buildArgs(playlistReq);
        final oIndexPl = playlistArgs.indexOf('-o');
        expect(oIndexPl, isNot(-1));
        expect(playlistArgs[oIndexPl + 1], contains('video'));
        expect(playlistArgs[oIndexPl + 1], contains('Summer Hits 2026'));
      },
    );
  });
}
