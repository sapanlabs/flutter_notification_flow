# flutter_notification_flow

A provider-independent Flutter package for normalizing and reliably routing notification interactions across different notification sources and application states.

[![CI](https://github.com/sapanlabs/flutter_notification_flow/actions/workflows/ci.yml/badge.svg)](https://github.com/sapanlabs/flutter_notification_flow/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/flutter_notification_flow.svg)](https://pub.dev/packages/flutter_notification_flow)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![style: flutter lints](https://img.shields.io/badge/style-flutter__lints-purple.svg)](https://pub.dev/packages/flutter_lints)

---

## 💡 Overview

Flutter applications frequently receive notification interactions from diverse sources:
- **Firebase Cloud Messaging (FCM)**
- **Flutter Local Notifications**
- **OneSignal / Pusher / WebSockets / Custom Backends**

These notification taps occur across distinct application lifecycles:
- **Foreground events**
- **Background events (user taps notification tray)**
- **Terminated state / Cold start launches**

Without a unified routing layer, developers end up duplicating navigation logic across `onMessageOpenedApp`, `getInitialMessage`, local notification callbacks, and deep links. This causes race conditions during startup, duplicate route pushes, and difficult-to-maintain spaghetti code.

**`flutter_notification_flow`** provides a clean, provider-independent layer that normalizes raw notification data into an immutable `NotificationPayload` and routes it to registered handlers or event callbacks—complete with built-in cold-start queueing, sliding-window deduplication, and observable lifecycle streams.

---

## ✨ Features

- 🎯 **Provider-Independent**: Zero required dependencies on Firebase, OneSignal, or any push service. Connect any provider in just a few lines.
- 📦 **Normalized Payloads**: Converts flat maps, nested maps, and JSON strings into an immutable `NotificationPayload`.
- 🧭 **Dual Routing Models**:
  - **Route-Based Handlers**: Execute context-aware handlers using Flutter's `NavigatorState`.
  - **Event-Based Callbacks**: Listen via `onNotification` for frameworks like **GetX**, **GoRouter**, **Riverpod**, and **Bloc**.
- ⏳ **Cold Start & Lifecycle Readiness**: Buffers notification events in a FIFO memory queue if the app is still launching or the `Navigator` is not ready, then automatically processes them when mounted.
- 🛡️ **Duplicate Protection**: Configurable sliding time-window deduplication using notification IDs or deterministic payload fingerprints.
- ⚠️ **Graceful Fallbacks & Error Isolation**: Handles unknown notification types and runtime handler exceptions without crashing the host app.
- 📡 **Observable Event Stream**: Broadcast stream of lifecycle events (`received`, `queued`, `handling`, `handled`, `duplicate`, `unhandled`, `failed`).
- 🪶 **Lightweight & Fast**: Pure Dart and Flutter SDK capabilities only with zero unnecessary dependencies.

---

## 🏛️ How It Works

```text
Notification Sources (FCM, Local Notifications, OneSignal, etc.)
                          │
                          ▼
              Normalize Payload Data
     (NotificationPayload.fromMap / fromJson)
                          │
                          ▼
                  NotificationFlow
                          │
       ┌──────────────────┴──────────────────┐
       ▼                                     ▼
Context Available?                     Context Unavailable? (Cold start)
       │                                     │
Route Resolver & Deduplication         Enqueue into NotificationQueue (FIFO)
       │                                     │
       ├─────────────────────────────────────┼────────────────────────────┐
       ▼                                     ▼                            ▼
Route Handler                         Event Callback              Unhandled Callback
(Navigator push / dialog)         (GetX / GoRouter / Riverpod)   (Logging / Analytics)
       │                                     │                            │
       └─────────────────────────────────────┴────────────────────────────┘
                                             │
                                             ▼
                              Application Action / Navigation
```

---

## 📦 Installation

Add `flutter_notification_flow` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_notification_flow: ^0.1.0
```

Then install dependencies:

```bash
flutter pub get
```

---

## 🚀 Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:flutter_notification_flow/flutter_notification_flow.dart';

final navigatorKey = GlobalKey<NavigatorState>();

final notificationFlow = NotificationFlow(
  navigatorKey: navigatorKey,
  routes: {
    'chat': (context, payload) {
      final chatId = payload.data['chatId'];
      Navigator.of(context).pushNamed('/chat', arguments: chatId);
    },
    'post': (context, payload) {
      final postId = payload.data['postId'];
      Navigator.of(context).pushNamed('/post', arguments: postId);
    },
  },
  onUnhandledNotification: (payload) {
    debugPrint('Unhandled notification type: ${payload.type}');
  },
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await notificationFlow.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: const Scaffold(
        body: Center(child: Text('Home Screen')),
      ),
    );
  }
}
```

---

## 📖 Basic Usage

### Option A: Route-Based Handling (Recommended)

When using standard Flutter navigation, provide a `GlobalKey<NavigatorState>` and register route handlers:

```dart
final notificationFlow = NotificationFlow(
  navigatorKey: navigatorKey,
  routes: {
    'chat': (context, payload) async {
      final chatId = payload.data['chatId'];
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatPage(chatId: chatId)),
      );
    },
    'profile': (context, payload) {
      final userId = payload.data['userId'];
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProfilePage(userId: userId)),
      );
    },
  },
);
```

### Option B: Event-Based Handling (Custom Navigation / State Management)

If your app uses **GetX**, **GoRouter**, **Riverpod**, or **Bloc**, you can handle notification interactions without requiring a `navigatorKey`:

```dart
final notificationFlow = NotificationFlow(
  onNotification: (payload) {
    switch (payload.type) {
      case 'chat':
        // Example with GoRouter:
        // context.go('/chat/${payload.data['chatId']}');
        break;
      case 'profile':
        // Example with GetX:
        // Get.toNamed('/profile', arguments: payload.data);
        break;
    }
  },
);
```

---

## 🗂️ Notification Payload Structure

`NotificationPayload` automatically normalizes both nested and flat structures:

#### Nested Payload:
```json
{
  "type": "chat",
  "id": "notif_101",
  "data": {
    "chatId": "c_99",
    "sender": "Alice"
  }
}
```

#### Flat Payload:
```json
{
  "type": "chat",
  "id": "notif_101",
  "chatId": "c_99",
  "sender": "Alice"
}
```

Both produce identical normalized `NotificationPayload` instances:
- `payload.type` ➔ `'chat'`
- `payload.id` ➔ `'notif_101'`
- `payload.data` ➔ `{'chatId': 'c_99', 'sender': 'Alice'}`

Common alternative keys such as `notification_type`, `notificationType`, `notification_id`, `message_id`, and `messageId` are also parsed seamlessly.

---

## 🔌 Provider Integrations

### Firebase Cloud Messaging (FCM)

The package remains completely provider-independent. Integrate Firebase Messaging in your application code:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_notification_flow/flutter_notification_flow.dart';

void setupFirebaseMessaging(NotificationFlow flow) async {
  // 1. App opened from terminated state (cold start)
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    await flow.handleMap(initialMessage.data);
  }

  // 2. App opened from background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    flow.handleMap(message.data);
  });
}
```

### Flutter Local Notifications

Forward tapped local notification payload strings directly:

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_notification_flow/flutter_notification_flow.dart';

void onSelectNotification(NotificationResponse response, NotificationFlow flow) {
  final payloadString = response.payload;
  if (payloadString != null && payloadString.isNotEmpty) {
    flow.handleJson(payloadString);
  }
}
```

