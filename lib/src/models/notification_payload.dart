import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../errors/notification_flow_exception.dart';

/// An immutable, normalized notification data payload.
///
/// Encapsulates the notification [type], optional identifier [id],
/// and associated key-value [data].
@immutable
class NotificationPayload {
  /// The routing type or action name of this notification (e.g. `'chat'`, `'post'`).
  final String type;

  /// Optional unique identifier for this notification instance.
  final String? id;

  /// The contextual data map associated with this notification.
  final Map<String, dynamic> data;

  /// Creates a [NotificationPayload].
  const NotificationPayload({
    required this.type,
    required this.data,
    this.id,
  });

  /// Creates a normalized [NotificationPayload] from a raw map.
  ///
  /// Supports both nested payloads:
  /// ```dart
  /// {
  ///   'type': 'chat',
  ///   'id': 'msg_01',
  ///   'data': {'chatId': '123'}
  /// }
  /// ```
  /// and flat payloads:
  /// ```dart
  /// {
  ///   'type': 'chat',
  ///   'chatId': '123'
  /// }
  /// ```
  ///
  /// Throws [NotificationPayloadException] if [type] is missing or empty.
  factory NotificationPayload.fromMap(Map<dynamic, dynamic> rawMap) {
    final map = <String, dynamic>{};
    for (final entry in rawMap.entries) {
      map[entry.key.toString()] = entry.value;
    }

    // Resolve type (support 'type', 'notification_type', 'notificationType')
    final rawType =
        map['type'] ?? map['notification_type'] ?? map['notificationType'];
    if (rawType == null || rawType.toString().trim().isEmpty) {
      throw const NotificationPayloadException(
        'Invalid notification payload: missing required non-empty "type" field.',
      );
    }
    final type = rawType.toString().trim();

    // Resolve ID (support 'id', 'notification_id', 'notificationId', 'message_id', 'messageId')
    final rawId = map['id'] ??
        map['notification_id'] ??
        map['notificationId'] ??
        map['message_id'] ??
        map['messageId'];
    final id = rawId?.toString().trim();

    // Resolve data
    final resolvedData = <String, dynamic>{};

    // If there is an explicit nested data map, extract its contents
    final nestedData = map['data'] ?? map['payload'];
    if (nestedData is Map) {
      for (final entry in nestedData.entries) {
        resolvedData[entry.key.toString()] = entry.value;
      }
    }

    // Collect all remaining top-level properties into data as well
    const reservedKeys = {
      'type',
      'notification_type',
      'notificationType',
      'id',
      'notification_id',
      'notificationId',
      'message_id',
      'messageId',
      'data',
      'payload',
    };

    for (final entry in map.entries) {
      if (!reservedKeys.contains(entry.key)) {
        resolvedData[entry.key] = entry.value;
      }
    }

    return NotificationPayload(
      type: type,
      id: (id != null && id.isNotEmpty) ? id : null,
      data: Map<String, dynamic>.unmodifiable(resolvedData),
    );
  }

  /// Parses a JSON string into a [NotificationPayload].
  ///
  /// Throws [NotificationPayloadException] if the JSON is malformed
  /// or does not evaluate to a Map structure.
  factory NotificationPayload.fromJson(String jsonString) {
    if (jsonString.trim().isEmpty) {
      throw const NotificationPayloadException(
        'Cannot parse empty JSON string into NotificationPayload.',
      );
    }

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) {
        throw NotificationPayloadException(
          'Expected JSON object for notification payload, got: ${decoded.runtimeType}',
        );
      }
      return NotificationPayload.fromMap(decoded);
    } on FormatException catch (e, stackTrace) {
      throw NotificationPayloadException(
        'Malformed JSON string provided to NotificationPayload.fromJson: ${e.message}',
        cause: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Generates a deterministic fingerprint string used for deduplication.
  ///
  /// Priority:
  /// 1. Explicit [id] if present and non-empty.
  /// 2. Canonical deterministic representation of [type] and sorted [data].
  String get fingerprint {
    if (id != null && id!.isNotEmpty) {
      return 'id:$id';
    }
    return _buildDataFingerprint(type, data);
  }

  static String _buildDataFingerprint(String type, Map<String, dynamic> data) {
    final sortedKeys = data.keys.toList()..sort();
    final parts = <String>[];
    for (final key in sortedKeys) {
      final value = data[key];
      parts.add('$key:${_normalizeValue(value)}');
    }
    return 'type:$type;data:{${parts.join(',')}}';
  }

  static String _normalizeValue(dynamic value) {
    if (value is Map) {
      final sortedSubKeys = value.keys.map((k) => k.toString()).toList()
        ..sort();
      final subParts = <String>[];
      for (final k in sortedSubKeys) {
        subParts.add('$k:${_normalizeValue(value[k])}');
      }
      return '{${subParts.join(',')}}';
    } else if (value is List) {
      final listParts = value.map(_normalizeValue).toList();
      return '[${listParts.join(',')}]';
    }
    return value?.toString() ?? 'null';
  }

  /// Converts this payload to a normalized Map representation.
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      if (id != null) 'id': id,
      'data': Map<String, dynamic>.from(data),
    };
  }

  /// Converts this payload to a JSON string.
  String toJson() => jsonEncode(toMap());

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NotificationPayload) return false;
    if (runtimeType != other.runtimeType) return false;
    if (type != other.type || id != other.id) return false;
    return _deepMapEquals(data, other.data);
  }

  @override
  int get hashCode => Object.hash(
        type,
        id,
        _deepHashCode(data),
      );

  static bool _deepMapEquals(
      Map<dynamic, dynamic>? a, Map<dynamic, dynamic>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      final valA = a[key];
      final valB = b[key];
      if (!_deepEquals(valA, valB)) return false;
    }
    return true;
  }

  static bool _deepEquals(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a is Map && b is Map) {
      return _deepMapEquals(a, b);
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  static int _deepHashCode(dynamic val) {
    if (val is Map) {
      return Object.hashAll(
        val.entries.map((e) => Object.hash(e.key, _deepHashCode(e.value))),
      );
    }
    if (val is List) {
      return Object.hashAll(val.map(_deepHashCode));
    }
    return val.hashCode;
  }

  @override
  String toString() => 'NotificationPayload(type: $type, id: $id, data: $data)';
}
