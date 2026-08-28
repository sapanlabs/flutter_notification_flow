import 'package:flutter/material.dart';
import 'package:flutter_notification_flow/flutter_notification_flow.dart';
import 'chat_page.dart';
import 'home_page.dart';
import 'post_page.dart';
import 'profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final navigatorKey = GlobalKey<NavigatorState>();

  final notificationFlow = NotificationFlow(
    navigatorKey: navigatorKey,
    config: const NotificationFlowConfig(
      enableDuplicateProtection: true,
      duplicateCacheDuration: Duration(minutes: 5),
      enableDebugLogs: true,
    ),
    routes: {
      'chat': (context, payload) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatPage(payload: payload),
          ),
        );
      },
      'post': (context, payload) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PostPage(payload: payload),
          ),
        );
      },
      'profile': (context, payload) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProfilePage(payload: payload),
          ),
        );
      },
    },
    onUnhandledNotification: (payload) {
      debugPrint('Unhandled notification type received: "${payload.type}"');
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unhandled notification type: "${payload.type}"'),
            backgroundColor: Colors.blueGrey,
          ),
        );
      }
    },
    onError: (payload, error, stackTrace) {
      debugPrint('NotificationFlow error occurred: $error');
    },
  );

  await notificationFlow.initialize();

  runApp(MyApp(navigatorKey: navigatorKey, flow: notificationFlow));
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final NotificationFlow flow;

  const MyApp({
    super.key,
    required this.navigatorKey,
    required this.flow,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Notification Flow Demo',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: HomePage(flow: flow),
    );
  }
}
