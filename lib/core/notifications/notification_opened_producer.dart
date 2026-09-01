import 'package:jyotishasha_app/core/analytics/safe_default_activity_event_client.dart';
import 'package:jyotishasha_app/core/notifications/notification_dispatcher.dart';
import 'package:jyotishasha_app/services/activity_event_client.dart';

/// Phase 5B -- emits `notification_opened` for a real notification TAP
/// only. Must be called exclusively from the shared tap-handling seam
/// (`handleNotificationTap` in main.dart, itself reached only by
/// `FirebaseMessaging.onMessageOpenedApp` and
/// `FirebaseMessaging.instance.getInitialMessage()`) -- never from
/// foreground message receipt (`FirebaseMessaging.onMessage`, wired to a
/// separate listener that never calls `handleNotificationTap`) and never
/// on a generic app launch with no notification involved.
class NotificationOpenedProducer {
  NotificationOpenedProducer._();

  /// Frozen `notification_context` allowlist (Phase 2/3) -- nothing else
  /// is ever copied out of the raw FCM `data` payload.
  static const List<String> _allowedContextKeys = [
    'notification_id',
    'campaign_id',
    'slot',
  ];

  /// Fire-and-forget: never awaited by the caller, never throws
  /// ([ActivityEventClient.record] itself never throws). No `properties`
  /// are ever sent for this event (frozen schema: `notification_opened`
  /// -> `{}`) -- only `notification_context`, and only for keys actually
  /// present in `destination.payload` (the raw FCM `data` map). Title,
  /// body, route, type, event_id, and every other payload field are
  /// deliberately left behind -- never copied.
  static Future<void> emit(
    NotificationDispatchDestination destination, {
    ActivityEventClient? client,
  }) {
    final eventClient = client ?? safeDefaultActivityEventClient();
    return eventClient.record(
      eventName: 'notification_opened',
      notificationContext: _extractContext(destination.payload),
    );
  }

  static Map<String, Object?>? _extractContext(Map<String, dynamic> payload) {
    final context = <String, Object?>{};
    for (final key in _allowedContextKeys) {
      final value = payload[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isEmpty) continue;
      context[key] = text;
    }
    // An empty notification_context is omitted entirely rather than sent
    // as `{}` -- ActivityEventClient already treats null the same as
    // "field absent".
    return context.isEmpty ? null : context;
  }
}
