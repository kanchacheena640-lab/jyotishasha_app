import 'package:flutter/material.dart';

import 'package:jyotishasha_app/core/models/events/event_resource_contracts.dart';
import 'package:jyotishasha_app/core/notifications/notification_dispatcher.dart';
import 'package:jyotishasha_app/features/events/authority_resource_screen.dart';

/// N3 — the destination for a personalized Planetary Transit notification
/// tap (`type: "transit"`), from either push or Bell.
///
/// The backend already resolved and sent the exact, verified Planet-in-House
/// article URL for this user's own house + language
/// (`services/notification_builder.py::build_transit_content()` /
/// `_planet_in_house_url()`) — this page does no URL construction, planet/
/// house lookup, or language decision of its own; it only reads
/// `destination.payload['url']` and reuses the SAME existing "open an
/// article in-app" product pattern `EventDispatcherPage`'s own "Know More"
/// button already uses (`AuthorityResourceScreen` → the generic
/// `InAppWebView`), rather than introducing a second one.
///
/// A missing/malformed `url` (backend contract violation, older cached
/// payload, etc.) is handled entirely by `AuthorityResourceScreen`'s own
/// existing empty state — not duplicated here.
class TransitArticlePage extends StatelessWidget {
  const TransitArticlePage({super.key, this.destination});

  final NotificationDispatchDestination? destination;

  @override
  Widget build(BuildContext context) {
    final payload = destination?.payload ?? const {};
    final rawUrl = payload['url'];
    final url = rawUrl is String && rawUrl.trim().isNotEmpty
        ? rawUrl.trim()
        : null;

    return AuthorityResourceScreen(
      resource: ResourceDto(
        type: 'authority',
        id: destination?.eventId,
        url: url,
      ),
    );
  }
}
