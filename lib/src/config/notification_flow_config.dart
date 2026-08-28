import 'package:flutter/foundation.dart';

/// Configuration options for [NotificationFlow].
@immutable
class NotificationFlowConfig {
  /// Whether duplicate notification protection is enabled.
  ///
  /// When `true`, notifications with identical identifiers or deterministic
  /// fingerprints received within [duplicateCacheDuration] are ignored and
  /// will trigger a `duplicate` event rather than invoking route handlers again.
  ///
  /// Defaults to `true`.
  final bool enableDuplicateProtection;

  /// The time window during which a processed notification is considered a duplicate.
  ///
  /// Defaults to `Duration(minutes: 5)`.
  final Duration duplicateCacheDuration;

  /// Whether internal debug logs are emitted via Flutter's `debugPrint`.
  ///
  /// Defaults to `false`.
  final bool enableDebugLogs;

  /// Whether pending queued notifications are automatically drained and processed
  /// once navigation context or handlers become available.
  ///
  /// Defaults to `true`.
  final bool autoProcessQueueOnReady;

  /// Creates a [NotificationFlowConfig] instance.
  const NotificationFlowConfig({
    this.enableDuplicateProtection = true,
    this.duplicateCacheDuration = const Duration(minutes: 5),
    this.enableDebugLogs = false,
    this.autoProcessQueueOnReady = true,
  });

  /// Creates a copy of this configuration with the given fields replaced.
  NotificationFlowConfig copyWith({
    bool? enableDuplicateProtection,
    Duration? duplicateCacheDuration,
    bool? enableDebugLogs,
    bool? autoProcessQueueOnReady,
  }) {
    return NotificationFlowConfig(
      enableDuplicateProtection:
          enableDuplicateProtection ?? this.enableDuplicateProtection,
      duplicateCacheDuration:
          duplicateCacheDuration ?? this.duplicateCacheDuration,
      enableDebugLogs: enableDebugLogs ?? this.enableDebugLogs,
      autoProcessQueueOnReady:
          autoProcessQueueOnReady ?? this.autoProcessQueueOnReady,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationFlowConfig &&
          runtimeType == other.runtimeType &&
          enableDuplicateProtection == other.enableDuplicateProtection &&
          duplicateCacheDuration == other.duplicateCacheDuration &&
          enableDebugLogs == other.enableDebugLogs &&
          autoProcessQueueOnReady == other.autoProcessQueueOnReady;

  @override
  int get hashCode => Object.hash(
        enableDuplicateProtection,
        duplicateCacheDuration,
        enableDebugLogs,
        autoProcessQueueOnReady,
      );

  @override
  String toString() =>
      'NotificationFlowConfig(enableDuplicateProtection: $enableDuplicateProtection, '
      'duplicateCacheDuration: $duplicateCacheDuration, enableDebugLogs: $enableDebugLogs, '
      'autoProcessQueueOnReady: $autoProcessQueueOnReady)';
}
