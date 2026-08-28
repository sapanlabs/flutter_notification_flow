import 'package:flutter_notification_flow/flutter_notification_flow.dart';
import 'package:flutter_notification_flow/src/queue/notification_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationQueue', () {
    test('enqueues and dequeues payloads in strict FIFO order', () {
      final queue = NotificationQueue();
      expect(queue.isEmpty, isTrue);
      expect(queue.length, equals(0));

      const p1 = NotificationPayload(type: 'chat', id: '1', data: {});
      const p2 = NotificationPayload(type: 'post', id: '2', data: {});
      const p3 = NotificationPayload(type: 'alert', id: '3', data: {});

      queue.enqueue(p1);
      queue.enqueue(p2);
      queue.enqueue(p3);

      expect(queue.length, equals(3));
      expect(queue.isNotEmpty, isTrue);
      expect(queue.peek(), equals(p1));

      expect(queue.dequeue(), equals(p1));
      expect(queue.length, equals(2));
      expect(queue.peek(), equals(p2));

      expect(queue.dequeue(), equals(p2));
      expect(queue.dequeue(), equals(p3));
      expect(queue.dequeue(), isNull);
      expect(queue.isEmpty, isTrue);
    });

    test('drain empties the queue and returns all items in order', () {
      final queue = NotificationQueue();
      const p1 = NotificationPayload(type: 'a', data: {});
      const p2 = NotificationPayload(type: 'b', data: {});

      queue.enqueue(p1);
      queue.enqueue(p2);

      final items = queue.drain();
      expect(items, equals([p1, p2]));
      expect(queue.isEmpty, isTrue);
    });

    test('processAll processes queued items sequentially', () async {
      final queue = NotificationQueue();
      const p1 = NotificationPayload(type: 'p1', data: {});
      const p2 = NotificationPayload(type: 'p2', data: {});

      queue.enqueue(p1);
      queue.enqueue(p2);

      final processed = <String>[];
      await queue.processAll((payload) async {
        await Future.delayed(const Duration(milliseconds: 10));
        processed.add(payload.type);
      });

      expect(processed, equals(['p1', 'p2']));
      expect(queue.isEmpty, isTrue);
    });

    test('processAll keeps remaining items if processor throws', () async {
      final queue = NotificationQueue();
      const p1 = NotificationPayload(type: 'good', data: {});
      const p2 = NotificationPayload(type: 'bad', data: {});
      const p3 = NotificationPayload(type: 'remaining', data: {});

      queue.enqueue(p1);
      queue.enqueue(p2);
      queue.enqueue(p3);

      final processed = <String>[];

      expect(
        () => queue.processAll((payload) {
          if (payload.type == 'bad') {
            throw Exception('Processing failure');
          }
          processed.add(payload.type);
        }),
        throwsException,
      );

      expect(processed, equals(['good']));
      expect(queue.length, equals(1));
      expect(queue.peek(), equals(p3));
    });

    test('clear removes all queued items', () {
      final queue = NotificationQueue();
      queue.enqueue(const NotificationPayload(type: 'a', data: {}));
      queue.enqueue(const NotificationPayload(type: 'b', data: {}));
      expect(queue.length, equals(2));

      queue.clear();
      expect(queue.isEmpty, isTrue);
    });
  });
}
