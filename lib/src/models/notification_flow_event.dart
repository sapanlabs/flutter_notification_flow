import 'package:flutter/foundation.dart';
import 'notification_payload.dart';

/// Represents the lifecycle status of a notification interaction in [NotificationFlow].
enum NotificationFlowStatus {
  /// The notification payload was received by the flow.
  received,

  /// The notification was queued because navigation/context is not yet ready.
  queued,

  /// A handler is currently executing for the notification.
  handling,

  /// The notification was successfully processed by a registered handler or callback.
  handled,

  /// No handler was registered for this notification type, or routing was unhandled.
  unhandled,

  /// The notification was identified as a duplicate and ignored by the duplicate guard.
  duplicate,

  /// An error occurred during routing or handler execution.
  failed,
}

/// An event emitted to the [NotificationFlow.events] stream during notification lifecycle transitions.
@immutable
class NotificationFlowEvent {
  /// The notification payload associated with this event.
  final NotificationPayload payload;

  /// The status of this lifecycle event.
  final NotificationFlowStatus status;

  /// The timestamp when this event occurred.
  final DateTime timestamp;

  /// Optional error object if the status is [NotificationFlowStatus.failed].
  final Object? error;

  /// Optional stack trace if the status is [NotificationFlowStatus.failed].
  final StackTrace? stackTrace;

  /// Creates a [NotificationFlowEvent].
  NotificationFlowEvent({
    required this.payload,
    required this.status,
    DateTime? timestamp,
    this.error,
    this.stackTrace,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationFlowEvent &&
          runtimeType == other.runtimeType &&
          payload == other.payload &&
          status == other.status &&
          timestamp == other.timestamp &&
          error == other.error;

  @override
  int get hashCode => Object.hash(payload, status, timestamp, error);

  @override
  String toString() =>
      'NotificationFlowEvent(status: $status, payload: $payload, timestamp: $timestamp${error != null ? ', error: $error' : ''})';
}
