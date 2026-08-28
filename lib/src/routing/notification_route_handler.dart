import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/notification_payload.dart';

/// Handler function signature for route-based notification handling with [BuildContext].
///
/// Can return a [Future] for asynchronous operations (e.g. async navigation or data fetching).
typedef NotificationRouteHandler = FutureOr<void> Function(
  BuildContext context,
  NotificationPayload payload,
);

/// Callback signature for event-based notification handling without direct [BuildContext] requirement.
///
/// Ideal for GetX, GoRouter, Riverpod, Bloc, or custom navigation solutions.
typedef NotificationEventHandler = FutureOr<void> Function(
  NotificationPayload payload,
);

/// Callback signature for error reporting during notification routing and execution.
typedef NotificationErrorHandler = void Function(
  NotificationPayload? payload,
  Object error,
  StackTrace stackTrace,
);
