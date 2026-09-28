import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../../core/errors/logger_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../download_engine/download_engine.dart';
import '../../../download_engine/engine_resolver.dart';
import '../../../download_engine/models/download_progress.dart';
import '../../../download_engine/models/download_request.dart';
import '../../../download_engine/models/download_task.dart';
import '../../../download_engine/models/media_info.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/download_record.dart';

/// Global provider for the central DownloadManager.
final downloadManagerProvider =
    StateNotifierProvider<DownloadManager, DownloadManagerState>((ref) {
      final storage = ref.watch(storageServiceProvider);
      return DownloadManager(storage);
    });

class DownloadManagerState {
  final List<DownloadTask> tasks;
  final List<DownloadRecord> history;
  final String activeEngineName;

  const DownloadManagerState({
    this.tasks = const [],
    this.history = const [],
    this.activeEngineName = 'Auto',
  });

  List<DownloadTask> get activeTasks =>
      tasks.where((t) => t.status.isActive).toList();

  List<DownloadTask> get completedTasks =>
      tasks.where((t) => t.status == DownloadStatus.completed).toList();

  List<DownloadTask> get scheduledTasks =>
      tasks.where((t) => t.status == DownloadStatus.scheduled).toList();

  List<DownloadTask> get pausedTasks =>
      tasks.where((t) => t.status == DownloadStatus.paused).toList();

  DownloadManagerState copyWith({
    List<DownloadTask>? tasks,
    List<DownloadRecord>? history,
    String? activeEngineName,
  }) {
    return DownloadManagerState(
      tasks: tasks ?? this.tasks,
      history: history ?? this.history,
      activeEngineName: activeEngineName ?? this.activeEngineName,
    );
  }
}

class DownloadManager extends StateNotifier<DownloadManagerState> {
  final StorageService _storage;
  DownloadEngine? _engine;
  final _uuid = const Uuid();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _schedulerTimer;
  List<ConnectivityResult> _currentConnectivity = [ConnectivityResult.wifi];

  DownloadManager(this._storage) : super(const DownloadManagerState()) {
    _init();
  }

  Future<void> _init() async {
    _engine = await EngineResolver.resolveDefaultEngine(
      customBinaryPath: null,
      ffmpegPath: null,
      aria2cPath: null,
    );

    // Load saved history
    final rawHistory = _storage.getSavedHistory();
    final parsedHistory = rawHistory
        .map((m) => DownloadRecord.fromJson(m))
        .toList();

    state = state.copyWith(
      history: parsedHistory,
      activeEngineName: _engine?.engineName ?? 'Pure Dart',
    );

    // Initialize network listener
    try {
      _currentConnectivity = await Connectivity().checkConnectivity();
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
        _handleConnectivityChanged,
      );
    } catch (e) {
      LoggerService.warning('Failed to initialize connectivity: $e');
    }

