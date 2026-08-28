# Changelog

All notable changes to this project will be documented in this file.

## 0.1.0

- Initial release.
- Added normalized `NotificationPayload` supporting flexible nested and flat data structures, JSON parsing, and deterministic fingerprinting.
- Added context-aware route handling with `NotificationRouter` and `NotificationRouteHandler`.
- Added framework-independent event-based handling via `onNotification`.
- Added in-memory FIFO `NotificationQueue` for cold starts and navigation lifecycle readiness.
- Added `NotificationDuplicateGuard` with configurable cache expiration windows.
- Added lightweight broadcast `events` stream with comprehensive `NotificationFlowStatus` states.
- Added structured error handling via `NotificationFlowException` and `onError` callback.
- Added customizable `NotificationFlowConfig` and internal debug logging.
