import 'dart:async';
import 'dart:collection';
import '../models/notification_payload.dart';

/// An in-memory FIFO queue for storing and processing notification payloads
/// that arrive before navigation context or handlers are ready.
class NotificationQueue {
  final Queue<NotificationPayload> _queue = Queue<NotificationPayload>();

  /// The number of pending notification payloads currently in the queue.
  int get length => _queue.length;

  /// Whether the queue contains no pending notifications.
  bool get isEmpty => _queue.isEmpty;

  /// Whether the queue contains at least one pending notification.
  bool get isNotEmpty => _queue.isNotEmpty;

  /// Adds a notification [payload] to the back of the queue.
  void enqueue(NotificationPayload payload) {
    _queue.addLast(payload);
  }

  /// Removes and returns the oldest notification payload in the queue, or `null` if empty.
  NotificationPayload? dequeue() {
    if (_queue.isEmpty) return null;
    return _queue.removeFirst();
  }

  /// Returns the oldest notification payload without removing it, or `null` if empty.
  NotificationPayload? peek() {
    if (_queue.isEmpty) return null;
    return _queue.first;
  }

  /// Returns a snapshot list of all currently queued payloads in FIFO order.
  List<NotificationPayload> toList() => List.unmodifiable(_queue);

  /// Removes and returns all pending notification payloads in FIFO order.
  List<NotificationPayload> drain() {
    final items = _queue.toList();
    _queue.clear();
    return items;
  }

  /// Iterates through and processes each queued notification in FIFO order.
  ///
  /// Each item is dequeued before processing. If [processor] throws, subsequent items
  /// remain in the queue.
  Future<void> processAll(
    FutureOr<void> Function(NotificationPayload payload) processor,
  ) async {
    while (_queue.isNotEmpty) {
      final payload = _queue.removeFirst();
      final result = processor(payload);
      if (result is Future) {
        await result;
      }
    }
  }

  /// Clears all pending notifications from the queue.
  void clear() {
    _queue.clear();
  }
}
