import 'package:firebase_messaging/firebase_messaging.dart';

/// Strongly-typed outcome of [NotificationDispatcher.parse]. Describes only
/// where a notification tap SHOULD go — it never performs navigation.
///
/// FCM data payloads are always `Map<String, String>` on the wire, so every
/// recognized field is exposed as a nullable [String]. [payload] retains the
/// full original map (including fields not promoted to a typed getter, e.g.
/// `planet`/`house`, `category`/`severity`, `mahadasha`/`antardasha`) so no
/// information is lost ahead of the Event Card phase.
///
/// [title]/[body] are the notification's own display text — for a push tap
/// this is `RemoteMessage.notification` (a *different* part of the message
/// than `data`, which only [payload]/[type]/[eventId]/[route] come from);
/// for a Bell tap this is the Notification Center item's own `title`/`body`
/// fields (siblings of `data` in that JSON shape, not inside it). Carried
/// here — not re-derived per destination screen — so any content-only
/// destination (N1: [eventId] that isn't a resolvable AstroEvent id) can
/// render the notification's actual content without a second network call.
final class NotificationDispatchDestination {
  const NotificationDispatchDestination({
    this.type,
    this.eventId,
    this.route,
    this.title,
    this.body,
    this.payload = const {},
  });

  final String? type;
  final String? eventId;
  final String? route;
  final String? title;
  final String? body;
  final Map<String, dynamic> payload;

  @override
  String toString() =>
      'NotificationDispatchDestination(type: $type, eventId: $eventId, '
      'route: $route, title: $title, body: $body, payload: $payload)';
}

/// Centralized decision point for "where should this notification tap go" —
/// for every entry point (FCM tap, Notification Center tap, and any future
/// deep link). Every one of them must be parsed through this class rather
/// than reading a payload/JSON map directly at the call site, so field
/// extraction only ever happens in one place.
final class NotificationDispatcher {
  const NotificationDispatcher._();

  /// Parses an FCM [RemoteMessage] (foreground/background-opened/terminated
  /// tap) into a [NotificationDispatchDestination]. `title`/`body` come from
  /// [RemoteMessage.notification] — the display block FCM itself renders in
  /// the tray — not from `data`.
  static NotificationDispatchDestination parse(RemoteMessage message) {
    try {
      return _build(
        data: message.data,
        title: _stringOrNull(message.notification?.title),
        body: _stringOrNull(message.notification?.body),
      );
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
      return _build(
        data: dataMap ?? const {},
        // title/body are siblings of `data` in this item shape (see
        // AppNotification.toJson()), not nested inside it.
        title: _stringOrNull(map?['title']),
        body: _stringOrNull(map?['body']),
      );
    } catch (_) {
      return const NotificationDispatchDestination();
    }
  }

  static NotificationDispatchDestination _build({
    required Map<String, dynamic> data,
    String? title,
    String? body,
  }) {
    return NotificationDispatchDestination(
      type: _stringOrNull(data['type']),
      eventId: _stringOrNull(data['event_id']),
      route: _stringOrNull(data['route']),
      title: title,
      body: body,
      payload: Map<String, dynamic>.from(data),
    );
  }

  static String? _stringOrNull(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
