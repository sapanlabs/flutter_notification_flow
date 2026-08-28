import 'package:flutter_notification_flow/flutter_notification_flow.dart';
import 'package:flutter_notification_flow/src/duplicate/notification_duplicate_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationDuplicateGuard', () {
    test(
        'detects duplicate payloads with identical explicit IDs within cache window',
        () {
      final currentTime = DateTime(2026, 1, 1, 12, 0, 0);
      final guard = NotificationDuplicateGuard(
        cacheDuration: const Duration(minutes: 5),
        nowProvider: () => currentTime,
      );

      const p1 = NotificationPayload(
          type: 'chat', id: 'msg_1', data: {'text': 'hello'});
      const p2 = NotificationPayload(
          type: 'chat', id: 'msg_1', data: {'text': 'updated'});

      expect(guard.isDuplicate(p1), isFalse);
      expect(guard.checkAndRecord(p1),
          isFalse); // First time: not a duplicate, now recorded.

      expect(guard.isDuplicate(p1), isTrue);
      expect(guard.checkAndRecord(p1), isTrue); // Second time: duplicate!
      expect(guard.checkAndRecord(p2), isTrue); // Same ID msg_1: duplicate!
      expect(guard.cacheSize, equals(1));
    });

    test(
        'detects duplicate payloads without ID using deterministic data fingerprints',
        () {
      final currentTime = DateTime(2026, 1, 1, 12, 0, 0);
      final guard = NotificationDuplicateGuard(
        cacheDuration: const Duration(minutes: 5),
        nowProvider: () => currentTime,
      );

      const p1 = NotificationPayload(type: 'chat', data: {'a': '1', 'b': '2'});
      const p2 = NotificationPayload(type: 'chat', data: {'b': '2', 'a': '1'});
      const p3 = NotificationPayload(type: 'chat', data: {'a': '1', 'b': '99'});

      expect(guard.checkAndRecord(p1), isFalse);
      expect(guard.checkAndRecord(p2), isTrue); // Same fingerprint: duplicate!
      expect(guard.checkAndRecord(p3), isFalse); // Different data: fresh!
    });

    test(
        'allows repeated notification after cacheDuration expiration window passes',
        () {
      var currentTime = DateTime(2026, 1, 1, 12, 0, 0);
      final guard = NotificationDuplicateGuard(
        cacheDuration: const Duration(minutes: 5),
        nowProvider: () => currentTime,
      );

      const payload =
          NotificationPayload(type: 'alert', id: 'alert_1', data: {});

      expect(guard.checkAndRecord(payload), isFalse);
      expect(guard.isDuplicate(payload), isTrue);

      // Fast forward 4 minutes (still within window)
      currentTime = currentTime.add(const Duration(minutes: 4));
      expect(guard.isDuplicate(payload), isTrue);

      // Fast forward past 5 minutes (now expired)
      currentTime = currentTime.add(const Duration(minutes: 2));
      expect(guard.isDuplicate(payload), isFalse);
      expect(guard.checkAndRecord(payload), isFalse); // Fresh again!
    });

    test('clears tracked cache accurately', () {
      final guard = NotificationDuplicateGuard();
      const p1 = NotificationPayload(type: 'a', id: '1', data: {});
      const p2 = NotificationPayload(type: 'b', id: '2', data: {});

      guard.record(p1);
      guard.record(p2);
      expect(guard.cacheSize, equals(2));

      guard.clear();
      expect(guard.cacheSize, equals(0));
      expect(guard.isDuplicate(p1), isFalse);
    });
  });
}
