import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jyotishasha_app/core/notifications/notification_dispatcher.dart';
import 'package:jyotishasha_app/features/events/notification_detail_page.dart';

import '../../helpers/test_harness.dart';

void main() {
  group('NotificationDetailPage', () {
    testWidgets(
      'renders an Alert notification\'s title/body and category/severity '
      'chips directly from the payload — no backend fetch',
      (tester) async {
        await tester.pumpTestHarness(
          const NotificationDetailPage(
            destination: NotificationDispatchDestination(
              type: 'alert',
              eventId: 'financial_gain_opportunity',
              title: 'Financial Signal',
              body: 'A financial signal is active for you today.',
              payload: {
                'type': 'alert',
                'event_id': 'financial_gain_opportunity',
                'category': 'financial',
                'severity': 'medium',
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Financial Signal'), findsOneWidget);
        expect(
          find.text('A financial signal is active for you today.'),
          findsOneWidget,
        );
        expect(find.text('Category: Financial'), findsOneWidget);
        expect(find.text('Severity: Medium'), findsOneWidget);
      },
    );

    testWidgets(
      'renders a Dasha notification\'s mahadasha/antardasha context',
      (tester) async {
        await tester.pumpTestHarness(
          const NotificationDetailPage(
            destination: NotificationDispatchDestination(
              type: 'dasha_pre',
              eventId: 'dasha_pre_42_Venus_Moon',
              title: 'Dasha Change Coming',
              body: '5 din baad aapki Venus - Moon dasha shuru hogi',
              payload: {
                'type': 'dasha_pre',
                'event_id': 'dasha_pre_42_Venus_Moon',
                'mahadasha': 'Venus',
                'antardasha': 'Moon',
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dasha Change Coming'), findsOneWidget);
        expect(
          find.text('5 din baad aapki Venus - Moon dasha shuru hogi'),
          findsOneWidget,
        );
        expect(find.text('Mahadasha: Venus'), findsOneWidget);
        expect(find.text('Antardasha: Moon'), findsOneWidget);
        // Alert-only fields must not leak in for a Dasha notification.
        expect(find.textContaining('Category:'), findsNothing);
        expect(find.textContaining('Severity:'), findsNothing);
      },
    );

    testWidgets(
      'renders no context chips when the payload carries none — never '
      'fabricates category/severity/dasha info that was not sent',
      (tester) async {
        await tester.pumpTestHarness(
          const NotificationDetailPage(
            destination: NotificationDispatchDestination(
              type: 'some_unknown_future_type',
              title: 'A future notification type',
              body: 'Its body text, shown as-is.',
              payload: {'type': 'some_unknown_future_type'},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('A future notification type'), findsOneWidget);
        expect(find.text('Its body text, shown as-is.'), findsOneWidget);
        expect(find.byType(Chip), findsNothing);
      },
    );

    testWidgets(
      'shows a graceful, honest empty state instead of a blank/crashing '
      'page when there is no title AND no body',
      (tester) async {
        await tester.pumpTestHarness(
          const NotificationDetailPage(
            destination: NotificationDispatchDestination(
              type: 'alert',
              eventId: 'unknown_event',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'No additional details are available for this notification.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders the same graceful empty state when destination itself is null',
      (tester) async {
        await tester.pumpTestHarness(const NotificationDetailPage());
        await tester.pumpAndSettle();

        expect(
          find.text(
            'No additional details are available for this notification.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders Hindi AppBar title, labels, and empty-state text end to end',
      (tester) async {
        await tester.pumpTestHarness(
          const NotificationDetailPage(
            destination: NotificationDispatchDestination(
              type: 'alert',
              eventId: 'mood_positive',
              title: 'मूड में बदलाव',
              body: 'आज आपका भावनात्मक दृष्टिकोण बदल सकता है।',
              payload: {'category': 'emotional', 'severity': 'low'},
            ),
          ),
          locale: const Locale('hi'),
        );
        await tester.pumpAndSettle();

        expect(find.text('सूचना'), findsOneWidget); // AppBar title
        expect(find.text('मूड में बदलाव'), findsOneWidget);
        expect(find.text('श्रेणी: Emotional'), findsOneWidget);
        expect(find.text('गंभीरता: Low'), findsOneWidget);
      },
    );
  });
}
