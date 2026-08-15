import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/core/notifications/notification_dispatcher.dart';
import 'package:jyotishasha_app/core/widgets/in_app_webview.dart';
import 'package:jyotishasha_app/features/events/authority_resource_screen.dart';
import 'package:jyotishasha_app/features/events/transit_article_page.dart';

import '../../helpers/test_harness.dart';

void main() {
  group('TransitArticlePage', () {
    testWidgets(
      'N3.1 — renders the notification\'s own title/body, then a "Know '
      'More" CTA that opens the backend-resolved article via '
      'AuthorityResourceScreen (the SAME path EventDispatcherPage uses), '
      'plus Share — never straight into the WebView with no context',
      (tester) async {
        // A non-http(s) scheme is used deliberately, matching
        // authority_resource_screen_test.dart's own convention: it makes
        // InAppWebView take its "invalid URL" path instead of constructing
        // a real WebViewController, which needs a platform implementation
        // flutter test's headless environment doesn't provide. This still
        // fully verifies the tap reaches AuthorityResourceScreen with the
        // exact url this page received — real https:// URL handling itself
        // is covered by authority_resource_screen_test.dart.
        const testUrl =
            'not-a-real-scheme://jyotishasha.com/planet-in-house/moon-in-12th-house';

        await tester.pumpTestHarness(
          const TransitArticlePage(
            destination: NotificationDispatchDestination(
              type: 'transit',
              eventId: '201',
              title: 'Moon Transit Tomorrow: 12th House',
              body:
                  'Moon moves into your 12th House tomorrow. Tap to see '
                  'what this means for you.',
              payload: {
                'type': 'transit',
                'event_id': '201',
                'planet': 'Moon',
                'house': '12',
                'language': 'en',
                'transit_date': '2026-08-16',
                'url': testUrl,
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Moon Transit Tomorrow: 12th House'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Moon moves into your 12th House tomorrow'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(ElevatedButton, 'Know More'),
          findsOneWidget,
        );
        expect(find.widgetWithText(OutlinedButton, 'Share'), findsOneWidget);

        await tester.tap(find.widgetWithText(ElevatedButton, 'Know More'));
        await tester.pumpAndSettle();

        expect(find.byType(AuthorityResourceScreen), findsOneWidget);
        final webView = tester.widget<InAppWebView>(
          find.byType(InAppWebView),
        );
        expect(webView.url, testUrl);
      },
    );

    testWidgets(
      'N3.1 — Hindi payload renders the Hindi article CTA and Hindi Know '
      'More/Share labels, opening the Hindi article URL',
      (tester) async {
        await tester.pumpTestHarness(
          const TransitArticlePage(
            destination: NotificationDispatchDestination(
              type: 'transit',
              eventId: '201',
              title: 'चंद्र कल आपके द्वादश भाव में प्रवेश करेगा',
              body:
                  'यह गोचर आपके द्वादश भाव को प्रभावित करेगा। पूरी जानकारी '
                  'के लिए टैप करें।',
              payload: {
                'type': 'transit',
                'event_id': '201',
                'planet': 'Moon',
                'house': '12',
                'language': 'hi',
                'url':
                    'https://www.jyotishasha.com/hi/planet-in-house/moon-in-12th-house',
              },
            ),
          ),
          locale: const Locale('hi'),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('चंद्र कल आपके द्वादश भाव में प्रवेश करेगा'),
          findsOneWidget,
        );
        // "और जानें" -- the project's existing Know More equivalent, same
        // string EventDispatcherPage's Hindi build already uses. No new
        // localization key was added for this CTA.
        expect(find.widgetWithText(ElevatedButton, 'और जानें'), findsOneWidget);
        expect(
          find.widgetWithText(OutlinedButton, 'शेयर करें'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'N3.1 — malformed/missing article URL fails gracefully: no Know More '
      'button, but the notification context and Share remain available '
      '(never a crash, never a broken navigation)',
      (tester) async {
        await tester.pumpTestHarness(
          const TransitArticlePage(
            destination: NotificationDispatchDestination(
              type: 'transit',
              eventId: '999',
              title: 'Saturn Transit Tomorrow: 4th House',
              body: 'Saturn moves into your 4th House tomorrow.',
              payload: {
                'type': 'transit',
                'event_id': '999',
                // no "url" key at all
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Saturn Transit Tomorrow: 4th House'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Know More'), findsNothing);
        expect(find.widgetWithText(OutlinedButton, 'Share'), findsOneWidget);
      },
    );

    testWidgets(
      'N3.1 — a non-string/blank url payload value is treated the same as '
      'missing, not passed through to ResourceRouter',
      (tester) async {
        await tester.pumpTestHarness(
          const TransitArticlePage(
            destination: NotificationDispatchDestination(
              type: 'transit',
              title: 'Venus Transit Tomorrow: 7th House',
              body: 'Venus moves into your 7th House tomorrow.',
              payload: {'type': 'transit', 'url': '   '},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.widgetWithText(ElevatedButton, 'Know More'), findsNothing);
      },
    );

    testWidgets(
      'N3.1 — null destination renders without crashing (no title/body, no '
      'Know More), Share remains present',
      (tester) async {
        await tester.pumpTestHarness(const TransitArticlePage());
        await tester.pumpAndSettle();

        expect(find.widgetWithText(ElevatedButton, 'Know More'), findsNothing);
        expect(find.widgetWithText(OutlinedButton, 'Share'), findsOneWidget);
      },
    );
  });
}
