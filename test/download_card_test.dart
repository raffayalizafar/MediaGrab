import 'package:downloader_all_platform/download_engine/models/download_progress.dart';
import 'package:downloader_all_platform/download_engine/models/download_request.dart';
import 'package:downloader_all_platform/download_engine/models/download_task.dart';
import 'package:downloader_all_platform/download_engine/models/media_info.dart';
import 'package:downloader_all_platform/features/downloads/ui/download_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mockMedia = MediaInfo(
    url: 'https://youtube.com/watch?v=123',
    title: 'Test Video Connecting Flow',
    author: 'Tester',
    duration: Duration(minutes: 4),
  );

  const mockRequest = DownloadRequest(
    url: 'https://youtube.com/watch?v=123',
    selectedQuality: '1080p',
    outputFormat: 'mp4',
    outputDirectory: '/tmp',
  );

  testWidgets(
    'ActiveDownloadCard renders CONNECTING and status message when bytes are 0',
    (tester) async {
      final task = DownloadTask(
        id: 'task-1',
        request: mockRequest,
        mediaInfo: mockMedia,
        status: DownloadStatus.downloading,
        startedAt: DateTime.now(),
        progress: const DownloadProgress(
          percentage: 0.0,
          downloadedBytes: 0,
          totalBytes: 50000000,
          statusMessage: 'Connecting to media server...',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveDownloadCard(
              task: task,
              onCancel: () {},
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('CONNECTING'), findsOneWidget);
      expect(find.text('Connecting to media server...'), findsOneWidget);
      expect(find.text('0% • 0.0 / 47.7 MB'), findsOneWidget);

      // Indicator must be indeterminate (value: null) so it actively animates
      final progressFinder = find.byType(LinearProgressIndicator);
      expect(progressFinder, findsOneWidget);
      final indicator = tester.widget<LinearProgressIndicator>(progressFinder);
      expect(indicator.value, isNull);
    },
  );

  testWidgets(
    'ActiveDownloadCard renders DOWNLOADING and live percentage when bytes > 0',
    (tester) async {
      final task = DownloadTask(
        id: 'task-2',
        request: mockRequest,
        mediaInfo: mockMedia,
        status: DownloadStatus.downloading,
        startedAt: DateTime.now(),
        progress: const DownloadProgress(
          percentage: 0.45,
          downloadedBytes: 22500000,
          totalBytes: 50000000,
          speedBytesPerSecond: 5242880, // 5 MB/s
          etaSeconds: 5,
          statusMessage: 'Downloading...',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveDownloadCard(
              task: task,
              onCancel: () {},
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('DOWNLOADING'), findsOneWidget);
      expect(find.text('Downloading...'), findsOneWidget);
      expect(find.text('45.0% • 21.5 / 47.7 MB'), findsOneWidget);
      expect(find.text('5.0 MB/s'), findsOneWidget);
      expect(find.text('ETA: 00:05'), findsOneWidget);

      // Determinate value
      final progressFinder = find.byType(LinearProgressIndicator);
      final indicator = tester.widget<LinearProgressIndicator>(progressFinder);
      expect(indicator.value, equals(0.45));
    },
  );

  testWidgets('ActiveDownloadCard renders PAUSED and triggers onResume', (
    tester,
  ) async {
    bool resumed = false;
    final task = DownloadTask(
      id: 'task-pause-1',
      request: mockRequest,
      mediaInfo: mockMedia,
      status: DownloadStatus.paused,
      startedAt: DateTime.now(),
      progress: const DownloadProgress(
        percentage: 0.30,
        downloadedBytes: 15000000,
        totalBytes: 50000000,
        waitingForWifi: true,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActiveDownloadCard(
            task: task,
            onCancel: () {},
            onRetry: () {},
            onResume: () => resumed = true,
          ),
        ),
      ),
    );

    expect(find.text('WAITING FOR WI-FI'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    expect(resumed, isTrue);
  });

  testWidgets('ActiveDownloadCard renders SCHEDULED with Start Now button', (
    tester,
  ) async {
    bool startedNow = false;
    final futureTime = DateTime.now().add(const Duration(hours: 1));
    final task = DownloadTask(
      id: 'task-sched-1',
      request: mockRequest,
      mediaInfo: mockMedia,
      status: DownloadStatus.scheduled,
      scheduledAt: futureTime,
      startedAt: DateTime.now(),
      progress: const DownloadProgress(
        percentage: 0.0,
        downloadedBytes: 0,
        totalBytes: 50000000,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActiveDownloadCard(
            task: task,
            onCancel: () {},
            onRetry: () {},
            onStartNow: () => startedNow = true,
          ),
        ),
      ),
    );

    expect(find.text('SCHEDULED'), findsOneWidget);
    expect(find.text('Start Now'), findsWidgets);

    await tester.tap(find.text('Start Now').first);
    await tester.pump();
    expect(startedNow, isTrue);
  });

  testWidgets('ActiveDownloadCard displays SLOW SPEED indicator', (
    tester,
  ) async {
    final task = DownloadTask(
      id: 'task-slow-1',
      request: mockRequest,
      mediaInfo: mockMedia,
      status: DownloadStatus.downloading,
      startedAt: DateTime.now(),
      progress: const DownloadProgress(
        percentage: 0.10,
        downloadedBytes: 5000000,
        totalBytes: 50000000,
        speedBytesPerSecond: 15360, // 15 KB/s
        isSlowSpeed: true,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActiveDownloadCard(task: task, onCancel: () {}, onRetry: () {}),
        ),
      ),
    );

    expect(find.text('SLOW SPEED'), findsOneWidget);
  });
}
