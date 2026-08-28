import 'package:flutter/material.dart';
import 'package:flutter_notification_flow/flutter_notification_flow.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBuildContext extends Fake implements BuildContext {}

void main() {
  group('NotificationFlow', () {
    test(
        'successfully handles notification via route handler with provided context',
        () async {
      final context = _FakeBuildContext();
      NotificationPayload? receivedPayload;

      final flow = NotificationFlow(
        routes: {
          'chat': (ctx, payload) {
            receivedPayload = payload;
          },
        },
      );

      const payload = NotificationPayload(
        type: 'chat',
        id: 'msg_10',
        data: {'chatId': '123'},
      );

      final handled = await flow.handle(payload, context: context);

      expect(handled, isTrue);
      expect(receivedPayload, equals(payload));
      expect(flow.pendingCount, equals(0));

      await flow.dispose();
    });

    testWidgets(
        'successfully handles notification via route handler when Navigator is mounted',
        (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      NotificationPayload? receivedPayload;

      final flow = NotificationFlow(
        navigatorKey: navKey,
        routes: {
          'chat': (context, payload) {
            receivedPayload = payload;
          },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: const Scaffold(body: Text('Home')),
        ),
      );

      const payload = NotificationPayload(
        type: 'chat',
        id: 'msg_10',
        data: {'chatId': '123'},
      );

      final handled = await flow.handle(payload);

      expect(handled, isTrue);
      expect(receivedPayload, equals(payload));
      expect(flow.pendingCount, equals(0));

      await flow.dispose();
    });

    testWidgets(
        'queues notification when Navigator context is not ready, then drains successfully',
        (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      final handledPayloads = <NotificationPayload>[];

      final flow = NotificationFlow(
        navigatorKey: navKey,
        routes: {
          'chat': (context, payload) {
            handledPayloads.add(payload);
          },
          'post': (context, payload) {
            handledPayloads.add(payload);
          },
        },
      );

      // Navigator is NOT pumped/mounted yet
      expect(navKey.currentContext, isNull);

      const p1 =
          NotificationPayload(type: 'chat', id: '1', data: {'chatId': 'c1'});
      const p2 =
          NotificationPayload(type: 'post', id: '2', data: {'postId': 'p1'});

      final queued1 = await flow.handle(p1);
      final queued2 = await flow.handle(p2);

      expect(queued1, isTrue);
      expect(queued2, isTrue);
      expect(flow.pendingCount, equals(2));
      expect(handledPayloads, isEmpty);

      // Mount Navigator
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: const Scaffold(body: Text('App Ready')),
        ),
      );
      expect(navKey.currentContext, isNotNull);

      // Process pending queue
      await flow.processPendingNotifications();

      expect(flow.pendingCount, equals(0));
      expect(handledPayloads, equals([p1, p2]));

      await flow.dispose();
    });

    test(
        'supports event-based mode without navigatorKey (e.g. for GetX, GoRouter, Riverpod)',
        () async {
      NotificationPayload? eventPayload;

      final flow = NotificationFlow(
        onNotification: (payload) {
          eventPayload = payload;
        },
      );

      const payload = NotificationPayload(
        type: 'custom_event',
        id: 'e_1',
        data: {'param': 'val'},
      );

      final handled = await flow.handle(payload);

      expect(handled, isTrue);
      expect(eventPayload, equals(payload));

      await flow.dispose();
    });

    test(
        'executes route handler when available, falling back to onNotification when no route matches',
        () async {
      final context = _FakeBuildContext();
      var routeHandled = false;
      var eventHandled = false;

      final flow = NotificationFlow(
        routes: {
          'routed_type': (ctx, payload) {
            routeHandled = true;
          },
        },
        onNotification: (payload) {
          eventHandled = true;
        },
      );

      // 1. Matched route
      await flow.handle(
          const NotificationPayload(type: 'routed_type', data: {}),
          context: context);
      expect(routeHandled, isTrue);
      expect(eventHandled, isFalse);

      // 2. Unmatched route falls back to onNotification
      await flow.handle(
          const NotificationPayload(type: 'fallback_type', data: {}),
          context: context);
      expect(eventHandled, isTrue);

      await flow.dispose();
    });

    test('calls onUnhandledNotification when no route or event handler matches',
        () async {
      final context = _FakeBuildContext();
      NotificationPayload? unhandledPayload;

      final flow = NotificationFlow(
        routes: {
          'known': (ctx, payload) {},
        },
        onUnhandledNotification: (payload) {
          unhandledPayload = payload;
        },
      );

      const payload = NotificationPayload(type: 'unknown_type', data: {});
      final handled = await flow.handle(payload, context: context);

      expect(handled, isFalse);
      expect(unhandledPayload, equals(payload));

      await flow.dispose();
    });

    test(
        'duplicate protection blocks repeated notifications and emits duplicate event',
        () async {
      final context = _FakeBuildContext();
      var handlerExecutions = 0;

      final flow = NotificationFlow(
        config: const NotificationFlowConfig(
          enableDuplicateProtection: true,
          duplicateCacheDuration: Duration(minutes: 5),
        ),
        routes: {
          'chat': (ctx, payload) {
            handlerExecutions++;
          },
        },
      );

      final events = <NotificationFlowEvent>[];
      final subscription = flow.events.listen(events.add);

      const payload =
          NotificationPayload(type: 'chat', id: 'dup_test_1', data: {});

      final firstResult = await flow.handle(payload, context: context);
      final secondResult = await flow.handle(payload, context: context);

      expect(firstResult, isTrue);
      expect(secondResult, isFalse);
      expect(handlerExecutions, equals(1));

      // Allow stream microtasks to fire
      await Future.delayed(const Duration(milliseconds: 10));

      expect(
        events.map((e) => e.status).toList(),
        equals([
          NotificationFlowStatus.received,
          NotificationFlowStatus.handling,
          NotificationFlowStatus.handled,
          NotificationFlowStatus.duplicate,
        ]),
      );

      await subscription.cancel();
      await flow.dispose();
    });

    test(
        'catches handler exceptions, reports via onError, and emits failed event',
        () async {
      final context = _FakeBuildContext();
      Object? caughtError;
      NotificationPayload? failedPayload;

      final flow = NotificationFlow(
        routes: {
          'error_trigger': (ctx, payload) {
            throw StateError('Custom route exception');
          },
        },
        onError: (payload, error, stackTrace) {
          failedPayload = payload;
          caughtError = error;
        },
      );

      final events = <NotificationFlowEvent>[];
      final subscription = flow.events.listen(events.add);

      const payload = NotificationPayload(type: 'error_trigger', data: {});
      final result = await flow.handle(payload, context: context);

      expect(result, isFalse);
      expect(failedPayload, equals(payload));
      expect(caughtError, isA<NotificationRouteException>());

      await Future.delayed(const Duration(milliseconds: 10));
      expect(
          events.any((e) => e.status == NotificationFlowStatus.failed), isTrue);

      await subscription.cancel();
      await flow.dispose();
    });

    test('handleMap and handleJson parse and process payloads correctly',
        () async {
      final context = _FakeBuildContext();
      final handledTypes = <String>[];

      final flow = NotificationFlow(
        routes: {
          'chat': (ctx, payload) {
            handledTypes.add(payload.type);
          },
          'post': (ctx, payload) {
            handledTypes.add(payload.type);
          },
        },
      );

      final mapSuccess = await flow
          .handleMap({'type': 'chat', 'chatId': '101'}, context: context);
      final jsonSuccess = await flow
          .handleJson('{"type":"post","postId":"202"}', context: context);

      expect(mapSuccess, isTrue);
      expect(jsonSuccess, isTrue);
      expect(handledTypes, equals(['chat', 'post']));

      // Malformed inputs
      var errorCaught = false;
      final flowWithError = NotificationFlow(
        onError: (payload, error, stackTrace) {
          errorCaught = true;
        },
      );

      final badJsonSuccess =
          await flowWithError.handleJson('invalid json', context: context);
      expect(badJsonSuccess, isFalse);
      expect(errorCaught, isTrue);

      await flow.dispose();
      await flowWithError.dispose();
    });

    test(
        'dynamic route management (registerRoute, registerRoutes, unregisterRoute)',
        () {
      final flow = NotificationFlow();

      expect(flow.hasRoute('chat'), isFalse);
      flow.registerRoute('chat', (context, payload) {});
      expect(flow.hasRoute('chat'), isTrue);
      expect(flow.registeredRoutes, contains('chat'));

      flow.registerRoutes({
        'post': (context, payload) {},
        'profile': (context, payload) {},
      });
      expect(flow.registeredRoutes.length, equals(3));

      expect(flow.unregisterRoute('post'), isTrue);
      expect(flow.hasRoute('post'), isFalse);
    });

    test(
        'concurrent processPendingNotifications calls do not duplicate processing',
        () async {
      final context = _FakeBuildContext();
      var executedCount = 0;

      final flow = NotificationFlow(
        routes: {
          'chat': (ctx, payload) async {
            await Future.delayed(const Duration(milliseconds: 25));
            executedCount++;
          },
        },
      );

      // Queue items without context first
      await flow
          .handle(const NotificationPayload(type: 'chat', id: 'q1', data: {}));
      await flow
          .handle(const NotificationPayload(type: 'chat', id: 'q2', data: {}));
      expect(flow.pendingCount, equals(2));

      // Trigger multiple concurrent process calls
      final future1 = flow.processPendingNotifications(context: context);
      final future2 = flow.processPendingNotifications(context: context);
      final future3 = flow.processPendingNotifications(context: context);

      await Future.wait([future1, future2, future3]);

      expect(executedCount, equals(2));
      expect(flow.pendingCount, equals(0));

      await flow.dispose();
    });

    test('throws NotificationFlowException when calling methods after disposal',
        () async {
      final flow = NotificationFlow();
      await flow.dispose();
      expect(flow.isDisposed, isTrue);

      expect(
        () => flow.handle(const NotificationPayload(type: 'chat', data: {})),
        throwsA(isA<NotificationFlowException>()),
      );
    });
  });
}
