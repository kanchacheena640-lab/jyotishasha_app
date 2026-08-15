import 'package:flutter/material.dart';

import 'package:jyotishasha_app/core/models/events/event_resource_contracts.dart';
import 'package:jyotishasha_app/core/notifications/notification_dispatcher.dart';
import 'package:jyotishasha_app/core/resources/resource_router.dart';
import 'package:jyotishasha_app/core/sharing/share_service.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

/// N3 — the destination for a personalized Planetary Transit notification
/// tap (`type: "transit"`), from either push or Bell.
///
/// N3.1: a real-device tap on the very first live transit notification
/// (profile 276, Moon → 12th House) exposed two problems, not one — this
/// page's job is now to fix both without touching routing, which was
/// already correct:
///
/// 1. The tap that was actually observed opened `/event` (Share only, no
///    Know More — because a transit AstroEvent has never had a backend
///    Resource wired to it, see EventDispatcherPage). Root cause: the
///    device that received that notification was running a build from
///    before the N1.1/N3 routing commit landed — an old-APK problem, not a
///    code defect (`/transit-article` already resolves correctly for
///    `type: "transit"` in the reviewed, committed code — see
///    NotificationNavigationService._resolveRoute()). No routing change
///    made here.
/// 2. Independent of that: this page's own PREVIOUS implementation jumped
///    straight into AuthorityResourceScreen/InAppWebView with no
///    interstitial at all — it never showed the notification's own
///    context, and had no Share action. That is a genuine product gap,
///    fixed below: this page now renders the notification's own
///    title/body first (the same "retain useful context" pattern
///    NotificationDetailPage already established for Alerts/Dasha), then
///    offers a prominent, localized "Read More"/"Know More" CTA that opens
///    the backend-resolved Planet-in-House article — through the EXACT
///    SAME [ResourceRouter] → [AuthorityResourceScreen] → InAppWebView
///    path EventDispatcherPage's own "Know More" button already uses, not
///    a second navigation mechanism — plus a Share action, reusing
///    [ShareService] exactly as EventDispatcherPage does. No new
///    localization keys were added: `eventKnowMoreCta`/`eventShareCta`/
///    `notificationDetailAppBarTitle`/`shareBranding`/`shareDownloadApp`/
///    `shareVisitWebsite` already exist and already cover this CTA row in
///    both languages ("Know More" / "और जानें", "Share" / "शेयर करें").
///
/// The backend already resolved and sent the exact, verified Planet-in-House
/// article URL for this user's own house + language
/// (`services/notification_builder.py::build_transit_content()` /
/// `_planet_in_house_url()`) — this page does no URL construction, planet/
/// house lookup, or language decision of its own.
///
/// A missing/malformed `url` (backend contract violation, older cached
/// payload, etc.) is handled by simply not showing the Read More button —
/// the notification's own title/body and Share remain available rather
/// than the page failing outright.
class TransitArticlePage extends StatelessWidget {
  const TransitArticlePage({super.key, this.destination});

  final NotificationDispatchDestination? destination;

  bool get _hasTitle => (destination?.title ?? '').trim().isNotEmpty;
  bool get _hasBody => (destination?.body ?? '').trim().isNotEmpty;

  String? get _url {
    final raw = destination?.payload['url'];
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final horizontalPadding = MediaQuery.sizeOf(context).width < 360
        ? 16.0
        : 20.0;
    final url = _url;

    return Scaffold(
      appBar: AppBar(title: Text(t.notificationDetailAppBarTitle)),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_hasTitle) ...[
              Text(
                destination!.title!,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_hasBody) ...[
              Text(
                destination!.body!,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 28),
            ],
            if (_hasTitle || _hasBody) ...[
              const Divider(height: 1),
              const SizedBox(height: 20),
            ],

            // "Read More" / "Know More" — same CTA label EventDispatcherPage
            // already uses, same ResourceRouter destination. Hidden (not a
            // disabled button, not an error state) when the backend hasn't
            // sent a usable url -- Share below still works either way.
            if (url != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => ResourceRouter.open(
                    context,
                    ResourceDto(
                      type: 'authority',
                      id: destination?.eventId,
                      url: url,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(t.eventKnowMoreCta),
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _share(context, t, url),
                icon: const Icon(Icons.ios_share),
                label: Text(t.eventShareCta),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Same centralized ShareService every other feature routes through (see
  // EventDispatcherPage._shareEvent) -- no page-specific share formatting,
  // no direct share-plugin call. Falls back to the app name if the payload
  // carried no title (defensive only; the backend always sends one).
  void _share(BuildContext context, AppLocalizations t, String? url) {
    ShareService.share(
      ShareableContent(
        title: destination?.title ?? t.appName,
        description: destination?.body,
        canonicalUrl: url,
        brandingTagline: t.shareBranding,
        downloadAppLabel: t.shareDownloadApp,
        visitWebsiteLabel: t.shareVisitWebsite,
      ),
    );
  }
}
