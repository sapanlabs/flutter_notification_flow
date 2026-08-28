import 'package:flutter/foundation.dart';

/// Lightweight internal logger for Flutter Notification Flow.
class NotificationLogger {
  final bool _enabled;

  /// Creates a logger instance with optional debug output.
  const NotificationLogger({bool enabled = false}) : _enabled = enabled;

  /// Logs an informational message if logging is enabled.
  void info(String message) {
    if (_enabled) {
      debugPrint('[NotificationFlow] $message');
    }
  }

  /// Logs a warning message if logging is enabled.
  void warning(String message) {
    if (_enabled) {
      debugPrint('[NotificationFlow:WARN] $message');
    }
  }

  /// Logs an error message if logging is enabled.
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (_enabled) {
      final buffer = StringBuffer('[NotificationFlow:ERROR] $message');
      if (error != null) {
        buffer.write('\nError: $error');
      }
      if (stackTrace != null) {
        buffer.write('\n$stackTrace');
      }
      debugPrint(buffer.toString());
    }
  }
}
