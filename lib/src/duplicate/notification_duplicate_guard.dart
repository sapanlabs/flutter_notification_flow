import '../models/notification_payload.dart';

/// Lightweight in-memory guard that protects against duplicate notification handling
/// within a sliding time window.
class NotificationDuplicateGuard {
  /// The duration for which a processed notification fingerprint remains cached.
  final Duration cacheDuration;

  /// Custom timestamp provider (useful for deterministic unit testing).
  final DateTime Function() _now;

  final Map<String, DateTime> _seenCache = <String, DateTime>{};

  /// Creates a [NotificationDuplicateGuard] with the specified [cacheDuration].
  NotificationDuplicateGuard({
    this.cacheDuration = const Duration(minutes: 5),
    DateTime Function()? nowProvider,
  }) : _now = nowProvider ?? DateTime.now;

  /// Returns the number of items currently tracked in the duplicate cache.
  int get cacheSize {
    _sweepExpired();
    return _seenCache.length;
  }

  /// Checks if [payload] is a duplicate within the current [cacheDuration] window.
  bool isDuplicate(NotificationPayload payload) {
    _sweepExpired();
    final key = payload.fingerprint;
    final timestamp = _seenCache[key];
    if (timestamp == null) return false;

    final isExpired = _now().difference(timestamp) > cacheDuration;
    if (isExpired) {
      _seenCache.remove(key);
      return false;
    }
    return true;
  }

  /// Records [payload] in the duplicate cache.
  void record(NotificationPayload payload) {
    _sweepExpired();
    _seenCache[payload.fingerprint] = _now();
  }

  /// Atomically checks if [payload] is a duplicate and records it if it was not.
  ///
  /// Returns `true` if the notification is a duplicate (already seen within [cacheDuration]),
  /// or `false` if it was fresh and has now been recorded.
  bool checkAndRecord(NotificationPayload payload) {
    if (isDuplicate(payload)) {
      return true;
    }
    record(payload);
    return false;
  }

  /// Clears all cached entries.
  void clear() {
    _seenCache.clear();
  }

  /// Sweeps expired cache entries to prevent memory growth over long app lifecycles.
  void _sweepExpired() {
    final now = _now();
    _seenCache.removeWhere(
        (_, timestamp) => now.difference(timestamp) > cacheDuration);
  }
}
