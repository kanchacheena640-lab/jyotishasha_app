import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:jyotishasha_app/core/models/events/event_resource_contracts.dart';
import 'package:jyotishasha_app/core/notifications/notification_dispatcher.dart';
import 'package:jyotishasha_app/core/state/language_provider.dart';
import 'package:jyotishasha_app/features/events/authority_resource_screen.dart';
import 'package:jyotishasha_app/features/events/event_dispatcher_page.dart';

import '../../helpers/test_harness.dart';
import '../../mocks/common_mocks.dart';

void main() {
  group('EventDispatcherPage', () {
    Widget wrap(Widget child) => ChangeNotifierProvider<LanguageProvider>(
      create: (_) => LanguageProvider(),
      child: child,
    );

    testWidgets('shows a loading indicator while the request is in flight', (
      tester,
    ) async {
      final repository = MockEventRepository();
      final completer = Completer<EventResourceResponse>();
      when(
        () => repository.getEventResource(
          eventId: any(named: 'eventId'),
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) => completer.future);

      await tester.pumpTestHarness(
        wrap(
          EventDispatcherPage(
            destination: const NotificationDispatchDestination(
              eventId: '62',
            ),
            eventRepository: repository,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Resolve the pending future so nothing is left outstanding when the
      // test ends.
      completer.complete(const EventResourceResponse());
      await tester.pumpAndSettle();
    });

    testWidgets(
      'renders title, body, type, and date, and shows Know More when a resource exists',
      (tester) async {
        final repository = MockEventRepository();
        when(
          () => repository.getEventResource(
            eventId: 62,
            language: any(named: 'language'),
          ),
        ).thenAnswer(
          (_) async => const EventResourceResponse(
            schemaVersion: 1,
            event: EventDto(
              id: 62,
              type: 'vrat',
              title: 'Trisparsha Mahadwadashi, Yogini Ekadashi Tomorrow',
              body: 'Some event body text.',
              date: '2026-07-11',
            ),
            resource: ResourceDto(type: 'authority', id: 'ekadashi/yogini'),
          ),
        );

        await tester.pumpTestHarness(
          wrap(
            EventDispatcherPage(
              destination: const NotificationDispatchDestination(
                eventId: '62',
              ),
              eventRepository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Trisparsha Mahadwadashi, Yogini Ekadashi Tomorrow'),
          findsOneWidget,
        );
        expect(find.text('Some event body text.'), findsOneWidget);
        // Category chip renders the type uppercased; date renders as
        // DD-MM-YYYY (both intentional display changes, not raw pass-through
        // of the backend values anymore).
        expect(find.text('VRAT'), findsOneWidget);
        expect(find.text('11-07-2026'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Know More'), findsOneWidget);
        expect(find.widgetWithText(OutlinedButton, 'Share'), findsOneWidget);
      },
    );

    testWidgets(
      'renders Hindi CTA/AppBar text end to end when the app locale is '
      'Hindi — proves this is not hardcoded English',
      (tester) async {
        final repository = MockEventRepository();
        when(
          () => repository.getEventResource(
            eventId: 62,
            language: any(named: 'language'),
          ),
        ).thenAnswer(
          (_) async => const EventResourceResponse(
            schemaVersion: 1,
            event: EventDto(
              id: 62,
              type: 'vrat',
              title: 'योगिनी एकादशी कल',
              body: 'व्रत और भक्ति का विशेष दिन।',
              date: '2026-07-11',
            ),
            resource: ResourceDto(type: 'authority', id: 'ekadashi/yogini'),
          ),
        );

        await tester.pumpTestHarness(
          ChangeNotifierProvider<LanguageProvider>(
            create: (_) => LanguageProvider()..currentLang = 'hi',
            child: EventDispatcherPage(
              destination: const NotificationDispatchDestination(
                eventId: '62',
              ),
              eventRepository: repository,
            ),
          ),
          locale: const Locale('hi'),
        );
        await tester.pumpAndSettle();

        expect(find.text('इवेंट'), findsOneWidget); // AppBar title
        expect(find.text('योगिनी एकादशी कल'), findsOneWidget); // event title
        expect(find.widgetWithText(ElevatedButton, 'और जानें'), findsOneWidget);
        expect(find.widgetWithText(OutlinedButton, 'शेयर करें'), findsOneWidget);
        // No English CTA text alongside the Hindi — a real switch, not both
        // languages rendering at once.
        expect(find.text('Event'), findsNothing);
        expect(find.text('Know More'), findsNothing);
        expect(find.text('Share'), findsNothing);
      },
    );

    testWidgets(
      'tapping Know More routes an authority resource to AuthorityResourceScreen',
      (tester) async {
        final repository = MockEventRepository();
        when(
          () => repository.getEventResource(
            eventId: 62,
            language: any(named: 'language'),
          ),
        ).thenAnswer(
          (_) async => const EventResourceResponse(
            schemaVersion: 1,
            event: EventDto(
              id: 62,
              type: 'vrat',
              title: 'Some title',
              body: 'Some body',
              date: '2026-07-11',
            ),
            resource: ResourceDto(type: 'authority', id: 'ekadashi/yogini'),
          ),
        );

        // AuthorityResourceScreen is reached via Navigator.push, a second
        // route — LanguageProvider (needed by EventDispatcherPage's own
        // event-fetch call, not by AuthorityResourceScreen) must be
        // supplied above MaterialApp via `providers:`, not wrapped around
        // just this page via `wrap()`, or it would be invisible once the
        // second route is pushed.
        await tester.pumpTestHarness(
          EventDispatcherPage(
            destination: const NotificationDispatchDestination(eventId: '62'),
            eventRepository: repository,
          ),
          providers: [
            ChangeNotifierProvider<LanguageProvider>(
              create: (_) => LanguageProvider(),
            ),
          ],
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Know More'));
        await tester.pumpAndSettle();

        // No `url` on the mocked resource: a non-null resource.url would
        // make AuthorityResourceScreen open a real WebView, whose
        // WebViewController requires a platform implementation flutter
        // test's headless environment doesn't provide (see
        // in_app_webview_test.dart). This test's job is to verify the tap
        // reaches AuthorityResourceScreen end to end; resource.url handling
        // itself is covered by authority_resource_screen_test.dart.
        expect(find.byType(AuthorityResourceScreen), findsOneWidget);
        expect(find.text('Content not available'), findsOneWidget);
      },
    );

    testWidgets('hides Know More entirely when resource is null', (
      tester,
    ) async {
      final repository = MockEventRepository();
      when(
        () => repository.getEventResource(
          eventId: 62,
          language: any(named: 'language'),
        ),
      ).thenAnswer(
        (_) async => const EventResourceResponse(
          schemaVersion: 1,
          event: EventDto(
            id: 62,
            type: 'vrat',
            title: 'Some title',
            body: 'Some body',
            date: '2026-07-11',
          ),
          resource: null,
        ),
      );

      await tester.pumpTestHarness(
        wrap(
          EventDispatcherPage(
            destination: const NotificationDispatchDestination(
              eventId: '62',
            ),
            eventRepository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('Some title'), findsOneWidget);
    });

    testWidgets('renders gracefully instead of crashing on a network/API failure', (
      tester,
    ) async {
      final repository = MockEventRepository();
      // thenAnswer with an async closure, not thenThrow: simulates an
      // async failure (a failed Future), matching how the real
      // (always-`async`) HttpEventRepository actually fails.
      when(
        () => repository.getEventResource(
          eventId: any(named: 'eventId'),
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => throw Exception('Event resource API error 404'));

      await tester.pumpTestHarness(
        wrap(
          EventDispatcherPage(
            destination: const NotificationDispatchDestination(
              eventId: '62',
            ),
            eventRepository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Something went wrong. Please try again later.'),
        findsOneWidget,
      );
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets(
      'renders gracefully instead of crashing when eventId is missing/invalid',
      (tester) async {
        final repository = MockEventRepository();

        await tester.pumpTestHarness(
          wrap(
            EventDispatcherPage(
              destination: const NotificationDispatchDestination(),
              eventRepository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No event data available.'), findsOneWidget);
        verifyNever(
          () => repository.getEventResource(
            eventId: any(named: 'eventId'),
            language: any(named: 'language'),
          ),
        );
      },
    );

    testWidgets(
      'renders gracefully instead of crashing when destination itself is null',
      (tester) async {
        final repository = MockEventRepository();

        await tester.pumpTestHarness(
          wrap(EventDispatcherPage(eventRepository: repository)),
        );
        await tester.pumpAndSettle();

        expect(find.text('No event data available.'), findsOneWidget);
      },
    );
  });
}
