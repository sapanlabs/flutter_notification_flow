import 'dart:async';
import 'package:flutter/widgets.dart';
import 'config/notification_flow_config.dart';
import 'duplicate/notification_duplicate_guard.dart';
import 'errors/notification_flow_exception.dart';
import 'models/notification_flow_event.dart';
import 'models/notification_payload.dart';
import 'queue/notification_queue.dart';
import 'routing/notification_route_handler.dart';
import 'routing/notification_router.dart';
import 'utils/notification_logger.dart';

/// The central coordinator for normalized notification payload routing,
/// navigation lifecycle readiness, queueing, deduplication, and event streaming.
class NotificationFlow {
  /// Global navigator key used to access the current [BuildContext] for route handlers.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Global callback for event-based notification handling (independent of [NavigatorState]).
  final NotificationEventHandler? onNotification;

  /// Callback invoked when a notification arrives with a type that has no registered handler.
  final NotificationEventHandler? onUnhandledNotification;

  /// Callback invoked when an error occurs during payload normalization or routing execution.
  final NotificationErrorHandler? onError;

  /// Configuration options for this flow.
  final NotificationFlowConfig config;

  final NotificationRouter _router;
  final NotificationQueue _queue;
  final NotificationDuplicateGuard _duplicateGuard;
  final NotificationLogger _logger;
  final StreamController<NotificationFlowEvent> _eventController;

  bool _isDisposed = false;

  /// Creates a [NotificationFlow] instance.
  NotificationFlow({
    this.navigatorKey,
    Map<String, NotificationRouteHandler>? routes,
    this.onNotification,
    this.onUnhandledNotification,
    this.onError,
    NotificationFlowConfig? config,
    NotificationQueue? queue,
    NotificationDuplicateGuard? duplicateGuard,
  })  : config = config ?? const NotificationFlowConfig(),
        _router = NotificationRouter(routes),
        _queue = queue ?? NotificationQueue(),
        _duplicateGuard = duplicateGuard ??
            NotificationDuplicateGuard(
              cacheDuration: (config ?? const NotificationFlowConfig())
                  .duplicateCacheDuration,
            ),
        _logger = NotificationLogger(
          enabled: (config ?? const NotificationFlowConfig()).enableDebugLogs,
        ),
        _eventController = StreamController<NotificationFlowEvent>.broadcast();

  /// Broadcast stream of notification lifecycle events.
  Stream<NotificationFlowEvent> get events => _eventController.stream;

  /// Returns the number of notification payloads currently pending in the queue.
  int get pendingCount => _queue.length;

  /// Returns an unmodifiable snapshot list of pending notifications in FIFO order.
  List<NotificationPayload> get pendingNotifications => _queue.toList();

  /// Returns an unmodifiable set of all currently registered route types.
  Set<String> get registeredRoutes => _router.registeredRoutes;

  /// Whether this [NotificationFlow] has been disposed.
  bool get isDisposed => _isDisposed;

  /// Initializes the notification flow and processes any queued notifications
  /// if [NotificationFlowConfig.autoProcessQueueOnReady] is enabled.
  Future<void> initialize() async {
    _logger.info('Initializing NotificationFlow');
    if (config.autoProcessQueueOnReady && _queue.isNotEmpty) {
      await processPendingNotifications();
    }
  }

  /// Registers a [handler] for a given notification [type].
  void registerRoute(String type, NotificationRouteHandler handler) {
    _router.register(type, handler);
    _logger.info('Registered route handler for type: "$type"');
  }

  /// Registers multiple routes at once.
  void registerRoutes(Map<String, NotificationRouteHandler> routes) {
    _router.registerAll(routes);
    _logger.info('Registered ${routes.length} route handlers');
  }

  /// Unregisters the handler for a given notification [type].
  bool unregisterRoute(String type) {
    final removed = _router.unregister(type);
    if (removed) {
      _logger.info('Unregistered route handler for type: "$type"');
    }
    return removed;
  }

  /// Checks if a route handler is registered for the specified notification [type].
  bool hasRoute(String type) => _router.hasRoute(type);

  /// Handles an incoming normalized [NotificationPayload].
  ///
  /// Performs duplicate protection, lifecycle readiness checks, queueing if context
  /// is not yet available, and route/event dispatching.
  ///
  /// Returns `true` if the notification was successfully handled or queued for deferred handling,
  /// or `false` if it was rejected as a duplicate or unhandled.
  Future<bool> handle(NotificationPayload payload,
      {BuildContext? context}) async {
    _ensureNotDisposed();

    try {
      // 1. Duplicate Protection Check
      if (config.enableDuplicateProtection) {
        final isDup = _duplicateGuard.checkAndRecord(payload);
        if (isDup) {
          _logger.warning(
              'Duplicate notification ignored: ${payload.fingerprint}');
          _emitEvent(NotificationFlowEvent(
            payload: payload,
            status: NotificationFlowStatus.duplicate,
          ));
          return false;
        }
      }

      // 2. Emit Received Event
      _logger.info(
          'Received notification: type="${payload.type}", id="${payload.id}"');
      _emitEvent(NotificationFlowEvent(
        payload: payload,
        status: NotificationFlowStatus.received,
      ));

      // 3. Check Navigation Readiness
      final effectiveContext = context ?? navigatorKey?.currentContext;
      final hasRegisteredRoute = _router.hasRoute(payload.type);

      // If a route handler is registered for this type but context is not ready, queue it.
      if (hasRegisteredRoute && effectiveContext == null) {
        _logger.info(
            'Navigator context not ready. Queuing notification: ${payload.type}');
        _queue.enqueue(payload);
        _emitEvent(NotificationFlowEvent(
          payload: payload,
          status: NotificationFlowStatus.queued,
        ));
        return true;
      }

      // 4. Dispatch and Execute Handler
      return await _dispatchPayload(payload, effectiveContext);
    } catch (error, stackTrace) {
      _handleError(payload, error, stackTrace);
      return false;
    }
  }

