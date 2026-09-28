import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Centralized Logger and Safe Execution Service following universal dev standards.
class LoggerService {
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(
        '[DEBUG] ${tag != null ? '[$tag] ' : ''}$message',
        name: tag ?? 'MediaGrab',
      );
    }
  }

  static void info(String message, {String? tag}) {
    developer.log(
      '[INFO] ${tag != null ? '[$tag] ' : ''}$message',
      name: tag ?? 'MediaGrab',
    );
  }

  static void warning(String message, {String? tag, Object? error}) {
    developer.log(
      '[WARN] ${tag != null ? '[$tag] ' : ''}$message',
      name: tag ?? 'MediaGrab',
      error: error,
    );
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      '[ERROR] ${tag != null ? '[$tag] ' : ''}$message',
      name: tag ?? 'MediaGrab',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Safe synchronous execution wrapper.
  static T? safeExecute<T>(
    String operation,
    T Function() block, {
    String? tag,
    T? fallback,
  }) {
    try {
      return block();
    } catch (e, st) {
      error('Operation failed: $operation', tag: tag, error: e, stackTrace: st);
      return fallback;
    }
  }

  /// Safe asynchronous execution wrapper.
  static Future<T?> safeExecuteAsync<T>(
    String operation,
    Future<T> Function() block, {
    String? tag,
    T? fallback,
  }) async {
    try {
      return await block();
    } catch (e, st) {
      error(
        'Async operation failed: $operation',
        tag: tag,
        error: e,
        stackTrace: st,
      );
      return fallback;
    }
  }
}
