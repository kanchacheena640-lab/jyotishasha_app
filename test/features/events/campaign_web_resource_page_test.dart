import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/core/notifications/notification_dispatcher.dart';
import 'package:jyotishasha_app/features/events/campaign_web_resource_page.dart';

import '../../helpers/test_harness.dart';

/// P3E -- [CampaignWebResourcePage] is this app's SECOND, independent
/// defense-in-depth layer for Campaign C WEB_URL (the dispatcher's own
/// [NotificationDispatcher] route resolution is the first -- see
/// `notification_dispatcher_test.dart`'s own WEB_URL unapproved-domain
/// tests). These tests deliberately construct this page DIRECTLY with a
/// payload that already carries an unapproved url -- proving this page's
/// own gate holds even if some future caller ever reached it without
/// going through the dispatcher's own check first.
///
/// A real tap on the CTA (which would open a genuine `https://` url in
/// [InAppWebView]) is not exercised here -- that requires a platform
/// WebView implementation this headless environment doesn't provide (see
/// in_app_webview_test.dart's own note); what's proven here is purely
/// whether the CTA itself renders at all for a given url.
void main() {
  group('CampaignWebResourcePage', () {
    testWidgets(
      'renders the CTA for an approved jyotishasha.com url',
      (tester) async {
        await tester.pumpTestHarness(
          const CampaignWebResourcePage(
            destination: NotificationDispatchDestination(
              type: 'admin_campaign',
              title: 'Diwali Offer',
              body: 'Special offer inside',
              payload: {'url': 'https://jyotishasha.com/some/article'},
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Know More'), findsOneWidget);
        expect(find.text('Diwali Offer'), findsOneWidget);
      },
    );

    testWidgets(
      'renders the CTA for the exact approved YouTube channel url',
      (tester) async {
        await tester.pumpTestHarness(
          const CampaignWebResourcePage(
            destination: NotificationDispatchDestination(
              type: 'admin_campaign',
              title: 'Watch our channel',
              payload: {'url': 'https://www.youtube.com/@jyotishasha'},
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Know More'), findsOneWidget);
      },
    );

    testWidgets(
      'P3E: does NOT render the CTA for an unapproved-domain url -- fails '
      'closed even though this page was constructed directly, bypassing '
      'the dispatcher\'s own first-layer check',
      (tester) async {
        await tester.pumpTestHarness(
          const CampaignWebResourcePage(
            destination: NotificationDispatchDestination(
              type: 'admin_campaign',
              title: 'Diwali Offer',
              body: 'Special offer inside',
              payload: {'url': 'https://eviljyotishasha.com/phish'},
            ),
          ),
        );
        await tester.pump();

        // Title/body still render -- only the CTA (the actual navigation
        // opportunity) is withheld.
        expect(find.text('Diwali Offer'), findsOneWidget);
        expect(find.text('Special offer inside'), findsOneWidget);
        expect(find.text('Know More'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'P3E: does NOT render the CTA for a lookalike-domain url either',
      (tester) async {
        await tester.pumpTestHarness(
          const CampaignWebResourcePage(
            destination: NotificationDispatchDestination(
              type: 'admin_campaign',
              title: 'Diwali Offer',
              payload: {'url': 'https://jyotishasha.com.evil.example/phish'},
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Know More'), findsNothing);
      },
    );

    testWidgets(
      'P3E: does NOT render the CTA for a non-HTTPS url',
      (tester) async {
        await tester.pumpTestHarness(
          const CampaignWebResourcePage(
            destination: NotificationDispatchDestination(
              type: 'admin_campaign',
              title: 'Diwali Offer',
              payload: {'url': 'http://jyotishasha.com/article'},
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Know More'), findsNothing);
      },
    );

    testWidgets(
      'no CTA and no crash when destination/url is entirely absent',
      (tester) async {
        await tester.pumpTestHarness(const CampaignWebResourcePage());
        await tester.pump();

        expect(find.text('Know More'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
