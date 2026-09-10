import 'package:flutter/material.dart';

import 'package:jyotishasha_app/core/models/events/event_resource_contracts.dart';
import 'package:jyotishasha_app/core/notifications/destination_opened_producer.dart';
import 'package:jyotishasha_app/core/notifications/notification_dispatcher.dart';
import 'package:jyotishasha_app/core/resources/resource_router.dart';
import 'package:jyotishasha_app/l10n/app_localizations.dart';

/// N6 -- destination screen for a Campaign C (ADMIN_CAMPAIGN) WEB_URL
/// action. The url itself was already validated server-side at composer
/// save time (`notifications/campaign_service.py::valid_url()` -- only
/// `jyotishasha.com`/`www.jyotishasha.com` HTTPS or the one approved
/// YouTube URL can ever reach this page's payload); this page does not
/// re-validate it, re-derive it, or accept any other url -- same trust
/// model TransitArticlePage already uses for its own backend-resolved
/// url, no new/wider URL launcher introduced.
///
/// Opens through the EXACT SAME [ResourceRouter] ->
/// [AuthorityResourceScreen] in-app WebView path TransitArticlePage and
/// EventDispatcherPage's own "Know More" already use -- no second
/// navigation/launch mechanism.
///
/// `destination_opened` is emitted ONLY from the CTA's own `onPressed`,
/// after [ResourceRouter.open] returns without throwing -- never merely
/// because this interstitial screen was reached (that would be "the
/// notification was opened", already covered by `notification_opened`;
/// this page's own view is not yet "the destination").
class CampaignWebResourcePage extends StatelessWidget {
  const CampaignWebResourcePage({super.key, this.destination});

  final NotificationDispatchDestination? destination;

  bool get _hasTitle => (destination?.title ?? '').trim().isNotEmpty;
  bool get _hasBody => (destination?.body ?? '').trim().isNotEmpty;

  /// P3E -- second, independent layer of defense-in-depth. The dispatcher
  /// (see [NotificationDispatcher._resolveCampaignRoute]) already refuses
  /// to resolve this very route for a url outside [CampaignUrlPolicy]'s
  /// allowlist, so in practice this page is never reached with an
  /// unapproved url -- this check exists so that guarantee does not
  /// depend on this page being reached ONLY through that one call path
  /// forever; a future caller that somehow constructs this page directly
  /// still cannot render a CTA for an unapproved url.
  String? get _url {
    final raw = destination?.payload['url'];
    if (raw is! String) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return CampaignUrlPolicy.isApproved(trimmed) ? trimmed : null;
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

            // Missing/malformed url (should never happen -- the dispatcher
            // never resolves this route without one) fails safe: the
            // notification's own title/body still renders, just with no
            // CTA, rather than a broken button or a crash.
            if (url != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _open(context, url),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(t.eventKnowMoreCta),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, String url) {
    // P3E -- redirect defense-in-depth: the WebView is allowed to load
    // [url] itself (already proven approved by this page's own [_url]
    // getter and, before that, the dispatcher), but is NOT free to follow
    // an in-page redirect or link tap to anywhere outside the same
    // approved allowlist -- see [InAppWebView.isNavigationAllowed]'s own
    // docstring. Every other [ResourceRouter.open] caller
    // (TransitArticlePage, EventDispatcherPage) omits this and keeps its
    // existing unrestricted-navigation behavior exactly.
    ResourceRouter.open(
      context,
      ResourceDto(type: 'authority', url: url),
      isNavigationAllowed: (uri) => CampaignUrlPolicy.isApproved(uri.toString()),
    );
    final current = destination;
    if (current != null) {
      DestinationOpenedProducer.emit(current);
    }
  }
}
