import 'package:firebase_messaging/firebase_messaging.dart';

/// Strongly-typed outcome of [NotificationDispatcher.parse]. Describes only
/// where a notification tap SHOULD go — it never performs navigation.
///
/// FCM data payloads are always `Map<String, String>` on the wire, so every
/// recognized field is exposed as a nullable [String]. [payload] retains the
/// full original map (including fields not promoted to a typed getter, e.g.
/// `planet`/`house`) so no information is lost ahead of the Event Card phase.
final class NotificationDispatchDestination {
  const NotificationDispatchDestination({
    this.type,
    this.eventId,
    this.route,
    this.payload = const {},
  });

  final String? type;
  final String? eventId;
  final String? route;
  final Map<String, dynamic> payload;

  @override
  String toString() =>
      'NotificationDispatchDestination(type: $type, eventId: $eventId, '
      'route: $route, payload: $payload)';
}

/// Centralized decision point for "where should this notification tap go" —
/// for every entry point (FCM tap, Notification Center tap, and any future
/// deep link). Every one of them must be parsed through this class rather
/// than reading a payload/JSON map directly at the call site, so field
/// extraction only ever happens in one place.
final class NotificationDispatcher {
  const NotificationDispatcher._();

  /// Parses an FCM [RemoteMessage] (foreground/background-opened/terminated
  /// tap) into a [NotificationDispatchDestination].
  static NotificationDispatchDestination parse(RemoteMessage message) {
    try {
      return _fromDataMap(message.data);
    } catch (_) {
      return const NotificationDispatchDestination();
    }
  }

  /// Parses a Notification Center list item — the same backend JSON shape
  /// returned by `NotificationRepository.getNotifications()` — into the
  /// identical [NotificationDispatchDestination] shape [parse] produces for
  /// FCM, so both entry points share one field-extraction path instead of
  /// each interpreting the payload independently. Accepts `Object?` rather
  /// than a typed `Map` so a malformed/unexpected item can never throw
  /// before reaching the fail-safe fallback below.
  static NotificationDispatchDestination fromNotificationCenterItem(
    Object? item,
  ) {
    try {
      final map = item is Map ? Map<String, dynamic>.from(item) : null;
      final data = map?['data'];
      final dataMap = data is Map ? Map<String, dynamic>.from(data) : null;
      return _fromDataMap(dataMap ?? const {});
    } catch (_) {
      return const NotificationDispatchDestination();
    }
  }

  static NotificationDispatchDestination _fromDataMap(
    Map<String, dynamic> data,
  ) {
    return NotificationDispatchDestination(
      type: _stringOrNull(data['type']),
      eventId: _stringOrNull(data['event_id']),
      route: _stringOrNull(data['route']),
      payload: Map<String, dynamic>.from(data),
    );
  }

  static String? _stringOrNull(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