---

## 🛡️ Duplicate Notification Protection

Notifications can occasionally be processed multiple times during rapid app launches (for instance, when `getInitialMessage` and `onMessageOpenedApp` both fire for the same interaction).

`NotificationDuplicateGuard` caches recently seen notifications in memory:

```dart
final notificationFlow = NotificationFlow(
  config: const NotificationFlowConfig(
    enableDuplicateProtection: true,
    duplicateCacheDuration: Duration(minutes: 5), // Cache sliding window
    enableDebugLogs: true,
  ),
);
```

#### Deduplication Strategy:
1. **Explicit Notification ID**: If `payload.id` is present, it is used as the unique key.
2. **Deterministic Data Fingerprint**: If `payload.id` is omitted, a deterministic fingerprint is generated based on `payload.type` and recursively sorted key-value pairs of `payload.data`.

---

## ⏳ Cold Start & Pending Queue

When a notification arrives before the Flutter widget tree or `NavigatorState` is mounted (`navigatorKey.currentContext == null`):

1. The notification is placed into an in-memory FIFO `NotificationQueue`.
2. A `NotificationFlowStatus.queued` event is emitted on the event stream.
3. When `notificationFlow.initialize()` or `processPendingNotifications()` is called, pending notifications are drained and executed in strict arrival order.