  /// Normalizes a raw map and handles the resulting [NotificationPayload].
  ///
  /// Useful for Firebase Messaging payloads:
  /// ```dart
  /// notificationFlow.handleMap(remoteMessage.data);
  /// ```
  Future<bool> handleMap(Map<dynamic, dynamic> map,
      {BuildContext? context}) async {
    _ensureNotDisposed();
    try {
      final payload = NotificationPayload.fromMap(map);
      return await handle(payload, context: context);
    } catch (error, stackTrace) {
      _handleError(null, error, stackTrace);
      return false;
    }
  }

  /// Parses a JSON string and handles the resulting [NotificationPayload].
  ///
  /// Useful for local notification payloads:
  /// ```dart
  /// notificationFlow.handleJson(notificationResponse.payload!);
  /// ```
  Future<bool> handleJson(String jsonString, {BuildContext? context}) async {
    _ensureNotDisposed();
    try {
      final payload = NotificationPayload.fromJson(jsonString);
      return await handle(payload, context: context);
    } catch (error, stackTrace) {
      _handleError(null, error, stackTrace);
      return false;
    }
  }

  bool _isProcessingQueue = false;

  /// Processes all notifications currently held in the pending queue in FIFO order.
  ///
  /// If navigation context is still not available and queued items require route handlers,
  /// processing is safely halted and unhandled items remain in the queue.
  ///
  /// Concurrent calls to this method are ignored while a queue processing cycle is active.
  Future<void> processPendingNotifications({BuildContext? context}) async {
    _ensureNotDisposed();
    if (_queue.isEmpty || _isProcessingQueue) return;

    _isProcessingQueue = true;
    try {
      final effectiveContext = context ?? navigatorKey?.currentContext;
      _logger.info('Processing ${_queue.length} pending notifications');

      while (_queue.isNotEmpty) {
        final payload = _queue.peek();
        if (payload == null) break;

        final hasRegisteredRoute = _router.hasRoute(payload.type);
        if (hasRegisteredRoute && effectiveContext == null) {
          _logger.warning(
              'Context still unavailable when processing pending notification: ${payload.type}');
          break;
        }

        // Dequeue right before dispatching
        _queue.dequeue();

        try {
          await _dispatchPayload(payload, effectiveContext);
        } catch (error, stackTrace) {
          _handleError(payload, error, stackTrace);
        }
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Dispatches the payload to route handler or event handler.
  Future<bool> _dispatchPayload(
    NotificationPayload payload,
    BuildContext? context,
  ) async {
    _emitEvent(NotificationFlowEvent(
      payload: payload,
      status: NotificationFlowStatus.handling,
    ));

    // Priority 1: Registered Route Handler (if route exists and context is present)
    if (_router.hasRoute(payload.type) && context != null) {
      _logger.info('Dispatching to route handler: "${payload.type}"');
      await _router.execute(context, payload);
      _emitEvent(NotificationFlowEvent(
        payload: payload,
        status: NotificationFlowStatus.handled,
      ));
      return true;
    }

    // Priority 2: Global Event Callback (for event-based navigation e.g. GetX, GoRouter, Riverpod)
    if (onNotification != null) {
      _logger.info('Dispatching to onNotification callback: "${payload.type}"');
      final result = onNotification!(payload);
      if (result is Future) {
        await result;
      }
      _emitEvent(NotificationFlowEvent(
        payload: payload,
        status: NotificationFlowStatus.handled,
      ));
      return true;
    }

    // Priority 3: Unhandled
    _logger
        .warning('No handler found for notification type: "${payload.type}"');
    if (onUnhandledNotification != null) {
      final result = onUnhandledNotification!(payload);
      if (result is Future) {
        await result;
      }
    }
    _emitEvent(NotificationFlowEvent(
      payload: payload,
      status: NotificationFlowStatus.unhandled,
    ));
    return false;
  }

  void _emitEvent(NotificationFlowEvent event) {
    if (!_isDisposed && !_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  void _handleError(
      NotificationPayload? payload, Object error, StackTrace stackTrace) {
    _logger.error('Error handling notification', error, stackTrace);

    if (payload != null) {
      _emitEvent(NotificationFlowEvent(
        payload: payload,
        status: NotificationFlowStatus.failed,
        error: error,
        stackTrace: stackTrace,
      ));
    }

    if (onError != null) {
      onError!(payload, error, stackTrace);
    } else {
      // If no custom error handler was provided and error is NotificationFlowException, do not swallow silently
      if (error is NotificationFlowException) {
        // Logged already
      }
    }
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw const NotificationFlowException(
        'Cannot perform operation: NotificationFlow has already been disposed.',
      );
    }
  }

  /// Disposes resources, closes the event stream, and clears memory queues.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _queue.clear();
    _duplicateGuard.clear();
    _router.clear();
    await _eventController.close();
    _logger.info('NotificationFlow disposed successfully');
  }
}
