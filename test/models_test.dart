import 'package:downloader_all_platform/download_engine/models/download_progress.dart';
import 'package:downloader_all_platform/download_engine/models/download_request.dart';
import 'package:downloader_all_platform/download_engine/models/download_task.dart';
import 'package:downloader_all_platform/download_engine/models/media_info.dart';
import 'package:downloader_all_platform/download_engine/models/stream_option.dart';
import 'package:downloader_all_platform/features/downloads/models/download_record.dart';
import 'package:downloader_all_platform/features/templates/models/command_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Data Models & JSON Serialization Tests', () {
    test('MediaInfo serialization & duration formatting', () {
      const info = MediaInfo(
        url: 'https://youtube.com/watch?v=abc',
        title: 'Rick Astley - Never Gonna Give You Up',
        author: 'RickAstleyVEVO',
        duration: Duration(minutes: 3, seconds: 32),
        thumbnailUrl: 'https://img.youtube.com/vi/abc/hqdefault.jpg',
        isPlaylist: false,
        availableQualities: ['1080p', '720p'],
      );

      expect(info.durationFormatted, equals('3:32'));

      final json = info.toJson();
      final roundTrip = MediaInfo.fromJson(json);

      expect(roundTrip.title, equals(info.title));
      expect(roundTrip.author, equals(info.author));
      expect(roundTrip.duration, equals(info.duration));
      expect(roundTrip.availableQualities, equals(info.availableQualities));
    });

    test('StreamOption size formatting', () {
      const option = StreamOption(
        label: '1080p',
        format: 'mp4',
        sizeBytes: 104857600, // 100 MB
      );

      expect(option.formattedSize, equals('100.0 MB'));
    });

    test('DownloadProgress metrics formatting', () {
      const progress = DownloadProgress(
        downloadedBytes: 52428800, // 50 MB
        totalBytes: 104857600, // 100 MB
        speedBytesPerSecond: 5242880, // 5 MB/s
        etaSeconds: 10,
        percentage: 0.5,
      );

      expect(progress.speedFormatted, equals('5.0 MB/s'));
      expect(progress.etaFormatted, equals('00:10'));
      expect(progress.downloadedFormatted, equals('50.0 / 100.0 MB'));
    });

    test('DownloadRecord serialization round-trip', () {
      final now = DateTime.now();
      final record = DownloadRecord(
        id: 'task-123',
        title: 'Test Video',
        author: 'Test Author',
        url: 'https://test.com/video',
        format: 'mp4',
        quality: '1080p',
        isAudioOnly: false,
        filePath: '/path/to/file.mp4',
        fileSizeBytes: 2048000,
        dateCompleted: now,
      );

      final json = record.toJson();
      final roundTrip = DownloadRecord.fromJson(json);

      expect(roundTrip.id, equals(record.id));
      expect(roundTrip.title, equals(record.title));
      expect(roundTrip.fileSizeBytes, equals(record.fileSizeBytes));
    });

    test('CommandTemplate defaults exist and serialize properly', () {
      final templates = CommandTemplate.defaultTemplates;
      expect(templates, isNotEmpty);
      expect(templates.first.name, contains('1080p'));

      final json = templates.first.toJson();
      final roundTrip = CommandTemplate.fromJson(json);
      expect(roundTrip.name, equals(templates.first.name));
      expect(roundTrip.templateArgs, equals(templates.first.templateArgs));
    });

    test('DownloadTask scheduled and paused states & serialization', () {
      final futureDate = DateTime.now().add(const Duration(hours: 2));
      final task = DownloadTask(
        id: 'task-sched-1',
        request: const DownloadRequest(
          url: 'https://test.com',
          selectedQuality: '1080p',
          outputFormat: 'mp4',
          outputDirectory: '/tmp',
          scheduledAt: null,
        ),
        mediaInfo: const MediaInfo(
          url: 'https://test.com',
          title: 'Scheduled Test',
          author: 'Tester',
        ),
        status: DownloadStatus.scheduled,
        scheduledAt: futureDate,
        startedAt: DateTime.now(),
      );

      expect(task.isScheduled, isTrue);
      expect(task.isPaused, isFalse);
      expect(task.isActive, isTrue);

      final json = task.toJson();
      final roundTrip = DownloadTask.fromJson(json);

      expect(roundTrip.status, equals(DownloadStatus.scheduled));
      expect(
        roundTrip.scheduledAt?.millisecondsSinceEpoch,
        equals(futureDate.millisecondsSinceEpoch),
      );

      final pausedTask = task.copyWith(status: DownloadStatus.paused);
      expect(pausedTask.isPaused, isTrue);
      expect(pausedTask.isScheduled, isFalse);
      expect(pausedTask.isActive, isTrue);

      final clearedTask = task.copyWith(clearScheduledAt: true);
      expect(clearedTask.scheduledAt, isNull);
    });

    test('DownloadProgress network condition flags', () {
      const progress = DownloadProgress(
        downloadedBytes: 1000,
        totalBytes: 5000,
        isSlowSpeed: true,
        isStalled: true,
        waitingForWifi: true,
        waitingForNetwork: true,
      );

      expect(progress.isSlowSpeed, isTrue);
      expect(progress.isStalled, isTrue);
      expect(progress.waitingForWifi, isTrue);
      expect(progress.waitingForNetwork, isTrue);

      final copy = progress.copyWith(isSlowSpeed: false, waitingForWifi: false);
      expect(copy.isSlowSpeed, isFalse);
      expect(copy.waitingForWifi, isFalse);
      expect(copy.isStalled, isTrue);
    });
  });
}