---

## 📡 Event Stream & Observability

Subscribe to `events` to monitor lifecycle status transitions across your entire app:

```dart
final subscription = notificationFlow.events.listen((event) {
  print('Status: ${event.status}, Type: ${event.payload.type}');
});
```

### Lifecycle Statuses (`NotificationFlowStatus`)

| Status | Description |
| :--- | :--- |
| `received` | The notification was received by `NotificationFlow`. |
| `queued` | Navigator context is not yet ready; payload was queued. |
| `handling` | Handler execution has started. |
| `handled` | Handler or callback completed successfully. |
| `unhandled` | No handler was registered for this notification type. |
| `duplicate` | The notification was identified as a duplicate and ignored. |
| `failed` | An error occurred during routing or handler execution. |

---

## ⚠️ Error Handling

Errors during route execution or payload parsing are isolated and reported through `onError` without crashing the application:

```dart
final notificationFlow = NotificationFlow(
  onError: (payload, error, stackTrace) {
    debugPrint('NotificationFlow error handling "${payload?.type}": $error');
  },
);
```

---

## 📚 API Reference

### `NotificationFlow`
- `NotificationFlow({navigatorKey, routes, onNotification, onUnhandledNotification, onError, config})` — Main coordinator.
- `Future<void> initialize()` — Initializes flow and flushes queued cold-start notifications.
- `Future<bool> handle(NotificationPayload payload, {BuildContext? context})` — Handles normalized payload.
- `Future<bool> handleMap(Map<dynamic, dynamic> map, {BuildContext? context})` — Parses map and handles payload.
- `Future<bool> handleJson(String jsonString, {BuildContext? context})` — Parses JSON string and handles payload.
- `Future<void> processPendingNotifications({BuildContext? context})` — Manually processes queued notifications.
- `void registerRoute(String type, NotificationRouteHandler handler)` — Dynamically registers a route handler.
- `void registerRoutes(Map<String, NotificationRouteHandler> routes)` — Registers multiple route handlers.
- `bool unregisterRoute(String type)` — Removes a registered route handler.
- `bool hasRoute(String type)` — Checks if a route handler exists.
- `Stream<NotificationFlowEvent> get events` — Broadcast stream of lifecycle events.
- `int get pendingCount` — Number of pending notifications currently queued.
- `List<NotificationPayload> get pendingNotifications` — Snapshot of queued notifications.
- `Future<void> dispose()` — Releases stream controllers and internal caches.

### `NotificationPayload`
- `NotificationPayload({required type, required data, id})` — Immutable payload.
- `NotificationPayload.fromMap(Map<dynamic, dynamic> map)` — Factory from raw map.
- `NotificationPayload.fromJson(String jsonString)` — Factory from JSON string.
- `String get fingerprint` — Deterministic unique string for deduplication.
- `Map<String, dynamic> toMap()` / `String toJson()` — Serialization helpers.

### `NotificationFlowConfig`
- `enableDuplicateProtection: bool` (default: `true`)
- `duplicateCacheDuration: Duration` (default: `Duration(minutes: 5)`)
- `enableDebugLogs: bool` (default: `false`)
- `autoProcessQueueOnReady: bool` (default: `true`)

---

## 📱 Example Application

A complete example application is available in the [`example/`](example/) directory.

To run the example app locally:

```bash
cd example
flutter pub get
flutter run
```

---

## 🤝 Contributing

Contributions are welcome! Please check out [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on code formatting, static analysis, running tests, and opening pull requests.

---

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.
