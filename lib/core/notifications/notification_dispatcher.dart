import 'dart:convert';

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

  /// N6 -- the exact `source` literal campaign_worker.py's FCM payload
  /// (unmodified) and the unified Bell list response both use to identify
  /// a Campaign C (ADMIN_CAMPAIGN) row. Checked BEFORE the generic `type`-
  /// based path below, since Campaign C's shape (`action_type`/
  /// `action_target`/`campaign_action`) is structurally different from
  /// every A/B `type`/`route`/`event_id` payload -- never guessed from
  /// `type` alone.
  static const String campaignSource = 'ADMIN_CAMPAIGN';

  /// N6 -- the synthetic `type` this dispatcher assigns every Campaign C
  /// destination, so downstream code (Bell-tap notification_opened gating,
  /// deep-link destination_opened gating, the Bell row's leading icon)
  /// has one authoritative discriminator, exactly like every other `type`
  /// already has. Never sent by the backend itself under this name.
  static const String campaignType = 'admin_campaign';

  /// N6 -- frozen N3/N4 APP_DEEP_LINK target -> real app route. Do not
  /// widen: exactly the 6 allowlisted targets, nothing else.
  static const Map<String, String> _appDeepLinkRoutes = {
    'ASK_NOW': '/asknow',
    'KUNDALI': '/kundali/overview',
    'REPORTS': '/reports',
    'SUBSCRIPTION': '/subscription',
    'PROFILE': '/profile',
    'DASHBOARD': '/dashboard',
  };

  /// N6 -- interstitial route for a Campaign C WEB_URL action (reuses the
  /// existing ResourceRouter/AuthorityResourceScreen in-app WebView, the
  /// same mechanism TransitArticlePage already uses for its own
  /// backend-resolved URL -- see CampaignWebResourcePage).
  static const String campaignWebRoute = '/campaign-web';

  /// N6 -- every real (non-fallback) route a Campaign C APP_DEEP_LINK
  /// destination can resolve to. Used to gate destination_opened so it is
  /// never fired for a destination that actually fell back to Notification
  /// Detail (an unsupported/invalid target, or NONE).
  static Set<String> get campaignDeepLinkRoutes => _appDeepLinkRoutes.values.toSet();

  /// Parses an FCM [RemoteMessage] (foreground/background-opened/terminated
  /// tap) into a [NotificationDispatchDestination]. `title`/`body` come from
  /// [RemoteMessage.notification] — the display block FCM itself renders in
  /// the tray — not from `data`.
  static NotificationDispatchDestination parse(RemoteMessage message) {
    try {
      final data = message.data;
      final title = _stringOrNull(message.notification?.title);
      final body = _stringOrNull(message.notification?.body);
      if (_stringOrNull(data['source']) == campaignSource) {
        return _buildCampaign(
          campaignId: _stringOrNull(data['campaign_id']),
          notificationId: _stringOrNull(data['execution_id']) ?? _stringOrNull(data['campaign_id']),
          actionType: _stringOrNull(data['action_type']),
          actionTarget: _stringOrNull(data['action_target']),
          actionParameters: _parseActionParameters(data['action_parameters']),
          title: title,
          body: body,
        );
      }
      return _build(data: data, title: title, body: body);
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
      if (map == null) return const NotificationDispatchDestination();

      final title = _stringOrNull(map['title']);
      final body = _stringOrNull(map['body']);

      // N6 -- a Campaign C Bell row has NO `data` key at all (its own
      // navigation shape lives in the sibling `campaign_action` key) --
      // checked by `source`, never guessed from the presence/absence of
      // `data`.
      if (_stringOrNull(map['source']) == campaignSource) {
        final action = map['campaign_action'];
        final actionMap = action is Map ? Map<String, dynamic>.from(action) : const {};
        return _buildCampaign(
          campaignId: _stringOrNull(map['campaign_id']),
          notificationId: _stringOrNull(map['execution_id']) ?? _stringOrNull(map['campaign_id']),
          actionType: _stringOrNull(actionMap['type']),
          actionTarget: _stringOrNull(actionMap['target']),
          actionParameters: actionMap['parameters'] is Map
              ? Map<String, dynamic>.from(actionMap['parameters'] as Map)
              : null,
          title: title,
          body: body,
        );
      }

      final data = map['data'];
      final dataMap = data is Map ? Map<String, dynamic>.from(data) : null;
      return _build(
        data: dataMap ?? const {},
        // title/body are siblings of `data` in this item shape (see
        // AppNotification.toJson()), not nested inside it.
        title: title,
        body: body,
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

  /// N6 -- resolves a Campaign C action (frozen N3/N4 registry only) into
  /// the same [NotificationDispatchDestination] shape every other type
  /// already produces, from EITHER of Campaign C's two on-the-wire shapes
  /// (FCM's flat `action_type`/`action_target`/`action_parameters`, or the
  /// Bell's nested `campaign_action`) -- both call sites above normalize
  /// to this one set of named arguments first.
  ///
  /// `route` is left null for NONE and for any target outside the frozen
  /// allowlist (or a WEB_URL with no usable url) -- NotificationNavigation
  /// Service's own existing fallback (no explicit route + a `type` outside
  /// its AstroEvent-backed set) then correctly lands on
  /// `/notification-detail`, with ZERO changes to that class.
  static NotificationDispatchDestination _buildCampaign({
    String? campaignId,
    String? notificationId,
    String? actionType,
    String? actionTarget,
    Map<String, dynamic>? actionParameters,
    String? title,
    String? body,
  }) {
    final url = _stringOrNull(actionParameters?['url']);
    final route = _resolveCampaignRoute(actionType, actionTarget, url);
    final payload = <String, dynamic>{
      if (campaignId != null) 'campaign_id': campaignId,
      if (notificationId != null) 'notification_id': notificationId,
      'slot': 'general',
      if (actionType != null) 'action_type': actionType,
      if (actionTarget != null) 'action_target': actionTarget,
      if (url != null) 'url': url,
    };
    return NotificationDispatchDestination(
      type: campaignType,
      eventId: null,
      route: route,
      title: title,
      body: body,
      payload: payload,
    );
  }

  static String? _resolveCampaignRoute(
    String? actionType,
    String? actionTarget,
    String? url,
  ) {
    switch (actionType) {
      case 'APP_DEEP_LINK':
        // A target outside the frozen allowlist resolves to null here --
        // never a widened/invented route -- so the caller falls back to
        // Notification Detail exactly like an unsupported type today.
        return _appDeepLinkRoutes[actionTarget];
      case 'WEB_URL':
        // P3E -- client-side defense-in-depth: previously this only
        // checked "is there a url at all", trusting the backend's own
        // composer-time `valid_url()` validation completely. That
        // validation is still authoritative and still never re-derived
        // or widened here -- but a client that ALSO refuses to resolve a
        // route for a url outside the exact same approved set is a real,
        // free second layer, in case a url is ever mistakenly stored
        // without going through that validation (a backend bug, a
        // migration, a future code path) or a bad actor with response
        // write access (a different threat, still worth failing closed
        // on).
        return (url != null && CampaignUrlPolicy.isApproved(url))
            ? campaignWebRoute
            : null;
      case 'NONE':
      default:
        return null;
    }
  }

  /// P2 -- real FCM `data` payloads are always `Map<String, String>` on the
  /// wire (a platform constraint, not a choice this app made), so a real
  /// WEB_URL push's `action_parameters` arrives as a JSON-ENCODED STRING
  /// (e.g. `'{"url":"https://jyotishasha.com/..."}'`), never a native Dart
  /// Map -- unlike the Bell/API path ([fromNotificationCenterItem]), whose
  /// JSON body already decodes a nested object into a real Map before this
  /// code ever sees it. [parse] was only ever exercised (in tests) with
  /// APP_DEEP_LINK, which needs no `action_parameters` at all, so this gap
  /// shipped unnoticed until a real device WEB_URL push (P1 finding).
  ///
  /// Normalizes BOTH on-the-wire shapes to the identical
  /// `Map<String, dynamic>?` [_buildCampaign] already expects -- a native
  /// Map is preserved exactly as before; a String is `jsonDecode`d and
  /// used only if the decoded value is itself a Map. Anything else (null,
  /// a non-Map/non-String type, malformed JSON, or JSON that decodes to an
  /// array/scalar) fails closed to `null` -- the exact same value
  /// [_buildCampaign] already treated as "no parameters" before this
  /// change, which [_resolveCampaignRoute] already turns into a safe
  /// Notification Detail fallback for WEB_URL (no widened trust, no new
  /// validation relaxed: the url itself is still only ever used verbatim
  /// from whatever the backend's own composer-time validation already put
  /// in it, exactly as documented on [CampaignWebResourcePage]).
  static Map<String, dynamic>? _parseActionParameters(Object? raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        // Malformed JSON -- fail closed (falls through to null below),
        // never thrown further; [parse]'s own outer try/catch is a second,
        // redundant safety net, not the only one.
      }
    }
    return null;
  }

  static String? _stringOrNull(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

/// P3E -- client-side mirror of the backend's OWN Campaign C WEB_URL
/// allowlist (`notifications/campaign_service.py::WEBSITE_HOSTS`/
/// `YOUTUBE_URL`/`valid_url()`, read directly, not guessed). The backend
/// remains the single authoritative validator at composer-save time; this
/// is a SECOND, independent check applied here at consume time, so a url
/// that somehow reached the client without going through that validation
/// still cannot open. Never widens the backend's allowlist -- if anything,
/// this is free to be equally strict or stricter, never looser.
///
/// Uses proper URI host parsing ([Uri.host], exact [Set] membership) --
/// never substring/`contains`/`endsWith` matching, which a lookalike host
/// like `jyotishasha.com.evil.example` (host IS that whole string, not
/// `jyotishasha.com`) or `eviljyotishasha.com` (host is that whole string,
/// still not an exact match) would otherwise slip past.
class CampaignUrlPolicy {
  const CampaignUrlPolicy._();

  /// Exact-match only -- mirrors backend `WEBSITE_HOSTS`. No subdomain
  /// wildcarding: `blog.jyotishasha.com` is NOT approved unless the
  /// backend's own set is ever widened to include it (it is not, today).
  static const Set<String> _approvedHosts = {
    'jyotishasha.com',
    'www.jyotishasha.com',
  };

  /// Exact URL match only (after trailing-slash tolerance, mirroring the
  /// backend's own `value.rstrip('/') == YOUTUBE_URL`) -- mirrors backend
  /// `YOUTUBE_URL`. This is NOT a `youtube.com`/`www.youtube.com` HOST
  /// allowlist (any other YouTube video/channel is NOT approved) --
  /// deliberately narrower than a host check, exactly matching the
  /// backend's own narrower-than-host validation.
  static const String _approvedYoutubeUrl =
      'https://www.youtube.com/@jyotishasha';

  /// True only for a url that is HTTPS, has no embedded credentials, uses
  /// only the default HTTPS port (443, or unspecified), and whose host is
  /// exactly one of [_approvedHosts] -- or whose full url exactly matches
  /// [_approvedYoutubeUrl] (trailing slash tolerated). Rejects (returns
  /// `false` for) null/blank input, non-HTTPS schemes including `http`,
  /// `javascript:`, `data:`, `file:`, or any other custom scheme,
  /// malformed URIs, and any host outside the approved set -- fails
  /// closed, never throws.
  static bool isApproved(String? rawUrl) {
    if (rawUrl == null) return false;
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return false;

    final Uri? uri;
    try {
      uri = Uri.parse(trimmed);
    } on FormatException {
      return false;
    }

    if (uri.scheme.toLowerCase() != 'https') return false;
    if (uri.userInfo.isNotEmpty) return false;
    if (uri.hasPort && uri.port != 443) return false;

    final host = uri.host.toLowerCase();
    if (host.isNotEmpty && _approvedHosts.contains(host)) return true;

    final withoutTrailingSlash = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    return withoutTrailingSlash == _approvedYoutubeUrl;
  }
}
