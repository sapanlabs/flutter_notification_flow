import 'package:flutter_notification_flow/flutter_notification_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPayload', () {
    test('parses nested payload format correctly', () {
      final map = {
        'type': 'chat',
        'id': 'notif_100',
        'data': {'chatId': 'c_123', 'sender': 'Alice'},
      };

      final payload = NotificationPayload.fromMap(map);

      expect(payload.type, equals('chat'));
      expect(payload.id, equals('notif_100'));
      expect(payload.data['chatId'], equals('c_123'));
      expect(payload.data['sender'], equals('Alice'));
    });

    test('parses flat payload format correctly', () {
      final map = {
        'type': 'post',
        'id': 'notif_200',
        'postId': 'p_456',
        'author': 'Bob',
      };

      final payload = NotificationPayload.fromMap(map);

      expect(payload.type, equals('post'));
      expect(payload.id, equals('notif_200'));
      expect(payload.data['postId'], equals('p_456'));
      expect(payload.data['author'], equals('Bob'));
      expect(payload.data.containsKey('type'), isFalse);
      expect(payload.data.containsKey('id'), isFalse);
    });

    test(
        'supports alternative keys (notification_type, notification_id, message_id)',
        () {
      final map1 = {
        'notification_type': 'profile',
        'notification_id': 'nid_1',
        'userId': 'u_789',
      };
      final payload1 = NotificationPayload.fromMap(map1);
      expect(payload1.type, equals('profile'));
      expect(payload1.id, equals('nid_1'));
      expect(payload1.data['userId'], equals('u_789'));

      final map2 = {
        'notificationType': 'alert',
        'messageId': 'mid_2',
        'level': 'high',
      };
      final payload2 = NotificationPayload.fromMap(map2);
      expect(payload2.type, equals('alert'));
      expect(payload2.id, equals('mid_2'));
      expect(payload2.data['level'], equals('high'));
    });

    test('throws NotificationPayloadException on missing or empty type', () {
      expect(
        () => NotificationPayload.fromMap(const {'chatId': '123'}),
        throwsA(isA<NotificationPayloadException>()),
      );

      expect(
        () => NotificationPayload.fromMap(const {'type': '   '}),
        throwsA(isA<NotificationPayloadException>()),
      );
    });

    test('parses valid JSON string correctly', () {
      const jsonStr = '{"type":"chat","id":"n1","data":{"chatId":"123"}}';
      final payload = NotificationPayload.fromJson(jsonStr);

      expect(payload.type, equals('chat'));
      expect(payload.id, equals('n1'));
      expect(payload.data['chatId'], equals('123'));
    });

    test(
        'throws NotificationPayloadException on malformed JSON or empty string',
        () {
      expect(
        () => NotificationPayload.fromJson(''),
        throwsA(isA<NotificationPayloadException>()),
      );

      expect(
        () => NotificationPayload.fromJson('{not valid json}'),
        throwsA(isA<NotificationPayloadException>()),
      );

      expect(
        () => NotificationPayload.fromJson('["array", "not", "map"]'),
        throwsA(isA<NotificationPayloadException>()),
      );
    });

    test('generates deterministic fingerprint based on ID or sorted data', () {
      const payloadWithId1 = NotificationPayload(
        type: 'chat',
        id: '123',
        data: {'b': 2, 'a': 1},
      );
      const payloadWithId2 = NotificationPayload(
        type: 'chat',
        id: '123',
        data: {'x': 9},
      );
      expect(payloadWithId1.fingerprint, equals('id:123'));
      expect(payloadWithId2.fingerprint, equals('id:123'));

      // Payloads without ID should generate deterministic fingerprint regardless of map key insertion order
      const payloadNoId1 = NotificationPayload(
        type: 'chat',
        data: {'b': '2', 'a': '1'},
      );
      const payloadNoId2 = NotificationPayload(
        type: 'chat',
        data: {'a': '1', 'b': '2'},
      );
      expect(payloadNoId1.fingerprint, equals(payloadNoId2.fingerprint));
      expect(payloadNoId1.fingerprint, contains('type:chat;data:{a:1,b:2}'));
    });

    test('supports toMap and toJson serialization roundtrip', () {
      const original = NotificationPayload(
        type: 'chat',
        id: 'id_123',
        data: {
          'chatId': 'c_1',
          'nested': {'flag': true}
        },
      );

      final map = original.toMap();
      final roundtrip = NotificationPayload.fromMap(map);
      expect(roundtrip, equals(original));

      final jsonStr = original.toJson();
      final jsonRoundtrip = NotificationPayload.fromJson(jsonStr);
      expect(jsonRoundtrip, equals(original));
    });

    test('equality and hashCode work properly', () {
      const p1 = NotificationPayload(type: 'chat', id: '1', data: {'a': 1});
      const p2 = NotificationPayload(type: 'chat', id: '1', data: {'a': 1});
      const p3 = NotificationPayload(type: 'chat', id: '2', data: {'a': 1});
      const p4 = NotificationPayload(type: 'chat', id: '1', data: {'a': 2});

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
      expect(p1, isNot(equals(p4)));
    });
  });
}
