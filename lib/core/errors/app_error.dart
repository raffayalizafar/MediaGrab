/// Severity levels for application errors.
enum ErrorSeverity {
  critical,
  error,
  warning,
  info;

  bool get requiresUserNotification => this == critical || this == error;
}

/// Standardized error model as required by universal development standards.
class AppError implements Exception {
  final String code;
  final String message;
  final ErrorSeverity severity;
  final String source;
  final Object? originalError;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;
  final String userMessage;
  final bool isRetryable;

  const AppError({
    required this.code,
    required this.message,
    this.severity = ErrorSeverity.error,
    required this.source,
    this.originalError,
    this.stackTrace,
    this.context,
    String? userMessage,
    this.isRetryable = false,
  }) : userMessage = userMessage ?? message;

  @override
  String toString() =>
      'AppError(code: $code, source: $source, message: $message)';
}
