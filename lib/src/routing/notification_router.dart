import 'dart:async';
import 'package:flutter/widgets.dart';
import '../errors/notification_flow_exception.dart';
import '../models/notification_payload.dart';
import 'notification_route_handler.dart';

/// Registry and dispatcher for route-based notification handlers.
class NotificationRouter {
  final Map<String, NotificationRouteHandler> _routes;

  /// Creates a [NotificationRouter] with optional initial [routes].
  NotificationRouter([Map<String, NotificationRouteHandler>? routes])
      : _routes =
            Map<String, NotificationRouteHandler>.from(routes ?? const {});

  /// Returns an unmodifiable view of all registered route keys.
  Set<String> get registeredRoutes => Set.unmodifiable(_routes.keys);

  /// Checks whether a handler is registered for the specified notification [type].
  bool hasRoute(String type) => _routes.containsKey(type);

  /// Registers a [handler] for a given notification [type].
  void register(String type, NotificationRouteHandler handler) {
    _routes[type] = handler;
  }

  /// Registers multiple [routes] at once.
  void registerAll(Map<String, NotificationRouteHandler> routes) {
    _routes.addAll(routes);
  }

  /// Unregisters the handler for a given notification [type].
  ///
  /// Returns `true` if a handler was removed, or `false` if none was registered.
  bool unregister(String type) {
    return _routes.remove(type) != null;
  }

  /// Clears all registered routes.
  void clear() {
    _routes.clear();
  }

  /// Retrieves the handler for a given notification [type], or `null` if not registered.
  NotificationRouteHandler? getHandler(String type) => _routes[type];

  /// Executes the registered handler for the given [payload] using the provided [context].
  ///
  /// Throws [NotificationRouteException] if no handler is registered or if handler execution fails.
  Future<void> execute(
      BuildContext context, NotificationPayload payload) async {
    final handler = _routes[payload.type];
    if (handler == null) {
      throw NotificationRouteException(
        'No route handler registered for notification type: "${payload.type}".',
        routeType: payload.type,
      );
    }

    try {
      final result = handler(context, payload);
      if (result is Future) {
        await result;
      }
    } catch (e, stackTrace) {
      if (e is NotificationFlowException) {
        rethrow;
      }
      throw NotificationRouteException(
        'Error occurred while executing route handler for notification type "${payload.type}": $e',
        routeType: payload.type,
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }
}
