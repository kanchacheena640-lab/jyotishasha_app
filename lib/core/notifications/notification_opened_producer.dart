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
  ///
  /// Campaign C Analytics Hardening (P0) -- an `idempotencyKey` is now
  /// always attached when `payload['notification_id']` is present, so a
  /// re-processed `getInitialMessage()`/`onMessageOpenedApp()` dispatch
  /// for the SAME physical notification (a known cold-start double-fire
  /// on some Android versions), or a genuine repeat tap on an
  /// already-opened item, can never record a second `notification_opened`
  /// for it. See [_idempotencyKey]'s own doc for the exact key shape and
  /// why it can never collide with [DestinationOpenedProducer]'s own key
  /// for the identical notification.
  static Future<void> emit(
    NotificationDispatchDestination destination, {
    ActivityEventClient? client,
  }) {
    final eventClient = client ?? safeDefaultActivityEventClient();
    return eventClient.record(
      eventName: 'notification_opened',
      notificationContext: _extractContext(destination.payload),
      idempotencyKey: _idempotencyKey(destination.payload),
    );
  }

  /// `notification_opened_<notification_id>` -- reuses the SAME stable
  /// identifier already carried in `notification_context.notification_id`
  /// (for a push tap: the per-send FCM `data.notification_id`; for a
  /// Campaign C tap via EITHER the system tray OR the Bell,
  /// notification_dispatcher.dart resolves this to the SAME
  /// `execution_id` for every recipient of one campaign send -- see that
  /// file's own `_buildCampaign()`), so both entry points produce the
  /// IDENTICAL key for the same real-world notification, and the
  /// backend's own existing idempotency_key -> dedupe_key -> partial
  /// unique index infrastructure (activity_events.dedupe_key,
  /// modules/activity_events/ingestion_service.py) collapses any retry
  /// or duplicate tap to the one already-recorded row. The
  /// `notification_opened_` prefix is a deliberate, explicit namespace --
  /// even though the backend's own dedupe_key already segments by
  /// event_name too, this keeps [NotificationOpenedProducer]'s and
  /// [DestinationOpenedProducer]'s own keys visibly, structurally
  /// distinct for the SAME notification_id, per this task's own explicit
  /// "must not share the same key" requirement. Only `[A-Za-z0-9_-]+` is
  /// ever produced here (matching the backend's own idempotency_key
  /// charset contract) -- notification_id is always a UUID string on
  /// every real payload shape this app produces. Returns null (no key
  /// sent -- the event is still recorded, just without idempotency
  /// protection) when no notification_id is present at all, which
  /// [ActivityEventClient.record] already treats as "field absent".
  static String? _idempotencyKey(Map<String, dynamic> payload) {
    final id = payload['notification_id'];
    if (id == null) return null;
    final text = id.toString().trim();
    return text.isEmpty ? null : 'notification_opened_$text';
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
