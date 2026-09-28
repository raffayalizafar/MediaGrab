import 'package:flutter/foundation.dart';
import '../errors/logger_service.dart';

/// Centralized Analytics & Telemetry Façade adhering to universal dev standards (Part 7).
/// In development/offline mode, telemetry is safely logged via LoggerService.
/// In production, can dispatch to opt-in privacy-respecting telemetry providers.
class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._internal();

  AnalyticsService._internal();

  /// Logs a screen view navigation event.
  void trackScreenView(String screenName) {
    LoggerService.debug('ScreenView: $screenName', tag: 'Analytics');
  }

  /// Logs a custom user or business event with properties.
  void trackEvent(String eventName, [Map<String, dynamic>? properties]) {
    LoggerService.debug(
      'Event: $eventName${properties != null ? ' | data: $properties' : ''}',
      tag: 'Analytics',
    );
  }

  /// Logs handled errors or unexpected states.
  void trackError(String message, [dynamic error, StackTrace? stackTrace]) {
    LoggerService.error(
      'TrackedError: $message',
      tag: 'Analytics',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Logs performance durations (e.g. metadata extraction time, download time).
  void trackPerformance(String metricName, Duration duration) {
    if (kDebugMode) {
      LoggerService.debug(
        'Performance: $metricName took ${duration.inMilliseconds}ms',
        tag: 'Analytics',
      );
    }
  }
}
