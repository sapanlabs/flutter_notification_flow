/// Base exception class for all errors originating from `flutter_notification_flow`.
class NotificationFlowException implements Exception {
  /// The descriptive error message.
  final String message;

  /// Optional underlying cause or error object.
  final Object? cause;

  /// Optional stack trace associated with the original cause.
  final StackTrace? stackTrace;

  /// Creates a [NotificationFlowException].
  const NotificationFlowException(
    this.message, {
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() {
    if (cause != null) {
      return 'NotificationFlowException: $message (Cause: $cause)';
    }
    return 'NotificationFlowException: $message';
  }
}

/// Thrown when notification payload parsing or validation fails.
class NotificationPayloadException extends NotificationFlowException {
  /// Creates a [NotificationPayloadException].
  const NotificationPayloadException(
    super.message, {
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    if (cause != null) {
      return 'NotificationPayloadException: $message (Cause: $cause)';
    }
    return 'NotificationPayloadException: $message';
  }
}

/// Thrown when route resolution or handler execution encounters an error.
class NotificationRouteException extends NotificationFlowException {
  /// The route type identifier that failed.
  final String? routeType;

  /// Creates a [NotificationRouteException].
  const NotificationRouteException(
    super.message, {
    this.routeType,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('NotificationRouteException: $message');
    if (routeType != null) {
      buffer.write(' [Route: $routeType]');
    }
    if (cause != null) {
      buffer.write(' (Cause: $cause)');
    }
    return buffer.toString();
  }
}
