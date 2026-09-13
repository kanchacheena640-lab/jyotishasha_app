import 'package:jyotishasha_app/core/analytics/safe_default_activity_event_client.dart';
import 'package:jyotishasha_app/core/notifications/notification_dispatcher.dart';
import 'package:jyotishasha_app/services/activity_event_client.dart';

/// N6 -- emits the canonical `destination_opened` event: NOT "the OS
/// notification was tapped" (that is [NotificationOpenedProducer]'s own,
/// separate, frozen `notification_opened`) but "the app actually reached
/// the notification's destination". A genuinely distinct, later moment --
/// see the backend's own event_schemas.py registration comment for the
/// full ownership/distinctness justification. Never renamed to
/// `notification_clicked`/`push_clicked`/`notification_tapped` or any
/// other near-duplicate.
///
/// Scoped to Campaign C (ADMIN_CAMPAIGN) only in this app today -- A/B
/// notifications have no destination-open concept of their own defined by
/// this task, and this class is never called for them.
class DestinationOpenedProducer {
  DestinationOpenedProducer._();

  static const List<String> _allowedContextKeys = [
    'notification_id',
    'campaign_id',
    'slot',
  ];

  /// Fire-and-forget, mirrors [NotificationOpenedProducer.emit] exactly:
  /// never throws, never awaited by a caller for correctness, no
  /// `properties`, only the frozen `notification_context` envelope, and
  /// only for keys actually present in `destination.payload`.
  ///
  /// Campaign C Analytics Hardening (P0) -- carries its own
  /// `idempotencyKey`, independently of [NotificationOpenedProducer]'s
  /// own (see [_idempotencyKey]), so a duplicate `maybeEmitForDeepLink`
  /// call for the same notification can never inflate
  /// `destination_opened_count` either.
  static Future<void> emit(
    NotificationDispatchDestination destination, {
    ActivityEventClient? client,
  }) {
    final eventClient = client ?? safeDefaultActivityEventClient();
    return eventClient.record(
      eventName: 'destination_opened',
      notificationContext: _extractContext(destination.payload),
      idempotencyKey: _idempotencyKey(destination.payload),
    );
  }

  /// Emits ONLY when `destination` is a Campaign C destination that
  /// resolved to a genuine APP_DEEP_LINK route (one of the 6 frozen
  /// targets) -- never for NONE, never for an unsupported/invalid target
  /// that fell back to Notification Detail, and never for WEB_URL (whose
  /// own success signal fires later, from CampaignWebResourcePage itself,
  /// once the link actually opens -- see that page).
  ///
  /// Called exactly once, synchronously, right after the single shared
  /// navigation call at each tap seam (push-tap in main.dart, Bell-tap in
  /// greeting_header_widget.dart) -- never from a screen's own lifecycle
  /// -- so a Bell tap, its navigation callback, and the destination
  /// screen's own build/initState can never be miscounted as three opens.
  static void maybeEmitForDeepLink(
    NotificationDispatchDestination destination, {
    ActivityEventClient? client,
  }) {
    if (destination.type != NotificationDispatcher.campaignType) return;
    final route = destination.route;
    if (route == null) return;
    if (!NotificationDispatcher.campaignDeepLinkRoutes.contains(route)) return;
    emit(destination, client: client);
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
    return context.isEmpty ? null : context;
  }

  /// `destination_opened_<notification_id>` -- see
  /// [NotificationOpenedProducer._idempotencyKey]'s own doc for the full
  /// reasoning (identical stable identifier, identical charset
  /// contract). The `destination_opened_` prefix is DELIBERATELY
  /// different from that producer's `notification_opened_` prefix so the
  /// two events can never share a key for the same notification_id, per
  /// this task's own explicit requirement, even though the backend's own
  /// dedupe_key already segments by event_name too.
  static String? _idempotencyKey(Map<String, dynamic> payload) {
    final id = payload['notification_id'];
    if (id == null) return null;
    final text = id.toString().trim();
    return text.isEmpty ? null : 'destination_opened_$text';
  }
}