    // Start scheduler ticker every 10s
    _schedulerTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkScheduledTasks();
    });
  }

  @override
  void dispose() {
    _schedulerTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _handleConnectivityChanged(List<ConnectivityResult> results) {
    _currentConnectivity = results;
    final isNone = results.every((r) => r == ConnectivityResult.none);
    final isWifiOrEthernet =
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
    final isMobileOnly =
        results.contains(ConnectivityResult.mobile) && !isWifiOrEthernet;

    if (isNone) {
      if (_storage.autoResumeOnReconnect) {
        final running = state.tasks
            .where(
              (t) =>
                  t.status == DownloadStatus.downloading ||
                  t.status == DownloadStatus.muxing,
            )
            .toList();
        for (final task in running) {
          pauseTask(
            task.id,
            waitingForNetwork: true,
            customMessage: 'Connection lost. Auto-resuming when reconnected...',
          );
        }
      }
    } else if (isMobileOnly && _storage.downloadOverWifiOnly) {
      final running = state.tasks
          .where(
            (t) =>
                t.status == DownloadStatus.downloading ||
                t.status == DownloadStatus.muxing,
          )
          .toList();
      for (final task in running) {
        pauseTask(
          task.id,
          waitingForWifi: true,
          customMessage: 'Paused: Waiting for Wi-Fi...',
        );
      }
    } else if (isWifiOrEthernet ||
        (!isMobileOnly && !isNone) ||
        (!_storage.downloadOverWifiOnly && !isNone)) {
      bool hasResumed = false;
      for (final task in state.tasks) {
        if (task.status == DownloadStatus.paused &&
            (task.progress.waitingForWifi || task.progress.waitingForNetwork)) {
          resumeTask(task.id);
          hasResumed = true;
        }
      }
      if (hasResumed) {
        _processQueue();
      }
    }
  }

  void _checkScheduledTasks() {
    final now = DateTime.now();
    bool hasTriggered = false;
    for (final task in state.tasks) {
      if (task.status == DownloadStatus.scheduled &&
          task.scheduledAt != null &&
          now.isAfter(task.scheduledAt!)) {
        _updateTask(
          task.copyWith(
            status: DownloadStatus.queued,
            clearScheduledAt: true,
            progress: const DownloadProgress(
              statusMessage: 'Scheduled time reached. Starting...',
            ),
          ),
        );
        hasTriggered = true;
      }
    }
    if (hasTriggered) {
      _processQueue();
    }
  }

  static String _formatScheduledTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final month = dt.month;
    final day = dt.day;
    return '$month/$day at $hour:$min';
  }

  /// Whether there is any task currently downloading or queued.
  bool get hasActiveDownloads => state.activeTasks.isNotEmpty;

  /// Enqueues a new download task or schedules it for later.
  Future<String> enqueueDownload(
    DownloadRequest request,
    MediaInfo mediaInfo,
  ) async {
    final taskId = _uuid.v4();
    final isScheduled =
        request.scheduledAt != null &&
        request.scheduledAt!.isAfter(DateTime.now());

    final newTask = DownloadTask(
      id: taskId,
      request: request,
      mediaInfo: mediaInfo,
      status: isScheduled ? DownloadStatus.scheduled : DownloadStatus.queued,
      scheduledAt: request.scheduledAt,
      startedAt: DateTime.now(),
      progress: isScheduled
          ? DownloadProgress(
              statusMessage:
                  'Scheduled for ${_formatScheduledTime(request.scheduledAt!)}',
            )
          : const DownloadProgress(),
    );

    state = state.copyWith(tasks: [newTask, ...state.tasks]);
    if (!isScheduled) {
      _processQueue();
    }
    return taskId;
  }

  /// Evaluates and runs pending queued tasks if capacity and network allow.
  void _processQueue() {
    final isWifiOrEthernet =
        _currentConnectivity.contains(ConnectivityResult.wifi) ||
        _currentConnectivity.contains(ConnectivityResult.ethernet);
    final isMobileOnly =
        _currentConnectivity.contains(ConnectivityResult.mobile) &&
        !isWifiOrEthernet;

    if (_storage.downloadOverWifiOnly && isMobileOnly) {
      return; // Hold queued tasks until Wi-Fi is restored
    }

    final maxConcurrent = _storage.maxConcurrentDownloads;
    final currentlyRunning = state.tasks
        .where(
          (t) =>
              t.status == DownloadStatus.downloading ||
              t.status == DownloadStatus.muxing,
        )
        .length;

    if (currentlyRunning >= maxConcurrent) {
      return;
    }

    // Find next queued task
    final nextTaskIndex = state.tasks.indexWhere(
      (t) => t.status == DownloadStatus.queued,
    );
    if (nextTaskIndex == -1) return;

    final taskToRun = state.tasks[nextTaskIndex];
    _startTaskExecution(taskToRun);
  }

  Future<void> _startTaskExecution(DownloadTask task) async {
    DownloadTask currentTask = task;
    if (currentTask.request.outputDirectory.trim().isEmpty) {
      final validDir = await _storage.getDownloadDirectory();
      currentTask = DownloadTask(
        id: currentTask.id,
        mediaInfo: currentTask.mediaInfo,
        status: DownloadStatus.downloading,
        startedAt: currentTask.startedAt,
        request: DownloadRequest(
          url: currentTask.request.url,
          outputDirectory: validDir,
          isAudioOnly: currentTask.request.isAudioOnly,
          selectedQuality: currentTask.request.selectedQuality,
          outputFormat: currentTask.request.outputFormat,
          embedSubtitles: currentTask.request.embedSubtitles,
          subtitleLanguage: currentTask.request.subtitleLanguage,
          embedMetadata: currentTask.request.embedMetadata,
          embedThumbnail: currentTask.request.embedThumbnail,
          useAria2c: currentTask.request.useAria2c,
          customArgs: currentTask.request.customArgs,
          isPlaylist: currentTask.request.isPlaylist,
          playlistTitle: currentTask.request.playlistTitle,
          playlistIndices: currentTask.request.playlistIndices,
        ),
      );
    }

    _updateTask(
      currentTask.copyWith(
        status: DownloadStatus.downloading,
        progress: const DownloadProgress(
          percentage: 0.0,
          downloadedBytes: 0,
          statusMessage: 'Connecting & resolving streams...',
        ),
      ),
    );

    NotificationService.instance.showDownloadProgress(
      taskId: currentTask.id,
      title: currentTask.mediaInfo.title,
      percentage: 0.0,
      statusMessage: 'Connecting to media server...',
    );

    try {
      final engine = _engine ?? await EngineResolver.resolveDefaultEngine();

      final destinationPath = await engine.startDownload(
        currentTask.id,
        currentTask.request,
        onProgress: (progress) {
          _updateTask(
            currentTask.copyWith(
              status: progress.percentage >= 1.0
                  ? DownloadStatus.completed
                  : DownloadStatus.downloading,
              progress: progress,
            ),
          );

          NotificationService.instance.showDownloadProgress(
            taskId: currentTask.id,
            title: currentTask.mediaInfo.title,
            percentage: progress.percentage,
            statusMessage: progress.statusMessage ?? 'Downloading...',
            downloadedBytes: progress.downloadedBytes,
            totalBytes: progress.totalBytes,
            speedBytesPerSecond: progress.speedBytesPerSecond,
          );
        },
      );

      final completedTask = task.copyWith(
        status: DownloadStatus.completed,
        filePath: destinationPath,
        completedAt: DateTime.now(),
        progress: const DownloadProgress(
          percentage: 1.0,
          statusMessage: 'Completed',
        ),
      );
      _updateTask(completedTask);

      NotificationService.instance.showDownloadCompleted(
        taskId: currentTask.id,
        title: currentTask.mediaInfo.title,
        filePath: destinationPath,
      );

      // Save to history record
      int fileSize = 0;
      try {
        final file = File(destinationPath);
        if (await file.exists()) {
          fileSize = await file.length();
        }
      } catch (_) {}

      final record = DownloadRecord(
        id: task.id,
        title: task.mediaInfo.title,
        author: task.mediaInfo.author,
        url: task.request.url,
        format: task.request.outputFormat,
        quality: task.request.selectedQuality,
        isAudioOnly: task.request.isAudioOnly,
        filePath: destinationPath,
        fileSizeBytes: fileSize,
        thumbnailUrl: task.mediaInfo.thumbnailUrl,
        dateCompleted: DateTime.now(),
      );

      final updatedHistory = [record, ...state.history];
      state = state.copyWith(history: updatedHistory);
      _storage.saveHistory(updatedHistory.map((h) => h.toJson()).toList());
    } on DownloadPausedException {
      LoggerService.info('Task ${currentTask.id} paused.');
      final latest = state.tasks.firstWhere(
        (t) => t.id == currentTask.id,
        orElse: () => currentTask,
      );
      _updateTask(
        latest.copyWith(
          status: DownloadStatus.paused,
          progress: latest.progress.copyWith(
            statusMessage: latest.progress.statusMessage ?? 'Paused',
          ),
        ),
      );
    } on DownloadCancelledException {
      NotificationService.instance.cancel(currentTask.id);
      LoggerService.info('Task ${currentTask.id} cancelled by user.');
      _updateTask(
        currentTask.copyWith(
          status: DownloadStatus.cancelled,
          errorMessage: 'Cancelled by user',
        ),
      );
    } catch (e, st) {
      final latest = state.tasks.firstWhere(
        (t) => t.id == currentTask.id,
        orElse: () => currentTask,
      );
      if (latest.status == DownloadStatus.cancelled) {
        NotificationService.instance.cancel(currentTask.id);
        LoggerService.info('Task ${currentTask.id} cancelled by user.');
        return;
      }
      if (latest.status == DownloadStatus.paused) {
        return;
      }

      final isNetworkDrop =
          e is SocketException ||
          e is HttpException ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('ClientException');

      if (isNetworkDrop && _storage.autoResumeOnReconnect) {
        LoggerService.warning('Network drop during task ${currentTask.id}: $e');
        _updateTask(
          currentTask.copyWith(
            status: DownloadStatus.paused,
            progress: currentTask.progress.copyWith(
              waitingForNetwork: true,
              statusMessage:
                  'Connection lost. Auto-resuming when reconnected...',
            ),
          ),
        );
        return;
      }

      NotificationService.instance.showDownloadFailed(
        taskId: currentTask.id,
        title: currentTask.mediaInfo.title,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );

      LoggerService.error(
        'Error executing task ${currentTask.id}',
        error: e,
        stackTrace: st,
      );
      _updateTask(
        currentTask.copyWith(
          status: DownloadStatus.failed,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    } finally {
      // Process next queued task
      _processQueue();
    }
  }

  void _updateTask(DownloadTask updated) {
    state = state.copyWith(
      tasks: state.tasks.map((t) => t.id == updated.id ? updated : t).toList(),
    );
  }

  /// Pauses an active downloading task while retaining partial files.
  Future<void> pauseTask(
    String taskId, {
    bool waitingForWifi = false,
    bool waitingForNetwork = false,
    String? customMessage,
  }) async {
    final taskIndex = state.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = state.tasks[taskIndex];
    if (task.status.isActive) {
      final updatedProgress = task.progress.copyWith(
        statusMessage: customMessage ?? 'Paused',
        waitingForWifi: waitingForWifi,
        waitingForNetwork: waitingForNetwork,
      );
      _updateTask(
        task.copyWith(status: DownloadStatus.paused, progress: updatedProgress),
      );
      await _engine?.pauseDownload(taskId);
      LoggerService.info('Task $taskId paused.');
    }
    _processQueue();
  }

  /// Resumes a paused download task.
  void resumeTask(String taskId) {
    final taskIndex = state.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = state.tasks[taskIndex];
    if (task.status == DownloadStatus.paused) {
      final refreshed = task.copyWith(
        status: DownloadStatus.queued,
        errorMessage: null,
        progress: task.progress.copyWith(
          statusMessage: 'Queued to resume...',
          waitingForWifi: false,
          waitingForNetwork: false,
        ),
      );
      _updateTask(refreshed);
      _processQueue();
    }
  }

  /// Overrides a scheduled download and starts downloading immediately.
  void startScheduledTaskNow(String taskId) {
    final taskIndex = state.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = state.tasks[taskIndex];
    if (task.status == DownloadStatus.scheduled) {
      final refreshed = task.copyWith(
        status: DownloadStatus.queued,
        clearScheduledAt: true,
        progress: const DownloadProgress(
          statusMessage: 'Starting immediately...',
        ),
      );
      _updateTask(refreshed);
      _processQueue();
    }
  }

  /// Cancels an active or queued download task.
  Future<void> cancelTask(String taskId) async {
    final taskIndex = state.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = state.tasks[taskIndex];
    if (task.status.isActive) {
      NotificationService.instance.cancel(taskId);
      _updateTask(
        task.copyWith(
          status: DownloadStatus.cancelled,
          errorMessage: 'Cancelled by user',
        ),
      );
      await _engine?.cancelDownload(taskId);
      LoggerService.info('Task $taskId cancellation initiated by user.');
    }
    _processQueue();
  }

  /// Retries a failed or cancelled task.
  void retryTask(String taskId) {
    final taskIndex = state.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = state.tasks[taskIndex];
    final refreshed = task.copyWith(
      status: DownloadStatus.queued,
      errorMessage: null,
      progress: const DownloadProgress(),
    );
    _updateTask(refreshed);
    _processQueue();
  }

  /// Deletes a task from the list and optionally removes the downloaded file.
  Future<void> deleteTask(String taskId, {bool deleteFile = false}) async {
    NotificationService.instance.cancel(taskId);
    final DownloadTask? task = state.tasks.cast<DownloadTask?>().firstWhere(
      (t) => t?.id == taskId,
      orElse: () => null,
    );
    final DownloadRecord? record = state.history
        .cast<DownloadRecord?>()
        .firstWhere((h) => h?.id == taskId, orElse: () => null);

    final filePath = task?.filePath ?? record?.filePath;
    if (deleteFile && filePath != null && filePath.isNotEmpty) {
      try {
        final f = File(filePath);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (e) {
        LoggerService.warning('Failed to delete file $filePath: $e');
      }
    }

    state = state.copyWith(
      tasks: state.tasks.where((t) => t.id != taskId).toList(),
      history: state.history.where((h) => h.id != taskId).toList(),
    );
    _storage.saveHistory(state.history.map((h) => h.toJson()).toList());
  }

  /// Clears all completed tasks from the active list.
  void clearCompleted() {
    state = state.copyWith(
      tasks: state.tasks.where((t) => t.status.isActive).toList(),
    );
  }

  /// Shares a downloaded file using platform share sheet.
  Future<void> shareFile(String filePath, {String? title}) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await Share.shareXFiles([
          XFile(filePath),
        ], text: title ?? 'Shared from MediaGrab');
      }
    } catch (e) {
      LoggerService.error('Error sharing file: $e');
    }
  }

  /// Opens the downloaded file in the system default media player / viewer.
  Future<void> openFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        if (Platform.isMacOS) {
          await Process.run('open', [filePath]);
        } else if (Platform.isWindows) {
          await Process.run('start', ['', filePath], runInShell: true);
        } else if (Platform.isLinux) {
          await Process.run('xdg-open', [filePath]);
        }
      }
    } catch (e) {
      LoggerService.error('Error opening file: $e');
    }
  }
}
