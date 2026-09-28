import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import '../errors/logger_service.dart';
import 'notification_service.dart';

/// Background service to handle desktop window lifecycle.
/// Prevents premature app termination when the user closes the window during an active download,
/// smoothly hiding the window while downloads continue in the background.
class BackgroundService with WindowListener {
  static final BackgroundService _instance = BackgroundService._internal();
  static BackgroundService get instance => _instance;

  BackgroundService._internal();

  bool Function()? _hasActiveDownloadsCallback;
  bool _isInitialized = false;

  /// Initializes window manager and registers window close listener on desktop platforms.
  Future<void> initialize(bool Function() hasActiveDownloadsCallback) async {
    if (_isInitialized) {
      _hasActiveDownloadsCallback = hasActiveDownloadsCallback;
      return;
    }

    _hasActiveDownloadsCallback = hasActiveDownloadsCallback;

    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      try {
        await windowManager.ensureInitialized();
        windowManager.addListener(this);
        await windowManager.setPreventClose(true);
        await windowManager.setTitle('MediaGrab');
        await windowManager.setMinimumSize(const Size(420, 600));
        _isInitialized = true;
        LoggerService.info(
          'BackgroundService initialized with preventClose: true, title: MediaGrab',
        );
      } catch (e, st) {
        LoggerService.error(
          'Failed to initialize BackgroundService',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  @override
  void onWindowClose() async {
    final hasActive = _hasActiveDownloadsCallback?.call() ?? false;
    LoggerService.info('Window close requested. Active downloads: $hasActive');

    if (hasActive) {
      // Hide window to background instead of terminating active download
      try {
        await windowManager.hide();
        await NotificationService.instance.showNotice(
          title: 'MediaGrab Downloading',
          body:
              'Your download is running in the background. Tap the app icon to reopen.',
        );
      } catch (e) {
        LoggerService.error('Error hiding window: $e');
      }
    } else {
      // Cleanly destroy window and exit
      try {
        await windowManager.destroy();
      } catch (e) {
        LoggerService.error('Error destroying window: $e');
      }
    }
  }

  /// Restores and focuses the application window.
  Future<void> showAndFocusWindow() async {
    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      try {
        await windowManager.show();
        await windowManager.focus();
      } catch (e) {
        LoggerService.error('Error restoring window: $e');
      }
    }
  }

  void dispose() {
    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      windowManager.removeListener(this);
    }
  }
}
