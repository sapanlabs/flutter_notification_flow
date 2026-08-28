import 'package:flutter/material.dart';
import 'package:flutter_notification_flow/flutter_notification_flow.dart';
import 'package:flutter_notification_flow_example/home_page.dart';
import 'package:flutter_notification_flow_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Example app renders HomePage with simulation buttons',
      (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    final flow = NotificationFlow(navigatorKey: navKey);

    await tester.pumpWidget(
      MyApp(
        navigatorKey: navKey,
        flow: flow,
      ),
    );

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Flutter Notification Flow'), findsOneWidget);
    expect(find.text('Simulate Chat Notification'), findsOneWidget);
    expect(find.text('Simulate Post Notification'), findsOneWidget);
    expect(find.text('Simulate Profile Notification'), findsOneWidget);
    expect(find.text('Live Event Stream'), findsOneWidget);

    await flow.dispose();
  });
}
