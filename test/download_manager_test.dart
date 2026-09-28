import 'package:downloader_all_platform/core/services/storage_service.dart';
import 'package:downloader_all_platform/download_engine/models/download_request.dart';
import 'package:downloader_all_platform/download_engine/models/download_task.dart';
import 'package:downloader_all_platform/download_engine/models/media_info.dart';
import 'package:downloader_all_platform/features/downloads/models/download_record.dart';
import 'package:downloader_all_platform/features/downloads/providers/download_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late DownloadManager manager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    manager = DownloadManager(storage);
  });

  group('DownloadManager.deleteTask regression tests', () {
    test(
      'Safely deletes when tasks list is empty and record is in history',
      () async {
        const recordId = 'history-task-123';
        final record = DownloadRecord(
          id: recordId,
          url: 'https://example.com/video',
          title: 'Completed Video',
          author: 'Channel',
          format: 'mp4',
          quality: '1080p',
          isAudioOnly: false,
          filePath: '',
          fileSizeBytes: 1024,
          dateCompleted: DateTime.now(),
        );

        manager.state = manager.state.copyWith(tasks: [], history: [record]);

        expect(manager.state.tasks, isEmpty);
        expect(manager.state.history.length, equals(1));

        // This previously threw Bad state: No element when tasks was empty
        await expectLater(
          manager.deleteTask(recordId, deleteFile: false),
          completes,
        );

        expect(manager.state.history, isEmpty);
      },
    );

    test(
      'Safely handles non-existent taskId when both tasks and history are empty',
      () async {
        manager.state = manager.state.copyWith(tasks: [], history: []);

        await expectLater(
          manager.deleteTask('non-existent-id', deleteFile: false),
          completes,
        );

        expect(manager.state.tasks, isEmpty);
        expect(manager.state.history, isEmpty);
      },
    );
  });

  group('DownloadManager Pause, Resume & Schedule tests', () {
    test('pauseTask transitions active task to paused state', () async {
      final task = DownloadTask(
        id: 'task-pause-test',
        request: const DownloadRequest(
          url: 'https://test.com',
          selectedQuality: '1080p',
          outputFormat: 'mp4',
          outputDirectory: '/tmp',
        ),
        mediaInfo: const MediaInfo(
          url: 'https://test.com',
          title: 'Pause Test',
          author: 'Tester',
        ),
        status: DownloadStatus.downloading,
        startedAt: DateTime.now(),
      );

      manager.state = manager.state.copyWith(tasks: [task]);
      await manager.pauseTask('task-pause-test');

      final updated = manager.state.tasks.firstWhere(
        (t) => t.id == 'task-pause-test',
      );
      expect(updated.status, equals(DownloadStatus.paused));
    });

    test('resumeTask transitions paused task back to queued', () async {
      final task = DownloadTask(
        id: 'task-resume-test',
        request: const DownloadRequest(
          url: 'https://test.com',
          selectedQuality: '1080p',
          outputFormat: 'mp4',
          outputDirectory: '/tmp',
        ),
        mediaInfo: const MediaInfo(
          url: 'https://test.com',
          title: 'Resume Test',
          author: 'Tester',
        ),
        status: DownloadStatus.paused,
        startedAt: DateTime.now(),
      );

      manager.state = manager.state.copyWith(tasks: [task]);
      manager.resumeTask('task-resume-test');

      final updated = manager.state.tasks.firstWhere(
        (t) => t.id == 'task-resume-test',
      );
      expect(
        updated.status,
        anyOf(DownloadStatus.queued, DownloadStatus.downloading),
      );
    });

    test(
      'startScheduledTaskNow transitions scheduled task to queued and clears scheduledAt',
      () async {
        final futureTime = DateTime.now().add(const Duration(hours: 3));
        final task = DownloadTask(
          id: 'task-sched-test',
          request: const DownloadRequest(
            url: 'https://test.com',
            selectedQuality: '1080p',
            outputFormat: 'mp4',
            outputDirectory: '/tmp',
          ),
          mediaInfo: const MediaInfo(
            url: 'https://test.com',
            title: 'Schedule Test',
            author: 'Tester',
          ),
          status: DownloadStatus.scheduled,
          scheduledAt: futureTime,
          startedAt: DateTime.now(),
        );

        manager.state = manager.state.copyWith(tasks: [task]);
        manager.startScheduledTaskNow('task-sched-test');

        final updated = manager.state.tasks.firstWhere(
          (t) => t.id == 'task-sched-test',
        );
        expect(
          updated.status,
          anyOf(DownloadStatus.queued, DownloadStatus.downloading),
        );
        expect(updated.scheduledAt, isNull);
      },
    );
  });
}
