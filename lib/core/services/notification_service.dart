import 'dart:async';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../errors/logger_service.dart';

/// Service managing system notifications for active and completed media downloads.
/// Displays live progress in the Notification Panel / Center across macOS, Android, Windows, and Linux.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Track last notification update timestamp per task to throttle system notifications
  final Map<String, DateTime> _lastUpdateMap = {};
  final Map<String, int> _lastPercentMap = {};

  static const String channelId = 'media_downloads_channel';
  static const String channelName = 'Media Downloads';
  static const String channelDescription =
      'Shows live download progress and download completion alerts';

  int _getNotificationId(String taskId) => taskId.hashCode.abs() % 2147483647;

  /// Initializes the local notification plugin and requests permissions.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const linuxInit = LinuxInitializationSettings(defaultActionName: 'Open');

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
        linux: linuxInit,
      );

      final result = await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // On Android 13+, request POST_NOTIFICATIONS runtime permission
      if (Platform.isAndroid) {
        final androidPlatform = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await androidPlatform?.requestNotificationsPermission();
      }

      // On macOS, ensure permissions are requested
      if (Platform.isMacOS) {
        final macOSPlatform = _notifications
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >();
        await macOSPlatform?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      _isInitialized = result ?? true;
      LoggerService.info('NotificationService initialized: $_isInitialized');
    } catch (e, st) {
      LoggerService.error(
        'Failed to initialize NotificationService',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    LoggerService.info('Notification tapped: ${response.payload}');
  }

  /// Displays or throttles updating active download progress in the system notification panel.
  Future<void> showDownloadProgress({
    required String taskId,
    required String title,
    required double percentage,
    required String statusMessage,
    int? downloadedBytes,
    int? totalBytes,
    double? speedBytesPerSecond,
  }) async {
    if (!_isInitialized) return;

    final id = _getNotificationId(taskId);
    final percentInt = (percentage * 100).round().clamp(0, 100);
    final now = DateTime.now();

    // Throttle progress updates to at most once every 1200ms or on significant % jumps
    final lastTime = _lastUpdateMap[taskId];
    final lastPercent = _lastPercentMap[taskId] ?? -1;

    if (lastTime != null &&
        now.difference(lastTime).inMilliseconds < 1200 &&
        (percentInt - lastPercent).abs() < 5 &&
        percentInt < 100) {
      return;
    }

    _lastUpdateMap[taskId] = now;
    _lastPercentMap[taskId] = percentInt;

    String body;
    if (downloadedBytes != null && downloadedBytes > 0) {
      final mbDownloaded = (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
      final speedText = speedBytesPerSecond != null && speedBytesPerSecond > 0
          ? ' • ${(speedBytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s'
          : '';
      if (totalBytes != null && totalBytes > 0) {
        final mbTotal = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
        body = '$percentInt% ($mbDownloaded / $mbTotal MB)$speedText';
      } else {
        body = '$percentInt% ($mbDownloaded MB)$speedText';
      }
    } else {
      body = statusMessage;
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        onlyAlertOnce: true,
        ongoing: true,
        maxProgress: 100,
        progress: percentInt,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _notifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: taskId,
      );
    } catch (e) {
      LoggerService.error('Error showing download progress notification: $e');
    }
  }

  /// Displays a download completion alert in the notification panel.
  Future<void> showDownloadCompleted({
    required String taskId,
    required String title,
    required String filePath,
  }) async {
    _lastUpdateMap.remove(taskId);
    _lastPercentMap.remove(taskId);

    if (!_isInitialized) return;
    final id = _getNotificationId(taskId);

    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _notifications.show(
        id: id,
        title: 'Download Complete',
        body: title,
        notificationDetails: details,
        payload: filePath,
      );
    } catch (e) {
      LoggerService.error('Error showing download completed notification: $e');
    }
  }

  /// Displays a download failure alert.
  Future<void> showDownloadFailed({
    required String taskId,
    required String title,
    required String errorMessage,
  }) async {
    _lastUpdateMap.remove(taskId);
    _lastPercentMap.remove(taskId);

    if (!_isInitialized) return;
    final id = _getNotificationId(taskId);

    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _notifications.show(
        id: id,
        title: 'Download Failed',
        body: '$title: $errorMessage',
        notificationDetails: details,
      );
    } catch (e) {
      LoggerService.error('Error showing download failed notification: $e');
    }
  }

  /// Dismisses a notification for a task.
  Future<void> cancel(String taskId) async {
    _lastUpdateMap.remove(taskId);
    _lastPercentMap.remove(taskId);

    if (!_isInitialized) return;
    final id = _getNotificationId(taskId);
    try {
      await _notifications.cancel(id: id);
    } catch (e) {
      LoggerService.error('Error cancelling notification: $e');
    }
  }

  /// Displays an informational notice (e.g. background running status).
  Future<void> showNotice({required String title, required String body}) async {
    if (!_isInitialized) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );
      await _notifications.show(
        id: 999999,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      LoggerService.error('Error showing notice notification: $e');
    }
  }
}
