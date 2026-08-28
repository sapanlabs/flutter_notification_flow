import 'package:flutter/widgets.dart';
import 'package:flutter_notification_flow/flutter_notification_flow.dart';
import 'package:flutter_notification_flow/src/routing/notification_router.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBuildContext extends Fake implements BuildContext {}

void main() {
  group('NotificationRouter', () {
    test('registers and executes synchronous handler', () async {
      final context = _FakeBuildContext();
      NotificationPayload? handledPayload;
      final router = NotificationRouter({
        'chat': (ctx, payload) {
          handledPayload = payload;
        },
      });

      expect(router.hasRoute('chat'), isTrue);
      expect(router.hasRoute('post'), isFalse);
      expect(router.registeredRoutes, contains('chat'));

      const payload = NotificationPayload(
        type: 'chat',
        data: {'chatId': '123'},
      );

      await router.execute(context, payload);

      expect(handledPayload, equals(payload));
    });

    test('registers and awaits asynchronous handler', () async {
      final context = _FakeBuildContext();
      var asyncFinished = false;
      final router = NotificationRouter();
      router.register('profile', (ctx, payload) async {
        await Future.delayed(const Duration(milliseconds: 10));
        asyncFinished = true;
      });

      const payload = NotificationPayload(type: 'profile', data: {});
      await router.execute(context, payload);

      expect(asyncFinished, isTrue);
    });

    test('registers multiple routes and supports unregister & clear', () {
      final router = NotificationRouter();
      router.registerAll({
        'chat': (context, payload) {},
        'post': (context, payload) {},
        'feed': (context, payload) {},
      });

      expect(router.registeredRoutes.length, equals(3));
      expect(router.hasRoute('post'), isTrue);

      final removed = router.unregister('post');
      expect(removed, isTrue);
      expect(router.hasRoute('post'), isFalse);
      expect(router.registeredRoutes.length, equals(2));

      router.clear();
      expect(router.registeredRoutes, isEmpty);
    });

    test('throws NotificationRouteException on unregistered route execution',
        () async {
      final context = _FakeBuildContext();
      final router = NotificationRouter();
      const payload = NotificationPayload(type: 'unknown', data: {});

      expect(
        () => router.execute(context, payload),
        throwsA(
          isA<NotificationRouteException>().having(
            (e) => e.routeType,
            'routeType',
            'unknown',
          ),
        ),
      );
    });

    test('wraps handler exceptions in NotificationRouteException', () async {
      final context = _FakeBuildContext();
      final router = NotificationRouter({
        'buggy': (ctx, payload) {
          throw StateError('Handler failure simulation');
        },
      });

      const payload = NotificationPayload(type: 'buggy', data: {});

      expect(
        () => router.execute(context, payload),
        throwsA(
          isA<NotificationRouteException>().having(
            (e) => e.cause,
            'cause',
            isA<StateError>(),
          ),
        ),
      );
    });
  });
}
